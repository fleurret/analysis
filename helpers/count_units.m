function count_units(savedir)

fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

maxNumDays = 7;
days = 1:min(maxNumDays,length(Cday));

c = 0;
mua = 0;
su = 0;

for i = 1:length(days)
    Ci = Cday{i};
    id = [Ci.Name];
    uid = unique(id);
    num = length(uid);
    c = c+num;
    
    for j = 1:length(uid)
        ind = uid(j) == id;
        unit = Ci(ind);
        if unit(1).Type == "MUA"
            mua = mua +1 ;
        end
        
        if unit(1).Type == "SU"
            su = su + 1;
        end
    end
end

fr = 0;
p = 0;
vs = 0;
r = 0;

for i = 1:length(days)
    Ci1 = filterunits(savedir, 'trial_firingrate', Cday, i, 'all', 'all');
    Ci2 = filterunits(savedir, 'cl_calcpower', Cday, i, 'SU', 'all');
    Ci3 = filterunits(savedir, 'vector_strength_cycle_by_cycle', Cday, i, 'SU', 'all');
    
    frid = [Ci1.Name];
    fruid = unique(frid);
    a = length(fruid);
    fr = fr+a;
    
    pid = [Ci2.Name];
    puid = unique(pid);
    b = length(puid);
    p = p+b;
    
    vsid = [Ci3.Name];
    vsuid = unique(vsid);
    v = length(vsuid);
    vs = vs + v;
    
    C = union(Ci1, Ci2);
    X = union(C, Ci3);
    
    id = [X.Name];
    uid = unique(id);
    
    z = length(uid);
    r = r+z;
end

fprintf('Total units: %.0f\n', c)
fprintf('Multi-units: %.0f\n', mua)
fprintf('Single-units: %.0f\n', su)
fprintf('Responsive units: %.0f\n', r)
fprintf('FR: %.0f\n', fr)
fprintf('Power: %.0f\n', p)
fprintf('VScc: %.0f\n', vs)