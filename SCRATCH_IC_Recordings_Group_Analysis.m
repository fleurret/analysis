%% Group Analysis
% behavior
parentDir = 'C:\Users\Rose\OneDrive\Documents\Caras\MATLAB\';
behav_file = fullfile(parentDir,'behavior_combined.mat');
load(behav_file)

% neural
spth = 'C:\Users\Rose\OneDrive\Documents\Caras\Data';


subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% subjects(1)= [];

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
    end    
end


%% Plot 

% parname = 'FiringRate';
% parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
parname = 'Power';

alpha = 0.05;
minNumSpikes = 0;
maxNumDays = 7;

sessionName = ["Pre","Active","Post"];

cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

mk = '^>v';
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
    
    y = arrayfun(@(a) a.UserData.(parname),Ci,'uni',0);
    ind = cellfun(@(a) isfield(a,'ERROR'),y);
   
    ind = ind | [Ci.N] < minNumSpikes;
    
    y(ind) = [];
    
    Ci(ind) = [];
    
    y = [y{:}];
    
    thr{i} = [y.threshold];

%     thr{i} = 20*log10(thr{i});
    
    didx{i} = ones(size(y))*i;
    
    sidx{i} = nan(size(y));
    
    sn = [Ci.SessionName];
    sidx{i}(contains(sn,"Pre")) = 1;
    sidx{i}(contains(sn,"Aversive")) = 2;
    sidx{i}(contains(sn,"Post")) = 3;
     
    x = 1+ones(size(thr{i}))*log10(days(i));

    for j = 1:3 % plot each session seperately
        ind = sidx{i} == j;
        xi = x*xoffset(j);

        h = line(ax(1),xi(ind),thr{i}(ind), ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',max(cm(j,:)-.1,0), ...
            'MarkerFaceColor',cm(j,:), ...
            'ButtonDownFcn',{@cluster_plot_callback,Ci(ind),xi(ind),thr{i}(ind),parname});

       
        xi = mean(xi);
        yi = mean(thr{i}(ind),'omitnan');
        h = line(ax(2),xi,yi, ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',max(cm(j,:)-.1,0), ...
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


    
% behavior data
behav_mean = behav_mean(1:7);
behav_std = behav_std(1:7);
bplot = line(ax(2),log10(days)+1,behav_mean);
    bplot.Marker = 'o';
    bplot.MarkerSize = 8;
    bplot.LineStyle = 'none';
    bplot.Color = '#FAB4CF';
    bplot.MarkerFaceColor = '#FAB4CF';
    

    xi = log10(1:7);
    [b_fo,b_gof] = fit(xi',behav_mean','poly1');
    
    yi = b_fo.p1.*xi + b_fo.p2;
    
    bfit = line(ax(2), xi+1, yi,...
        'DisplayName', sprintf('Behavior (%.2f)', b_fo.p1),...
        'LineWidth',3,...
        'Color','#FAB4CF');

set([ax.XAxis], ...
    'TickValues',log10(days)+1, ...
    'TickLabels',arrayfun(@(a) num2str(a,'%d'),days,'uni',0));
ax(1).YAxis.Label.Rotation = 90;
ax(2).YAxis.Label.Rotation = 90;

set(findobj(ax,'-property','FontName'),'FontName','Arial')

ylim(ax(2),ylim(ax(1)));

xlabel(ax,'Psychometric testing day');
ylabel(ax,'Threshold (dB re: 100%)');
title(ax,sprintf('%s (n = %d)',parname,length(subjects)));
box(ax,'on');

legend(hfit,'Location','southwest');
legend([hfitm,bfit],'Location','southwest');




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


