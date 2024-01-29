function qm(spth)

% prompt user to select folder
datafolders_names = uigetfile_n_dir(spth,'Select data directory');
datafolders = {};
for i=1:length(datafolders_names)
    [~, datafolders{end+1}, ~] = fileparts(datafolders_names{i});
end

for i = 1:length(datafolders)
    DataPath = cell2mat(datafolders(i));
    fd = dir(fullfile(spth, DataPath,'CSV files','*quality_metrics.csv'));
    
    Q = readtable(fullfile(fd.folder,fd.name));
    
    for j = 1:height(Q)
        unit = Q(j,:);
        type = convertCharsToStrings(cell2mat(unit.Cluster_quality));
        
        if type == "good"
            if unit.ISI_FPRate < 0.5 && unit.ISI_ViolationRate < 2 && unit.Fraction_missing < 0.1
                continue
            else
                Q(j,4) = {'mua'};
            end
        end
    end
    
    sf = fullfile(fd.folder,fd.name);
    fprintf('\n Saving quality metrics for %s ...', fd.name)
    writetable(Q,sf);
    fprintf(' done\n')
end