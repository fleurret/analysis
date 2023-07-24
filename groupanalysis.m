%% Set directories - run first!

% which metric to use
% parname = 'FiringRate';
% parname = 'Power';
parname = 'VScc';

% region = "IC";
% region = "IC shell";
region = "MGN";
% region = "ACx";

if region == "IC"
    spth = 'D:\Caras\Analysis\IC recordings\Data\';
    savedir = 'D:\Caras\Analysis\IC recordings';
    behavdir = 'D:\Caras\Analysis\IC recordings\Behavior\';
end

if region == "IC shell"
    spth = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\Data\';
    savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\';
    behavdir = 'C:\Users\rose\Documents\Caras\Analysis\IC shell recordings\Behavior\';
end

if region == "MGN"
    spth = 'D:\Caras\Analysis\MGB recordings\Data\';
    savedir = 'D:\Caras\Analysis\MGB recordings\';
    behavdir = 'D:\Caras\Analysis\MGB recordings\Behavior\';
end

if region == "ACx"
    spth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Reformatted\';
    savedir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\';
    behavdir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior\';
end

%% Load .mat and convert neural data
% only needs to be run whenever new data is added

load_clusters(spth, savedir);

%% Flag cluster
% syntax: flag_cluster(savedir, parname, remove, flag_day, cid, session)

% remove: "unit", "session"
% flag_day: day
% cid: cluster name
% session: "Pre", "Aversive", "Post"

flag_cluster(savedir, parname, "session", 3, "224_cluster1451", "Post")

%% AM/Non-AM metrics across sessions
% syntax: metrics_across_sessions(parname, spth, savedir, meas, type, depth)

% meas: 'Mean', 'CoV' (Coefficient of variation)
% type: 'AM', 'NonAM'
% depth: in dB; 0 -3 -6 -9 -12 -15 -18

metrics_across_sessions(parname, spth, savedir, 'CoV', 'AM', "all", "SU", 0)

%% Plot neurometric fits across sessions
% syntax: fit_over_days(spth, savedir, parname, subj, unit_type)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

fit_over_sessions(spth, savedir, parname, "all", "SU")

%% Plot thresholds across sessions
% syntax: thresholds_across_sessions(spth, savedir, parname, subj, unit_type, day)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

% day: day number

thresholds_across_sessions(spth, savedir, parname, "all", "SU", 1)

%% Plot dprime over days
% syntax: plot_dprime(spth, savedir, parname, subj, unit_type, depth, sv)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

% depth: in dB; 0 -3 -6 -9 -12 -15 -18

% save file?: 1 = yes, 0 = no

plot_dprime(spth, savedir, parname, "all", "SU", -12, 0)

%% Plot neurometric fits over days
% syntax: fit_over_days(spth, savedir, parname, subj, unit_type)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

fit_over_days(spth, savedir, parname, "all", "SU")

%% Plot thresholds across days
% syntax: plot_units(spth, behavdir, savedir, parname, subj, condition, unit_type, replace)

% subj: "all", "202", "222", "223", "224", "267"

% condition: "all", "i" (improved), "w" (worsened)

% unit_type: "all", "SU"

% replace (NaN thresholds with highest depth presented): "yes"

% save file?: 1 = yes, 0 = no

plot_units(spth, behavdir, savedir, parname, "all", "all", "SU", "no", 0)

%% Calculate CoV across days
% syntax: plot_units(spth, behavdir, savedir, parname, subj, condition, unit_type, replace)

% subj: "all", "202", "222", "223", "224", "267"

% condition: "all", "i" (improved), "w" (worsened)

% unit_type: "all", "SU"

% replace (NaN thresholds with highest depth presented): "yes"

% save file?: 1 = yes, 0 = no

plot_units(spth, behavdir, savedir, parname, "all", "all", "SU", "no", 0)

%% Plot behavior vs neural for an individual subject
% syntax: bvsn(behavdir, savedir, parname, maxdays, subj)

bvsn(behavdir, savedir, parname, 7, "380")

%% Plot behavior vs neural for population
% syntax: bvsn(behavdir, savedir, parname, maxdays)

bvsn_pop(behavdir, savedir, parname, 7)

%% Sort units into improved/worsened
% syntax: split_condition(savedir, maxNumDays, parname, replace)

% maxNumDays: max days for analysis, default = 7

% replace: replace NaN thresholds with lowest depth presented. "yes", "no"

split_condition(savedir, 7, parname, "no")

%% Compare thresholds by coding
% syntax: compare_thresholds(savedir, parx, pary, shownans)

% parx/pary: 'FiringRate', 'VScc', 'Power'

% shownans: "yes", "no"

% session: "pre", "active", "post", "all"

compare_thresholds(savedir, 'FiringRate', 'VScc', "yes", "active")

%% Calculate vector change in threshold between passive/active

change_in_threshold(savedir, spth, 'FiringRate', 'VScc');
% 
% mean([output{:,3}], 'omitnan')
% mean([output{:,4}], 'omitnan')
% mean([output{:,5}], 'omitnan')
% mean([output{:,6}], 'omitnan')

%% Extract mean/median/max firing rate info

val = 'Mean';
% val = 'Median';
% val = 'Max';

% depth: in dB; 0 -3 -6 -9 -12 -15 -18
depth = -9;

makeplot = 'y';

extract_fr(savedir, parname, val, depth, makeplot)

%% Plot thresholds across regions - not finished

% parname = 'FiringRate';
parname = 'VScc';

% region = "all";

% session = 'Pre';
session = 'Active';
% session = 'Post';

sd1 = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\';
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(sd1,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(sd1,fn));

sd2 = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings\';
sd3 = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\';

%% Plot histograms for each unit

plot_histo(savedir, parname)

%% Count units

count_units(savedir)



