par = [];
par.event = "";
par.eventvalue = 'all';
par.referencevalue = [];
par.window = [0 1];
par.complete = false;
par.metric = @epa.metric.cl_calcpower;

E = u.Session.Events;

[v,oot] = E.subset(par.eventvalue);

[v,vidx] = sort(v);
vidx = 1:length(v);
oot = oot(vidx);

if numel(par.window) == 1
    par.window = sort([0 par.window]);
end
par.window = par.window(:)';

twin = par.window + oot(:,1);

st = u.SpikeTimes;

t = []; eidx = []; vid = [];
for z = 1:size(twin,1)
    ind = st >= twin(z,1) & st <= twin(z,2);
    if ~any(ind), continue; end
    t    = [t; st(ind)-oot(z,1)];
    eidx = [eidx; z*ones(sum(ind),1)];
    vid  = [vid; v(z)*ones(sum(ind),1)];
end

ue = unique(eidx);

% get no trials
trials = cell(size(ue));
V = nan(size(trials));
for l = 1:length(ue)
    ind = eidx == ue(l);
    trials{l} = t(ind);
    V(l) = v(find(ind,1));
end
eidx = ue;


par.modfreq = [];

par.tapers = [5 9]; %[TW K] where TW = time-bandwidth product and K =
%the number of tapers to be used (<= 2TW-1). [5 9]
%are the values used by Rosen, Semple and Sanes (2010) J Neurosci.

par.pad = 3; %Padding for the FFT. -1 corresponds to no padding,
%0 corresponds to the next higher power of 2 and so
%on. This value will not affect the result
%calculation, however, using a value of 1 improves
%the efficiancy of the function and increases the
%number of frequency bins of the result.

par.fpass = [-1 1]; % [-1 +1] octave around modfreq

par.fs = 1;        %Sampling rate

par.err = [1 .05];  %Theoretical errorbars (p = 0.05). For Jacknknife
%errorbars use [2 p]. For no errorbars use [0 p].

par.trialave = 0;   %If 1, average over 