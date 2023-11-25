function coding_strategy(spth, savedir, ndays, unit_type, condition)

load(fullfile(savedir,'Cday_original.mat'));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

fr = 0;
vscc = 0;
both = 0;

for i = ndays
    Ci_x = filterunits(savedir, 'trial_firingrate', Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, 'vector_strength_cycle_by_cycle', Cday, i, unit_type, condition);
    Ci = union(Ci_x, Ci_y);
    
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
          
        % get threshold
        fr_threshold = [U(1).UserData.trial_firingrate.threshold, U(2).UserData.trial_firingrate.threshold, U(3).UserData.trial_firingrate.threshold];
        vscc_threshold = [U(1).UserData.vector_strength_cycle_by_cycle.threshold, U(2).UserData.vector_strength_cycle_by_cycle.threshold, U(3).UserData.vector_strength_cycle_by_cycle.threshold];
        
        if sum(isnan(fr_threshold)) == 3
            vscc = vscc + 1;
        elseif sum(isnan(vscc_threshold)) == 3
            fr = fr + 1;
        else
            both = both + 1;
        end
    end
end

fprintf('FR only = %s \n', num2str(fr))
fprintf('VScc only = %s \n', num2str(vscc))
fprintf('Both = %s \n', num2str(both))