% load neural
Cdayfile = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Cday.mat';
load(Cdayfile)

spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Data';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';

minNumSpikes = 0;
maxNumDays = 7;
days = 1:min(maxNumDays,length(Cday));

temp = zeros(93,4);

% neural data
for i = 7
    Ci = Cday{i};
  
    % remove flagged units
    note = {Ci.Note};
    removeind = cellfun(@isempty, note);
    Ci = Ci(removeind);
    
    % list all
    for j = 1:length(Ci)
        id = str2num(erase(Ci(j).Name,"cluster"));
        subject = str2num(Ci(j).Subject);
        session = Ci(j).Session.Name;
        measure = Ci(j).UserData.(parname);
        checkempty = isfield(measure,'threshold');
        
        temp(j,1) = id;
        temp(j,2) = subject;
        
        if contains(session,"Pre")
            temp(j,3) = 1;
        end
        
        if contains(session,"Aversive")
            temp(j,3) = 2;
        end
        
        if contains(session,"Post")
            temp(j,3) = 3;
        end
        
        if checkempty == 1
            temp(j,4) = measure.threshold;
            temp(j,5) = measure.p_val;
        end
        
       
    end
   
        
    % remove units with bad fit
%     alpha = 0.05;
%     pidx = zeros(1,length(Ci));
%     for j = 1:length(Ci)
%         pvs = Ci(j).UserData.(parname);
%         if ~isfield(pvs,'p_val')
%             pidx(j) = 0;
%         else
%             p_val = pvs.p_val;
%             if p_val >= alpha || isnan(p_val)
%                 pidx(j) = 0;
%             end
%             
%             if p_val < alpha
%                 pidx(j) = 1;
%             end
%         end
%     end
%     pidx = logical(pidx);
%     Ci = Ci(pidx);
    
end