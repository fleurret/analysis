
load('D:\Caras\Analysis\IC recordings\Behavior\267\SUBJ-ID-267_allSessions.mat')
f = figure;
f.Position = [0, 0, 850, 400];
hold on

days = [1:7];

x = log10(days)+1;
xoffset = 0.98;
x = x*xoffset;

ylim([-8, 4])
xticks(log10(days)+1)
xticklabels({1,2,3,4,5,6,7})

ccolor = '#343434';
ecolor = '#BC78D5';

% control
c = line(x,B1,...
    'Marker', '^',...
    'MarkerSize', 8,...
    'LineStyle', 'none',...
    'Color', ccolor,...
    'MarkerFaceColor', ccolor);

xi = log10(1:7);
[c_fo,c_gof] = fit(xi',B1','poly1');
yi = c_fo.p1.*xi + c_fo.p2;
    
% fit
cfit = line(xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', c_fo.p1),...
    'LineWidth',3,...
    'Color', ccolor);

% experimental
e = line(x,B2,...
    'Marker', 'o',...
    'MarkerSize', 8,...
    'LineStyle', 'none',...
    'Color', ecolor,...
    'MarkerFaceColor', ecolor);

[e_fo,e_gof] = fit(xi',B2','poly1');
yi = e_fo.p1.*xi + e_fo.p2;
    
% fit
efit = line(xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', e_fo.p1),...
    'LineWidth',3,...
    'Color', ecolor);

%%

b1 = thresholds(1);
B1 = thresholds-b1;

b2 = thresholds2(1);
B2 = thresholds2-b2;
