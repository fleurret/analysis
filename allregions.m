a = readtable('D:\Caras\Analysis\allregions.csv');

region = ["IC", "MGN", "ACx"];
sessions = ["Pre", "Active", "Post"];

%% proportions
cm = [3, 7, 30; 240, 240, 240]./255; % session colormap

f = figure;
f.Position = [0, 0, 900, 500];

ax = gca;
set(gca, 'TickDir', 'out',...
    'XTickLabelRotation', 0,...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3);
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
ucm = cm(1,:);
hold on

xticks([1:9])
set(gca,'XTickLabelMode','auto',...
    'FontSize', 36)
xticklabels({'Pre','Task','Post','Pre','Task','Post','Pre','Task','Post'})

for i = 1:length(region)
    r = region(i);
    ind = contains(a.Region,r);
    
    subset = a(ind,:);
    
    % each session
    for j = 1:length(sessions)
       sind = contains(subset.Session, sessions(j));
       t = subset(sind,:);
       
       total = height(t);
       valid = sum(t.Validity);
      
       v(j) = valid/total;
    end
    
    % plot
    x = [0,1,2]+(i*3-2);
    nr = ones(1,length(sessions));
    bar(x, nr,...
        'BarWidth', 0.5,...
        'FaceColor', cm(2,:),...
        'EdgeColor', 'none')
    bar(x, v,...
        'BarWidth', 0.5,...
        'FaceColor', cm(1,:),...
        'EdgeColor', 'none')

        
end

%% task thresholds
% plot settings
cm = [3, 7, 30]./255; % session colormap

f = figure;
f.Position = [0, 0, 500, 600];

ax = gca;
set(gca, 'TickDir', 'out',...
    'XTickLabelRotation', 0,...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3);
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
ucm = cm(1,:);
hold on

xticks([1:3])
set(gca,'XTickLabelMode','auto',...
    'FontSize', 36)
xticklabels({'ICC','MGV','ACx'})

xlabel(ax,'Session','FontSize',36,...
    'FontWeight','bold')
ylabel(ax,'Task threshold (dB re: 100%)',...
    'FontSize', 36,...
    'FontWeight', 'bold');
xlim([0.8 3.2])
ylim([-20 0])

for i = 1:length(region)
    r = region(i);
    ind = contains(a.Region,r);
    
    subset = a(ind,:);
    
    % only task
    for j = 1:height(subset)
       sind = contains(subset.Session, 'Active');
       tt = subset(sind,:);
       
       % remove nans
       tt = tt(~isnan(tt.Threshold),:);
    end
    
    m(i) = mean(tt.Threshold);
    
    % plot
    
    x = i*ones(height(tt),1);
    y = [tt.Threshold];
    
    scatter(x,y,...
        'Marker', 'o',...
        'SizeData', 80,...
        'MarkerFaceColor', cm(1,:),...
        'MarkerFaceAlpha', 0.1,...
        'MarkerEdgeAlpha', 0)
    scatter(i, m(i),...
        'Marker', 'o',...
        'SizeData', 220,...
        'MarkerFaceColor', cm(1,:),...
        'MarkerEdgeAlpha', 0)
    
end