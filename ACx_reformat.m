%% Physiology data
% load file
spth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Processed\DL14_MAT_combined';

day = cell2mat(extractBetween(spth, "Processed\","_MAT"));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% loop through subjects
for s = 1:length(subjects)
    subj = subjects(s).name;
    subjfolder = fullfile(subjects(s).folder,subj);
    sessionfile = dir(subjfolder);
    sessionfile(ismember({sessionfile.name},{'.','..'})) = [];
    
    for j = 1:length(sessionfile)
        session = sessionfile(j).name;
        ffn = fullfile(sessionfile(j).folder,session);
        load(ffn)
        
        % assign properties
        % initiate Session
        S(j) = epa.Session;
        
        % sampling rate
        S(j).SamplingRate = 24414.125;
        
        % subject ID
        S(j).Subject = subj;
        
        % session name
        if contains(ffn, 'passive_pre')
            sn = "PassivePre";
        end
        
        if contains(ffn, 'active')
            sn = "AversiveAM";
        end
        
        if contains(ffn, 'passive_post')
            sn = "PassivePost";
        end
        
        S(j).Name = sn;
        
        v = data.behavior.trial_log.modulation_depth;
        onoff = [data.behavior.trial_log.ts_start data.behavior.trial_log.ts_end] ./ (2*S(j).SamplingRate);
        S(j).add_Event('AMdepth',onoff,v); % S.add_Event(Name,Timestamps,Values)
        
        % C = epa.Cluster(SessionObj,[ID],[Samples],[SpikeWaveforms])
        
        channels = fieldnames(data.physiology);
        
        unitid = 0;
        
        for i = 1:length(channels)
            CH = data.physiology.(channels{i});
            for k = 1:length(CH.clusters)
                
                % create cluster and add spike times
                a = num2str(k);
                clusterid = CH.clusters(k).clusterID;
                assigns = CH.assigns;
                ind = clusterid == assigns;
                spk = CH.timestamps(ind);
                
                unitid = unitid + 1;
                
                S(j).add_Cluster(unitid,spk);
                
                % set properties
                % channel
                cname = string(cell2mat(channels(i)));
                cname = str2num(erase(cname,"ch"));
                
                % type
                unittype = string(CH.clusters(k).clusterType);
                if unittype == "good unit"
                    unittype = "SU";
                end
                
                if unittype == "multi-unit"
                    unittype = "MUA";
                end
                
                % add properties
                S(j).Clusters(k).Channel = cname;
                S(j).Clusters(k).Type = unittype;
                S(j).Clusters(k).Name = unitid;
            end
        end
    end
    % save reformatted
    savedir = "C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Reformatted";
    mkdir(savedir, subj)
    
    fn = fullfile(savedir,subj);
    dayfile = append(day,".mat");
    fn = fullfile(fn, dayfile);
    
    save(fn, 'S')
    
    clear S
end

