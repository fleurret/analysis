 function fit_over_days(spth, savedir, parname, subj, unit_type)

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

cm = [138,156,224; 117,139,219; 97,122,213; 77,105,208; 57,88,203; 49,78,185; 44,70,165;]./255; % session colormap

mk = '^^^';
xoffset = [.99, 1, 1.01];

f = figure;
f.Position = [0, 0, 1000, 350];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
ylim([-0.5,3]);

days = 1:min(maxNumDays,length(Cday));

DV = cell(size(days));
sidx = DV;
didx = DV;

% neural data
count = zeros(1,3);

for i = 1:length(days)
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
        Dsz = min(dsz);
        
        DP = [];

        for j = 1:length(dprimes)
            z = flip(dprimes{j});
            
            if all(dsz == dsz(1))
                DP(j,:) = z;
            else
                if length(dprimes{j}) == min(Dsz)
                    z(end+1) = NaN;
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
    [V] = cellfun(@min, vals);
    vidx = V == min(V);
    vv = vals(vidx);
    
    mv = cellfun('size', vv, 1);
    mvidx = mv == max(mv);
    V = vv(mvidx);
    v = flip(cell2mat(V(end)));
    
    for j = 2 %:3 % plot each session seperately
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
            'Color', cm(i,:),...
            'LineWidth', 2)
        legend('Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Day 7')
    end
end

% grid(ax(1),'off');
% 
% % axes etc
% set([ax.XAxis], ...
%     'TickValues',log10(days)+1, ...
%     'TickLabels',arrayfun(@(a) num2str(a,'%d'),days,'uni',0),...
%     'TickDir','out',...
%     'FontSize',12);
% set([ax.YAxis],...
%     'TickDir','out',...
%     'FontSize',12);
% ax(1).YAxis.Label.Rotation = 90;
% ax(2).YAxis.Label.Rotation = 90;
% 
% set(findobj(ax,'-property','FontName'),...
%     'FontName','Arial')
% 
% xlabel(ax,'Psychometric testing day',...
%     'FontWeight','bold',...
%     'FontSize', 15);
% ylabel(ax,'d''',...
%     'FontWeight','bold',...
%     'FontSize', 15);
% title(ax,sprintf('%s (n = %d)',parname,length(subjects)),...
%     'FontSize',15);
% 
% box(ax,'on');
% 
% legend(hfit,'Location','southwest','FontSize',12);
% legend([hfitm,bfit],'Location','southwest','FontSize',12);
% legend boxoff