function output = change_in_threshold(savedir, spth, parx, pary)

% convert parnames to correct label
if strcmp(parx,'FiringRate')
    parx = 'trial_firingrate';
    x_label = 'Firing Rate';
end

if strcmp(pary,'FiringRate')
    pary = 'trial_firingrate';
    y_label = 'Firing Rate';
end

if strcmp(parx,'Power')
    parx = 'cl_calcpower';
    x_label = 'Power';
end

if strcmp(pary,'Power')
    pary = 'cl_calcpower';
    y_label = 'Power';
end

if strcmp(parx,'VScc')
    parx = 'vector_strength_cycle_by_cycle';
    x_label = 'VScc';
end

if strcmp(pary,'VScc')
    pary = 'vector_strength_cycle_by_cycle';
    y_label = 'VScc';
end

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 7;

% plot settings
f = figure;
f.Position = [0, 0, 1700, 350];
tiledlayout(1, maxNumDays)

for i = 1:maxNumDays
    
    % make subplot
    ax(i) = nexttile;
    xline(0)
    yline(0)
    
    output = [];
    
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
            xthr = u.UserData.(parx).threshold;
            ythr = u.UserData.(pary).threshold;
            
            if isnan(xthr)
                x(k) = 1;
            else
                x(k) = xthr;
            end
            
            if isnan(ythr)
                y(k) = 1;
            else
                y(k) = ythr;
            end
        end
        
        % calculate vector components
        xcomp = x(2)- x(1);
        ycomp = y(2)- y(1);
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
    end
    
    % plot
    %         for k = 1:2
    %             hold on
    %             scatter(ax(i),x(k),y(k), 75,...
    %                 'Marker','o',...
    %                 'MarkerFaceColor',cm(i,:),...
    %                 'MarkerFaceAlpha', 0.3,...
    %                 'MarkerEdgeAlpha', 0);
    %         end
    %
    %         h = annotation('arrow');
    %         set(h,'parent', gca, ...
    %             'X', x,...
    %             'Y', y,...
    %             'HeadLength', 4, 'HeadWidth', 4, 'HeadStyle', 'ellipse');
    %
    %         set(ax(i), 'xdir', 'reverse',...
    %             'ydir', 'reverse',...
    %             'xlim', [-25 5],...
    %             'ylim', [-25 5]);
    
    % calculate average vector
%     avgM = mean([output{:,3}], 'omitnan');
    avgX = mean([output{:,4}], 'omitnan');
    avgY = mean([output{:,5}], 'omitnan');
%     avgA = mean([output{:,6}], 'omitnan');
    
    % plot individual vectors
    for j = 1:length(output)
        X(1) = 0;
        Y(1) = 0;
        X(2) = [output{j,4}];
        Y(2) = [output{j,5}];
        
        for k = 1:2
            hold on
            scatter(ax(i),X(k), Y(k),...
                'Marker', 'none')
        end
        
        h1 = annotation('arrow');
        set(h1,'parent', gca, ...
            'X', X,...
            'Y', Y,...
            'HeadLength', 4,...
            'HeadWidth', 4,...
            'HeadStyle', 'plain');
    end
    
    % plot mean vector
    xm = [0 avgX];
    ym = [0 avgY];
    
    h2 = annotation('arrow');
    set(h2, 'parent', gca,...
        'X', xm,...
        'Y', ym,...
        'LineWidth', 3,...
        'Color', [34,226,232]./255,...
        'HeadLength', 4,...
        'HeadWidth', 4,...
        'HeadStyle', 'ellipse');
    
    % set axes etc.
    set(ax(i),'xlim', [-20 20],...
        'ylim', [-20 20]);
    
    title('Day ', i)
    xlabel(append('\Delta', x_label, ' threshold'))
    ylabel(append('\Delta', y_label, ' threshold'))
end



