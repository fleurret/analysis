function avg_threshold(pth, maxdays, yl, c)

% PROCESS

% extract groups
groups = dir(pth);
groups(~[groups.isdir]) = [];
groups(ismember({groups.name},{'.','..'})) = [];

% access condition folders
for i = 1:length(groups)
    cond = groups(i).name;
    fn = fullfile(pth,cond);

    % extract subjects
    subjects = dir(fn);
    subjects(~[subjects.isdir]) = [];
    subjects(ismember({subjects.name},{'.','..'})) = [];
    
    % create empty array to store data
    t = nan(1,maxdays);
    thresholds = nan(length(subjects),maxdays);
    
    % extract thresholds
    for subj = 1:length(subjects)
        spth = fullfile(subjects(subj).folder,subjects(subj).name);
        d = dir(fullfile(spth,'*.mat'));
        ffn = fullfile(d.folder,d.name);
        
        fprintf('Loading subject %s ...',subjects(subj).name)
        load(ffn)
        fprintf(' done\n')
        
        for j = 1:length(output)
            t(j) = output(j).fitdata.threshold;
        end
        
        thresholds(subj,1:length(t)) = t;
    end
    
    % calculate mean and standard error across days
    for j = 1:maxdays
        x = thresholds(1:subj,j);
        m = mean(x, 'omitnan');
        s = std(x, 'omitnan');
        s = s /(sqrt(maxdays));
        
        M(i,j) = m;
        S(i,j) = s;
    end
    
    % populate legend values
    lv = append(cond,' (n = ', num2str(length(subjects)),')');
    C{i} = lv;
end

% PLOT

f = figure();

% set figure size (in px)
f.Position = [0, 0, 800, 350];

% change x values to log scale and offset
days = 1:maxdays;
xx = log10(days)+1;
xoffset = [0.99,1.01];

% set axes
ax = gca;

hold on

% plot data
for i = 1:length(groups)
    y = M(i,:);
    s = S(i,:);
    xi = xx*xoffset(i);
    
    % errorbar properties
    e = errorbar(xi,y,s,...
        'Color', c(i,:),...
        'CapSize', 0,...
        'LineWidth', 2,...
        'LineStyle', 'none',...
        'Marker', 'o',...
        'MarkerFaceColor', c(i,:), ...
        'MarkerSize',8);
    alpha = 0.3;
    set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
    uistack(e,'bottom');
    
    % fit line
    [fo,~] = fit(xi',y','poly1');
    bf = fo.p1 .*xi + fo.p2;
    f(i) = line(xi, bf,...
        'LineWidth',3,...
        'Color',c(i,:));
end

% GRAPH PROPERTIES

% tick label, direction, line width, font size
set(ax, 'XTick', log10(x)+1,...
    'XTickLabel',days,...
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
legend(flip(C),'Location','southwest','FontSize',12);
legend boxoff

