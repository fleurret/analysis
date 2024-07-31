 ndays = 1:7;
 unit_type = "all";
 condition = "all";
 depth = -9;
 savefile = 1;
 
% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

output = [];

% set static variables
parnames = ["trial_firingrate"; "cl_calcpower"; "vector_strength_cycle_by_cycle"];
sessions = ["Pre", "Active", "Post"];
sex = ["M", "F"];
count = 0;

 
for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    id = [Ci.Name];
    uid = unique(id);
    count = count+length(uid);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % make sure unit has 3 sessions
        if length(U) ~= 3
            continue
        end
        
        % create output
        clear temp
        temp = {};
        b = [];
        
        % get events and calculate baseline
        for k = 1:length(U)
            
            % set session
            session = sessions(k);
            
            % pull values
            u = U(k);
            [mAM, mNAM, ~, ~] = calc_mas(u, Parname, depth);
            
            b = [b, mAM/mNAM];
        end
        
        % get subject
        subjid = split(u.Name, '_');
        
        % get sex
        if contains(subjid(1), '228') || contains(subjid(1), '267') || contains(subjid(1), '378') || contains(subjid(1), '380') || contains(subjid(1), '642')
            s = sex(1);
        else
            s = sex(2);
        end
        
        % add to list
        temp{1} = uid(j);
        temp{2} = subjid(1);
        temp{3} = s;
        temp{4} = i;
        temp{5} = u.Type;
        temp{6} = b(1);
        temp{7} = b(2);
        temp{8} = b(3);
        output = [output; temp];
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit", "Subject", "Sex","Day", "Type", "Pre", "Active", "Post"];

% save as file
if savefile == 1
    sf = fullfile(savedir,append('Spreadsheets\Task\',parname,'_', mat2str(length(ndays)),'days_AMRatio_reformat.csv'));
    fprintf('Saving file %s \n', sf)
    writetable(output,sf);
    fprintf(' done\n')
end