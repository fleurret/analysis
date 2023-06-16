function [AM, NAM] = calc_cv(u,parname)

E = u.Session.Events;
V = u.UserData.(parname).V;
M = u.UserData.(parname).M;
dV = u.UserData.(parname).vals;

% find non-AM
par.referencevalue = min(V);
refInd = V == par.referencevalue;

b = nan(1);

ind = dV(1) == V;
data = [M(refInd); M(ind)]';
tind = [false(1,sum(refInd)) true(1,sum(ind))];
[AM, NAM] = cv(data,tind);