uiopen('D:\Caras\Analysis\ACx recordings\concatenated_forplot.csv',1)

%%
data = concatenatedforplot;

cm = [77,127,208; 96,216,216; 2,37,81;]./255;% session colormap

mk = 'ooo';
xoffset = [.99, 1, 1.01];

f = figure;
f.Position = [0, 0, 1000, 290];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
ax(2) = subplot(122,'parent',f);
hold on

for i = 1:7
    day = data.Day == i;
    subset = data(day,3:5);
    logday = log10(i)+1;
    x = repelem(logday, height(subset));
    
    for j = 1:3
        xi = x*xoffset(j);
        yi = table2array(subset(:,j));
        
        % fit
        line(ax(1),xi, yi, ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',(cm(j,:)), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',8);
            
        % means and error bars
        xj = mean(xi);
        yj = mean(yi);
        se = std(yi)/(sqrt(length(yi)));

        e = errorbar(ax(2),xj,yj,se);
        e.Color = cm(j,:);
        e.CapSize = 0;
        e.LineWidth = 2;
        
        % set transparency and order
        alpha = 1;
        set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
        uistack(e,'bottom');
        
        h = line(ax(2),xj,yj, ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',max(cm(j,:),0), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',8);
    end
end

grid(ax(1),'off');
grid(ax(2),'off');

thr = data(:,3:5);

% fit lines
for i = 1:3
    dr = table2array(thr(:,i));
    xi = log10(table2array(data(:,2)));
    
    [fo{i,1},gof(i,1)] = fit(xi,dr,'poly1');
    yi = fo{i,1}.p1.*xi + fo{i,1}.p2;
    
    hfit(i) = line(ax(2),1+xi,yi, ...
        'Color',max(cm(i,:),0), ...
        'LineWidth',3);
end

% axes etc
set([ax.XAxis], ...
    'TickValues',log10(1:7)+1, ...
    'TickLabels',arrayfun(@(a) num2str(a,'%d'),1:7,'uni',0),...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3,...
    'FontSize', 16);
set([ax.YAxis],...
    'TickDir','out',...,
    'TickLength', [0.02,0.02],...
    'LineWidth', 3,...
    'FontSize', 16);
ax(1).XLim = [0.8,1.95];
ax(2).XLim = [0.8,1.95];
ax(1).YTick = [-15 -10 -5 0];
ax(2).YTick = [-15 -10 -5 0];
ax(1).YLim = [-17,0];
ax(2).YLim = [-17,0];

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xlabel(ax,'Perceptual training day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'Threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 15);