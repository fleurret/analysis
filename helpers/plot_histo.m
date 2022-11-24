function plot_histo(savedir,parname)

fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

days = 7;

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
        
        ind = uid(j) == id;
        Cj = Ci(ind);

        for k = 1:length(Cj)
            Ck = Cj(k);
            ev = Ck.Session.find_Event("AMDepth").DistinctValues;
            ev(ev==0) = [];
            
            y = figure;
            y.Position = [0, 0, 500, 1500];
            z = tiledlayout('flow');
            
            for l = 1:numel(ev)
                nexttile([1 length(ev)])
                h = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',ev);
                [fr,b,uv] = Ck.psth(h);
                
                depths = round(Ck.UserData.(parname).vals);
                depth = depths(l);
                
                ptitle = append(mat2str(depth),' dB');
                bar(b,fr(l,:),...
                    'EdgeAlpha',0,...
                    'FaceColor','k');
                
                if max(fr(:)) < 100
                    ylim([0 100]);
                end
                
                if 100 <= max(fr(:)) && max(fr(:)) < 200
                    ylim([0 200]);
                end
                
                if 200 <= max(fr(:)) && max(fr(:)) <= 300
                    ylim([0 300]);
                end
                
                title(ptitle);
            end
            
            sn = Ck.SessionName;
            cluster = Ck.TitleStr;
            
            ztitle = append(cluster, ' ',sn);
            title(z, ztitle)
            
            % save figure
            s = split(cluster, '_');
            subject = s(1);
            
            folder = append(savedir,'PSTH\',subject,'\',mat2str(i));
            filename = append(cluster,'-',sn);
            ffn = fullfile(folder,filename);
            
            saveas(y, ffn, 'pdf')
            close(y)
        end
    end
end