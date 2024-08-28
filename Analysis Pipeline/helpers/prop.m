function prop(savedir, sv)

fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

maxNumDays = 7;
days = 1:min(maxNumDays,length(Cday));

output = [];

for i = 1:length(days)
    Ci = Cday{i};
    name = [Ci.Name];
    sn = unique(split(name,'_'));
    subjs = sn(contains(sn,'SUBJ'));
    
    for j = 1:length(subjs)
        S = subjs(j);
        U = Ci(contains(name,S));
        total = length(unique([U.Name]));
        
        SU = U([U.Type]=="SU");
        totalSU = length(unique([SU.Name]));
        
        Ci1 = filterunits(savedir, 'trial_firingrate', Cday, i, 'SU', 'all');
        Ci3 = filterunits(savedir, 'vector_strength_cycle_by_cycle', Cday, i, 'SU', 'all');
        
        allfr = unique([Ci1.Name]);
        fr = length(allfr(contains(allfr,S)));
        allvs = unique([Ci3.Name]);
        vs = length(allvs(contains(allvs,S)));
        
        temp = [S, i, fr, vs, total, totalSU, fr/total, vs/totalSU];
        output = [output; temp];
        
        clear temp
    end
end

output = array2table(output);
output.Properties.VariableNames = ["Subject", "Day", "FR", "VS", "Total", "TotalSU", "FR prop", "VS prop"];

if sv == 1
    sf = fullfile(savedir,append('Spreadsheets\Proportions.csv'));
    fprintf('\n Saving file %s ...', sf)
    writetable(output,sf);
    fprintf(' done\n')
end

% plot
f = figure;
f.Position = [0, 0, 1000, 290];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
hold on
ax(2) = subplot(122,'parent',f);
hold on

for i = 1:7
    day = output(output.Day == num2str(i),:);
    FR = sum(str2double(day.FR))/sum(str2double(day.Total));
    VS = sum(str2double(day.VS))/sum(str2double(day.TotalSU));
    
    bar(ax(1), i, FR);
    bar(ax(2), i, VS);
end

% axes etc
set([ax.XAxis], ...
    'TickValues',1:7, ...
    'TickLabels',1:7,...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3,...
    'FontSize', 16);
set([ax.YAxis],...
    'TickDir','out',...,
    'TickLength', [0.02,0.02],...
    'LineWidth', 3,...
    'FontSize', 16);
ax(1).XLim = [0,8];
ax(2).XLim = [0,8];
ax(1).YLim = [0, 0.4];
ax(2).YLim = [0, 0.4];

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')
xlabel(ax,'Perceptual training day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'Proportion of AM-sensitive units',...
    'FontWeight','bold',...
    'FontSize', 15);