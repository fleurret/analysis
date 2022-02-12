% save directory
savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\';
parname = 'VScc';

% load neural
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');
load(fullfile(savedir,fn));

% set all MUA
for i = 1:length(days)
    Ci = Cday{i};
    
     for j = 1:length(Ci)
         Ci(j).Type = "MUA";
     end
end   

%% Set as SU
flag_day = 7;
cid = "267_cluster1619";

s = [Cday{flag_day}.SessionName];
ind = [Cday{flag_day}.Name] == cid;
set(Cday{flag_day}(ind),'Type',"SU")