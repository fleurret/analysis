spth = 'C:\Users\rose\Documents\Caras\Analysis\Caspase\Maintenance\No caspase';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

maxdays = 17;

t = nan(1,maxdays);
thresholds = nan(length(subjects),maxdays);

% extract output
for subj = 1:length(subjects)
    spth = fullfile(subjects(subj).folder,subjects(subj).name);
    d = dir(fullfile(spth,'*.mat'));
    ffn = fullfile(d.folder,d.name);
    
    fprintf('Loading subject %s ...',subjects(subj).name)
    load(ffn)
    fprintf(' done\n')
    
    for i = 1:length(output)
        t(i) = output(i).fitdata.threshold;
    end

    thresholds(subj,1:length(t)) = t;
end

% calculate mean and std across days
for i = 1:maxdays
    x = thresholds(1:subj,i);
    m = mean(x, 'omitnan');
    s = std(x, 'omitnan');
    s = s /(sqrt(maxdays-1));

    thresholds(subj+1,i) = m;
    thresholds(subj+2,i) = s;
end

behav_mean = thresholds(subj+1,:);
behav_std = thresholds(subj+2,:);

%%
% save as file
file = 'C:\Users\rose\Documents\Caras\Analysis/IC recordings\Behavior\behavior_combined.mat';
save(file, 'behav_mean','behav_std')
