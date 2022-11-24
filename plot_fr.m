%% overall mean
% 
% fr = table2array(MeanFiringRate12FiringRate);

% fr
day = fr(:,1);
pre = fr(:,2);
active = fr(:,3);
post = fr(:,4);

frm(1) = mean(pre, 'omitnan');
frs(1) = std(pre, 'omitnan');
frse(1) = std(pre, 'omitnan')/sqrt(length(pre));
cv(1) = frs(1)/frm(1);

frm(2) = mean(active, 'omitnan');
frs(2) = std(active, 'omitnan');
frse(2) = std(active, 'omitnan')/sqrt(length(active));
cv(2) = frs(2)/frm(2);

frm(3) = mean(post, 'omitnan');
frs(3) = std(post, 'omitnan');
frse(3) = std(post, 'omitnan')/sqrt(length(post));
cv(3) = frs(3)/frm(3);

% vs
% pre = vs(:,2);
% active = vs(:,3);
% post = vs(:,4);
%
% vsm(1) = mean(pre, 'omitnan');
% vsse(1) = std(pre, 'omitnan')/sqrt(length(pre));
%
% vsm(2) = mean(active, 'omitnan');
% vsse(2) = std(active, 'omitnan')/sqrt(length(active));
%
% vsm(3) = mean(post, 'omitnan');
% vsse(3) = std(post, 'omitnan')/sqrt(length(post));

% f = figure(1);
% f.Position = [0, 0, 500, 750];

hold on
plot(frm,...
    'Marker', 'square',...
    'LineWidth', 5,...
    'Color','#90cca0',...
    'MarkerSize',15,...
    'MarkerFaceColor','#bee1c6')

e1 = errorbar(frm, frse);
e1.Color = '#90cca0';
e1.CapSize = 0;
e1.LineWidth = 5;

% plot(vsm,...
%     'Marker','o',...
%     'LineWidth', 5,...
%     'Color','#208668',...
%     'MarkerSize',15,...
%     'MarkerFaceColor','#3aad87')
%
% e2 = errorbar(vsm, vsse);
% e2.Color = '#208668';
% e2.CapSize = 0;
% e2.LineWidth = 5;

% ylim([10,30])

%% by day

% a = table2array(MeanVScc12FiringRate);
a = table2array(MeanFiringRate12FiringRate);

days = 1:7;

means = nan(7,3);
ses = nan(7,3);
stds = nan(7,3);
cvs = nan(7,3);

for i = 1:7
    idx = find(a(:,1)==i);
    if length(idx) > 1
        subset = a(idx(1):idx(end),:);
    else
        subset = a(idx,:);
    end
    
    m(1) = mean(subset(:,2), 'omitnan');
    sd(1) = std(subset(:,2), 'omitnan');
    se(1) = std(subset(:,2), 'omitnan')/sqrt(length(subset));
    cv(1) = sd(1)/m(1);
    
    m(2) = mean(subset(:,3), 'omitnan');
    sd(2) = std(subset(:,3), 'omitnan');
    se(2) = std(subset(:,3), 'omitnan')/sqrt(length(subset));
    cv(2) = sd(2)/m(2);
    
    m(3) = mean(subset(:,4), 'omitnan');
    sd(3) = std(subset(:,4), 'omitnan');
    se(3) = std(subset(:,4), 'omitnan')/sqrt(length(subset));
    cv(3) = sd(3)/m(3);
    
    means(i,:) = m;
    stds(i,:) = sd;
    ses(i,:) = se;
    cvs(i,:) = cv;
end

f = figure(2);
f.Position = [0, 0, 750, 500];

xoffset = [.99, 1, 1.01];
cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap
hold on

for i = 1:3
    x = log10(1:7);
    mx = x*xoffset(i);
    my = means(:,i);
    plot(mx,my,...
        'Marker','^',...
        'LineStyle', 'none',...
        'Color', cm(i,:),...
        'MarkerSize',8,...
        'MarkerFaceColor', cm(i,:))
    
    % error bar
    e = errorbar(mx, my, ses(:,i));
    e.Color = cm(i,:);
    e.CapSize = 0;
    e.LineWidth = 2;
    
    % set transparency and order
    alpha = 0.3;
    set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
    uistack(e,'bottom');
    
    % fit line
    [fo{i,2},gof(i,2)] = fit(mx',my,'poly1');
    yi = fo{i,2}.p1.*mx + fo{i,2}.p2;
    
    hfitm(i) = line(mx,yi, ...
        'Color',max(cm(i,:),0), ...
        'LineWidth',3);
end

ax = gca;
set([ax.XAxis], ...
    'TickValues',x, ...
    'TickLabels',1:7)
ylim([0,80])
xlabel('Perceptual learning day')
ylabel('Mean firing rate (Hz)')

%% baseline firing
depth = 0.2500;

% baseline = MGNPLallTrialdf(MGNPLallTrialdf.Period == 'Baseline',:);
% baseline = ICPLallTrialdf(ICPLallTrialdf.Period == 'Baseline',:);

pre = baseline(baseline.Session == 'Pre',:);
active = baseline(baseline.Session == 'Active',:);
post = baseline(baseline.Session == 'Post',:);

uid = unique(baseline.Unit);
bfr = {};

for i = 1:length(uid)
    name = char(uid(i));
    bfr{i,1} = name;
    
    % pre
    unit = pre(pre.Unit == uid(i),:);
    %     overall_fr = mean(unit.FR_Hz);
    
    if ~isempty(depth)
        dr = unit(unit.AMdepth == depth,:);
        d_fr = mean(dr.FR_Hz);
        bfr{i,2} = d_fr;
    end
    
    % active
    unit = active(active.Unit == uid(i),:);
    %     overall_fr = mean(unit.FR_Hz);
    
    if ~isempty(depth)
        dr = unit(unit.AMdepth == depth,:);
        d_fr = mean(dr.FR_Hz);
        bfr{i,3} = d_fr;
    end
    
    % post
    unit = post(post.Unit == uid(i),:);
    %     overall_fr = mean(unit.FR_Hz);
    
    if ~isempty(depth)
        dr = unit(unit.AMdepth == depth,:);
        d_fr = mean(dr.FR_Hz);
        bfr{i,4} = d_fr;
    end
end

pre = cell2mat(bfr(:,2));
active = cell2mat(bfr(:,3));
post = cell2mat(bfr(:,4));

frm(1) = mean(pre, 'omitnan');
frse(1) = std(pre, 'omitnan')/sqrt(length(pre));

frm(2) = mean(active, 'omitnan');
frse(2) = std(active, 'omitnan')/sqrt(length(active));

frm(3) = mean(post, 'omitnan');
frse(3) = std(post, 'omitnan')/sqrt(length(post));

f = figure(1);
f.Position = [0, 0, 500, 750];

hold on
plot(frm,...
    'Marker', 'square',...
    'LineWidth', 5,...
    'Color','#000000',...
    'MarkerSize',15,...
    'MarkerFaceColor','#bee1c6')

e1 = errorbar(frm, frse);
e1.Color = '#000000';
e1.CapSize = 0;
e1.LineWidth = 5;

ylim([0,30])

%% extract d'
parname = 'FiringRate';
% parname = 'VScc';
days = 7;
depth = -12;
savedir = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\';
% savedir = 'C:\Users\rose\Documents\Caras\Analysis\MGB recordings\';
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

% make table
headers = {'Cluster','Subject','Day','Pre', 'Aversive','Post'};
dprime = cell2table(cell(0,6),'VariableNames', headers);

for i = 1:days
    Ci = Cday{i};
    
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
        
        if ~isfield(c.UserData.(parname),'threshold')
            c.UserData.(parname).threshold = 0;
        end
        
        if ~isfield(c.UserData.(parname),'p_val')
            c.UserData.(parname).p_val = nan;
        end
    end
    
    alpha = 0.05;
    
    % create lookup table for each cluster
    id = [Ci.Name];
    uid = unique(id);
    flaggedForRemoval = "";
    for j = 1:length(uid)
        ind = uid(j) == id;
        
        % flag if no
        % flag if thresholds are all NaN or 0, or all pvals are NaN or > 0.05
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
            flaggedForRemoval(end+1) = uid(j);
            %             fprintf(2,'ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        else
            %             fprintf('ID %s, thr = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        end
    end
    
    % remove invalid units
    idx = false(1,length(Ci));
    for j = 1:length(Ci)
        if ismember(id(j),flaggedForRemoval)
            idx(j) = 0;
        else
            idx(j) = 1;
        end
    end
    Ci = Ci(idx);
    
    % remove any additional manually flagged units
    note = {Ci.Note};
    removeind = cellfun(@isempty, note);
    Ci = Ci(removeind);
    
    id = [Ci.Name];
    uid = unique(id);
    
    % index into one unit
    for j = 1:length(uid)
        D = nan(1,3);
        
        ind = uid(j) == id;
        Cj = Ci(ind);
        
        for k = 1:length(Cj)
            Ck = Cj(k);
            
            sn = Ck.SessionName;
            
            % determine if depth was presented that day
            
            presented = round(Ck.UserData.(parname).vals);
            
            if sum(ismember(presented,depth) == 1)
                didx = find(presented==depth);
                
                % session
                if contains(sn,"Pre")
                    D(1) = Ck.UserData.(parname).dprime(didx);
                end
                
                if contains(sn,"Aversive")
                    D(2) = Ck.UserData.(parname).dprime(didx);
                end
                
                if contains(sn,"Post")
                    D(3) = Ck.UserData.(parname).dprime(didx);
                end
            end
        end
        
        % id
        cluster = Ck.TitleStr;
        
        s = split(cluster, '_');
        subject = s(1);
        
        day = i;
        
        row = {cluster, subject, day, D(1), D(2), D(3)};
        
        dprime = [dprime; row];
    end 
end

%% plot d' across sessions

day = table2array(dprime(:,3));
pre = table2array(dprime(:,4));
active = table2array(dprime(:,5));
post = table2array(dprime(:,6));

frm(1) = mean(pre, 'omitnan');
frse(1) = std(pre, 'omitnan')/sqrt(length(pre));

frm(2) = mean(active, 'omitnan');
frse(2) = std(active, 'omitnan')/sqrt(length(active));

frm(3) = mean(post, 'omitnan');
frse(3) = std(post, 'omitnan')/sqrt(length(post));

f = figure(1);
f.Position = [0, 0, 450, 500];

hold on
plot(frm,...
    'Marker', 'square',...
    'LineWidth', 5,...
    'Color','#90cca0',...
    'MarkerSize',15,...
    'MarkerFaceColor','#bee1c6')

e1 = errorbar(frm, frse);
e1.Color = '#90cca0';
e1.CapSize = 0;
e1.LineWidth = 5;

ylim([-0.2 1])
ylabel('d')

%% plot d' by day

% a = table2array(MeanVScc12FiringRate);
% a = table2array(MeanFiringRate12FiringRate);
a = table2array(dprime(:,3:6));

days = 1:7;

means = nan(7,3);
ses = nan(7,3);

for i = 1:7
    idx = find(a(:,1)==i);
    if length(idx) > 1
        subset = a(idx(1):idx(end),:);
    else
        subset = a(idx,:);
    end
    
    m(1) = mean(subset(:,2), 'omitnan');
    se(1) = std(subset(:,2), 'omitnan')/sqrt(length(subset));
    
    m(2) = mean(subset(:,3), 'omitnan');
    se(2) = std(subset(:,3), 'omitnan')/sqrt(length(subset));
    
    m(3) = mean(subset(:,4), 'omitnan');
    se(3) = std(subset(:,4), 'omitnan')/sqrt(length(subset));
    
    means(i,:) = m;
    ses(i,:) = se;
end

f = figure(2);
f.Position = [0, 0, 750, 500];

xoffset = [.99, 1, 1.01];
cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap
hold on

for i = 1:3
    x = log10(1:7);
    mx = x*xoffset(i);
    my = means(:,i);
    plot(mx,my,...
        'Marker','^',...
        'LineStyle', 'none',...
        'Color', cm(i,:),...
        'MarkerSize',8,...
        'MarkerFaceColor', cm(i,:))
    
    % error bar
    e = errorbar(mx, my, ses(:,i));
    e.Color = cm(i,:);
    e.CapSize = 0;
    e.LineWidth = 2;
    
    % set transparency and order
    alpha = 0.3;
    set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
    uistack(e,'bottom');
    
    % fit line
    [fo{i,2},gof(i,2)] = fit(mx',my,'poly1');
    yi = fo{i,2}.p1.*mx + fo{i,2}.p2;
    
    hfitm(i) = line(mx,yi, ...
        'Color',max(cm(i,:),0), ...
        'LineWidth',3);
end

ax = gca;
set([ax.XAxis], ...
    'TickValues',x, ...
    'TickLabels',1:7)
ylim([-0.5,1.1])
xlabel('Perceptual learning day')
ylabel('d')