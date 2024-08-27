function average_change(savedir, parname, ndays, unit_type, condition)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

sessions = ["Pre", "Active", "Post"];

fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

pre2task = [];
task2post = [];
post2pre = [];

for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
   
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        clear t
        
        % calculate change
        for k = 1:length(U)
            
            % pull values
            u = U(k);
            
            if ~isfield(u.UserData.(Parname),'threshold')
                t(k) = NaN;
            else
                t(k) = u.UserData.(Parname).threshold;
            end
        end
        
%         p2t = (t(2)-t(1));
%         t2p = (t(2)-t(3));
%         p2p = (t(3)-t(1));

        p2t = (t(2)-t(1))/t(1)*100;
        t2p = (t(2)-t(3))/t(1)*100;
        p2p = (t(3)-t(1))/t(1)*100;
        
        pre2task = [pre2task,p2t];
        task2post = [task2post,t2p]; 
        post2pre = [post2pre,p2p];
    end
end

% calculate mean
M1 = mean(pre2task,'omitnan');
M2 = mean(task2post,'omitnan');
M3 = mean(post2pre,'omitnan');
S1 = std(pre2task,'omitnan')/sum(~isnan(pre2task));
S2 = std(task2post,'omitnan')/sum(~isnan(task2post));
S3 = std(post2pre,'omitnan')/sum(~isnan(post2pre));

fprintf('\n Pre to Task: %s +/- %s', num2str(M1), num2str(S1))
fprintf('\n Post to Task: %s +/- %s', num2str(M2), num2str(S2))
fprintf('\n Post to Pre: %s +/- %s \n', num2str(M3), num2str(S3))
