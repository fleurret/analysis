%% Set directories - run first!

% which metric to use
parname = 'FiringRate';
% parname = 'Power';
% parname = 'VScc';

% region = "IC";
% region = "IC shell";
% region = "MGN";
region = "ACx";

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
    spth = 'D:\Caras\Analysis\ACx recordings\Reformatted\';
    savedir = 'D:\Caras\Analysis\ACx recordings\';
    behavdir = 'D:\Caras\Analysis\ACx recordings\Behavior\';
end

%% Load .mat and convert neural data
% only needs to be run whenever new data is added

load_clusters(spth, savedir);

%% Flag cluster
% syntax: flag_cluster(savedir, flag_day, cid)

% flag_day: day
% cid: cluster number

flag_cluster(savedir, 1, "323", "784", "MUA")

%% AM/Non-AM metrics across sessions first day
% syntax: metrics_across_sessions(parname, spth, savedir, ndays, meas, type, unit_type, condition, depth, savefile)

% meas: 'Mean', 'CoV' (Coefficient of variation)
% type: 'AM', 'NonAM'
% depth: in dB; 0 -3 -6 -9 -12 -15 -18

metrics_across_sessions(parname, spth, savedir, 1:7, 'Mean', 'AM', "all", "all", -9, 1)

%% Calculate AM/NonAM ratio
% syntax: am_ratio(parname, spth, savedir, ndays, unit_type, condition, depth, savefile)

% am_ratio(parname, spth, savedir, 1, "SU", "all", 0 ,0)

am_ratio_combined(parname, spth, savedir, 1:7, "all", "all", -9 ,0)

%% CoV combined

cov_combined(parname, spth, savedir, 1:7, 'NonAM', "all", "all", -9 ,0)

%% Plot neurometric fits across sessions
% syntax: fit_over_days(spth, savedir, parname, subj, unit_type)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

fit_over_sessions(spth, savedir, parname, "all", "SU")

%% Plot neurometric fits across sessions from one unit
% syntax: fit_over_days(spth, savedir, parname, ndays, unit_type, condition, cn)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

% cn = which number unit

fit_over_sessions_rep(spth, savedir, parname, 3, "SU", "all", 7)

%%

metrics_across_depth_rep(spth, savedir, parname, 3, "SU", "all", 7)

%% Plot histograms for each unit
% plot_histo(savedir, parname, ndays, unit_type, condition, cn, figpath)

figpath = 'D:\Caras\Manuscripts\Ying JNeuro 2024\Figures\Panels\IC\vscc\representative 3';

% IC
% plot_histo(savedir, parname, 1, "all", "all", 10, figpath)

% plot_histo(savedir, parname, 1, "SU", "all", 12, figpath)
% plot_histo(savedir, parname, 1, "SU", "all", 19, figpath)
plot_histo(savedir, parname, 3, "SU", "all", 7, figpath)

% MGN
% plot_histo(savedir, parname, 1, "all", "all", 24, figpath)

% plot_histo(savedir, parname, 1, "SU", "all", 7, figpath)
% plot_histo(savedir, parname, 1, "SU", "all", 27, figpath)
% plot_histo(savedir, parname, 4, "SU", "all", 4, figpath)

%% Plot thresholds across sessions
% syntax: thresholds_across_sessions(spth, savedir, parname, day, subj, unit_type, condition,  savefile)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

% day: day number

% condition: all, improved, worsened

% savefile: 0 no 1 yes

% thresholds_across_sessions(spth, savedir, parname, 1:7, "SU", "all", 0)

thresholds_across_sessions_combined(spth, savedir, parname, 1:7, "all", "SU", "all", 0)

%% Plot dprime over days
% syntax: plot_dprime(spth, savedir, parname, subj, unit_type, depth, condition, sv)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

% depth: in dB; 0 -3 -6 -9 -12 -15 -18

% save file?: 1 = yes, 0 = no

% plot_dprime(spth, savedir, parname, "all", "SU", -9, "i", 0)

%% Plot neurometric fits over days
% syntax: fit_over_days(spth, savedir, parname, subj, unit_type)

% subj: "all", "202", "222", "223", "224", "267"

% unit_type: "all", "SU"

% fit_over_days(spth, savedir, parname, "all", "SU")

%% Plot thresholds across days
% syntax: plot_units(region, spth, behavdir, savedir, parname, ndays, subj, condition, unit_type, replace, savefile)

% subj: "all", "202", "222", "223", "224", "267"

% condition: "all", "i" (improved), "w" (worsened)

% unit_type: "all", "SU"

% replace (NaN thresholds with 0): "yes"

% save file?: 1 = yes, 0 = no

plot_units(region, spth, behavdir, savedir, parname, 1:7, "all", "all", "all", "yes", 1)

output(region, spth, behavdir, savedir, parname, 1:7, "all", "all", "all", "yes", 1)

%% Plot behavior vs neural for an individual subject
% syntax: bvsn(behavdir, savedir, parname, ndays, subj, unit_type, condition)

bvsn(behavdir, savedir, parname, 1:7, "223", "all", "all")

%% Plot behavior vs neural for population
% syntax: bvsn(behavdir, savedir, parname, ndays, unit_type, condition)

bvsn_pop(behavdir, savedir, parname, 1:7, "all", "all")

%% Sort units into better/worse/same
% syntax: split_condition(savedir, parname, ndays, unit_type, condition)

split_condition(savedir, parname, 1:7, "SU", "all")

%% Compare thresholds by coding
% syntax: compare_thresholds(savedir, parx, pary, ndays, unit_type, condition, shownans, savefile)

% parx/pary: 'FiringRate', 'VScc', 'Power'

% shownans: yes 1, no 0

% savefile: yes 1, no 0

compare_thresholds(savedir, 'VScc', 'FiringRate', 1:7, "SU", "all", 1, 0)

%% Coding shift for individual neurons between sessions
% syntax: compare_thresholds(savedir, parx, pary, session 1, session 2, ndays, unit_type, condition, shownans)

% parx: passive measure

% pary: active measure

% shownans: yes 1, no 0

% savefile: yes 1, no 0

coding_shift(savedir, 'VScc', 'FiringRate', 'Pre', 'Active', 1:7, "SU", "all")

%% Coding strategy
% syntax: (spth, savedir, ndays, unit_type, condition)

coding_strategy(spth, savedir, 1:7, "SU", "all")

%% Calculate vector change in threshold between passive/active

% change_in_threshold(savedir, spth, 'FiringRate', 'VScc', 1:7, "SU", "all");
change_in_threshold_combined(savedir, spth, 'VScc', 'FiringRate', 1:7, "SU", "all");
%%
change_in_threshold_correlation(savedir)
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

%% Count units

count_units(savedir)

%% Average % change

average_change(savedir, parname, 1:7, "all", "all")
%%
average_change_m(savedir, parname, 1:7, "all", "all", -9)

%% Plot white noise
white_noise(1)