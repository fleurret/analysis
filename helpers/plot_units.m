function plot_units(spth, behavdir, savedir, parname, subj, condition, unit_type)

% Plot individual unit thresholds and means across days

% correlation coefficient is set to Spearman's

% load behavior
load(fullfile(behavdir,'behavior_combined.mat'));

% load neural
if unit_type == "SU"
    load(fullfile(savedir,'Cday_VScc_restrictiveSU.mat'));
else
    fn = 'Cday_';
    fn = strcat(fn,(parname),'.mat');
    load(fullfile(savedir,fn));
end

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 10;

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
    
    % only plot one subject    
    if subj ~= "all"
        subj_idx = zeros(1,length(Ci));
        for j = 1:length(Ci)
            cs = convertCharsToStrings(Ci(j).Subject);
            if contains(cs,subj)
                subj_idx(j) = 1;
            else
                subj_idx(j) = 0;
            end
        end
        subj_idx = logical(subj_idx);
        Ci = Ci(subj_idx);
    end
    
    % only plot one condition
    if condition ~= "all"
        if condition == "w"
            ffn = fullfile(savedir,'NeuralThresholds',(parname),'thresholds_worsened.mat');
            load(ffn)
            
            subset = worsened;
        end
        
        if condition == "i"
            ffn = fullfile(savedir,'NeuralThresholds',(parname),'thresholds_improved.mat');
            load(ffn)
            
            subset = improved;
        end
        
        id = [Ci.Name];
        uid = unique(id);
        
        j = 1:length(subset);
        subj_idx = cell2mat(subset(j,2)) == i;
        wid = subset(subj_idx);
        wid = [wid{:}];
        
        flaggedForRemoval = "";
        
        for k = 1:length(uid)
            ind = uid(k) == wid;
            if sum(ind) == 0
                flaggedForRemoval(end+1) = uid(k);
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
    end

    % remove multiunits
    if unit_type == "SU"
        removeind = [Ci.Type] == "SU";
        Ci = Ci(removeind);
    end
    
    y = arrayfun(@(a) a.UserData.(parname),Ci,'uni',0);
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
            'Color',max(cm(j,:),0), ...
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
bplot.Color = '#ff7bb1';
bplot.MarkerFaceColor = '#ff7bb1';

xi = log10(1:7);
[b_fo,b_gof] = fit(xi',behav_mean','poly1'); %#ok<ASGLU>
yi = b_fo.p1.*xi + b_fo.p2;

% fit
bfit = line(ax(2), xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', b_fo.p1),...
    'LineWidth',3,...
    'Color','#ff7bb1');

% error bars
e = errorbar(ax(2), (xi+1)*xoffset,behav_mean, behav_std);
e.LineStyle = 'none';
e.LineWidth= 2;
e.Color = '#ff7bb1';
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