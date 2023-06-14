function convert_session(spth)

sfolder = append(spth,'/Sessions');

d = dir(sfolder);
d(ismember({d.name},{'.','..'})) = [];

% strips waveforms, rebuilds any clusters into sessions
for i = 1:length(d)
    ffn = fullfile(d(i).folder,d(i).name);
    
    clear S
    
    fprintf('Loading %s ...',d(i).name)
    load(ffn)
    fprintf(' done\n')
   

    if ~exist('S','var')

        % an array of Cluster objects was saved and not just the Session
        % objects, but we can recover the original Session from its property.
        S = unique([C.Session]);
    end


    S = [S.find_Session("Pre"), S.find_Session("Aversive"), S.find_Session("Post")];
    
    
    for j = 1:length(S)
        arrayfun(@remove_waveforms,S(j).Clusters);
%         S(j).Subject = subj;
    end
    
    arrayfun(@disp,[S.Name])
    
    
    fprintf('Saving %s ...',d(i).name);
    save(ffn,'S')
    fprintf(' done\n')
    
%     clear S
end
