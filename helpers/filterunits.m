function Ci = filterunits(Parname, Cday, i)
    Ci = Cday{i};
    minNumSpikes = 0;

    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        
        % skip freq tuning sessions
        if contains(Ci.SessionName, 'FreqTuning')
            continue
        end
        
        % negative fits are invalid
        yfit = Ci(j).UserData.(Parname).yfit;
        curve = [yfit(1), yfit(500), yfit(1000)];
        
        if curve(1) > curve(2) && curve(2) > curve(3) && sum(yfit>1) > 0
            Ci(j).UserData.(Parname).threshold = NaN;
        end
        
        % no threshold is invalid
        if ~isfield(Ci(j).UserData.(Parname),'threshold')
            Ci(j).UserData.(Parname).threshold = NaN;
        end
        
        % no pval is invalid
        if ~isfield(c.UserData.(Parname),'p_val')
            c.UserData.(Parname).p_val = NaN;
        end
        
        alpha = 0.05;
        
        % create lookup table for each cluster
        id = [Ci.Name];
        uid = unique(id);
        flaggedForRemoval = "";
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        for k = 1:length(uid)
            t = arrayfun(@(a) a.UserData.(Parname).threshold,Ci(ind));
            pval = arrayfun(@(a) a.UserData.(Parname).p_val,Ci(ind));
            if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
                flaggedForRemoval(end+1) = uid(k);
                %             fprintf(2,'ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
            else
                %             fprintf('ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
            end
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
    
    % only plot one subject
    if subj ~= "all"
        subj_idx = zeros(1,length(Ci));
        
        for j = 1:length(Ci)
            if Ci(j).Subject == ""
                nsubj = append(subj,"_");
                cs = convertCharsToStrings(Ci(j).Name);
                if contains(cs,nsubj)
                    subj_idx(j) = 1;
                else
                    subj_idx(j) = 0;
                end
            else
                cs = convertCharsToStrings(Ci(j).Subject);
                if contains(cs,subj)
                    subj_idx(j) = 1;
                else
                    subj_idx(j) = 0;
                end
            end
        end
        
        subj_idx = logical(subj_idx);
        Ci = Ci(subj_idx);
    end
    
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
    
    % replace NaN thresholds with 1
    %     for j = 1:length(Ci)
    %         if isnan(Ci(j).UserData.(parname).threshold)
    %             Ci(j).UserData.(parname).threshold = 1;
    %         end
    %     end
end