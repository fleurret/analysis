function count_units(savedir)

fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

maxNumDays = 7;
days = 1:min(maxNumDays,length(Cday));

c = 0;
mua = 0;
su = 0;
hist = 0;
s = 0;

flaggedForRemoval = "";

for i = 1:length(days)
    Ci = Cday{i};
    id = [Ci.Name];
    uid = unique(id);
%     uidx = contains(uid, 'SUBJ-ID-670');
%     
%     idx = contains(id, 'SUBJ-ID-670');
%     p = Ci(idx);
%     s = s + length(p);
%     
%     for j = 1:length(p)
%         if p(j).Note == "dorsal"
%             hist = hist+1;
%             flaggedForRemoval(end+1) = p(j).Name;
%         end
%     end
%     
%     flagged = unique(flaggedForRemoval);
%     hidx = false(1,length(uid));
%     
%     for j = 1:length(uid)
%         if ismember(uid(j),flagged)
%             hidx(j) = 0;
%         else
%             hidx(j) = 1;
%         end
%     end
%     
%     uid = uid(~hidx);
%     num = length(uid);
%     c = c+num;
        
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
vs = 0;
r = 0;

for i = 1:length(days)
    Ci1 = filterunits(savedir, 'trial_firingrate', Cday, i, 'all', 'all');
    Ci3 = filterunits(savedir, 'vector_strength_cycle_by_cycle', Cday, i, 'SU', 'all');
    
    frid = [Ci1.Name];
    fruid = unique(frid);
    a = length(fruid);
    fr = fr+a;
    
    vsid = [Ci3.Name];
    vsuid = unique(vsid);
    v = length(vsuid);
    vs = vs + v;
    
    X = union(Ci1, Ci3);
    
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
fprintf('VScc: %.0f\n', vs)