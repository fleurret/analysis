function plot_units(spth, behavdir, savedir, parname, ndays, subj, condition, unit_type, sv)

% Plot individual unit thresholds and means across days

% correlation coefficient is set to Spearman's

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    titlepar = 'Firing Rate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    titlepar = 'Power';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
    titlepar = 'VScc';
end

% load behavior
if subj == "all"
    load(fullfile(behavdir,'behavior_combined.mat'));
else
    pth = fullfile(behavdir,subj);
    d = dir(fullfile(pth,'*.mat'));
    ffn = fullfile(d.folder,d.name);
    
    load(ffn, 'output')
    for i = 1:length(output)
        a(i) = output(i).fitdata;
    end
    
    behav_os = [a.threshold];
    
    clear a
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

% vars for output file
unit = [];
subj_id = [];
sx = [];
thrs = [];
day = [];
session = [];
valid = [];

% set properties
sessionName = ["Pre","Active","Post"];
sex = ["M", "F"];

cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

mk = '^^^';
xoffset = [.99, 1, 1.01];

f = figure;
f.Position = [0, 0, 1200, 375];
set(f,'color','w');
clf(f);
ax = subplot(121,'parent',f);
ax(2) = subplot(122,'parent',f);

thr = cell(size(ndays));
sidx = thr;
didx = thr;

% neural data
count = zeros(1,3);

for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    
        % replace NaN thresholds
        for j = 1:length(Ci)
            if isnan(Ci(j).UserData.(Parname).threshold)
                Ci(j).UserData.(Parname).threshold = 0;
            end
        end
    
    % only one sex
    %     for j = 1:length(Ci)
    %         if contains(Ci(j).Name, 'SUBJ-ID-228') || contains(Ci(j).Name, 'SUBJ-ID-267')
    %             idx(j) = 0;
    %         else
    %             idx(j) = 1;
    %         end
    %     end
    %
    %     idx = logical(idx);
    %     Ci = Ci(idx);
    %
    %     clear idx
    
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
    
    
    
    y = arrayfun(@(a) a.UserData.(Parname),Ci,'uni',0);
    ind = cellfun(@(a) isfield(a,'ERROR'),y);
    uinfo = arrayfun(@(a) a.Name, Ci);
    
    y(ind) = [];
    Ci(ind) = [];
    
    y = [y{:}];
    
    if ~isempty(y)
        thr{i} = [y.threshold];
        
        didx{i} = ones(size(y))*i;
        sidx{i} = nan(size(y));
        
        sn = [Ci.Session];
        sn = [sn.Name];
        sidx{i}(contains(sn,"Pre")) = 1;
        sidx{i}(contains(sn,"Active")) = 2;
        sidx{i}(contains(sn,"Aversive")) = 2;
        sidx{i}(contains(sn,"Post")) = 3;
        x = 1+ones(size(thr{i}))*log10(ndays(i));
    else
        continue
    end
    
    for j = 1:3 % plot each session seperately
        ind = sidx{i} == j;
        xi = x*xoffset(j);
        n_mean(j,i) = mean(thr{i}(ind),'omitnan');
        
        % calculate number of valid units
        count(j) = count(j) + sum(~isnan(thr{i}(ind)));
        
        % individual points
        h = line(ax(1),xi(ind),thr{i}(ind), ...
            'LineStyle','none',...
            'Marker',mk(j),...
            'Color',(cm(j,:)), ...
            'MarkerFaceColor',cm(j,:), ...
            'MarkerSize',10,...
            'ButtonDownFcn',{@cluster_plot_callback,Ci(ind),xi(ind),thr{i}(ind),Parname});
        
        % means and error bars
        xi = mean(xi);
        yi = mean(thr{i}(ind),'omitnan');
        yi_std = std(thr{i}(ind),'omitnan');
        yi_std = yi_std / (sqrt(length(thr{i}(ind))-1));
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
            'MarkerSize',10);
        
        % get info for output
        U = uinfo(ind);
        
        if isempty(U)
            continue
        else
            
            for z = 1:length(U)
                Subj = split(U(z), '_cluster');
                subjlist(z) = Subj(1);
                
                if contains(U(z), '228') || contains(U(z), '267')
                    sx = [sx, sex(1)];
                else
                    sx = [sx, sex(2)];
                end
                
                TR = thr{i}(ind);
                if isnan(TR(z))
                    valid = [valid, "0"];
                else
                    valid = [valid, "1"];
                end
            end
            
            unit = [unit; U'];
            subj_id = [subj_id; subjlist'];
            thrs = [thrs; thr{i}(ind)'];
            day = [day; ones(length(thr{i}(ind)), 1)*i];
            session = [session; repelem(sessionName(j), length(thr{i}(ind)), 1)];
            
            clear subjlist
        end
    end
end

grid(ax(1),'off');
grid(ax(2),'off');

q = [sidx{:}];
r = [thr{:}];
d = [didx{:}];
clear p s m
hfit = [];
fo = cell(1,3);

% fit lines
for i = 1:3
    ind = q == i & ~isnan(r);
    
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

if ~any(hfit == 0)
    uistack(hfit,'bottom');
end

% Pearson's R
for i = 1:3
    smean = n_mean(i,:);
    z = ~(isnan(smean));
    [n_PR,n_P]= corr(smean(z)', ndays(z)', 'type','Spearman');
    PR{i} = n_PR;
    PRP{i} = n_P;
end

% behavior data
if subj == "all"
    behav_mean = behav_mean(1:7);
    behav_std = behav_std(1:7);
else
    behav_mean = behav_os(1:7);
end

x = log10(ndays)+1;
xoffset = 0.98;
x = x*xoffset;

bplot = line(ax(2),x,behav_mean,...
    'Marker', 'o',...
    'MarkerSize', 8,...
    'MarkerFaceColor', '#ff7bb1',...
    'LineStyle', 'none',...
    'Color', '#ff7bb1');

xi = log10(1:7);
[b_fo,~] = fit(xi',behav_mean','poly1');
yi = b_fo.p1.*xi + b_fo.p2;

% fit
bfit = line(ax(2), xi+1, yi,...
    'DisplayName', sprintf('Behavior (%.2f)', b_fo.p1),...
    'LineWidth',3,...
    'Color','#ff7bb1');

% error bars
if subj == "all"
    e = errorbar(ax(2), (xi+1)*xoffset,behav_mean, behav_std);
    e.LineStyle = 'none';
    e.LineWidth= 2;
    e.Color = '#ff7bb1';
    e.CapSize = 0;
    
    % set transparency
    alpha = 0.3;
    set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*alpha])
    uistack(e, 'bottom');
end

% Pearson's R
[b_PR,b_P] = corrcoef(behav_mean, xi);

% axes etc
set([ax.XAxis], ...
    'TickValues',log10(ndays)+1, ...
    'TickLabels',arrayfun(@(a) num2str(a,'%d'),ndays,'uni',0),...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 1.5,...
    'FontSize',12);
set([ax.YAxis],...
    'TickDir','out',...,
    'TickLength', [0.02,0.02],...
    'LineWidth', 1.5,...
    'FontSize',12);
ax(1).XLim = [0.8,1.95];
ax(2).XLim = [0.8,1.95];
ax(1).YTick = [-20 -15 -10 -5 0];
ax(2).YTick = [-20 -15 -10 -5 0];
ax(1).YLim = [-20,2];
ax(2).YLim = [-20,2];

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xlabel(ax,'Psychometric testing day',...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,'Threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 15);
title(ax,sprintf('%s (n = %d)',titlepar,length(subjects)),...
    'FontSize',15);

legend(hfit,'Location','southwest','FontSize',12, 'box', 'off');
legend([hfitm,bfit],'Location','southwest','FontSize',12, 'box', 'off');

fprintf('Behavior R = %s, p = %s \n', num2str(b_PR(2)), num2str(b_P(2)))
fprintf('Pre R = %s, p = %s \n', num2str(PR{1}), num2str(PRP{1}))
fprintf('Active R = %s, p = %s \n', num2str(PR{2}), num2str(PRP{2}))
fprintf('Post R = %s, p = %s \n', num2str(PR{3}), num2str(PRP{3}))
fprintf('%s Pre, %s Active, %s Post', num2str(count(1)), num2str(count(2)), num2str(count(3)))

% save as file
if sv == 1
    output = [unit, subj_id, sx', day, thrs, session, valid'];
    output = array2table(output);
    output.Properties.VariableNames = ["Unit", "Subject", "Sex", "Day", "Threshold", "Session", "Validity"];
    
    sf = fullfile(savedir,append(parname,'_threshold_zero.csv'));
    fprintf('\n Saving file %s ...', sf)
    writetable(output,sf);
    fprintf(' done\n')
    
    
end