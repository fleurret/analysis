function neurometrics(spth)

sfolder = append(spth,'/Sessions');

units = dir(sfolder);
units(ismember({units.name},{'.','..'})) = [];

badclusters = {}; % keep track of which ones throw errors

for u = 1:length(units)
    ffn = fullfile(sfolder,units(u).name);
    load(ffn)
    
    logTransformEventValues = true;
    
    par = [];
    par.event = "AMdepth";
    par.referenceval = 0;
    par.window = [0 1];
    par.modfreq = 5;
    
    metrics = {['@epa.metric.trial_firingrate'],['@epa.metric.cl_calcpower'],['@epa.metric.vector_strength_cycle_by_cycle']};
    
    % currently unused metrics
%     
    % par.metric = @epa.metric.tmtf; parname = 'TMTF'; % use the temporal Modualation Transfer Function metric
    % par.metric = @epa.metric.vector_strength; parname = 'VS';
    % par.metric = @epa.metric.vector_strength_phase_projected;
    
    for m = 1:length(metrics)
        parname = cell2mat(metrics(m));
        parname = regexprep(parname,'@epa.metric.','','ignorecase');
        par.metric = eval(cell2mat(metrics(m)));
        
        if contains(parname,'power') && isempty(which('chronux.m'))
            addpath(genpath('C:\Users\rose\Documents\GitHub\chronux_2_12'));
            %     addpath(genpath('C:\Users\Daniel\src\chronux_2_12\'));
        end
        
        C = [S.Clusters];
        
        for k = 1:numel(C) % DO NOT USE PARFOR!
            Ck = C(k);
            fprintf('Computing %s and neurometric d'' for %s %s - %s\n', ...
                parname,Ck.Subject,Ck.TitleStr,Ck.SessionName)
            
            tpar = par;
            
            CkS = Ck.Session;
            
            % remove reminder trials
            ev = CkS.find_Event("Reminder");
            
            if ~isempty(ev)
                ind = ev.Values == 1;
                ev.remove_trials(ind);
                
                CkS.find_Event(par.event).remove_trials(ind);
            end
            
            if isempty(CkS.Events)
                fprintf(2,'Cluster "%s" does not have events for "%s", skipping\n',Ck.TitleStr,Ck.SessionName)
                bname = append(char(Ck.SessionName), '-', char(Ck.TitleStr),' on Day ', mat2str(u));
                badclusters{end+1} = bname;
                continue
            end
            
            [dp,v,M,V] = Ck.neurometric_dprime(tpar);
            
            if logTransformEventValues
                ind = v == 0;
                v(~ind) = 20*log10(v(~ind));
                v(ind)  = -120;
                
                ind = V == 0;
                V(~ind) = 20*log10(V(~ind));
                V(ind)  = -120;
            end
            
            % store the results along with the Cluster object
            Ck.UserData.(parname) = [];
            Ck.UserData.(parname).M      = M;
            Ck.UserData.(parname).V      = V;
            Ck.UserData.(parname).dprime = dp;
            Ck.UserData.(parname).vals   = v;
            Ck.UserData.(parname).lastUpdate = datestr(clock);
            
            % Compute neurometric fits
            minNTrials = 5;
            minNValues = 3;
            targDPrimeThreshold = 1;

            dprimeThreshold = targDPrimeThreshold;

            fprintf('Fitting "%s" neurometric d'' for %s %s\n',parname,Ck.TitleStr,Ck.Session.Name)
            
            if ~isfield(Ck.UserData,parname) || isfield(Ck.UserData.(parname),'ERROR')
                fprintf(2,'Cluster "%s" does not have "%s" analyzed\n',Ck.TitleStr,parname)
                continue
            end
            
            ndp = Ck.UserData.(parname);
            
            v = ndp.vals;
            dp = ndp.dprime;
            V = ndp.V;
            M = ndp.M;
            
            dp(isinf(dp)) = nan;
            if isempty(dp) || all(isnan(dp))
                Ck.UserData.(parname).ERROR = dp;
                fprintf(2,'Failed to compute for Cluster "%s"\n',Ck.TitleStr)
                continue
            end
            
            % weight fit by the number of trials per value
            w = arrayfun(@(a) sum(V==a),v);
            
            ind = w < minNTrials;
            
            v(ind) = [];
            dp(ind) = [];
            w(ind) = [];
            
            if isempty(v) || all(isnan(dp))
                Ck.UserData.(parname).ERROR = dp;
                fprintf(2,'No trials remaining or all NaN for "%s"\n',Ck.TitleStr)
                
                
                continue
            end
            
            % fit the data with a sigmoidal function
            [xfit,yfit,p_val] = epa.analysis.fit_sigmoid(v,dp,w);
            
            % determine where on the x-axis intersects with the neurometric curve
            % at dprimeThreshold
            if length(v) >= minNValues && max(yfit) >= dprimeThreshold
                try
                    valAtThreshold = spline(yfit,xfit,dprimeThreshold);
                catch
                    % spline doesn't like some extreme fits, so fall back on
                    % finding the nearest point
                    [~,m] = min((yfit - dprimeThreshold).^2);
                    valAtThreshold = xfit(m);
                end
            else
                valAtThreshold = nan;
            end
            
            % make sure threshold is within the limits of the actual stimulus
            if valAtThreshold > max(v)
                valAtThreshold = nan;
            end
            
            % pick the lowest d' if all d' values are greater than
            % dprimeThreshold
            if valAtThreshold <= min(xfit) && any(dp > 1)
                [m,q] = min(yfit);
                if m >= dprimeThreshold
                    dprimeThreshold = m;
                    valAtThreshold = xfit(q);
                else
                    valAtThreshold = nan;
                end
            end
            
            % find inflection point, if there is one
            dy = gradient(yfit,xfit);
            [m_infl,idy] = max(dy);
            x_infl = xfit(idy);
            y_infl = yfit(idy);
            
            if any(x_infl == [min(v) max(v)])
                x_infl = nan;
                y_infl = nan;
                m_infl = nan;
            end
            
            %             h = plot(v,dp,'o',xfit,yfit,'-k',...
            %                 valAtThreshold,dprimeThreshold,'sm', ...
            %                 x_infl,y_infl,'+r');
            %             ylabel('d''');
            %             xlabel(par.event)
            %             title(Ck.TitleStr)
            %             set(h([3 4]),'LineWidth',2)
            %             grid on
            %             pause
            
            % store the results along with the Cluster object
            Ck.UserData.(parname).xfit   = xfit;
            Ck.UserData.(parname).yfit   = yfit;
            Ck.UserData.(parname).x_infl = x_infl;
            Ck.UserData.(parname).y_infl = y_infl;
            Ck.UserData.(parname).m_infl = m_infl;
            Ck.UserData.(parname).fit_gradient = dy;
            Ck.UserData.(parname).p_val  = p_val;
            Ck.UserData.(parname).weights = w;
            Ck.UserData.(parname).threshold = valAtThreshold;
            Ck.UserData.(parname).dprimeThreshold = dprimeThreshold;
            Ck.UserData.(parname).lastUpdate = datestr(clock);
        end
    end
    
    fprintf('Saving %s ...',ffn);
    save(ffn,'S')
    fprintf(' done\n')
end

for i = 1:length(badclusters)
    fprintf(2, 'No events for cluster %s \n', cell2mat(badclusters(i)))
end
