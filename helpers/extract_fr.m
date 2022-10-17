function extract_fr(savedir,parname, val)

fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

days = 7;

% make table
headers = {'Cluster','Subject','Day','Pre', 'Aversive','Post'};
FiringRate = cell2table(cell(0,6),'VariableNames', headers);

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
        
        % flag if no
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
            flaggedForRemoval(end+1) = uid(j);
            %             fprintf(2,'ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        else
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
    
    id = [Ci.Name];
    uid = unique(id);
    
    % extract information
    for j = 1:length(uid)
        M = nan(3,3);
        
        ind = uid(j) == id;
        Cj = Ci(ind);
        
        for k = 1:length(Cj)
            Ck = Cj(k);
            ev = Ck.Session.find_Event("AMDepth").DistinctValues;
            ev(ev==0) = [];
            h = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',ev);
            [fr,b,uv] = Ck.psth(h);
            
            sn = Ck.SessionName;
            
            % session
            if contains(sn,"Pre")
                M(1,1) = mean(fr,'all');
                M(2,1) = median(fr,'all');
                M(3,1) = max(fr,[],'all');
            end
            
            if contains(sn,"Aversive")
                M(1,2) = mean(fr,'all');
                M(2,2) = median(fr,'all');
                M(3,2) = max(fr,[],'all');
            end
            
            if contains(sn,"Post")
                M(1,3) = mean(fr,'all');
                M(2,3) = median(fr,'all');
                M(3,3) = max(fr,[],'all');
            end
            
            % id
            cluster = Ck.TitleStr;
            
            s = split(cluster, '_');
            subject = s(1);
            
            day = i;
        end
        
        % combine
        if contains(val,'Mean')
            row = {cluster, subject, day, M(1,1), M(1,2), M(1,3)};
        end
        
        if contains(val,'Median')
            row = {cluster, subject, day, M(2,1), M(2,2), M(2,2)};
        end
        
        if contains(val,'Max')
            row = {cluster, subject, day, M(3,1), M(3,2), M(3,3)};
        end
        
        FiringRate = [FiringRate; row];
        
    end
end

ff = append(savedir,val,parname,'FiringRate.csv');
writetable(FiringRate,ff)
fprintf('File saved \n')

