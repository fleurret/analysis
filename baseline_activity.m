parname = 'FiringRate';
% parname = 'Power';
% parname = 'VScc';

spth = 'D:\Caras\Analysis\MGB recordings\Data\';
savedir = 'D:\Caras\Analysis\MGB recordings\';

%% create file

% convert parname to correct label
if contains(parname,'FiringRate')
    parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    parname = 'vector_strength_cycle_by_cycle';
end

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 7;

output = [];

for i = 1:maxNumDays
    Ci = Cday{i};
    
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
        
        if contains(c.SessionName, 'FreqTuning')
            continue
        end
        
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
    
    % replace Cday
    Cday{1,i} = Ci;
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        temp = {};
        B = [];
        
        % get events and calculate baseline
        for k = 1:length(U)
            u = U(k);
            
            if parname == 'trial_firingrate'
                b = baseline_fr(u);
            end
                
%             elseif parname == 'cl_calcpower'
%                 continue
%             else parname == 'vector_strength_cycle_by_cycle'
%                 continue
%             end

            B = [B; b];
        end
        % add to list
        temp{1} = uid(j);
        temp{2} = i;
        temp{3} = u.Type;
        temp{4} = B(1);
        temp{5} = B(2);
        temp{6} = B(3);
        
        output = [output; temp];
    end
end

% save as file
sf = fullfile(savedir,append(parname,'_baseline.xlsx'));
fprintf('Saving file %s/n', sf)
writecell(output,sf);
fprintf(' done\n')

%% plot

cm = [138,156,224; 117,139,219; 97,122,213; 77,105,208; 57,88,203; 49,78,185; 44,70,165;]./255; % session colormap

f = figure;
f.Position = [0, 0, 2000, 350];

for d = 1:maxNumDays
    ax = subplot(1,maxNumDays,d);
    hold on
    
    for i = 1:length(output)
        unit = output(i,:);
        pap = [cell2mat(unit(4)) cell2mat(unit(5)) cell2mat(unit(6))];
        ud = cell2mat(unit(2));
        ucm = cm(d,:);
        
        if d == ud
            plot(pap,...
                'Color',ucm,...
                'Marker','o',...
                'LineWidth',2)
            xticklabels({'Pre','','Active','','Post'})
            
            if parname == 'trial_firingrate'
                ylabel('Firing rate (Hz)')
                ylim([0 100])
            end

        end
    end
end