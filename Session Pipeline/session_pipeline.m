% This pipeline is used in combination with the +epa toolbox to convert the
% preprocessed cluster data into session data and calculate neurometric
% values (firing rate, power, vector strength cycle-by-cycle)

% data folder
spth = '/mnt/CL_4TB_1/Rose/IC recording/SUBJ-ID-202';

%% Assign quality metrics based on Allen Brain Institute parameters
qm(spth)

%% Create and save a new Session object(s)
load_session(spth)

%% Convert clusters to sessions
% only need to run once

convert_session(spth)

%% Calculate neurometrics
% this function computes firing rate, power, and vector strength cycle by
% cycle based neurometric d' for each cluster

neurometrics(spth)
