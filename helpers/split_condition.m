function split_condition(savedir, parname, ndays, unit_type, condition)
% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

% load clusters
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

temp = [];
output = [];

wc = 0;
bc = 0;
sc = 0;

av = {'Aversive', 'Active'};

% only AM responsive
for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        temp = cell(3,6);
        
        % unit
        temp(:,1) = cellstr(U(1).Name)';
        
        % subj
        subj = split(U(1).Name, '_');
        temp(:,2) = cellstr(subj(1));
        
        % sessions
        sessions = {};
        sns = [U.SessionName];
        
        pre = contains(sns, "Pre");
        sessions(pre) = cellstr("Pre");
        act = contains(sns, av);
        sessions(act) = cellstr("Active");
        post = contains(sns, "Post");
        sessions(post) = cellstr("Post");
        
        temp(:,3) = sessions';
        
        % days
        temp(:,4) = cellstr(num2str(i));
        
        % thresholds
        T = num2cell(arrayfun(@(a) a.UserData.(Parname).threshold, U));
         temp(:,5) = T';
        
        % condition
        Tx = cell2mat(T);
        Tx(isnan(Tx)) = 0;
        pre = Tx(1);
        active = Tx(2);
        
        if pre > active && pre~=active
            c = "Better";
            bc = bc + 1;
        elseif pre < active && pre~=active
            c = "Worse";
            wc = wc + 1;
        elseif pre == active
            c = "Same";
            sc = sc + 1;
        end
        
        temp(:,6) = cellstr(c);
        
        % Validity
        V = ones(1,3);
        nanidx = isnan(cell2mat(T));
        V(nanidx) = 0;
        
        temp(:,7) = num2cell(V)';

        output = [output; temp];
    end
    
    
end

output = cell2table(output);
output.Properties.VariableNames = ["Unit", "Subject", "Session", "Day", "Threshold","Condition","Validity"];

% save as file
sf = fullfile(savedir,append(parname,'_threshold_split.csv'));

fprintf('Saving file ...')
writetable(output,sf);
fprintf(' done\n')

fprintf('Better = %d\n', bc)
fprintf('Worse = %d\n', wc)
fprintf('Same = %d\n', sc)