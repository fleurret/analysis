function bvsn(behavdir, savedir, parname, ndays, subj, unit_type, condition)

% load subj behavior
subjects = dir(behavdir);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

bfolder = fullfile(behavdir, subj);
bfile = dir(fullfile(bfolder,'*.mat'));
ffn = fullfile(bfolder,bfile.name);
load(ffn)

fitdata = [output.fitdata];
bthr = [fitdata.threshold];
xall = bthr(ndays);

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
mk = '^^^';
cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

% set figure
f = figure;
f.Position = [0, 0, 1500, 600];
hold on

ax(1) = subplot(131,'parent',f);
ax(2) = subplot(132,'parent',f);
ax(3) = subplot(133,'parent',f);

% neural data
thr = cell(size(days));
sidx = thr;

yall = nan(1,7);

for k = 1:3 % plot each session seperately
    for i = ndays
        Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
        
        % restrict to subject
        subj_idx = zeros(1,length(Ci));
        
        c = [Ci.Name];
        sind = contains(c, subj);
        Ci = Ci(sind);
        
        if isempty(Ci)
            continue
        end
        
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
        end
        
        ind = sidx{i} == k;
        
        % neural means
        xi = mean(thr{i}(ind),'omitnan');
        yall(i) = xi;
        
    end
    
    % plot
    scatter(ax(k),xall,yall,...
        'Marker', 'o',...
        'SizeData', 80,...
        'MarkerFaceColor', cm(k,:),...
        'MarkerEdgeAlpha', 0)
    
    % fit and corr
    
    if isnan(xall)
        continue
    end
    
    idx = isnan(yall);
    xf = xall(~idx);
    yf = yall(~idx);
    
    coefficients = polyfit(xf, yf, 1);
    xFit = linspace(min(xf), max(xf), 1000);
    yFit = polyval(coefficients , xFit);
    
    hfit(k) = line(ax(k),xFit,yFit, ...
        'Color',max(cm(k,:),0), ...
        'LineWidth',3);
    
    [R,P] = corrcoef(xall,yall,'rows','complete');
    PR{k} = R;
    PRP{k} = P;
    
    % set title
    title(ax(k),sprintf('%s (%s)',sessionName(k),parname),...
        'FontSize',15);
    
    % axes etc
    set(ax(k), 'TickDir', 'out',...
        'XTickLabelRotation', 0,...
        'TickLength', [0.02,0.02],...
        'LineWidth', 3);
    set(findobj(ax,'-property','FontName'),...
        'FontName','Arial')

    ax(k).XLim = [-20,-5];
    ax(k).YLim = [-15,0];
    
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
    
    if k == 2
        fprintf('Slope = %s \n', num2str(coefficients(1)))
    end
end


grid(ax(1),'off');
grid(ax(2),'off');

axis(ax,'square');

fprintf('Pre R = %s, p = %s \n', num2str(PR{1}(2)), num2str(PRP{1}(2)))
fprintf('Active R = %s, p = %s \n', num2str(PR{2}(2)), num2str(PRP{2}(2)))
fprintf('Post R = %s, p = %s \n', num2str(PR{3}(2)), num2str(PRP{3}(2)))