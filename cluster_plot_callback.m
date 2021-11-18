function cluster_plot_callback(obj,src,C,xi,yi,parname)

crd = src.IntersectionPoint(1:2);

dxy = sqrt((crd(1)-xi).^2 + (crd(2)-yi).^2);
[m,mi] = min(dxy);


C = C(mi);

ndp = C.UserData.(parname);

f = figure(sum(uint8('cluster_plot_callback')));
set(f,'color','w');
clf(f);

hp = uipanel(f);
hp.BackgroundColor = 'w';
hp.Position = [.05 .05 .9 .6];
hp.BorderType = 'none';

hf = uipanel(f);
hf.BackgroundColor = 'w';
hf.Position = [.05 .65 .9 .3];
hf.BorderType = 'none';

ax = axes(hf);
h = plot(ax, ...
    ndp.vals,ndp.dprime,'--o', ...
    ndp.xfit,ndp.yfit,'-k', ...
    ndp.threshold,ndp.dprimeThreshold,'+r');
h(3).LineWidth = 2;
h(3).MarkerSize = 6;
title(ax, ...
    {sprintf('%s ',C.Name);
     sprintf('%s - Threshold = %.1f dB',C.TitleStr,ndp.threshold)});
ylabel(ax,'d''');
xlabel(ax,'SNR (dB)');
grid(ax,'on');


ax = obj.Parent;

h = findobj(ax,'Tag','cluster_plot_callback_marker');
delete(h);

hl = line(ax,xi(mi),yi(mi), ...
    'Tag','cluster_plot_callback_marker', ...
    'Marker','s','Color','r','linewidth',3, ...
    'DisplayName',C.TitleStr);

uistack(hl,'bottom');

f.UserData.OriginalAx = ax; % can't pass additional arguments???
f.CloseRequestFcn = @delete_marker;

ev = C.Session.find_Event("AMDepth").DistinctValues;
ev(ev==0) = [];

h = epa.plot.PSTH_Raster(C,'event',"AMDepth",'eventvalue',ev);
h.showtitle = false;
h.normalization = 'firingrate';
h.ax = axes(hp);
h.plot;




function delete_marker(obj,src,event)
ax = obj.UserData.OriginalAx;
h = findobj(ax,'Tag','cluster_plot_callback_marker');
delete(h)
delete(obj)

