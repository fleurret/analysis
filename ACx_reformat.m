%% Physiology data
% load file
pth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Processed';
d = dir(pth);
d = d(~ismember({d.name},{'.','..'}));

for x = 1:length(d)
    folder = d(x).name;
    spth = fullfile(pth, folder);
    day = cell2mat(extractBetween(spth, "Processed\","_MAT"));
    
    % list subjects
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
            %         onoff = [data.behavior.trial_log.ts_start data.behavior.trial_log.ts_end] ./ (S(j).SamplingRate);
            start = data.behavior.trial_log.start;
            onoff = [start data.behavior.trial_log.xEnd];
            
            % S.add_Event(Name,Timestamps,Values)
            S(j).add_Event('AMdepth',onoff,v);
            
            % C = epa.Cluster(SessionObj,[ID],[Samples],[SpikeWaveforms])
            
            channels = fieldnames(data.physiology);
            unitid = 0;
            
            for i = 1:length(channels)
                CH = data.physiology.(channels{i});
                
                for k = 1:length(CH.clusters)
                    % type
                    unittype = string(CH.clusters(k).clusterType);
                    if unittype == "garbage"
                        unittype = "garbage";
                    end
                    
                    if unittype == "good unit"
                        unittype = "SU";
                    end
                    
                    if unittype == "multi-unit"
                        unittype = "MUA";
                    end
                    
                    % create cluster and add spike times
                    clusterid = CH.clusters(k).clusterID;
                    assigns = CH.assigns;
                    ind = clusterid == assigns;
                    
                    trials = CH.trials(ind);
                    samples = CH.timestamps(ind);
                    
                    % convert raw spiketimes into time relative to stim
                    % onset in seconds
                    raw_spiketimes = CH.spiketimes(ind);
                    trial_start = start(trials);
                    
                    relative_spiketimes = raw_spiketimes' - trial_start;
                    
                    % assign id so add_Cluster doesn't get mad
                    unitid = unitid+1;
                    
                    S(j).add_Cluster(unitid, samples);
                                       
                    % set properties
                    % channels
                    cname = string(cell2mat(channels(i)));
                    cname = str2num(erase(cname,"ch"));
                    
                    % create unique unit ID
                    uunitid = append(num2str(cname),num2str(clusterid));
                    
                    % add properties
                    S(j).Clusters(unitid).Channel = cname;
                    S(j).Clusters(unitid).Type = unittype;
                    S(j).Clusters(unitid).Name = uunitid;
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
end

%% Behavior data
% set paths
pth = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Processed';
savedir = 'C:\Users\rose\Documents\Caras\Analysis\ACx recordings\Behavior';

d = dir(pth);
d = d(~ismember({d.name},{'.','..'}));

for x = 1:length(d)
    folder = d(x).name;
    spth = fullfile(pth, folder);
    day = cell2mat(extractBetween(spth, "Processed\","_MAT"));
    
    % list subjects
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
            
            if contains(session,"active")
                activefile = sessionfile(j).name;
            end
        end
        
        ffn = fullfile(subjfolder,activefile);
        load(ffn)
        
        trialmat = [];
        output = [];
        
        p = data.behavior.PROCESSED;
        stimuli = p.stim_log;
        resps = p.resp_log;
        unique_stim = unique(stimuli);
        if length(unique_stim) > 6
            unique_stim = unique_stim(1:6);
        end
        
        %For each stimulus
        for i = 1:numel(unique_stim)
            stimulus_value = unique_stim(i);
            stimulus_index = find(stimuli == stimulus_value);
            
            %Pull out responses for just that stimulus...
            responses = resps(stimulus_index);
            
            
            %Adjust for perfect performance (hit rate = 1 or FA rate = 0) by
            %bounding hit/fa rates between 0.05 and 0.95. Note that other common
            %corrections (i.e. log-linear, 1/2N, etc) artificially inflate lower
            %bound when go trial numbers are small, nogo trial numbers are large,
            %hit rates are very low (sometimes for muscimol) and fa rates are very
            %low.
            
            %If NOGO
            if stimulus_value == 0
                
                %Count correct rejects and false alarms
                n_cr = sum(responses);
                n_fa = (numel(responses) - n_cr);
                n_safe = numel(responses);
                
                %Calculate fa rate
                fa_rate = (n_fa/n_safe);
                
                %Correct floor
                if fa_rate < 0.05
                    fa_rate = 0.05;
                end
                
                %Correct ceiling
                if fa_rate > 0.95
                    fa_rate = 0.95;
                end
                
                %Adjust number of false alarms to match adjusted fa rate (so we can
                %fit data with psignifit later)
                n_fa = fa_rate*n_safe;
                
                %Convert to z score
                z_fa = sqrt(2)*erfinv(2*fa_rate-1);
                
                %Append to trialmat
                trialmat = [trialmat;stimulus_value,n_fa,n_safe];
                
                %IF GO
            else
                
                %Count hits and misses
                n_miss = sum(responses);
                n_hit = (numel(responses)- n_miss);
                n_warn = numel(responses);
                
                %Calculate hit rate
                hit_rate = n_hit/n_warn;
                
                %Adjust floor
                if hit_rate <0.05
                    hit_rate = 0.05;
                end
                
                %adjust ceiling
                if hit_rate >0.95
                    hit_rate = 0.95;
                end
                
                %Adjust number of hits to match adjusted hit rate (so we can fit
                %data with psignifit later)
                n_hit = hit_rate*n_warn;
                
                %Append to trial mat
                trialmat = [trialmat;stimulus_value,n_hit,n_warn];
                
                
            end
        end
        %Convert stimulus values to log and sort data so safe stimulus is on top
        trialmat(:,1) = make_stim_log(trialmat);
        trialmat = sortrows(trialmat,1);
        
        %Calculate dprime
        hitrates = trialmat(2:end,2)./trialmat(2:end,3);
        z_hit = sqrt(2)*erfinv(2*(hitrates)-1);
        dprime = z_hit - z_fa;
        dprimemat = [trialmat(2:end,1),dprime];
        
        %Construct final output
        output.trialmat = trialmat;
        output.dprimemat = dprimemat;
        
        fn = fullfile(savedir,subj);
        
        % save file
        dayfile = append(day,".mat");
        fn = fullfile(fn, dayfile);
        
        save(fn, 'output')
    end
end

% helper function
function x = make_stim_log(mat)
%x = make_stim_log(mat)
%Converts AM depth values from proportions to dB re:100% values.
%
%Input variable mat contains data, with the first column containing
%stimulus values.
%
%ML Caras Dec 2015


x = mat(:,1);
x(x == 1)= 0.99; %to avoid infinity
x(x == 0) = 0.01;%to avoid infinity
x = 20*log10(x);

end