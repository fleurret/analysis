%% Set directories - run first!
% data directory
% spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Data';
% spth = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\Data';
spth = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings\Data';
% spth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Reformatted';

% save directory
% savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\';
% savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\';
savedir = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings';
% savedir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings';

% behavior directory
% behavdir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Behavior';
% behavdir = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\Behavior';
behavdir = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings\Behavior';
% behavdir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior';

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

% parname = 'FiringRate';
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

compare_thresholds(savedir, 'FiringRate', 'VScc', "yes", "post")
