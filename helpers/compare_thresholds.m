function compare_thresholds(savedir, parx, pary, shownans)

% load clusters
load(fullfile(savedir,'Cday_original.mat'));

maxNumDays = 7;
days = 1:min(maxNumDays,length(Cday));

thr = cell(size(days));
sidx = thr;
didx = thr;

% set figure
f = figure(sum(uint8('compare')));
f.Color = 'w';
clf(f);
ax = gca;
cm = [77,127,208; 52,228,234; 2,37,81;]./255; % session colormap

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
                Ci(j).UserData.(parx).threshold = 0;
            end
            
            if isnan(Ci(j).UserData.(pary).threshold)
                Ci(j).UserData.(pary).threshold = 0;
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
    
        
    for k = 1:3
        
        ud = {Ci(sidx{i}==k).UserData};
        
        x = nan(size(ud));
        y = x;
        
        for j = 1:length(ud)
            x(j) = ud{j}.(parx).threshold;
            y(j) = ud{j}.(pary).threshold;
        end
        
        line(ax,x,y,'LineStyle','none', ...
            'Marker','o',...
            'MarkerFaceColor',cm(k,:),...
            'MarkerEdgeColor',cm(k,:));
    end
    
end

box(ax,'on');

xlabel(ax,{'Threshold (dB)';parx});
ylabel(ax,{'Threshold (dB)';pary});

axis(ax,'equal');
axis(ax,'square');
        
       
ax = findobj(f,'type','axes');
y = get(ax,'ylim');
x = get(ax,'xlim');
m = [x; y];
m = [min(m(:)) max(m(:))];
set(ax,'xlim', m,...
    'ylim',m,...
    'xdir', 'reverse',...
    'ydir', 'reverse');

refline(1,0)

sgtitle(f,'Threshold Coding Comparisons Across Days');