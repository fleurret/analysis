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

fprintf('Total units: %.0f\n', c)
fprintf('Multi-units: %.0f\n', mua)
fprintf('Single-units: %.0f\n', su)