
% spth = '/mnt/CL_4TB_1/Rose/IC recording/SUBJ-ID-222';
% spth = '/mnt/CL_8TB_3/Rose/IC recording/SUBJ-ID-267';
spth = '/mnt/CL_4TB_2/Rose/MGN recording/SUBJ-ID-323';

%% Create and save a new Session object(s)

load_session(spth)

%% DataBrowser GUI finds valid Session objects in the base workspace

% S.remove_Event("Cam1")
D = epa.DataBrowser;

%% Convert clusters to sessions
% only need to run once

convert_session(spth)

%% Calculate neurometrics
% this function computes firing rate, power, and vector strength cycle by
% cycle based neurometric d' for each cluster

neurometrics(spth)