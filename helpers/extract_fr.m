function extract_fr(savedir,parname, val, depth, makeplot)

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
            
            % firing rate
            ev = Ck.Session.find_Event("AMDepth").DistinctValues;
            ev(ev==0) = [];
            h = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',ev);
            [fr,~,~] = Ck.psth(h);
            
            sn = Ck.SessionName;
            
            % determine if depth was presented that day
            
            presented = round(Ck.UserData.(parname).vals);
            
            if sum(ismember(presented,depth) == 1)
                didx = find(presented==depth);
                
                % session
                if contains(sn,"Pre")
                    M(1,1) = mean(fr(didx,:));
                    M(2,1) = median(fr(didx,:));
                    M(3,1) = max(fr(didx,:));
                end
                
                if contains(sn,"Aversive")
                    M(1,2) = mean(fr(didx,:));
                    M(2,2) = median(fr(didx,:));
                    M(3,2) = max(fr(didx,:));
                end
                
                if contains(sn,"Post")
                    M(1,3) = mean(fr(didx,:));
                    M(2,3) = median(fr(didx,:));
                    M(3,3) = max(fr(didx,:));
                end
                
            else
                continue
            end
        
            % VScc
%             p = Ck.UserData.VScc.V;
%             v = Ck.UserData.VScc.M;
            
        end
        
        % id
        cluster = Ck.TitleStr;
        
        s = split(cluster, '_');
        subject = s(1);
        
        day = i;
        
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

ff = append(savedir,val,parname,num2str(abs(depth)),'FiringRate.csv');
writetable(FiringRate,ff)
fprintf('File saved \n')

if makeplot == 'y'
    FR = table2array(FiringRate);
    cm = [138,156,224; 117,139,219; 97,122,213; 77,105,208; 57,88,203; 49,78,185; 44,70,165;]./255; % session colormap
    
    f = figure;
    f.Position = [0, 0, 2000, 350];
    
    for d = 1:days
        ax = subplot(1,days,d);
        hold on
        
        for i = 1:length(FR)
            unit = FR(i,:);
            pap = [str2num(unit(4)) str2num(unit(5)) str2num(unit(6))];
            ud = str2num(unit(3));
            ucm = cm(d,:);
            
            if d == ud
                plot(pap,...
                    'Color',ucm,...
                    'Marker','o',...
                    'LineWidth',2)
                xticklabels({'Pre','','Active','','Post'})
                ylabel('Firing rate (Hz)')
                T = append(num2str(depth),' dB');
                title(T);
                ylim([0 100])
            end
        end
    end
end

