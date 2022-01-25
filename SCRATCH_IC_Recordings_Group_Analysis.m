%% Set directories
% data directory
spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Data';

% save directory
savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\';

% behavior directory
behavdir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Behavior';

%% Load .mat and convert neural data
% only needs to be run whenever new data is added

load_clusters(spth, savedir);

%% Plot

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

% subj: "all", "202", "222", "223", "224", "267"

% condition: "all", "i" (improved), "w" (worsened)

plot_units(spth, behavdir, savedir, parname, "all")

%% compare thresholds by coding

% write this function later
% compare_thresholds()

%% Flag cluster
flag_day = 4;
ind = [Cday{flag_day}.Name] == "cluster1456";

% Notes: motor = "motor", reverse neurometric curve = "reverse"
set(Cday{flag_day}(ind),'Note',"reverse")

save(Cdayfile, 'Cday')

%% Organize thresholds by cluster ID

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

% load clusters
load(fullfile(savedir,'Cday.mat'));
days = 7;

temp = {};
output = {};

% only AM responsive
for i = 1:days
    Ci = Cday{i};
  
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
        if ~isfield(c.UserData.(parname),'threshold')
            c.UserData.(parname).threshold = 0;
        end
        
        if ~isfield(c.UserData.(parname),'p_val')
            c.UserData.(parname).p_val = nan;
        end
    end
    
    alpha = 0.05;

    % create lookup table for each cluster 
    id = [Ci.Name];
    uid = unique(id);
    flaggedForRemoval = "";
    for j = 1:length(uid)
        ind = uid(j) == id;
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
            flaggedForRemoval(end+1) = uid(j);
%             fprintf(2,'ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
%         else
%             fprintf('ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
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
    
    
    % replace Cday
    Cday{1,i} = Ci;
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % replace NaN thresholds with lowest depth presented
    for j = 1:length(Ci)
        if isnan(Ci(j).UserData.(parname).threshold) || Ci(j).UserData.(parname).threshold == 0
            Ci(j).UserData.(parname).threshold = Ci(j).UserData.(parname).vals(1);
        end
    end
    
    % create output
    clear temp
    
    for j = 1:length(uid)
        % check for multiple units with the same id
        count(j) = sum(id==uid(j));
        if count(j) > 3
            error('Warning: more than one unit with ID %s on day %d\n', uid(j), i)
        end
        
        % populate temp             
        ind = uid(j) == id;
        
        if sum(ind) < 3
            fprintf(2, 'Warning: cluster %s on day %d only has data from\n', uid(j), i)
            for k = 1:length(Ci(ind))
                fprintf(2, '%s\n', extractBefore(Ci(k).SessionName, '-'))
            end
        else
            temp{j,1} = uid(j);
            
            t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
            pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
            
            % thresholds
            temp{j,2} = t(1);
            temp{j,3} = t(2);
            temp{j,4} = t(3);
            
            % p vals
            temp{j,5} = pval(1);
            temp{j,6} = pval(2);
            temp{j,7} = pval(3);
        end
    end
    
    output = [output;temp];
end

%%
cat = true(1,length(output));

for i = 1:length(output)
    pre = cell2mat(output(i,2));
    aversive = cell2mat(output(i,3));
    
    % set aside units that only had a post threshold
    if isnan(pre) && isnan(aversive) || pre == aversive
        cat(i) = 0;
    end
end

removed = output(~cat,:);
output = output(cat,:);

ind = true(1,length(output));

for i = 1:length(output)
    pre = cell2mat(output(i,2));
    aversive = cell2mat(output(i,3));
    
    if isnan(aversive) || pre < aversive
        ind(i) = 0;
    end
    
    if isnan(pre) || pre > aversive
        ind(i) = 1;
    end
end

worsened = output(~ind,:);
improved = output(ind,:);