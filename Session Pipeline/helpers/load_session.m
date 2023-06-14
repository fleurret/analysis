function load_session(spth)

datafolders = dir(spth);
datafolders(~[datafolders.isdir]) = [];
datafolders(ismember({datafolders.name},{'.','..'})) = [];
datafolders(~contains({datafolders.name},{'concat'})) = [];

for i = 1:length(datafolders)
    DataPath = fullfile(datafolders(i).folder,datafolders(i).name);
    par = epa.load.phy('getdefaults');
    par.includespikewaveforms = false;
    
    S = epa.load.phy(DataPath,par);
    
    epa.load.events(S,DataPath);
    
    % View
    
    % par = [];
    % par.datafilestr = '*300hz.dat';
    % S = epa.load.phy(DataPath,par);
    
    % TDTTankPath = '/mnt/CL_4TB_2/Rose/IC recording/SUBJ-ID-222/Tank/210624';
    %
    % S.add_TDTEvents(TDTTankPath);
    
    % S.add_TDTStreams(TDTTankPath);
    
    % Save session
    fn = append(datafolders(i).name,'.mat');
    
    if ~exist([cd filesep 'Sessions']) == 1
        mkdir(spth,'Sessions')
    end
    
    fullFileName = fullfile(spth,'Sessions', fn);
    
    fprintf('Saving %s ...',fullFileName)
    
    save(fullFileName,'S');
    
    fprintf(' done\n')
end