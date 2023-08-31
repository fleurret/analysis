function thresholds_across_sessions(spth, savedir, parname, subj, unit_type, day, savefile)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
elseif contains(parname,'VScc')
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

% set static variables
parnames = ["trial_firingrate"; "cl_calcpower"; "vector_strength_cycle_by_cycle"];
sessions = ["Pre", "Active", "Post"];
sex = ["M", "F"];

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
        
        if ~isfield(c.UserData.(Parname),'threshold')
            c.UserData.(Parname).threshold = 0;
        end
        
        if ~isfield(c.UserData.(Parname),'p_val')
            c.UserData.(Parname).p_val = nan;
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
        t = arrayfun(@(a) a.UserData.(Parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(Parname).p_val,Ci(ind));
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
    
    % flag if fit is negative
    id = [Ci.Name];
    uid = unique(id);
    flaggedForRemoval = "";
    for j = 1:length(uid)
        ind = uid(j) == id;
        yfit = arrayfun(@(a) a.UserData.(Parname).yfit,Ci(ind),'UniformOutput',false);
        for k = 1:length(Ci(ind))
            syfit = yfit{k};
            curve = [syfit(1), syfit(500), syfit(1000)];
            
            if curve(1) > curve(2) && curve(2) > curve(3) && sum(yfit{k}>1) > 0
                flaggedForRemoval(end+1) = uid(j);
            end
        end
    end
    
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
    
    % replace NaN thresholds with 5
    for j = 1:length(Ci)
        if isnan(Ci(j).UserData.(Parname).threshold)
            Ci(j).UserData.(Parname).threshold = 5;
        end
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
            
            if ~isfield(u.UserData.(Parname),'threshold')
                b = NaN;
            else
                b = u.UserData.(Parname).threshold;
            end
            
            % set session
            session = sessions(k);
            
            
            % get subject
            subjid = split(u.Name, '_');
            
            % get sex
            if contains(subjid(1), '228') || contains(subjid(1), '267')
                s = sex(1);
            else
                s = sex(2);
            end
            
            % add to list
            temp{1} = uid(j);
            temp{2} = subjid(1);
            temp{3} = s;
            temp{4} = i;
            temp{5} = u.Type;
            temp{6} = session;
            temp{7} = b;
            output = [output; temp];
        end
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit","Subject", "Sex", "Day", "Type", "Session","Threshold"];


% save as file
if savefile == 1
    sf = fullfile(savedir,append(parname,'_Day', mat2str(day), '_thresholds.csv'));
    fprintf('Saving file %s \n', sf)
    writetable(output,sf);
    fprintf(' done\n')
end

% plot
cm = [3, 7, 30; 55, 6, 23; 106, 4, 15; 157, 2, 8; 208, 0, 0; 220, 47, 2; 232, 93, 4;]./255; % session colormap

f = figure;
f.Position = [0, 0, 1800, 250];

x = 1:3;


for d = 1%:maxNumDays
    ax = subplot(1,maxNumDays,d);
    set(gca, 'TickDir', 'out',...
        'XTickLabelRotation', 0,...
        'TickLength', [0.02,0.02],...
        'LineWidth', 1.5);
    set(findobj(ax,'-property','FontName'),...
        'FontName','Arial')
    ucm = cm(d,:);
    hold on
    
    for i = 1:length(sessions)
        % only on that day
        didx = output.Day == d;
        daydata = output(didx,:);
        
        % get each session
        sidx = contains(daydata{:,:}, sessions{i});
        [row,~] = find(sidx);
        onesession = daydata(row,:);
        smean = mean(table2array(onesession(:,7)), 'omitnan');
        
        daymeans(i) = smean;
    end
    
    plot(daymeans,...
        'Color', ucm,...
        'Marker', 'o',...
        'MarkerFaceColor', ucm,...
        'MarkerSize', 8,...
        'LineWidth', 2)
    
    units = table2struct(output);
    
    for i = 1%:maxNumDays
        currentday = [units.Day] == i;
        means = [units.Threshold];
        currentmeans = means(currentday);
        sess = [units.Session];
        currentsessions = sess(currentday);
        
        for j = 1:3
            seidx = currentsessions == sessions(j);
            meantable(j,:) = currentmeans(seidx);
        end
    end
    
    for i = 1:length(meantable)
        scatter(x,meantable(:,i),...
            'Marker','o',...
            'MarkerFaceColor', ucm,...
            'MarkerFaceAlpha', 0.3,...
            'MarkerEdgeAlpha', 0)
        
        line(x,meantable(:,i),...
            'Color', ucm,...
            'LineWidth',0.75,...
            'LineStyle', ':')
    end
end

xticklabels({'Pre','','Active','','Post'})
title('Day ', d)
ylabel('Threshold (dB re: 100%)')
ylim([-20 5])

