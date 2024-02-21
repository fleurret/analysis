sfolder = 'D:\Caras\Analysis\MGB recordings\Data\SUBJ-ID-670';

% prompt user to select 
units = uigetfile(sfolder,'Select session(s)','MultiSelect','on');

if ischar(units)
    units = {units};
end

for u = 1:length(units)
    ffn = fullfile(sfolder,units{u});
    
    load(ffn)
    
    for i = 1:length(S)
        session = S(i);
        
        for j = 1:length(session.Clusters)
            cluster = session.Clusters(j);
            if cluster.QualityMetrics.Shank > 1
                 cluster.Note = 'dorsal';
            else
                cluster.Note = [];
            end
        end
    end
    
    fprintf('Saving %s ...',ffn);
    save(ffn,'S')
    fprintf(' done\n')
end