 function fit_over_sessions(spth, savedir, parname, subj, unit_type)

% Plot individual unit thresholds and means across days

% correlation coefficient is set to Spearman's

% convert parname to correct label
if contains(parname,'FiringRate')
    parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    parname = 'vector_strength_cycle_by_cycle';
end

% load neural
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 7;

% set properties
sessionName = ["Pre","Active","Post"];

cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

mk = '^^^';

f = figure;
f.Position = [0, 0, 500, 275];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
ylim([-0.5,3]);

days = 1:min(maxNumDays,length(Cday));

DV = cell(size(days));
sidx = DV;
didx = DV;

% neural data
for i = 1
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
        
        % flag if threesholds are all NaN or 0, or all pvals are NaN or > 0.05
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
            flaggedForRemoval(end+1) = uid(j);
%             fprintf(2,'ID %s, DV = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        else
%             fprintf('ID %s, DV = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
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
   
    % remove multiunits
    if unit_type == "SU"
        removeind = [Ci.Type] == "SU";
        Ci = Ci(removeind);
    end
   
    % clear vars
    v = [];
    dp = [];
    
    y = arrayfun(@(a) a.UserData.(parname),Ci,'uni',0);
    ind = cellfun(@(a) isfield(a,'ERROR'),y);
    
    y(ind) = [];
    Ci(ind) = [];
    
    y = [y{:}];
    
    if ~isempty(y)
        dprimes = {y.dprime};
        dsz = cellfun('size', dprimes, 1);
        
        DP = [];

        for j = 1:length(dprimes)
            z = flip(dprimes{j});
            
            if all(dsz == dsz(1))
                DP(j,:) = z;
            else
                if length(dprimes{j})~= max(dsz)
                    dif = max(dsz)-length(dprimes{j});
                    Dif = 1:dif;

                    for k = 1:length(Dif)
                        z(length(dprimes{j})+Dif(k)) = NaN;
                    end
                    DP(j,:) = z;
                else
                    DP(j,:) = z;
                end
            end
        end
        
        sn = [Ci.Session];
        sn = [sn.Name];
        sidx{i}(contains(sn,"Pre")) = 1;
        sidx{i}(contains(sn,"Aversive")) = 2;
        sidx{i}(contains(sn,"Post")) = 3;
        x = 1+ones(size(sidx))*log10(days(i));
    else
        continue
    end
    
    vals = {y.vals};
    szv = cellfun('size', vals, 1);
    [V] = cellfun(@max, vals);
    vidx = szv == max(szv);
    vv = vals(vidx);
    v = flip(cell2mat(vv(end)));
    
    for j = 1:3 % plot each session seperately
        ind = sidx{i} == j;
        session = DP(ind,:);
        
        if size(session, 1) ~= 1
            dp = mean(session, 'omitnan');
        else
            dp = session;
        end
        
        dp = dp';
        [xfit,yfit] = epa.analysis.fit_sigmoid(v,dp);
        
        hold on
        plot(xfit,yfit,...
            'Color', cm(j,:),...
            'LineWidth', 4)
        legend(sessionName,...
            'location', 'northwest')
        legend boxoff
    end
end

% % axes etc
set([ax.XAxis], ...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 1.5,...
    'FontSize',12);
set([ax.YAxis],...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 1.5,...
    'FontSize',12);
ax(1).YAxis.Label.Rotation = 90;

xlabel(ax,'dB SPL re: 100%',...
    'FontWeight','bold',...
    'FontSize', 12);
ylabel(ax,'d''',...
    'FontWeight','bold',...
    'FontSize', 12);
