function one_subject_threshold(pth, maxdays, yl, c)

% PROCESS

% subj  name
subject = split(pth, '\');

% load file
d = dir(fullfile(pth,'*.mat'));
ffn = fullfile(d.folder,d.name);

fprintf('Loading subject %s ...',cell2mat(subject(end)))
load(ffn)
fprintf(' done\n')

for j = 1:length(output)
    thresholds(j) = output(j).fitdata.threshold;
end

% PLOT
f = figure();

% set figure size (in px)
f.Position = [0, 0, 800, 350];

% change x values to log scale and offset
y = thresholds(1:maxdays);

days = 1:maxdays;
x = log10(days)+1;

% set axes
ax = gca;

hold on

% plot data
plot(x,y,...
    'Color', c(1,:),...
    'LineStyle', 'none',...
    'Marker', 'o',...
    'MarkerFaceColor', c(1,:), ...
    'MarkerSize',8);

% fit line
[fo,~] = fit(x',y','poly1');
bf = fo.p1 .*x + fo.p2;
f = line(x, bf,...
    'LineWidth',3,...
    'Color',c(1,:));
    
% GRAPH PROPERTIES

% tick label, direction, line width, font size
set(ax, 'XTick', log10(days)+1,...
    'XTickLabel', days,...
    'YLim',yl,...
    'TickDir','out',...
    'LineWidth',1.5,...
    'FontSize',12);

% set font
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

% axes labels and title
xlabel(ax,'Psychometric testing day',...
    'FontWeight','bold',...
    'FontSize', 12);
ylabel(ax,'Threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 12);

% legend
% legend(flip(C),'Location','southwest','FontSize',12);
% legend boxoff

