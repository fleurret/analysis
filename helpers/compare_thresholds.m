function compare_thresholds(savedir, parx, pary, ndays, unit_type, condition, shownans, session)

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

thr = cell(size(ndays));
sidx = thr;
didx = thr;

% set figure
f = figure;
clf(f);
ax = gca;
cm = [77,127,208; 52,228,234; 2,37,81;]./255; % session colormap

for i = ndays
    
    Ci_x = filterunits(savedir, parx, Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, pary, Cday, i, unit_type, condition);
    
    Ci = union(Ci_x, Ci_y);
    
    % replace NaN thresholds with 5
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
        x = 1+ones(size(thr{i}))*log10(ndays(i));
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
            
            scatter(ax,x,y,...
                'Marker','o',...
                'SizeData', 100,...
                'MarkerFaceColor',cm(1,:),...
                'MarkerEdgeColor', 'none',...
                'MarkerFaceAlpha', 0.3);
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
            
            scatter(ax,x,y,...
                'Marker','o',...
                'SizeData', 100,...
                'MarkerFaceColor',cm(2,:),...
                'MarkerEdgeColor', 'none',...
                'MarkerFaceAlpha', 0.3);
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
            
            scatter(ax,x,y,...
                'Marker','o',...
                'SizeData', 100,...
                'MarkerFaceColor',cm(3,:),...
                'MarkerEdgeColor', 'none',...
                'MarkerFaceAlpha', 0.3);
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
            scatter(ax,x,y,...
                'Marker','o',...
                'SizeData', 100,...
                'MarkerFaceColor',cm(k,:),...
                'MarkerEdgeColor', 'none',...
                'MarkerFaceAlpha', 0.3);
        end
    end
end

xline(0)
yline(0)

xlabel(ax,{'Threshold (dB)';parx});
ylabel(ax,{'Threshold (dB)';pary});
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

axis(ax,'equal');
axis(ax,'square');

ax = findobj(f,'type','axes');
ax.LineWidth = 3;
ax.TickDir = 'out';
ax.TickLength = [0.02,0.02];
ax.XAxisLocation = "origin";
ax.YAxisLocation = "origin";

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
    set(ax,'xlim', [-20, 5],...
        'ylim', [-20, 5],...
        'xdir', 'reverse',...
        'ydir', 'reverse');
end


refline(1,0)

sgtitle(f,'Threshold Coding Comparisons Across Days');