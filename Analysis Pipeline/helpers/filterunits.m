function [Ci] = filterunits(savedir, Parname, Cday, i, unit_type, condition)

Ci = Cday{i};
alpha = 0.05;

% remove freqtuning sessions - currently empty
sn = [Ci.SessionName];
ftind = contains(sn, 'FreqTuning');
Ci = Ci(~ftind);

% first make sure that there is a threshold/p_val field for the "parname"
% threshold = NaN means curve did not cross d' = 1
% threshold = 0 means there were no spikes/failed to compute threshold
for j = 1:length(Ci)
    
    % no threshold is invalid
    if ~isfield(Ci(j).UserData.(Parname),'threshold')
        Ci(j).UserData.(Parname).threshold = NaN;
    end
    
    % no pval is invalid
    if ~isfield(Ci(j).UserData.(Parname),'p_val')
        Ci(j).UserData.(Parname).p_val = NaN;
    end
    
    
    % make sure cluster has yfit
    if ~isfield(Ci(j).UserData.(Parname), 'yfit')
        Ci(j).UserData.(Parname).threshold = NaN;
    else
        % negative fits are invalid
        yfit = Ci(j).UserData.(Parname).yfit;
        curve = [yfit(1), yfit(500), yfit(1000)];
        
        if curve(1) >= curve(2) && curve(2) >= curve(3) && sum(yfit>1) > 0
            Ci(j).UserData.(Parname).threshold = NaN;
        end
    end
end

% create lookup table for each cluster
flaggedForRemoval = "";

id = [Ci.Name];
uid = unique(id);

for j = 1:length(uid)
    ind = uid(j) == id;

    % make sure at least one threshold is not NaN and curve has a good fit
    t = arrayfun(@(a) a.UserData.(Parname).threshold,Ci(ind));
    pval = arrayfun(@(a) a.UserData.(Parname).p_val,Ci(ind));
    if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
        flaggedForRemoval(end+1) = uid(j);
    end
end

% remove invalid units
idx = false(1,length(Ci));
for j = 1:length(Ci)
    if ismember(id(j),flaggedForRemoval)
        idx(j) = 0;
    else
        idx(j) = 1;
    end
end
Ci = Ci(idx);

% remove any additional manually flagged units
note = {Ci.Note};
removeind = cellfun(@isempty, note);
Ci = Ci(removeind);


% only plot one condition
if condition ~= "all"
    ffn = fullfile(savedir,'VScc_threshold_split.csv');
    U = readtable(ffn);
    
    % only that day
    didx = U.Day == i;
    U = U(didx,:);
    
    if condition == "w"
        sind = ismember(U.Condition, 'Worse');
        subset = U(sind,:);
    end
    
    if condition == "i"
        sind = ismember(U.Condition, 'Better');
        subset = U(sind,:);
    end
    
    if condition == "s"
        sind = ismember(U.Condition, 'Both');
        subset = U(sind,:);
    end
    
    uid = [Ci.Name];
    sid = unique([subset.Unit]);
    
    [xid,~] = ismember(uid, sid);
    Ci = Ci(xid);
end

% remove multiunits
if unit_type == "SU" && ~isempty(Ci)
    removeind = [Ci.Type] == "SU";
    Ci = Ci(removeind);
end

% make sure all units have 3 sessions
flaggedForRemoval = "";

id = [Ci.Name];
uid = unique(id);

for j = 1:length(uid)
    ind = uid(j) == id;
   
    if length(Ci(ind)) ~= 3
        flaggedForRemoval(end+1) = uid(j);
    end
end

idx = false(1,length(Ci));

for j = 1:length(Ci)
    if ismember(id(j),flaggedForRemoval)
        idx(j) = 0;
    else
        idx(j) = 1;
    end
end

Ci = Ci(idx);

