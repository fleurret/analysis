function bvsn_pop(behavdir, savedir, parname, ndays, unit_type, condition)

% get subjects
subjects = dir(behavdir);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% format subjs
subjs = strcat('SUBJ-ID-', {subjects.name});

% load neural
fn = 'Cday_original.mat';
% fn = strcat(fn,(parname),'.mat');
load(fullfile(savedir,fn));

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

sessionName = ["Pre","Task","Post"];
av = {'Aversive', 'Active'};

% marker settings
cm = [223, 143, 234; 155, 95, 224; 40, 83, 221; 145, 209, 249; 58, 186, 137; 190, 232, 163]./255; % session colormap

tc = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

% set figure
f = figure;
f.Position = [0, 0, 1500, 600];

ax(1) = subplot(131,'parent',f);
ax(2) = subplot(132,'parent',f);
ax(3) = subplot(133,'parent',f);

hold(ax,'on')

% axes etc
set(ax, 'TickDir', 'out',...
    'XTickLabelRotation', 0,...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3);
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

for i = 1:length(ax)
    ax(i).XLim = [-20, -5];
    ax(i).YLim = [-15, 0];
end

set([ax.XAxis], ...
    'FontSize',12);
set([ax.YAxis],...
    'FontSize',12);

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xlabel(ax,'Behavioral threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 12);
ylabel(ax,'Neural threshold (dB re: 100%)',...
    'FontWeight','bold',...
    'FontSize', 12);

% neural data
thr = cell(size(days));
sidx = thr;

xall = nan(length(subjs),7);
yall = cell(1,3);

for i = 1:length(yall)
    yall{i} = nan(length(subjs),7);
end

for j = 1:length(subjs)
    
    % load subj behavior
    bfolder = fullfile(behavdir, subjects(j).name);
    bfile = dir(fullfile(bfolder,'*.mat'));
    ffn = fullfile(bfolder,bfile.name);
    load(ffn)
    
    fitdata = [output.fitdata];
    bthr = [fitdata.threshold];
    xall(j,:) = bthr(ndays);
    
    for i = ndays
        Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
        
        % only that subject
        idx = contains([Ci.Name],subjs{j});
        Ci = Ci(idx);
        
        y = arrayfun(@(a) a.UserData.(Parname),Ci,'uni',0);
        ind = cellfun(@(a) isfield(a,'ERROR'),y);
        
        y(ind) = [];
        Ci(ind) = [];
        
        y = [y{:}];
        
        if ~isempty(y)
            thr{i} = [y.threshold];
            sidx{i} = nan(size(y));
            
            sn = [Ci.Session];
            sn = [sn.Name];
            sidx{i}(contains(sn,"Pre")) = 1;
            sidx{i}(contains(sn,av)) = 2;
            sidx{i}(contains(sn,"Post")) = 3;
        else
            continue
        end
        
        for k = 1:3 % plot each session seperately
            ind = sidx{i} == k;
            
            % neural means
            yi = mean(thr{i}(ind),'omitnan');
            yall{k}(j,i) = yi;
            
            % plot
            scatter(ax(k),bthr(i),yi,...
                'Marker', 'o',...
                'SizeData', 80,...
                'MarkerFaceColor', cm(j,:),...
                'MarkerEdgeAlpha', 0)

        end
    end
end

% fit and corr
for k = 1:3
    sthr = yall{k};
    sz = size(sthr);
    sthr = reshape(sthr,1,sz(1)*sz(2));
    xthr = reshape(xall,1,sz(1)*sz(2));
    
    idx = isnan(sthr);
    xf = xthr(~idx);
    yf = sthr(~idx);
    
    coefficients = polyfit(xf, yf, 1);
    xFit = linspace(min(xf), max(xf), 1000);
    yFit = polyval(coefficients , xFit);
    
    hfit(k) = line(ax(k),xFit,yFit, ...
        'Color',tc(k,:), ...
        'LineWidth',3);
    
    [R,P] = corrcoef(xthr,sthr,'rows','complete');
    PR{k} = R;
    PRP{k} = P;
end

% set title
for k = 1:3
    title(ax(k),sprintf('%s (%s)',sessionName(k),parname),...
    'FontSize',15);
end

axis(ax,'square');

fprintf('Pre R = %s, p = %s \n', num2str(PR{1}(2)), num2str(PRP{1}(2)))
fprintf('Active R = %s, p = %s \n', num2str(PR{2}(2)), num2str(PRP{2}(2)))
fprintf('Post R = %s, p = %s \n', num2str(PR{3}(2)), num2str(PRP{3}(2)))