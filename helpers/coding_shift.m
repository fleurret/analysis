function coding_shift(savedir, parx, pary, s1, s2, ndays, unit_type, condition)

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

% set vars
output = [];
av = {'Aversive', 'Active'};

% load clusters
load(fullfile(savedir,'Cday_original.mat'));

for i = ndays
    Ci_x = filterunits(savedir, parx, Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, pary, Cday, i, unit_type, condition);
    Ci = union(Ci_x, Ci_y);
    
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        tx = ones(1,3);
        ty = ones(1,3);
        temp = {};
        
        % get subject
        subjid = split(U(1).Name, '_');
        
        % get thresholds
        for j = 1:length(U)
            if contains(U(j).SessionName,'Pre')
                tx(1) = U(j).UserData.(parx).threshold;
                ty(1) = U(j).UserData.(pary).threshold;
            end
            
            if contains(U(j).SessionName, av)
                tx(2) = U(j).UserData.(parx).threshold;
                ty(2) = U(j).UserData.(pary).threshold;
            end
            
            if contains(U(j).SessionName, 'Post')
                tx(3) = U(j).UserData.(parx).threshold;
                ty(3) = U(j).UserData.(pary).threshold;
            end
        end
        
        % add to lists
        temp{1} = U.ID;
        temp{2} = subjid(1);
        temp{3} = tx(1);
        temp{4} = tx(2);
        temp{5} = tx(3);
        temp{6} = ty(1);
        temp{7} = ty(2);
        temp{8} = ty(3);
        output = [output; temp];
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit", "Subject", "xPre", "xActive", "xPost", "yPre", "yActive", "yPost"];

% plot
f = figure;
f.Position = [0, 0, 600, 600];
cm = [183, 134, 188]./255;

% set plot
ax = gca;
set(gca, 'TickDir', 'out',...
    'XTickLabelRotation', 0,...
    'TickLength', [0.02,0.02],...
    'TickDir', 'out',...
    'LineWidth', 1.5,...
    'XDir', 'reverse',...
    'YDir', 'reverse',...
    'XLim', [-21 5],...
    'YLim', [-21 5],...
    'XAxisLocation', "origin",...
    'YAxisLocation', "origin");
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
hold on

scount = 0;
mcount = 0;

% only measureable active thresholds
p = output(~isnan(output.yActive),:);
tcount = height(p);

% find multiplex
midx = ~isnan(p.xActive);
mp = p(midx,:);
o = p(~midx,:);

% plot each unit
for i = 1:height(mp)
    
    % get thresholds
    t1 = mp.xPre(i);
    t2 = mp.yActive(i);

    % replace pre nans
    if isnan(t1)
        t1 = 5; 
    end
    
    scatter(ax, t1, t2,...
        'Marker','o',...
        'SizeData', 100,...
        'MarkerFaceColor',cm,...
        'MarkerEdgeColor',cm,...
        'MarkerFaceAlpha', 0.3,...
        'MarkerEdgeAlpha', 1);
    
    mcount = mcount+1;
end

for i = 1:height(o)
    
    % get thresholds
    t1 = o.xPre(i);
    t2 = o.yActive(i);

    % replace pre nans
    if isnan(t1)
        t1 = 5; 
    end
    
    scatter(ax, t1, t2,...
        'Marker','o',...
        'SizeData', 100,...
        'MarkerFaceColor',cm,...
        'MarkerEdgeColor',cm,...
        'MarkerFaceAlpha', 0.3,...
        'MarkerEdgeAlpha', 0);
    
    scount = scount+1;
end


xline(0)
yline(0)
axis(ax,'equal');
axis(ax,'square');

xlabel(ax,{s1;'threshold (dB)';parx});
ylabel(ax,{s2;'threshold (dB)';pary});
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

fprintf('%s total, %s switch strategy, %s also had active VS\n', num2str(tcount), num2str(tcount-scount), num2str(mcount))