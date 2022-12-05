parentDir = 'C:\Users\rose\Documents\Caras\Analysis\Caspase\Acquisition\Control\399';
behav_file = fullfile(parentDir,'SUBJ-ID-399_allSessions.mat');
load(behav_file)
%%
f = figure;
    f.Position = [0, 0, 500 600];
    f.Resize = 'off';
hold on

xlabel('AM Depth (dB re: 100%)',...
    'FontSize', 20,...
    'FontWeight', 'bold')
ylabel('d''',...
    'FontSize', 20,...
    'FontWeight', 'bold')
yticks([0, 1, 2, 3, 4])
ax = gca;
ax.FontSize = 20;
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
%% one fit
% day 1
x = output(4).fitdata.fit_plot.x([413:870]);
y = output(4).fitdata.fit_plot.dprime([413:870]);
p = plot(x,y);
    p.LineWidth = 5;
    p.Color = '#FAB4CF';
xpoint = output(1).dprimemat(:,1);
ypoint = output(1).dprimemat(:,2);
points = scatter(xpoint,ypoint,100);
    points.MarkerFaceColor = '#FAB4CF';
    points.MarkerFaceAlpha = 0.5;
    points.MarkerEdgeAlpha = 0;

set(gca, 'XLimMode', 'manual', 'XLim', [-27 2])    
set(gca, 'YLimMode', 'manual', 'YLim', [-0.5 3])
    
%% all fits
% day 1
% x = output(1).fitdata.fit_plot.x([413:870]);
% y = output(1).fitdata.fit_plot.dprime([413:870]);
% p = plot(x,y);
%     p.LineWidth = 5;
%     p.Color = '#FAB4CF';
% xpoint = output(1).dprimemat(:,1);
% ypoint = output(1).dprimemat(:,2);
% points = scatter(xpoint,ypoint,100);
%     points.MarkerFaceColor = '#FAB4CF';
%     points.MarkerFaceAlpha = 0.5;
%     points.MarkerEdgeAlpha = 0;

% day 2
% x = output(2).fitdata.fit_plot.x([435:928]);
% y = output(2).fitdata.fit_plot.dprime([435:928]);
% p = plot(x,y);
%     p.LineWidth = 5;
%     p.Color = '#cb83e6';
% xpoint = output(2).dprimemat(:,1);
% ypoint = output(2).dprimemat(:,2);
% points = scatter(xpoint,ypoint,100);
%     points.MarkerFaceColor = '#cb83e6';
%     points.MarkerFaceAlpha = 0.5;
%     points.MarkerEdgeAlpha = 0;

% day 3
% x = output(3).fitdata.fit_plot.x([470:1000]);
% y = output(3).fitdata.fit_plot.dprime([470:1000]);
% p = plot(x,y);
%     p.LineWidth = 5;
%     p.Color = '#836bd1';
% xpoint = output(3).dprimemat(:,1);
% ypoint = output(3).dprimemat(:,2);
% points = scatter(xpoint,ypoint,100);
%     points.MarkerFaceColor = '#836bd1';
%     points.MarkerFaceAlpha = 0.5;
%     points.MarkerEdgeAlpha = 0;

% day 4
x = output(4).fitdata.fit_plot.x([435:930]);
y = output(4).fitdata.fit_plot.dprime([435:930]);
p = plot(x,y);
    p.LineWidth = 5;
    p.Color = '#5882cf';
xpoint = output(4).dprimemat(:,1);
ypoint = output(4).dprimemat(:,2);
points = scatter(xpoint,ypoint,100);
    points.Marker = '^';
    points.MarkerFaceColor = '#5882cf';
    points.MarkerFaceAlpha = 0.5;
    points.MarkerEdgeAlpha = 0;

% day 5
% x = output(5).fitdata.fit_plot.x([460:900]);
% y = output(5).fitdata.fit_plot.dprime([460:900]);
% p = plot(x,y);
%     p.LineWidth = 5;
%     p.Color = '#74e3f0';
% xpoint = output(5).dprimemat(:,1);
% ypoint = output(5).dprimemat(:,2);
% points = scatter(xpoint,ypoint,100);
%     points.MarkerFaceColor = '#74e3f0';
%     points.MarkerFaceAlpha = 0.5;
%     points.MarkerEdgeAlpha = 0;

% day 6
% x = output(6).fitdata.fit_plot.x([470:1000]);
% y = output(6).fitdata.fit_plot.dprime([470:1000]);
% p = plot(x,y);
%     p.LineWidth = 5;
%     p.Color = '#8adea6';
% xpoint = output(6).dprimemat(:,1);
% ypoint = output(6).dprimemat(:,2);
% points = scatter(xpoint,ypoint,100);
%     points.MarkerFaceColor = '#8adea6';
%     points.MarkerFaceAlpha = 0.5;
%     points.MarkerEdgeAlpha = 0;

% day 7
% x = output(7).fitdata.fit_plot.x([470:1000]);
% y = output(7).fitdata.fit_plot.dprime([470:1000]);
% p = plot(x,y);
%     p.LineWidth = 5;
%     p.Color = '#d4e261';
% xpoint = output(6).dprimemat(:,1);
% ypoint = output(6).dprimemat(:,2);
% points = scatter(xpoint,ypoint,100);
%     points.MarkerFaceColor = '#d4e261';
%     points.MarkerFaceAlpha = 0.5;
%     points.MarkerEdgeAlpha = 0;
 
set(gca, 'XLimMode', 'manual', 'XLim', [-27 2])
set(gca, 'YLimMode', 'manual', 'YLim', [0 3.2])

% clear legend
legend('Day 1', '', 'Day 2', '', 'Day 3', '', 'Day 4', '', 'Day 5', '', 'Day 6', '', 'Day 7',...
    'FontSize',20)
legend boxoff

%% thresholds over days
f = figure;
    f.Position = [0, 0, 500 200];
    f.Resize = 'off';
hold on

% best fit line
x = [1:7];
y = [];
for i = [1:7]
    a = output(i).fitdata.threshold;
    y = [y, a];
end

coefficients = polyfit(log(x), y, 1);
xfit = linspace(min(x), max(x), 1000);
yfit = polyval(coefficients, log(xfit));
bestfit = plot(xfit, yfit, '-','LineWidth',2);
    bestfit.LineWidth = 3;
    bestfit.Color = '#000';
    
% day 1
x = 1;
y = output(1).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#ffa1d9';
    s.MarkerEdgeAlpha = 0;

% day 2
x = 2;
y = output(2).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#cb83e6';
    s.MarkerEdgeAlpha = 0;
    
% day 3
x = 3;
y = output(3).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#836bd1';
    s.MarkerEdgeAlpha = 0;
    
% day 4
x = 4;
y = output(4).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#5882cf';
    s.MarkerEdgeAlpha = 0;
    
% day 5
x = 5;
y = output(5).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#74e3f0';
    s.MarkerEdgeAlpha = 0;
    
% day 6
x = 6;
y = output(6).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#8adea6';
    s.MarkerEdgeAlpha = 0;  
    
% day 7
x = 7;
y = output(7).fitdata.threshold;
s = scatter(x,y,100);
    s.MarkerFaceColor = '#d4e261';
    s.MarkerEdgeAlpha = 0;    

    
set(gca, 'XLimMode', 'manual', 'XLim', [0.9 8])
set(gca, 'YLimMode', 'manual', 'YLim', [-20 -10])
set(gca, 'XScale', 'log')

xticks([1, 2, 3, 4, 5, 6, 7])
yticks([-20, -15, -10])
xlabel('Psychometric Testing Day',...
    'FontSize', 20,...
    'FontWeight','bold')
ylabel('Threshold (dB re: 100%)',...
    'FontSize', 20,...
    'FontWeight','bold')
ax = gca;
ax.FontSize = 20;
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
