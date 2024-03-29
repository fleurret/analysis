function plot_dprime(spth, savedir, parname, subj, unit_type, depth, condition, sv)

% Plot individual and mean d' across days for a given depth

% correlation coefficient is set to Spearman's

% convert parname to correct label
if contains(parname,'FiringRate')
    parname = 'trial_firingrate';
    titlepar = 'Firing Rate';
    
elseif contains(parname,'Power')
    parname = 'cl_calcpower';
    titlepar = 'Power';
    
else contains(parname,'VScc')
    parname = 'vector_strength_cycle_by_cycle';
    titlepar = 'VScc';
end

% load neural
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 7;

% vars for output file
unit = [];
subj_id = [];
thr = [];
day = [];
session = [];

% set properties
sessionName = ["Pre","Active","Post"];

cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

mk = '^^^';
xoffset = [.99, 1, 1.01];

f = figure;
f.Position = [0, 0, 1000, 350];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
ylim([-0.5 3])
ax(2) = subplot(122,'parent',f);
ylim(ax(2),[-0.5 3])

days = 1:min(maxNumDays,length(Cday));

DV = cell(size(days));
sidx = DV;
didx = DV;

% neural data
count = zeros(1,3);

for i = 1:length(days)
    Ci = Cday{i};
    
    % first make sure that there is a threshold/p_val field for the "parname"
    % threshold = NaN means curve did not cross d' = 1
    % threshold = 0 means there were no spikes/failed to compute threshold
    for j = 1:length(Ci)
        c = Ci(j);
        
        if contains(c.SessionName, 'FreqTuning')
            continue
        end
        
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
        
        % flag if threesholds are all NaN or 0, or all pvals are NaN or > 0.05
        t = arrayfun(@(a) a.UserData.(parname).threshold,Ci(ind));
        pval = arrayfun(@(a) a.UserData.(parname).p_val,Ci(ind));
        if sum(t,'omitnan') == 0 || all(isnan(pval)) || ~any(pval<=alpha)
            flaggedForRemoval(end+1) = uid(j);
            %             fprintf(2,'ID %s, DV = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        else
            %             fprintf('ID %s, DV = %s , pval = %s\n',uid(j),mat2str(t,2),mat2str(pval,2))
        end
    end
    
    % flag if fit is negative
    id = [Ci.Name];
    uid = unique(id);
    flaggedForRemoval = "";
    for j = 1:length(uid)
        ind = nan(1,length(uid));
        ind = uid(j) == id;
        yfit = arrayfun(@(a) a.UserData.(parname).yfit,Ci(ind),'UniformOutput',false);
        for k = 1:length(Ci(ind))
            syfit = yfit{k};
            curve = [syfit(1), syfit(500), syfit(1000)];
            
            if curve(1) > curve(2) && curve(2) > curve(3) && sum(yfit{k}>1) > 0
                flaggedForRemoval(end+1) = uid(j);
            end
        end
    end
    
    idx = false(1,length(Ci));
    for j = 1:length(Ci)
        if ismember(id(j),flaggedForRemoval)
            idx(j) = 0;
        else
            idx(j) = 1;
        end
    end
    Ci = Ci(idx);
    
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
    
    % only plot one subject
    if subj ~= "all"
        subj_idx = zeros(1,length(Ci));
        
        for j = 1:length(Ci)
            if Ci(j).Subject == ""
                nsubj = append(subj,"_");
                cs = convertCharsToStrings(Ci(j).Name);
                if contains(cs,nsubj)
                    subj_idx(j) = 1;
                else
                    subj_idx(j) = 0;
                end
            else
                cs = convertCharsToStrings(Ci(j).Subject);
                if contains(cs,subj)
                    subj_idx(j) = 1;
                else
                    subj_idx(j) = 0;
                end
            end
        end
        
        subj_idx = logical(subj_idx);
        Ci = Ci(subj_idx);
    end
    
    % only plot one condition
    if condition ~= "all"
        if condition == "w"
            ffn = fullfile(savedir,'thresholds_worsened.mat');
            load(ffn)
            
            subset = worsened;
        end
        
        if condition == "i"
            ffn = fullfile(savedir,'thresholds_improved.mat');
            load(ffn)
            
            subset = improved;
        end
        
        id = [Ci.Name];
        uid = unique(id);
        
        j = 1:length(subset);
        subj_idx = cell2mat(subset(j,2)) == i;
        wid = subset(subj_idx);
        wid = [wid{:}];
        
        flaggedForRemoval = "";
        
        for k = 1:length(uid)
            ind = uid(k) == wid;
            if sum(ind) == 0
                flaggedForRemoval(end+1) = uid(k);
            end
        end
        
        idx = false(1,length(Ci));
        
        for j = 1:length(Ci)
            if ismember(id(j),flaggedForRemoval)
                idx(j) = 0;
            else
                idx(j) = 1;
            end
        end
        Ci = Ci(idx);
    end
    
    % remove multiunits
    if unit_type == "SU"
        removeind = [Ci.Type] == "SU";
        Ci = Ci(removeind);
    end
    
    y = arrayfun(@(a) a.UserData.(parname),Ci,'uni',0);
    ind = cellfun(@(a) isfield(a,'ERROR'),y);
    uinfo = arrayfun(@(a) a.Name, Ci);
    
    y(ind) = [];
    Ci(ind) = [];
    
    y = [y{:}];
    
    if ~isempty(y)
        
        % find depth
        dp = [];
        
        for k = 1:length(y)
            v = y(k).vals;
            
            clear V
            
            for z = 1:length(v)
                V(z) = round(v(z));
            end
            
            grp = y(k).dprime;
            pind = V == depth;
            
            if sum(pind) == 0
                dp = NaN;
            end
            
            dp = [dp, grp(pind)];
        end
        
        %         if isempty(dp)
        %             DV{i} = NaN;
        %         else
        %             DV{i} = dp;
        %         end
        
        DV{i} = dp;
        didx{i} = ones(size(y))*i;
        sidx{i} = nan(size(y));
        
        sn = [Ci.Session];
        sn = [sn.Name];
        sidx{i}(contains(sn,"Pre")) = 1;
        sidx{i}(contains(sn,"Aversive")) = 2;
        sidx{i}(contains(sn,"Post")) = 3;
        x = 1+ones(size(DV{i}))*log10(days(i));
    else
        continue
    end
    
    
    for j = 1:3 % plot each session seperately
        
        ind = sidx{i} == j;
        xi = x*xoffset(j);
        n_mean(j,i) = mean(DV{i}(ind),'omitnan');
        
        % calculate number of valid units
        
        count(j) = count(j) + sum(~isnan(DV{i}(ind)));
        
        % individual points
        h = line(ax(1),xi(ind),DV{i}(ind), ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',(cm(j,:)), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',8,...
            'ButtonDownFcn',{@cluster_plot_callback,Ci(ind),xi(ind),DV{i}(ind),parname});
        
        % means and error bars
        xi = mean(xi);
        yi = mean(DV{i}(ind),'omitnan');
        yi_std = std(DV{i}(ind),'omitnan');
        yi_std = yi_std / (sqrt(length(DV{i}(ind))-1));
        hold on
        e = errorbar(ax(2),xi,yi,yi_std);
        e.Color = cm(j,:);
        e.CapSize = 0;
        e.LineWidth = 2;
        
        % set transparency and order
        alpha = 0.3;
        set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
        uistack(e,'bottom');
        
        h = line(ax(2),xi,yi, ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',max(cm(j,:),0), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',8);
        
        % get info for output
        U = uinfo(ind);
        
        for z = 1:length(U)
            Subj = split(U(z), '_cluster');
            subjlist(z) = Subj(1);
        end
        
        unit = [unit; U'];
        subj_id = [subj_id; subjlist'];
        thr = [thr; DV{i}(ind)'];
        day = [day; ones(length(DV{i}(ind)), 1)*i];
        session = [session; repelem(sessionName(j), length(DV{i}(ind)), 1)];
        
        clear subjlist
    end
end

grid(ax(1),'off');
grid(ax(2),'off');

Z = [sidx{:}];
r = [DV{:}];
d = [didx{:}];
clear p s m
hfit = [];
fo = cell(1,3);

% fit lines
for i = 1:3
    ind = Z == i & ~isnan(r);
    
    dd = d(ind);
    dr = r(ind);
    
    xi = log10(dd)';
    if length(xi) < 2
        continue
    end
    [fo{i,1},gof(i,1)] = fit(xi,dr','poly1');
    
    yi = fo{i,1}.p1.*xi + fo{i,1}.p2;
    
    hfit(i) = line(ax(1),1+xi,yi, ...
        'Color',max(cm(i,:),0), ...
        'DisplayName',sprintf('%s (%.2f)',sessionName(i),fo{i,1}.p1),...
        'LineWidth',3);
    
    udd = unique(dd);
    mdr = nan(size(udd));
    for j = 1:length(udd)
        dind = dd == udd(j);
        mdr(j) = mean(dr(dind),'omitnan');
    end
    
    xi = log10(udd);
    [fo{i,2},gof(i,2)] = fit(xi',mdr','poly1');
    
    yi = fo{i,2}.p1.*xi + fo{i,2}.p2;
    
    hfitm(i) = line(ax(2),1+xi,yi, ...
        'Color',max(cm(i,:),0), ...
        'DisplayName',sprintf('%s (%.2f)',sessionName(i),fo{i,2}.p1),...
        'LineWidth',3);
    
end
uistack(hfit,'bottom');

% Pearson's R
for i = 1:3
    smean = n_mean(i,:);
    z = ~(isnan(smean));
    [n_PR,n_P]= corr(smean(z)', days(z)', 'type','Spearman');
    PR{i} = n_PR;
    PRP{i} = n_P;
end

% axes etc
set([ax.XAxis], ...
    'TickValues',log10(days)+1, ...
    'TickLabels',arrayfun(@(a) num2str(a,'%d'),days,'uni',0),...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 1.5,...
    'FontSize',12);
set([ax.YAxis],...
    'TickDir','out',...,
    'TickLength', [0.02,0.02],...
    'LineWidth', 1.5,...
    'FontSize',12);
ax(1).YAxis.Label.Rotation = 90;
ax(2).YAxis.Label.Rotation = 90;

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xlabel(ax,'Psychometric testing day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'d''',...
    'FontWeight','bold',...
    'FontSize', 15);
title(ax,sprintf('%s (n = %d)',titlepar,length(subjects)),...
    'FontSize',15);

legend(ax(1), hfit,'Location','northwest','FontSize',12, 'box', 'off');

legend(ax(2), [hfitm],'Location','northwest','FontSize',12, 'box', 'off');

fprintf('Pre R = %s, p = %s \n', num2str(PR{1}), num2str(PRP{1}))
fprintf('Active R = %s, p = %s \n', num2str(PR{2}), num2str(PRP{2}))
fprintf('Post R = %s, p = %s \n', num2str(PR{3}), num2str(PRP{3}))
fprintf('%s Pre, %s Active, %s Post \n', num2str(count(1)), num2str(count(2)), num2str(count(3)))

% save as file
if sv == 1
    output = [unit, subj_id, day, thr, session];
    
    sf = fullfile(savedir,append(parname,'_dprime_',num2str(depth),'.csv'));
    fprintf('Saving file %s \n', sf)
    writematrix(output,sf);
    fprintf(' done\n')
end
