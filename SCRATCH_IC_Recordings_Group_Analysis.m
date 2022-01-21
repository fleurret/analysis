%% Load .mat and convert neural data

spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Data';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

Cday = {};

for subj = 1:length(subjects)
    spth = fullfile(subjects(subj).folder,subjects(subj).name);
    
    d = dir(fullfile(spth,'*.mat'));
    
    for day = 1:length(d)
        ffn = fullfile(d(day).folder,d(day).name);
        
        fprintf('Loading subject %s - %s ...',subjects(subj).name,d(day).name)
        load(ffn)
        fprintf(' done\n')
        
        if subj > 1
            Cday{day} = [Cday{day}, [S.Clusters]];
        else
            Cday{day} = [S.Clusters];
        end
        
        % add subject property and change to unique id
        for i = 1:length(Cday{day})
            if isprop(Cday{day}(i),'Subject')
                continue
            else
                addprop(Cday{day}(i), 'Subject');
                Cday{day}(i).Subject = subjects(subj).name;
            end
            
            if ~startsWith(Cday{day}(i).Name,string(subjects(subj).name))
                Cday{day}(i).Name = string(subjects(subj).name) + "_" + Cday{day}(i).Name;
            end
        end
    end
end

% save as file
file = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Cday.mat';
save(file, 'Cday')

%% Plot

% load behavior
parentDir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Behavior';
behav_file = fullfile(parentDir,'behavior_combined.mat');
load(behav_file)

% load neural
Cdayfile = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Cday.mat';
load(Cdayfile)

spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Data';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

minNumSpikes = 0;
maxNumDays = 7;

sessionName = ["Pre","Active","Post"];

cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

mk = '^^^';
xoffset = [.99, 1, 1.01];

f = figure(sum(uint8(parname)));
f.Position = [0, 0, 1000, 600];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
ax(2) = subplot(122,'parent',f);

days = 1:min(maxNumDays,length(Cday));

thr = cell(size(days));
sidx = thr;
didx = thr;

% neural data

for i = 1:length(days)
    Ci = Cday{i};
  
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
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
    
%     % only plot one subject
        subj = "202";
%         subj = "222";
%         subj = "223";
%         subj = "224";
    subj_idx = zeros(1,length(Ci));
    for j = 1:length(Ci)
        cs = convertCharsToStrings(Ci(j).Subject);
        if cs == subj
            subj_idx(j) = 0;
        else
            subj_idx(j) = 1;
        end
    end
    subj_idx = logical(subj_idx);
    Ci = Ci(subj_idx);

    % remove multiunits
    %     removeind = [Ci.Type] == "SU";
    %     Ci = Ci(removeind);
    
    y = arrayfun(@(a) a.UserData.(parname),Ci,'uni',0);
    ind = cellfun(@(a) isfield(a,'ERROR'),y);
    
    %     ind = ind | [Ci.N] < minNumSpikes;
    
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
    
    for j = 1:3 % plot each session seperately
        ind = sidx{i} == j;
        xi = x*xoffset(j);
        n_mean(j,i) = mean(thr{i}(ind),'omitnan');
        
        % individual points
        h = line(ax(1),xi(ind),thr{i}(ind), ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',(cm(j,:)), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',8,...
            'ButtonDownFcn',{@cluster_plot_callback,Ci(ind),xi(ind),thr{i}(ind),parname});
        
        % means and error bars
        xi = mean(xi);
        yi = mean(thr{i}(ind),'omitnan');
        yi_std = std(thr{i}(ind),'omitnan');
        yi_std = yi_std / (sqrt(length(thr{i}(ind))-1));
        hold on
        e = errorbar(ax(2),xi,yi,yi_std);
        e.Color = cm(j,:);
        e.CapSize = 0;
        e.LineWidth = 2;
        
        % set transparency and order
        alpha = 0.3;
        set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
        uistack(e,'bottom');
        
        h = line(ax(2),xi,yi, ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',max(cm(j,:)-.2,0), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',8);
    end
end

grid(ax(1),'off');
grid(ax(2),'off');

q = [sidx{:}];
r = [thr{:}];
d = [didx{:}];
clear p s m
hfit = [];
fo = cell(1,3);

% fit lines
for i = 1:3
    ind = q == i & ~isnan(r);
    
    dd = d(ind);
    dr = r(ind);
    
    xi = log10(dd)';
    [fo{i,1},gof(i,1)] = fit(xi,dr','poly1');
    
    yi = fo{i,1}.p1.*xi + fo{i,1}.p2;
    
    hfit(i) = line(ax(1),1+xi,yi, ...
        'Color',max(cm(i,:),0), ...
        'DisplayName',sprintf('%s (%.2f)',sessionName(i),fo{i,1}.p1),...
        'LineWidth',3);
    
    udd = unique(dd);
    mdr = nan(size(udd));
    for j = 1:length(udd)
        dind = dd == udd(j);
        mdr(j) = mean(dr(dind),'omitnan');
    end
    
    xi = log10(udd);
    [fo{i,2},gof(i,2)] = fit(xi',mdr','poly1');
    
    yi = fo{i,2}.p1.*xi + fo{i,2}.p2;
    
    hfitm(i) = line(ax(2),1+xi,yi, ...
        'Color',max(cm(i,:),0), ...
        'DisplayName',sprintf('%s (%.2f)',sessionName(i),fo{i,2}.p1),...
        'LineWidth',3);
    
end
uistack(hfit,'bottom');

% Pearson's R
for i = 1:3
    smean = n_mean(i,:);
    z = ~(isnan(smean) | isnan(days));
    [n_PR,n_P]= corr(smean(z)', days(z)', 'type','Spearman');
    PR{i} = n_PR;
    PRP{i} = n_P;
end

% behavior data
behav_mean = behav_mean(1:7);
behav_std = behav_std(1:7);
x = log10(days)+1;
xoffset = 0.98;
x = x*xoffset;
bplot = line(ax(2),x,behav_mean);
bplot.Marker = 'o';
bplot.MarkerSize = 8;
bplot.LineStyle = 'none';
bplot.Color = '#f77fad';
bplot.MarkerFaceColor = '#FAB4CF';

xi = log10(1:7);
[b_fo,b_gof] = fit(xi',behav_mean','poly1');
yi = b_fo.p1.*xi + b_fo.p2;

% fit
bfit = line(ax(2), xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', b_fo.p1),...
    'LineWidth',3,...
    'Color','#FAB4CF');

% error bars
e = errorbar(ax(2), (xi+1)*xoffset,behav_mean, behav_std);
e.LineStyle = 'none';
e.LineWidth= 2;
e.Color = '#FAB4CF';
e.CapSize = 0;

% set transparency
alpha = 0.3;
set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
uistack(e, 'bottom');

% Pearson's R
[b_PR,b_P] = corrcoef(behav_mean, xi);

% axes etc
set([ax.XAxis], ...
    'TickValues',log10(days)+1, ...
    'TickLabels',arrayfun(@(a) num2str(a,'%d'),days,'uni',0),...
    'FontSize',12);
set([ax.YAxis],...
    'FontSize',12);
ax(1).YAxis.Label.Rotation = 90;
ax(2).YAxis.Label.Rotation = 90;

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

ylim(ax(2),ylim(ax(1)));

xlabel(ax,'Psychometric testing day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'Threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 15);
title(ax,sprintf('%s (n = %d)',parname,length(subjects)),...
    'FontSize',15);

box(ax,'on');

legend(hfit,'Location','southwest','FontSize',12);
legend([hfitm,bfit],'Location','southwest','FontSize',12);
legend boxoff

fprintf('Behavior R = %s, p = %s \n', num2str(b_PR(2)), num2str(b_P(2)))
fprintf('Pre R = %s, p = %s \n', num2str(PR{1}), num2str(PRP{1}))
fprintf('Active R = %s, p = %s \n', num2str(PR{2}), num2str(PRP{2}))
fprintf('Post R = %s, p = %s \n', num2str(PR{3}), num2str(PRP{3}))

%% compare thresholds by coding

parx = 'FiringRate';
pary = 'VScc';

f = figure(sum(uint8('compare')));
f.Color = 'w';

clf(f);


cm = jet(length(days));

for i = 1:length(days)
    Ci = Cday{i};
    
    for k = 1:3
        
        ud = [Ci(sidx{i}==k).UserData];
        
        x = nan(size(ud));
        y = x;
        for j = 1:length(ud)
            if ~isfield(ud(j).(parx),'threshold') || ~isfield(ud(j).(pary),'threshold'), continue; end
            x(j) = ud(j).(parx).threshold;
            y(j) = ud(j).(pary).threshold;
        end
        
        ax = subplot(1,3,k);
        
        line(ax,x,y,'LineStyle','none', ...
            'Marker','o','Color',cm(i,:));
        
        if i == 1
            
            grid(ax,'on');
            box(ax,'on');
            
            xlabel(ax,{'Threshold (dB)';parx});
            
            if k == 1
                ylabel(ax,{'Threshold (dB)';pary});
            end
            
            axis(ax,'equal');
            axis(ax,'square');
            
            title(ax,sessionName(k));
        end
    end
    
end

ax = findobj(f,'type','axes');
y = get(ax,'ylim');
x = get(ax,'xlim');
m = cell2mat([x; y]);
m = [min(m(:)) max(m(:))];
set(ax,'xlim',m,'ylim',m);

sgtitle(f,'Threshold Coding Comparisons Across Days');


%% Flag cluster
flag_day = 4;
ind = [Cday{flag_day}.Name] == "cluster1456";

% Notes: motor = "motor", reverse neurometric curve = "reverse"
set(Cday{flag_day}(ind),'Note',"reverse")

save(Cdayfile, 'Cday')

%% Organize thresholds by cluster ID

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

% load clusters
Cdayfile = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Cday.mat';
load(Cdayfile)
days = 7;

temp = {};
output = {};

% only AM responsive
for i = 1:days
    Ci = Cday{i};
  
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
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
    
    % create output
    for j = 1:length(uid)
        % check for multiple units with the same id
        count(j) = sum(id==uid(j));
        if count(j) ~= 3
            error('Warning: more than one unit with ID %s on day %d\n', uid(j), i)
        end
        
        % populate temp
        temp{j,1} = uid(j);
        
        ind = uid(j) == id;
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        
        % thresholds
        temp{j,2} = t(1);
        temp{j,3} = t(2);
        temp{j,4} = t(3);
        
        % p vals
        temp{j,5} = pval(1);
        temp{j,6} = pval(2);
        temp{j,7} = pval(3);
    end
    
    output = [output;temp];
end

%%

% get total clusters
sumc = 0;
for i = 1:days
    numc = length(Cday{1,i});
    for j = 1:numc
        sumc = sumc + 1;
    end
end

% create matrix
output = [];

for i = 1:days
    numc = length(Cday{1,i});
    temp = zeros(numc,4);
    
    for j = 1:numc
        
        % add cluster ID
        id = str2num(erase(Cday{1,i}(j).Name,"cluster"));
        idcol = temp(:,1);
        if ismember(id, idcol)
            continue
        else
            temp(j,1) = id;
        end
    end
    
    % remove empty rows
    idx = [];
    for j = 1:length(temp)
        idx(j) = any(temp(j,1));
    end
    
    idx = logical(idx);
    temp = temp(idx,:);
    
    for j = 1:numc
        for k = 1:length(temp)
            id = str2num(erase(Cday{1,i}(j).Name,"cluster"));
            newid = temp(k,1);
            session = Cday{1,i}(j).Session.Name;
            measure = Cday{1,i}(j).UserData.(parname);
            checkempty = isfield(measure,'threshold');
           
            % add thresholds
            if contains(session,"Pre") && newid == id && checkempty == 1
                threshold = measure.threshold;
                temp(k,2) = threshold;
            end
            
            if contains(session,"Pre") && newid == id && checkempty == 0
                temp(k,2) = 100;
            end
            
            if contains(session,"Aversive") &&  newid == id && checkempty == 1
                threshold = measure.threshold;
                temp(k,3) = threshold;
            end
            
            if contains(session,"Post") && newid == id && checkempty == 1
                threshold = measure.threshold;
                temp(k,4) = threshold;
            end
        end
    end
    
    output = [output;temp];
end

%%
% outputfile = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\thresholds.mat';
% save(outputfile, 'output')

% split into improved vs worsened files
a = []; % improved
b = []; % worsened
c = []; % contained pre or active session(s) with 0 spikes

for i = 1:length(output)
    pre = output(i,2);
    active = output(i,3);
    post = output(i,4);
        
    if nnz(output(i,2:3)) < 2
        c = [c; output(i,:)];
    end
    
    if nnz(output(i,2:3)) == 2 && pre > active
        a = [a; output(i,:)];
    end
    
    if nnz(output(i,2:3)) == 2 && pre < active
        b = [b; output(i,:)];
    end
    
    if nnz(output(i,2:3)) == 2 && isnan(pre) && ~isnan(active)
        a = [a; output(i,:)];
    end
    
    if nnz(output(i,2:3)) == 2 && ~isnan(pre) && isnan(active)
        b = [b; output(i,:)];
    end
end

% file = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\thresholds_better.mat';
% save(file, 'a')
% 
% file = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\thresholds_worse.mat';
% save(file, 'b')

%%
x1 = a(:,2);
y1 = a(:,3);

[h1,p1] = ttest(x1,y1);

x2 = a(:,3);
y2 = a(:,4);

[h2,p2] = ttest(x2,y2);

x3 = b(:,2);
y3 = b(:,3);

[h3,p3] = ttest(x3,y3);

x4 = b(:,3);
y4 = b(:,4);

[h4,p4] = ttest(x4,y4);

fprintf('Clusters with improved threshold during active vs pre, p = %s \n',p1)
fprintf('Clusters with improved threshold during active vs post, p = %s \n',p2)
fprintf('Clusters with worsened threshold during active vs pre, p = %s \n',p3)
fprintf('Clusters with worsened threshold during active vs post, p = %s \n',p4)