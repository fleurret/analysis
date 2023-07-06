function metrics_across_sessions(parname, spth, savedir, meas, type, depth)

% convert parname to correct label
if contains(parname,'FiringRate')
    parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    parname = 'vector_strength_cycle_by_cycle';
end

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 7;

output = [];

for i = 1:maxNumDays
    Ci = Cday{i};
    
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
        
        if contains(c.SessionName, 'FreqTuning')
            continue
        end
        
        if ~isfield(c.UserData.(parname),'threshold')
            c.UserData.(parname).threshold = 0;
        end
        
        if ~isfield(c.UserData.(parname),'p_val')
            c.UserData.(parname).p_val = nan;
        end
    end
    
    alpha = 0.05;
    
    % create lookup table for each cluster
    id = [Ci.Name];
    uid = unique(id);
    flaggedForRemoval = "";
    for j = 1:length(uid)
        ind = uid(j) == id;
        
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
            flaggedForRemoval(end+1) = uid(j);
            %             fprintf(2,'ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        else
            %             fprintf('ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        end
    end
    
    % remove invalid units
    idx = false(1,length(Ci));
    for j = 1:length(Ci)
        if ismember(id(j),flaggedForRemoval)
            idx(j) = 0;
        else
            idx(j) = 1;
        end
    end
    Ci = Ci(idx);
    
    % remove any additional manually flagged units
    note = {Ci.Note};
    removeind = cellfun(@isempty, note);
    Ci = Ci(removeind);
    
    % replace Cday
    Cday{1,i} = Ci;
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        presented = round(U(1).UserData.(parname).vals);
        
        % create output
        clear temp
        temp = {};
        B = [];
        
        % get events and calculate baseline
        for k = 1:length(U)
            
            % pull values
            u = U(k);
            [mAM, mNAM, cAM, cNAM] = calc_mas(u, parname, depth);
            
            if strcmp(meas, 'Mean')
                if strcmp(type, 'AM')
                    b = mAM;
                else
                    b = mNAM;
                end
            else
                if strcmp(type, 'AM')
                    b = cAM;
                else
                    b = cNAM;
                end
            end
            B = [B; b];
        end
        
        % add to list

        temp{1} = uid(j);
        temp{2} = i;
        temp{3} = u.Type;
        temp{4} = B(1);
        temp{5} = B(2);
        
        if length(B) ~= 3
            temp{6} = NaN;
        else
            temp{6} = B(3);
        end
        
        
        output = [output; temp];
    end
end

% save as file
sf = fullfile(savedir,append(parname,'_',type, meas,'.xlsx'));
fprintf('Saving file %s \n', sf)
writecell(output,sf);
fprintf(' done\n')

% plot
cm = [3, 7, 30; 55, 6, 23; 106, 4, 15; 157, 2, 8; 208, 0, 0; 220, 47, 2; 232, 93, 4;]./255; % session colormap

f = figure;
f.Position = [0, 0, 2000, 350];

for d = 1:maxNumDays
    ax = subplot(1,maxNumDays,d);
    set(gca, 'TickDir', 'out')
    hold on
    
    for i = 1:length(output)
        unit = output(i,:);
        pap = [cell2mat(unit(4)) cell2mat(unit(5)) cell2mat(unit(6))];
        ud = cell2mat(unit(2));
        ucm = cm(d,:);
        
        if d == ud
            plot(pap,...
                'Color',ucm,...
                'Marker','o',...
                'LineWidth',2)
            xticklabels({'Pre','','Active','','Post'})
            title('Day ', d)
            
            if strcmp(parname, 'trial_firingrate')
                ylabel('Firing rate (Hz)')
                if strcmp(meas, 'Mean')
                    ylim([0 100])
                else
                    ylim([0 15])
                end
            end
            
            if strcmp(parname, 'cl_calcpower')
                ylabel('spikes/sec^{2}/Hz')
                if strcmp(meas, 'Mean')
                    ylim([0 100])
                else
                    ylim([0 10])
                end
            end
            
            if strcmp(parname, 'vector_strength_cycle_by_cycle')
                ylabel('Vector strength')
                ylim([0 1])
            end
        end
    end
end