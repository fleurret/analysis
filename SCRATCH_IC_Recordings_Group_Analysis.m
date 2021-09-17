%% Group Analysis

spth = 'C:\Users\Daniel\Documents\MATLAB\TestEPhysData\';


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


parname = 'FiringRate';
% parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

alpha = 0.05;
minNumSpikes = 0;
maxNumDays = 7;

sessionName = ["Pre","Active","Post"];


cm = [163,212,164; 57,147,205;0,148,63]./255;% session colormap

mk = '^sv';
xoffset = [.99, 1, 1.01];


f = figure(sum(uint8(parname)));
set(f,'color','w');
clf(f);
ax = axes(f);

days = 1:min(maxNumDays,length(Cday));

thr = cell(size(days));
sidx = thr;
didx = thr;

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
    for j = 1:length(y)
        sn = Ci(j).Session.Name;
        if contains(sn,"Pre")
            sidx{i}(j) = 1;
        elseif contains(sn,"Post")
            sidx{i}(j) = 3;
        else
            sidx{i}(j) = 2;
        end
    end
     
    x = 1+ones(size(thr{i}))*log10(days(i));

    for j = 1:3
        ind = sidx{i} == j;
        xi = x*xoffset(j);

        h = line(ax,xi(ind),thr{i}(ind), ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',max(cm(j,:)-.1,0), ...
            'MarkerFaceColor',cm(j,:), ...
            'ButtonDownFcn',{@cluster_plot_callback,Ci(ind),xi(ind),thr{i}(ind),parname});
    end
end

q = [sidx{:}];
r = [thr{:}];
d = [didx{:}];
clear p s m
for i = 1:3
    ind = q == i & ~isnan(r);
    
    [p(i,:),s(i),m(:,i)] = polyfit(log10(d(ind)),r(ind),1);
    
    xi = log10(days([1 end]));
    yi = polyval(p(i,:),xi,s(i),m(:,i));
    
    hfit(i) = line(ax,1+xi,yi,'Color',max(cm(i,:),0), ...
        'DisplayName',sprintf('%s (%.2f)',sessionName(i),p(i,1)),...
        'LineWidth',2);
end
uistack(hfit,'bottom');

ax.XAxis.TickValues = log10(days)+1;
ax.XAxis.TickLabels = arrayfun(@(a) num2str(a,'%d'),days,'uni',0);
ax.YAxis.Label.Rotation = 90;

set(findobj(ax,'-property','FontName'),'FontName','Consolas')

xlabel(ax,'day');
ylabel(ax,'Threshold (dB)');
title(ax,sprintf('%s (n = %d)',parname,length(subjects)));
grid(ax,'on');
box(ax,'on');

legend(hfit,'Location','southwest');




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


