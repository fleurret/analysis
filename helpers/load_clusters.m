function load_clusters(spth, savedir)


% Load and optimize clusters for analysis

% input variables
% spth = data folder
% savedir = save folder

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

Cday = cell(1,14);

for subj = 1:length(subjects)
    spth = fullfile(subjects(subj).folder,subjects(subj).name);
    
    d = dir(fullfile(spth,'*.mat'));
    
    for day = 1:length(d)
        ffn = fullfile(d(day).folder,d(day).name);
        
        fprintf('Loading subject %s - %s ...',subjects(subj).name,d(day).name)
        load(ffn)
        fprintf(' done\n')

        Cday{day} = [Cday{day}, [S.Clusters]];
        
        % add subject property and change to unique id
        for i = 1:length(Cday{day})
            if ~isprop(Cday{day}(i),'Subject')
                addprop(Cday{day}(i), 'Subject');
                Cday{day}(i).Subject = subjects(subj).name;
            end
            
            if ~startsWith(Cday{day}(i).Name,"cluster")
                continue
            else
                Cday{day}(i).Name = string(subjects(subj).name) + "_" + Cday{day}(i).Name;
            end
        end
    end
end

% save as file
fprintf('Saving file ...')
save(fullfile(savedir,'Cday_original.mat'), 'Cday')
fprintf(' done\n')