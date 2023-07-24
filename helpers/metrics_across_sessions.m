function metrics_across_sessions(parname, spth, savedir, meas, type, subj, unit_type, depth)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
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

parnames = ["trial_firingrate"; "cl_calcpower"; "vector_strength_cycle_by_cycle"];

for i = 1:maxNumDays
    Ci = Cday{i};
    
    % first make sure that there is a threshold/p_val field for all
    % parnames
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
        
        for k = 1:length(parnames)
            parname = char(parnames(k));
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
    end
    
    alpha = 0.05;
    
    % create lookup table for each cluster
    id = [Ci.Name];
    uid = unique(id);
    flaggedForRemoval = "";
    
    for j = 1:length(uid)
        ind = uid(j) == id;
        
        for k = 1:length(parnames)
            parname = char(parnames(k));
            
            tt = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
            tpval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
            
            if length(tt) < 3
                tnan = nan(1, 3-length(tt));
                t(:,k) = [tt tnan];
            else
                t(:,k) = tt;
            end
            
            if length(tpval) < 3
                pval(:,k) = [tpval tnan];
            else
                pval(:,k) = tpval;
            end
        end
        
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        if sum(sum(t,'omitnan')) == 0 || sum(sum(isnan(pval))) == length(parnames)*length(parnames) || sum(~any(pval<=alpha)) == length(parnames)*length(parnames)
            flaggedForRemoval(end+1) = uid(j);
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
    
    % only plot one subject
    if subj ~= "all"
        subj_idx = zeros(1,length(Ci));
        
        for j = 1:length(Ci)
            if Ci(j).Subject == ""
                nsubj = append(subj,"_");
                cs = convertCharsToStrings(Ci(j).Name);
                if contains(cs,nsubj)
                    subj_idx(j) = 1;
                else
                    subj_idx(j) = 0;
                end
            else
                cs = convertCharsToStrings(Ci(j).Subject);
                if contains(cs,subj)
                    subj_idx(j) = 1;
                else
                    subj_idx(j) = 0;
                end
            end
        end
        
        subj_idx = logical(subj_idx);
        Ci = Ci(subj_idx);
    end
    
    % remove multiunits
    if unit_type == "SU"
        removeind = [Ci.Type] == "SU";
        Ci = Ci(removeind);
    end
    
    % replace Cday
    Cday{1,i} = Ci;
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        presented = round(U(1).UserData.(Parname).vals);
        
        % create output
        clear temp
        temp = {};
        B = [];
        
        % get events and calculate baseline
        for k = 1:length(U)
            
            % pull values
            u = U(k);
            [mAM, mNAM, cAM, cNAM] = calc_mas(u, Parname, depth);
            
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

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit","Day", "Type", "Pre", "Active", "Post"];

% save as file
sf = fullfile(savedir,append(parname,'_',type, meas,'.xlsx'));
fprintf('Saving file %s \n', sf)
writetable(output,sf);
fprintf(' done\n')

% plot
cm = [3, 7, 30; 55, 6, 23; 106, 4, 15; 157, 2, 8; 208, 0, 0; 220, 47, 2; 232, 93, 4;]./255; % session colormap

f = figure;
f.Position = [0, 0, 1800, 250];

x = 1:3;

for d = 1%:maxNumDays
    ax = subplot(1,maxNumDays,d);
    set(gca, 'TickDir', 'out',...
        'XTickLabelRotation', 0)
    set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
    ucm = cm(d,:);
    hold on
    
    didx = output.Day == d;
    
    daymeans = [mean(output.Pre(didx), 'omitnan') mean(output.Active(didx), 'omitnan') mean(output.Post(didx), 'omitnan')];
    plot(daymeans,...
        'Color', ucm,...
        'Marker', 'o',...
        'MarkerFaceColor', ucm,...
        'MarkerSize', 8,...
        'LineWidth', 2)
    
    for i = 1:height(output)
        unit = table2cell(output(i,:));
        pap = [cell2mat(unit(4)) cell2mat(unit(5)) cell2mat(unit(6))];
        ud = cell2mat(unit(2));
        
        if d == ud
            scatter(x,pap,...
                'Marker','o',...
                'MarkerFaceColor', ucm,...
                'MarkerFaceAlpha', 0.3,...
                'MarkerEdgeAlpha', 0)
            
            line(x,pap,...
                'Color', ucm,...
                'LineWidth',0.75,...
                'LineStyle', ':')
            
        end
        
        xticklabels({'Pre','','Active','','Post'})
        title('Day ', d)
        
        if strcmp(meas, 'Mean')
            if strcmp(Parname, 'trial_firingrate')
                ylabel('Firing rate (Hz)')
                if strcmp(meas, 'Mean')
                    ylim([0 100])
                else
                    ylim([0 15])
                end
            end
            
            if strcmp(Parname, 'cl_calcpower')
                ylabel('spikes/sec^{2}/Hz')
                if strcmp(meas, 'Mean')
                    ylim([0 100])
                else
                    ylim([0 10])
                end
            end
            
            if strcmp(Parname, 'vector_strength_cycle_by_cycle')
                ylabel('Vector strength')
                ylim([0 1])
            end
        else
            ylabel('Variation')
            ylim([0 10])
        end
    end
end