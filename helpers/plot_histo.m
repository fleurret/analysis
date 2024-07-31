function plot_histo(savedir, parname, ndays, unit_type, condition, cn, figpath)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);

    s = [Ci.Name];
    units = unique(s);
    
    if cn > length(units)
        error('Unit does not exist :(')
    end
    
    % only the representative unit
    for j = cn
        uidx = units(j) == s;
        Cj = Ci(uidx);

        for k = 1:3
            Ck = Cj(k);
            ev = Ck.Session.find_Event("AMDepth").DistinctValues;
%             ev(ev==0) = [];

%             if length(ev) > 5
%                 ev = ev(end-4:end);
%             end

            % make new folder
            mkdir(figpath, Ck.SessionName)
            currentfolder = fullfile(figpath,Ck.SessionName);

            % plot each depth
            for d = 1:length(ev)
                
                y = figure('visible','off');
                y.Position = [0, 0, 500, 600];
                tiledlayout(3,1)
                
                depth = ev(d);

                % AM stimulus
                nexttile([1 1])
                white_noise(depth);
                
                % PSTH
                nexttile([1 1])
                psth = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',depth);
                [fr,b,~] = Ck.psth(psth);
                bar(b,fr,...
                    'EdgeAlpha',0,...
                    'FaceColor','k');
                ylim([0 150]);
                
                % raster
                nexttile([1 1])
                r = epa.plot.Raster(Ck,'event',"AMDepth",'eventvalue',ev);
                r.plot();
%                 plot_raster(Ck);
                
                % save figure
                ffn = fullfile(currentfolder,append(num2str(depth),'.svg'));
                saveas(y, ffn)
            end
        end
    end
end