function [Ci] = filterunits_acx(savedir, Parname, Cday, i, unit_type, condition)

Ci = Cday{i};
alpha = 0.05;

% remove 'garbage'
idx = false(1,length(Ci));
for j = 1:length(Ci)
    if strcmp(Ci(j).Type, "garbage") == 1
        idx(j) = 0;
    else
        idx(j) = 1;
    end
end
Ci = Ci(idx);

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

% remove multiunits
if unit_type == "SU" && ~isempty(Ci)
    removeind = [Ci.Type] == "SU";
    Ci = Ci(removeind);
end

% % make sure all units have 3 sessions
% flaggedForRemoval = "";
% 
% id = [Ci.Name];
% uid = unique(id);
% 
% for j = 1:length(uid)
%     ind = uid(j) == id;
%    
%     if length(Ci(ind)) ~= 3
%         flaggedForRemoval(end+1) = uid(j);
%     end
% end
% 
% idx = false(1,length(Ci));
% 
% for j = 1:length(Ci)
%     if ismember(id(j),flaggedForRemoval)
%         idx(j) = 0;
%     else
%         idx(j) = 1;
%     end
% end
% 
% Ci = Ci(idx);

