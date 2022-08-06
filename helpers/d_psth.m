function d_psth(d, parname, day, clustername)

ffn = fullfile(d(day).folder,d(day).name);

fprintf('Loading %s ...',d(day).name)
load(ffn)
fprintf(' done\n')


C = [S.Clusters];

% to plot a specific cluster
ind = ones(1,length(C));

for i = 1:length(C)
    if C(i).Name == clustername
        ind(i) = 1;
    else
        ind(i) = 0;
    end
end

ind = logical(ind);

C = C(ind);

% plot figures
f = figure('color','w');

ncol = 3;

ucid = unique([C.ID]);
nrow = length(ucid)*2;

t = tiledlayout(f,nrow,ncol);
t.TileSpacing = 'compact';
t.Padding = 'loose';

for i = 1:numel(C)
    Ck = C(i);
    
%     row = double(Ck.ID);
    ind = ucid == Ck.ID;
    row = find(ind);

    
    if contains(Ck.Session.Name,"Pre")
        col = 1;
    elseif contains(Ck.Session.Name,"Post")
        col = 3;
    else
        col = 2;
    end
    
    ax1 = nexttile(t,sub2ind([ncol nrow],col,row));
    
    ndp = Ck.UserData.(parname);
    
    if isfield(ndp,'ERROR'), continue; end
    
    h = plot(ax1, ...
        ndp.vals,ndp.dprime,'--o', ...
        ndp.xfit,ndp.yfit,'-k', ...
        ndp.threshold,ndp.dprimeThreshold,'+r');
    
    h(3).MarkerSize = 10;
    h(3).LineWidth = 2;
    
    grid(ax1,'off');
    ax1.YAxis.TickLabelFormat = '%.1f';
    ax1.YLim = [-0.5,2.5];
    
    if col == 1
        ax1.YAxis.Label.String = sprintf('%d %s',Ck.ID,Ck.Type);
    elseif col == 3
        ax1.YAxis.Label.String = Ck.Name;
        ax1.YAxisLocation = 'right';
    end
    
    if row == 1
        ax1.Title.String = Ck.Session.Name;
    end
    
    ev = Ck.Session.find_Event("AMDepth").DistinctValues;
    ev(ev==0) = [];
    
    row = row*2;
    ax2 = nexttile(t,sub2ind([ncol nrow],col,row));
    
    h = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',ev);
    h.showtitle = false;
    h.normalization = 'firingrate';
    h.ax = ax2;
    h.plot;
    
    
end
title(t,parname);
