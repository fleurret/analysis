function [Ci] = filterunits(savedir, Parname, Cday, i, unit_type, condition)

Ci = Cday{i};
minNumSpikes = 0;
alpha = 0.05;

% first make sure that there is a threshold/p_val field for the "parname"
% threshold = NaN means curve did not cross d' = 1
% threshold = 0 means there were no spikes/failed to compute threshold
for j = 1:length(Ci)
    
    % skip freq tuning sessions
    if contains(Ci(j).SessionName, 'FreqTuning')
        continue
    end
    
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
        
        if curve(1) > curve(2) && curve(2) > curve(3) && sum(yfit>1) > 0
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

% % only plot one subject
% if subj ~= "all"
%     subj_idx = zeros(1,length(Ci));
%
%     for j = 1:length(Ci)
%         if Ci(j).Subject == ""
%             nsubj = append(subj,"_");
%             cs = convertCharsToStrings(Ci(j).Name);
%             if contains(cs,nsubj)
%                 subj_idx(j) = 1;
%             else
%                 subj_idx(j) = 0;
%             end
%         else
%             cs = convertCharsToStrings(Ci(j).Subject);
%             if contains(cs,subj)
%                 subj_idx(j) = 1;
%             else
%                 subj_idx(j) = 0;
%             end
%         end
%     end
%
%     subj_idx = logical(subj_idx);
%     Ci = Ci(subj_idx);
% end

% only plot one condition
if condition ~= "all"
    if condition == "w"
        ffn = fullfile(savedir,'thresholds_worsened.mat');
        load(ffn)
        
        subset = worsened;
    end
    
    if condition == "i"
        ffn = fullfile(savedir,'thresholds_improved.mat');
        load(ffn)
        
        subset = improved;
    end
    
    id = [Ci.Name];
    uid = unique(id);
    
    j = 1:length(subset);
    subj_idx = cell2mat(subset(j,2)) == i;
    wid = subset(subj_idx);
    wid = [wid{:}];
    
    flaggedForRemoval = "";
    
    for k = 1:length(uid)
        ind = uid(k) == wid;
        if sum(ind) == 0
            flaggedForRemoval(end+1) = uid(k);
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
end

% remove multiunits
if unit_type == "SU"
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

% replace NaN thresholds with 1
%     for j = 1:length(Ci)
%         if isnan(Ci(j).UserData.(parname).threshold)
%             Ci(j).UserData.(parname).threshold = 1;
%         end
%     end