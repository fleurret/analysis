function output(region, spth, behavdir, savedir, parname, ndays, subj, condition, unit_type, replace, sv)

% Plot individual unit thresholds and means across days

% correlation coefficient is set to Spearman's

% convert parname to correct label
if strcmp(region,"ACx") == 0
    if contains(parname,'FiringRate')
        Parname = 'trial_firingrate';
        titlepar = 'Firing Rate';
        
    elseif contains(parname,'Power')
        Parname = 'cl_calcpower';
        titlepar = 'Power';
        
    else contains(parname,'VScc')
        Parname = 'vector_strength_cycle_by_cycle';
        titlepar = 'VScc';
    end
else
    Parname = parname;
    titlepar = parname;
end

% load behavior
if subj == "all"
    load(fullfile(behavdir,'behavior_combined.mat'));
else
    pth = fullfile(behavdir,subj);
    d = dir(fullfile(pth,'*.mat'));
    ffn = fullfile(d.folder,d.name);
    
    load(ffn, 'output')
    for i = 1:length(output)
        a(i) = output(i).fitdata;
    end
    
    behav_os = [a.threshold];
    
    clear a
end

% load neural
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% vars for output file
unitlist = [];
subjs = [];
thrs = [];
days = [];

for i = ndays
    if strcmp(region,"ACx") == 1
        Ci = filterunits_acx(savedir, Parname, Cday, i, unit_type, condition);
    else
        Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    end
    
    % replace NaN thresholds
    if replace == "yes"
        for j = 1:length(Ci)
            if isnan(Ci(j).UserData.(Parname).threshold)
                Ci(j).UserData.(Parname).threshold = 0;
            end
        end
    end
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        unit = U(1).Name;
        subj_id = split(unit, '_');
        subj_id = subj_id(1);
        day = i;
        thr = arrayfun(@(a) a.UserData.(Parname).threshold, U);
        
        unitlist = [unitlist; unit];
        subjs = [subjs; subj_id];
        thrs = [thrs; thr];
        days = [days; day];
    end
end


% save as file
if sv == 1
    output = [unitlist, subjs, days, thrs];
    output = array2table(output);
    output.Properties.VariableNames = ["Unit", "Subject","Day", "Pre Threshold", "Active Threshold", "Post Threshold"];
    
    sf = fullfile(savedir,append('Spreadsheets\Learning\IC concatenated NaN.csv'));
    fprintf('\n Saving file %s ...', sf)
    writetable(output,sf);
    fprintf(' done\n')
    
    
end