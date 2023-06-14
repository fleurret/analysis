function b = baseline_firingrate(u)

par = [];
par.event = "";
par.eventvalue = 'all';
par.referencevalue = [];
par.window = [0 1];
par.complete = false;
par.metric = @epa.metric.trial_firingrate;

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
trials = cell(size(ue));
V = nan(size(trials));
for l = 1:length(ue)
    ind = eidx == ue(l);
    trials{l} = t(ind);
    V(l) = v(find(ind,1));
end
eidx = ue;

V = u.UserData.trial_firingrate.V;
M = u.UserData.trial_firingrate.M;
dV = u.UserData.trial_firingrate.vals;

% find non-AM
par.referencevalue = min(V);
refInd = V == par.referencevalue;

b = nan(1);

ind = dV(1) == V;
data = [M(refInd); M(ind)]';
tind = [false(1,sum(refInd)) true(1,sum(ind))];
b = epa.metric.baseline_fr(data,tind);