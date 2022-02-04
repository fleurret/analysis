function flag_cluster(savedir, parname, remove, flag_day, cid, session)

% load neural
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');
load(fullfile(savedir,fn));


s = [Cday{flag_day}.SessionName];

if remove == "session"
    cidx = [Cday{flag_day}.Name] == cid;
    sidx = contains(s, session);
    sum = cidx + sidx;
    ind = sum == 2;
    set(Cday{flag_day}(ind),'Note',"reverse");
end

if remove == "unit"
    ind = [Cday{flag_day}.Name] == cid;
    set(Cday{flag_day}(ind),'Note',"reverse")
end

ffn = fullfile(savedir,fn);
fprintf('Saving files ...')
save(ffn, 'Cday')
fprintf(' done\n')