function plot_raster(Ck)

spiketimes = Ck.SpikeTimes;
numspikes = Ck.nSpikes;
fs = Ck.SamplingRate;

% for each depth
depths = Ck.UserData.trial_firingrate.vals;
events = Ck.Session.Events;

% eventlocked
[v, oot] = subset(events);
vidx = 1:length(v);
oot = oot(vidx);


trials=ceil(times/triallen);
reltimes=mod(times,triallen);
reltimes(~reltimes)=triallen;

xx=ones(3*numspikes,1)*nan;
yy=ones(3*numspikes,1)*nan;

yy(1:3:3*numspikes)=(trials-1)*1.5;
yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;

%scale the time axis to ms
xx(1:3:3*numspikes)=reltimes*1000/fs;
xx(2:3:3*numspikes)=reltimes*1000/fs;
xlim=[1,triallen*1000/fs];

axes(hresp);
h = plot(xx, yy, k,...
    'LineWidth',1);
axis ([xlim,0,(numtrials)*1.5]);

xlabel('Time(ms)');
ylabel('Trials');