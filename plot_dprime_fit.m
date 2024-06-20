% parentDir = 'D:\Caras\Analysis\Caspase\Acquisition\Control\512';
parentDir = 'D:\Caras\Analysis\IC recordings\Behavior\202';
behav_file = fullfile(parentDir,'SUBJ-ID-202_allSessions.mat');
load(behav_file)
%%
f = figure;
f.Position = [0, 0, 600 400];
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
ax.LineWidth = 3;
ax.TickDir = 'out';
ax.TickLength = [0.02,0.02];
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

cm = [131,31,94; 181,37,126; 206,71,148; 240,122,174; 241,157,196; 243,181,210; 250,211,228]./255; % session colormap
%% one fit
% day 1
x = output(1).fitdata.fit_plot.x([413:870]);
y = output(1).fitdata.fit_plot.dprime([413:870]);
p = plot(x,y);
p.LineWidth = 5;
p.Color = cm(1,:);
xpoint = output(1).dprimemat(:,1);
ypoint = output(1).dprimemat(:,2);
points = scatter(xpoint,ypoint,200);
points.MarkerFaceColor = cm(1,:);
points.MarkerFaceAlpha = 0.5;
points.MarkerEdgeAlpha = 0;

set(gca, 'XLimMode', 'manual', 'XLim', [-27 2])
set(gca, 'YLimMode', 'manual', 'YLim', [-0.25 3.2])

%% all fits
for i = 1:7
    x = output(i).fitdata.fit_plot.x([413:870]);
    y = output(i).fitdata.fit_plot.dprime([413:870]);
    p = plot(x,y);
    p.LineWidth = 5;
    p.Color = cm(i,:);
    xpoint = output(i).dprimemat(:,1);
    ypoint = output(i).dprimemat(:,2);
    points = scatter(xpoint,ypoint,100);
    points.MarkerFaceColor = cm(i,:);
    points.MarkerFaceAlpha = 0.5;
    points.MarkerEdgeAlpha = 0;
end

set(gca, 'XLimMode', 'manual', 'XLim', [-27 2])
set(gca, 'YLimMode', 'manual', 'YLim', [-0.25 3.2])

% clear legend
legend('Day 1', '','Day 2','', 'Day 3', '','Day 4', '','Day 5', '','Day 6', '','Day 7','','Day 8', '', 'Day 9', '', 'Day 10',...
    'FontSize',20,...
    'Location', 'Northwest')
legend boxoff

%% thresholds over days
f = figure;
f.Position = [0, 0, 600 400];
f.Resize = 'off';
hold on

% best fit line
x = [1:7];
y = [];
for i = x
    a = output(i).fitdata.threshold;
    y = [y, a];
end

coefficients = polyfit(log(x), y, 1);
xfit = linspace(min(x), max(x), 1000);
yfit = polyval(coefficients, log(xfit));
bestfit = plot(xfit, yfit, '-','LineWidth',2);
bestfit.LineWidth = 3;
bestfit.Color = '#000';

for i = x
    x = i;
    y = output(i).fitdata.threshold;
    s = scatter(x,y,100);
    s.MarkerFaceColor = cm(i,:);
    s.MarkerEdgeAlpha = 0;
end

set(gca, 'XLimMode', 'manual', 'XLim', [0.9 8])
set(gca, 'YLimMode', 'manual', 'YLim', [-20 -8])
set(gca, 'XScale', 'log')

xticks([1, 2, 3, 4, 5, 6, 7])
yticks([-20, -15, -10, -5])
xlabel('Psychometric Testing Day',...
    'FontSize', 16,...
    'FontWeight','bold')
ylabel('Threshold (dB re: 100%)',...
    'FontSize', 16,...
    'FontWeight','bold')
ax = gca;
ax.FontSize = 20;
ax.LineWidth = 3;
ax.TickDir = 'out';
ax.TickLength = [0.02,0.02];
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')


%% pretty plots
% average thresholds
behavdir = 'D:\Caras\Analysis\MGB recordings\Behavior\';
load(fullfile(behavdir,'behavior_combined.mat'));

% plot vars
f = figure;
f.Position = [0, 0, 415, 300];

set(f,'color','w');
clf(f);
cm = [131,31,94; 181,37,126; 206,71,148; 240,122,174; 241,157,196; 243,181,210; 250,211,228]./255; % session colormap

ylim([-20 -5])

% plot mean and std
days = 1:7;
behav_mean = behav_mean(1:7);
behav_std = behav_std(1:7);

x = log10(days)+1;
xoffset = 0.98;
x = x*xoffset;

hold on
for i = 1:length(behav_mean)
    bplot = plot(x(i),behav_mean(i));
    bplot.Marker = 'o';
    bplot.MarkerSize = 8;
    bplot.LineStyle = 'none';
    bplot.Color = cm(i,:);
    bplot.MarkerFaceColor =  cm(i,:);
end

xi = log10(1:7);
[b_fo,~] = fit(xi',behav_mean','poly1');
yi = b_fo.p1.*xi + b_fo.p2;

% fit
bfit = line(xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', b_fo.p1),...
    'LineWidth',3,...
    'Color','#000000');

e = errorbar((xi+1)*xoffset,behav_mean, behav_std);
e.LineStyle = 'none';
e.LineWidth= 2;
e.Color = '#000000';
e.CapSize = 0;

% set transparency
alpha = 0.3;
set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
uistack(e, 'bottom');

% axes
ax = gca;
set(ax,...
    'XTick',log10(days)+1, ...
    'XTickLabels',arrayfun(@(a) num2str(a,'%d'),days,'uni',0),...
    'TickDir','out',...
    'FontSize',12);

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xlabel(ax,'Psychometric testing day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'Threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 15);

%% pretty plots 2 
% average d' to -9db
behavdir = 'D:\Caras\Analysis\IC recordings\Behavior\';
data = readtable(fullfile(behavdir,'behavior_dprime_-9.csv'));
data = table2struct(data);

% get mean and std
behav_mean = nan(1,7);
behav_std = nan(1:7);

for i = 1:7
    currentday = [data.Day] == i;
    dprimes = [data.dprime];
    currentdata = dprimes(currentday);
    
    behav_mean(i) = mean(currentdata);
    behav_std(i) = std(currentdata);
end

% plot vars
f = figure;
f.Position = [0, 0, 415, 300];

set(f,'color','w');
clf(f);
cm = [250, 180, 207; 203, 131, 230; 131, 107, 209; 88, 130, 207; 51, 179, 229; 138, 222, 166; 212, 226, 97;]./255; % session colormap

ylim([0 3])

% plot mean and std
days = 1:7;
behav_mean = behav_mean(1:7);
behav_std = behav_std(1:7);

x = log10(days)+1;
xoffset = 0.98;
x = x*xoffset;

hold on
for i = 1:length(behav_mean)
    bplot = plot(x(i),behav_mean(i));
    bplot.Marker = 'o';
    bplot.MarkerSize = 8;
    bplot.LineStyle = 'none';
    bplot.Color = cm(i,:);
    bplot.MarkerFaceColor =  cm(i,:);
end

xi = log10(1:7);
[b_fo,~] = fit(xi',behav_mean','poly1');
yi = b_fo.p1.*xi + b_fo.p2;

% fit
bfit = line(xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', b_fo.p1),...
    'LineWidth',3,...
    'Color','#000000');

e = errorbar((xi+1)*xoffset,behav_mean, behav_std);
e.LineStyle = 'none';
e.LineWidth= 2;
e.Color = '#000000';
e.CapSize = 0;

% set transparency
alpha = 0.3;
set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
uistack(e, 'bottom');

% axes
ax = gca;
set(ax,...
    'XTick',log10(days)+1, ...
    'XTickLabels',arrayfun(@(a) num2str(a,'%d'),days,'uni',0),...
    'TickDir','out',...
    'FontSize',12);

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xlabel(ax,'Psychometric testing day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'d''',...
    'FontWeight','bold',...
    'FontSize', 15);
