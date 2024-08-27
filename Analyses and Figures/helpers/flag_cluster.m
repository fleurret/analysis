function flag_cluster(savedir, flag_day, subj, cid, newtype)

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));


s = [Cday{flag_day}.SessionName];

units = [Cday{flag_day}.Name];

cidx = zeros(1, length(units));

for i = 1:length(units)
    if contains(units(i), cid) && contains(units(i), subj)
        cidx(i) = 1;
    else
        continue
    end
end

cidx = logical(cidx);

if sum(cidx) > 3
    error('BAD!')
end

if sum(cidx) == 0
    error('This unit does not exist')
end

set(Cday{flag_day}(cidx),'Type',newtype)

ffn = fullfile(savedir,fn);
fprintf('cluster %s set to %s...', cid, newtype)
save(ffn, 'Cday')
fprintf(' done\n')