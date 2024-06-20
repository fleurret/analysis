function average_change_m(savedir, parname, ndays, unit_type, condition, depth)

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
pre2task2 = [];
task2post2 = [];
post2pre2 = [];

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
            
            [mAM, mNAM, cAM, ~] = calc_mas(u, Parname, depth);
            t(k) = mAM/mNAM;
            c(k) = cAM;
        end
        
        % ratio
        p2t = t(2)-t(1);
        t2p = t(3)-t(1);
        p2p = t(3)-t(2);

%         p2t = (t(2)-t(1))/t(1)*100;
%         t2p = (t(3)-t(1))/t(1)*100;
%         p2p = (t(3)-t(2))/t(1)*100;
        
        % cov
        p2t2 = c(2)-c(1);
        t2p2 = c(3)-c(1);
        p2p2 = c(3)-c(2);

%         p2t2 = (c(2)-c(1))/t(1)*100;
%         t2p2 = (c(3)-c(1))/t(1)*100;
%         p2p2 = (c(3)-c(2))/t(1)*100;
        
        pre2task = [pre2task,p2t];
        task2post = [task2post,t2p];  
        post2pre = [post2pre, p2p];
        
        pre2task2 = [pre2task2,p2t2];
        task2post2 = [task2post2,t2p2];  
        post2pre2 = [post2pre2, p2p2];
    end
end

% calculate ratio
M1 = mean(pre2task,'omitnan');
M2 = mean(task2post,'omitnan');
M3 = mean(post2pre,'omitnan');
S1 = std(pre2task,'omitnan')/sum(~isnan(pre2task));
S2 = std(task2post,'omitnan')/sum(~isnan(task2post));
S3 = std(post2pre,'omitnan')/sum(~isnan(post2pre));

% calculate cov
C1 = mean(pre2task2,'omitnan');
C2 = mean(task2post2,'omitnan');
C3 = mean(post2pre2,'omitnan');
s1 = std(pre2task2,'omitnan')/sum(~isnan(pre2task2));
s2 = std(task2post2,'omitnan')/sum(~isnan(task2post2));
s3 = std(post2pre2, 'omitnan')/sum(~isnan(post2pre2));

fprintf('\n Pre to Task ratio: %s +/- %s', num2str(M1), num2str(S1))
fprintf('\n Post to Task ratio: %s +/- %s', num2str(M2), num2str(S2))
fprintf('\n Post to Pre ratio: %s +/- %s \n', num2str(M3), num2str(S3))

fprintf('\n Pre to Task CoV: %s +/- %s', num2str(C1), num2str(s1))
fprintf('\n Post to Task CoV: %s +/- %s', num2str(C2), num2str(s2))
fprintf('\n Post to Pre CoV: %s +/- %s \n', num2str(C3), num2str(s3))