%% SET VARIABLES
% folder where your data is located - should have subfolders for each
% condition, and then sub-subfolder subject with behavior file
% e.g. Caspase > Control > SUBJ200 > behaviorfile.mat; your path will be
% C:\Users\rose\Caspase
pth = 'D:\Caras\Analysis\IC recordings\Behavior';

% number of days you want to analyze
maxdays = 7;

% y limit - adjust as needed to make sure all data points are visible
yl = [-20,-2];

% colors to use in your graphs. rgb values (https://www.color-hex.com/)
c = [69,207,217 ; 120,57,118]./255;

%% GRAPH AVERAGE THRESHOLDS ACROSS DAYS
% bars represent standard error

avg_threshold(pth, maxdays, yl, c)

%% SINGLE SUBJECT

pth = 'D:\Caras\Analysis\IC recordings\Behavior\222';

% number of days you want to analyze
maxdays = 7;

% y limit - adjust as needed to make sure all data points are visible
yl = [-20,-2];

% colors to use in your graphs. rgb values (https://www.color-hex.com/)
c = [69,207,217 ; 120,57,118]./255;

one_subject_threshold(pth, maxdays, yl, c);