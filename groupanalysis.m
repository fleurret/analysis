%% Set directories - run first!
% region = "IC";
% region = "IC shell";
region = "MGN";
% region = "ACx";

if region == "IC"
    spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Data';
    savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\';
    behavdir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Behavior';
end

if region == "IC shell"
    spth = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\Data';
    savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\';
    behavdir = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\Behavior';
end

if region == "MGN"
    spth = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings\Data';
    savedir = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings';
    behavdir = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings\Behavior';
end

if region == "ACx"
    spth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Reformatted';
    savedir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings';
    behavdir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior';
end

%% Load .mat and convert neural data
% only needs to be run whenever new data is added

load_clusters(spth, savedir);

%% Flag cluster
% syntax: flag_cluster(savedir, parname, remove, flag_day, cid, session)

% parname = 'FiringRate';
% parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

% remove: "unit", "session"
% flag_day: day
% cid: cluster name
% session: "Pre", "Aversive", "Post"

flag_cluster(savedir, parname, "session", 3, "224_cluster1451", "Post")

%% Plot thresholds across days
% syntax: plot_units(spth, behavdir, savedir, parname, subj, condition, unit_type, replace)

parname = 'FiringRate';
% parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

% subj: "all", "202", "222", "223", "224", "267"

% condition: "all", "i" (improved), "w" (worsened)

% unit_type: "all", "SU"

% replace (NaN thresholds with highest depth presented): "yes"

plot_units(spth, behavdir, savedir, parname, "all", "all", "all", "no")

%% Plot behavior vs neural for an individual subject
% syntax: bvsn(behavdir, savedir, parname, maxdays, subj)

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

bvsn(behavdir, savedir, parname, 7, "322")

%% Plot behavior vs neural for population
% syntax: bvsn(behavdir, savedir, parname, maxdays)

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

bvsn_pop(behavdir, savedir, parname, 7)
%% Sort units into improved/worsened
% syntax: split_condition(savedir, maxNumDays, parname, replace)

parname = 'FiringRate';
% parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

% maxNumDays: max days for analysis, default = 7

% replace: replace NaN thresholds with lowest depth presented. "yes", "no"

split_condition(savedir, 7, parname, "no")

%% Compare thresholds by coding
% syntax: compare_thresholds(savedir, parx, pary, shownans)

% parx/pary: 'FiringRate', 'VScc', 'VS', 'Power'

% shownans: "yes", "no"

% session: "pre", "active", "post", "all"

compare_thresholds(savedir, 'FiringRate', 'VScc', "yes", "pre")

%%
parname = 'FiringRate';
% parname = 'VScc';

fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

days = 7;

fr_mean = {};
fr_med = {};
fr_max = {};

pre_a = [];
pre_m = [];
pre_ma = [];

active_a = [];
active_m = [];
active_ma = [];

post_a = [];
post_m = [];
post_ma = [];

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
    
    % create table of fr values
    a1 = [];
    a2 = [];
    a3 = [];
    
    m1 = [];
    m2 = [];
    m3 = [];
    
    ma1 = [];
    ma2 = [];
    ma3 = [];
    
    for j = 1:length(Ci)
        Ck = Ci(j);
        ev = Ck.Session.find_Event("AMDepth").DistinctValues;
        ev(ev==0) = [];
        h = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',ev);
        [fr,b,uv] = Ck.psth(h);
        
        sn = Ck.SessionName;
        
        % mean
        M = mean(fr(:));
        if contains(sn,"Pre")
            a1 = [a1, M];
        end
        
        if contains(sn,"Aversive")
            a2 = [a2, M];
        end
        
        if contains(sn,"Post")
            a3 = [a3, M];
        end
        
        % median
        med = median(fr(:));
        if contains(sn,"Pre")
            m1 = [m1, med];
        end
        
        if contains(sn,"Aversive")
            m2 = [m2, med];
        end
        
        if contains(sn,"Post")
            m3 = [m3, med];
        end
        
        % max
        x = max(fr(:));
        if contains(sn,"Pre")
            ma1 = [ma1, x];
        end
        
        if contains(sn,"Aversive")
            ma2 = [ma2, x];
        end
        
        if contains(sn,"Post")
            ma3 = [ma3, x];
        end
    end
    
    fr_mean{i,1} = a1;
    fr_mean{i,2} = a2;
    fr_mean{i,3} = a3;
    
    fr_med{i,1} = m1;
    fr_med{i,2} = m2;
    fr_med{i,3} = m3;
    
    fr_max{i,1} = ma1;
    fr_max{i,2} = ma2;
    fr_max{i,3} = ma3;
    
    pre_a = [pre_a,a1];
    pre_m = [pre_m,m1];
    pre_ma = [pre_ma,ma1];
    
    active_a = [active_a,a2];
    active_m = [active_m,m2];
    active_ma = [active_ma,ma2];
    
    post_a = [post_a,a3];
    post_m = [post_m,m3];
    post_ma = [post_ma,ma3];
end

avg = [pre_a; active_a; post_a]';
medi = [pre_m; active_m; post_m]';
maxi = [pre_ma; active_ma; post_ma]';

avg1 = [mean(pre_a), mean(active_a), mean(post_a)];
medi1 = [mean(pre_m), mean(active_m), mean(post_m)];
maxi1 = [mean(pre_ma), mean(active_ma), mean(post_ma)];
