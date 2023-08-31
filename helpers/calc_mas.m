function [mAM, mNAM, cAM, cNAM] = calc_mas(u, parname, depth)

E = u.Session.Events;
V = u.UserData.(parname).V;
M = u.UserData.(parname).M;

% find non-AM
par.referencevalue = min(V);
refInd = V == par.referencevalue;

ind = depth == round(V);

% separate AM from non-AM
data = [M(refInd); M(ind)]';
tind = [false(1,sum(refInd)) true(1,sum(ind))]; 
[mAM, mNAM, cAM, cNAM] = mas(data,tind);