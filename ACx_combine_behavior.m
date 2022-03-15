%% fit with psignifit
dir = "C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior\XXFluffy_217821";

plot_pfs_behav(dir,dir)

%% combine output into one file

pth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior';
d = dir(pth);
d = d(~ismember({d.name},{'.','..'}));

temp = {};

for i = 1:length(d)
    subj = d(i).name;
    subjfolder = fullfile(d(i).folder,subj);
    sessionfile = dir(fullfile(subjfolder,'*.mat'));
    sessionfile(ismember({sessionfile.name},{'.','..'})) = [];
    
    for j = 1:length(sessionfile)
        fn = fullfile(subjfolder,sessionfile(j).name);
        load(fn)
        temp{j} = output;
    end
    
    clear output
    output = temp;
    
    savedir = "C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior";
    fn = fullfile(savedir,subj);
    file = append(subj,"combined.mat");
    fn = fullfile(fn, file);
    
    save(fn, 'output')
    
    clear output
end

%%
spth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

maxdays = 7;

t = nan(1,maxdays);
thresholds = nan(length(subjects),maxdays);

% extract output
for subj = 1:length(subjects)
    spth = fullfile(subjects(subj).folder,subjects(subj).name);
    d = dir(fullfile(spth,'*.mat'));
    
    for j = 1:length(d)
       if contains(d(j).name, "combined")
           file = d(j).name;
       end
    end
    
    ffn = fullfile(spth, file);
    
    fprintf('Loading subject %s ...',subjects(subj).name)
    load(ffn)
    fprintf(' done\n')
    
    for i = 1:length(output)
        a(i) = output{i}.fitdata;
    end
    
    t = [a.threshold];
    
    clear a
    
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

% save as file
file = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior\behavior_combined.mat';
save(file, 'behav_mean','behav_std')
