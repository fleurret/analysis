function compare_thresholds(savedir, parx, pary, shownans, session)

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

if strcmp(parx,'Power')
    pary = 'cl_calcpower';
end

if strcmp(parx,'VScc')
    parx = 'vector_strength_cycle_by_cycle';
end

if strcmp(pary,'VScc')
    pary = 'vector_strength_cycle_by_cycle';
end

% load clusters
load(fullfile(savedir,'Cday_original.mat'));

maxNumDays = 7;
days = 1:min(maxNumDays,length(Cday));

thr = cell(size(days));
sidx = thr;
didx = thr;

% set figure
f = figure;
f.Color = 'w';
clf(f);
ax = gca;
cm = [77,127,208; 52,228,234; 2,37,81;]./255; % session colormap
precm = [138,156,224; 117,139,219; 97,122,213; 77,105,208; 57,88,203; 49,78,185; 44,70,165;]./255; % session colormap
activecm = [212,249,251; 176,245,247; 141,240,243; 105,235,240; 34,226,232; 21,200,206; 18,165,170;]./255; % session colormap
postcm = [11,116,249; 6,107,234; 5,89,196; 4,72,158; 3,54,119; 2,37,81; 1,11,24;]./255; % session colormap

for i = 1:length(days)
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
    end
    Ci = Ci(idx);
    
    % remove any additional manually flagged units
    note = {Ci.Note};
    removeind = cellfun(@isempty, note);
    Ci = Ci(removeind);
    
    % replace NaN thresholds with 0
    if shownans == "yes"
        for j = 1:length(Ci)
            if isnan(Ci(j).UserData.(parx).threshold)
                Ci(j).UserData.(parx).threshold = 5;
            end
            
            if isnan(Ci(j).UserData.(pary).threshold)
                Ci(j).UserData.(pary).threshold = 5;
            end
        end
    end
    
    y = arrayfun(@(a) a.UserData.(pary),Ci,'uni',0);
    ind = cellfun(@(a) isfield(a,'ERROR'),y);
    
    y(ind) = [];
    Ci(ind) = [];
    y = [y{:}];
    
    if ~isempty(y)
        thr{i} = [y.threshold];
        
        didx{i} = ones(size(y))*i;
        sidx{i} = nan(size(y));
        
        sn = [Ci.Session];
        sn = [sn.Name];
        sidx{i}(contains(sn,"Pre")) = 1;
        sidx{i}(contains(sn,"Aversive")) = 2;
        sidx{i}(contains(sn,"Post")) = 3;
        x = 1+ones(size(thr{i}))*log10(days(i));
    end
    
    % plot according to session input
    if session ~= "all"
        
        % pre only
        if session == "pre"
            k = 1;
            ud = {Ci(sidx{i}==k).UserData};
            
            x = nan(size(ud));
            y = x;
            
            for j = 1:length(ud)
                x(j) = ud{j}.(parx).threshold;
                y(j) = ud{j}.(pary).threshold;
            end
            
            line(ax,x,y,'LineStyle','none', ...
                'Marker','o',...
                'MarkerSize', 12,...
                'MarkerFaceColor',precm(i,:),...
                'MarkerEdgeColor', 'none');
        end
        
        % active only
        if session == "active"
            k = 2;
            ud = {Ci(sidx{i}==k).UserData};
            
            x = nan(size(ud));
            y = x;
            
            for j = 1:length(ud)
                x(j) = ud{j}.(parx).threshold;
                y(j) = ud{j}.(pary).threshold;
            end
            
            line(ax,x,y,'LineStyle','none', ...
                'Marker','o',...
                'MarkerSize', 12,...
                'MarkerFaceColor',activecm(i,:),...
                'MarkerEdgeColor', 'none');
        end
        
        if session == "post"
            k = 3;
            ud = {Ci(sidx{i}==k).UserData};
            
            x = nan(size(ud));
            y = x;
            
            for j = 1:length(ud)
                x(j) = ud{j}.(parx).threshold;
                y(j) = ud{j}.(pary).threshold;
            end
            
            line(ax,x,y,'LineStyle','none', ...
                'Marker','o',...
                'MarkerSize', 12,...
                'MarkerFaceColor',postcm(i,:),...
                'MarkerEdgeColor', 'none');
        end
        
    else
        for k = 1:3
            
            ud = {Ci(sidx{i}==k).UserData};
            
            x = nan(size(ud));
            y = x;
            
            for j = 1:length(ud)
                x(j) = ud{j}.(parx).threshold;
                y(j) = ud{j}.(pary).threshold;
            end
            
            hold on
            plot(ax,x,y,'LineStyle','none', ...
                'Marker','o',...
                'MarkerSize', 12,...
                'MarkerFaceColor',cm(k,:),...
                'MarkerEdgeColor', 'none');
        end
    end
end

box(ax,'on');
xline(0)
yline(0)

xlabel(ax,{'Threshold (dB)';parx});
ylabel(ax,{'Threshold (dB)';pary});
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

axis(ax,'equal');
axis(ax,'square');

ax = findobj(f,'type','axes');
y = get(ax,'ylim');
x = get(ax,'xlim');

if session == "all"
    m = [x; y];
    m = [min(m(:)) max(m(:))];
    set(ax,'xlim', m,...
        'ylim',m,...
        'xdir', 'reverse',...
        'ydir', 'reverse');
else
    set(ax,'xlim', [-25, 5],...
        'ylim', [-25, 5],...
        'xdir', 'reverse',...
        'ydir', 'reverse');
end


refline(1,0)

sgtitle(f,'Threshold Coding Comparisons Across Days');