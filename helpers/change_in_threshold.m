function output = change_in_threshold(savedir, spth, parx, pary)

% convert parnames to correct label
if strcmp(parx,'FiringRate')
    parx = 'trial_firingrate';
end

if strcmp(pary,'FiringRate')
    pary = 'trial_firingrate';
end

if strcmp(parx,'Power')
    parx = 'cl_calcpower';
end

if strcmp(pary,'Power')
    pary = 'cl_calcpower';
end

if strcmp(parx,'VScc')
    parx = 'vector_strength_cycle_by_cycle';
end

if strcmp(pary,'VScc')
    pary = 'vector_strength_cycle_by_cycle';
end

% plot settings
cm = [77,127,208; 52,228,234; 2,37,81;]./255; % session colormap

f = figure;
f.Position = [0, 0, 800, 600];
hold on

set(gca, 'xdir', 'reverse',...
    'ydir', 'reverse',...
    'xlim', [-25 5],...
    'ylim', [-25 5]);
ax = gca;

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
        if ~isfield(c.UserData.(parx),'threshold')
            c.UserData.(parx).threshold = 0;
        end
        
        if ~isfield(c.UserData.(pary),'threshold')
            c.UserData.(pary).threshold = 0;
        end
        
        if ~isfield(c.UserData.(parx),'p_val')
            c.UserData.(parx).p_val = nan;
        end
        
        if ~isfield(c.UserData.(pary),'p_val')
            c.UserData.(pary).p_val = nan;
        end
    end
    
    alpha = 0.05;
    
    % create lookup table for each cluster
    id = [Ci.Name];
    uid = unique(id);

    % loop through parx
    flaggedForRemovalx = "";
    for j = 1:length(uid)
        ind = uid(j) == id;
        
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        tx = arrayfun(@(a) a.UserData.(parx).threshold,Ci(ind));
        pvalx = arrayfun(@(a) a.UserData.(parx).p_val,Ci(ind));
        
        if sum(tx,'omitnan') == 0 || all(isnan(pvalx)) || ~any(pvalx<=alpha)
            flaggedForRemovalx(end+1) = uid(j);
        end
    end
    
    % loop through pary
    flaggedForRemovaly = "";
    for j = 1:length(uid)
        ind = uid(j) == id;
        
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        ty = arrayfun(@(a) a.UserData.(pary).threshold,Ci(ind));
        pvaly = arrayfun(@(a) a.UserData.(pary).p_val,Ci(ind));
        
        if sum(ty,'omitnan') == 0 || all(isnan(pvaly)) || ~any(pvaly<=alpha)
            flaggedForRemovaly(end+1) = uid(j);
        end
    end
    
    % remove invalid units
    idx = false(1,length(Ci));
    for j = 1:length(Ci)
        if ismember(id(j),flaggedForRemovalx) && ismember(id(j),flaggedForRemovaly)
            idx(j) = 0;
        else
            idx(j) = 1;
        end
        
        if ismember(id(j),flaggedForRemovalx) && ismember(id(j),flaggedForRemovaly)
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
    
    % replace NaN thresholds with 0
    for j = 1:length(Ci)
        if isnan(Ci(j).UserData.(parx).threshold)
            Ci(j).UserData.(parx).threshold = 2;
        end
        
        if isnan(Ci(j).UserData.(pary).threshold)
            Ci(j).UserData.(pary).threshold = 2;
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
        
        % create output
        clear temp
        temp = {};
        
        % get thresholds
        x = nan(1,2);
        y = nan(1,2);
        
        for k = 1:2
            u = U(k);
            x(k) = u.UserData.(parx).threshold;
            y(k) = u.UserData.(pary).threshold;
        end
        
        xcomp = x(2)-x(1);
        ycomp = y(2)-y(1);
        V = sqrt(xcomp^2 + ycomp^2);
        a = rad2deg(atan(ycomp/xcomp));
        
        % add to list
        temp{1} = uid(j);
        temp{2} = i;
        temp{3} = V;
        temp{4} = xcomp;
        temp{5} = ycomp;
        temp{6} = a;
        
        output = [output; temp];
        
        % plot
        for k = 1:2
            plot(ax,x(k),y(k),'LineStyle','none', ...
                'Marker','o',...
                'MarkerSize', 12,...
                'MarkerFaceColor',cm(k,:),...
                'MarkerEdgeColor', 'none');
        end
        
        h = annotation('arrow');
        set(h,'parent', gca, ...
            'X', x,...
            'Y', y,...
            'HeadLength', 10, 'HeadWidth', 10, 'HeadStyle', 'plain');
    end
end

