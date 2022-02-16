function bvsn(behavdir, savedir, parname, maxdays, subj)

% load behavior
pth = fullfile(behavdir,subj);
d = dir(fullfile(pth,'*.mat'));
ffn = fullfile(d.folder,d.name);

load(ffn, 'output')

for i = 1:length(output)
    a(i) = output(i).fitdata;
end

behav = [a.threshold];

% load neural
fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');
load(fullfile(savedir,fn));

sessionName = ["Pre","Active","Post"];

% marker settings
mk = '^^^';
cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap

% set figure
f = figure(sum(uint8(parname)));

clf(f);

ax(1) = subplot(131,'parent',f);
ax(2) = subplot(132,'parent',f);
ax(3) = subplot(133,'parent',f);

set(ax,...
    'xlim', [-16,-5],...
    'ylim', [-16,-5]);

% neural data
days = 1:min(maxdays,length(Cday));

thr = cell(size(days));
sidx = thr;

xall = nan(3,7);

for k = 1:3 % plot each session seperately
    for i = 1:length(days)
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
        
        % restrict to subject
        subj_idx = zeros(1,length(Ci));
        for j = 1:length(Ci)
            cs = convertCharsToStrings(Ci(j).Subject);
            if contains(cs,subj)
                subj_idx(j) = 1;
            else
                subj_idx(j) = 0;
            end
        end
        subj_idx = logical(subj_idx);
        Ci = Ci(subj_idx);
        
        % remove any additional manually flagged units
        note = {Ci.Note};
        removeind = cellfun(@isempty, note);
        Ci = Ci(removeind);
        
        y = arrayfun(@(a) a.UserData.(parname),Ci,'uni',0);
        ind = cellfun(@(a) isfield(a,'ERROR'),y);
        
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
            sidx{i}(contains(sn,"Aversive")) = 2;
            sidx{i}(contains(sn,"Post")) = 3;
        end
        
        ind = sidx{i} == k;
        
        % neural means
        xi = mean(thr{i}(ind),'omitnan');
        xall(k,i) = xi;
        if isnan(xi)
            continue
        end
        
        % behavior
        yi = behav(i);
        
        line(ax(k),xi,yi,...
            'Marker', 'o',...
            'MarkerSize', 8,...
            'LineStyle','none',...
            'Color', cm(k,:),...
            'MarkerFaceColor', cm(k,:));
        
        % set title
        title(ax(k),sprintf('%s (%s)',sessionName(k),parname),...
            'FontSize',15);
    end
    % axes etc
    set([ax.XAxis], ...
        'FontSize',12);
    set([ax.YAxis],...
        'FontSize',12);
    ax(1).YAxis.Label.Rotation = 90;
    ax(2).YAxis.Label.Rotation = 90;
    
    set(findobj(ax,'-property','FontName'),...
        'FontName','Arial')
   
    xlabel(ax,'Neural threshold (dB re: 100%)',...
        'FontWeight','bold',...
        'FontSize', 12);
    ylabel(ax,'Behavioral threshold (dB re: 100%)',...
        'FontWeight','bold',...
        'FontSize', 12);
    
end

grid(ax(1),'off');
grid(ax(2),'off');

axis(ax,'square');

hfit = [];

% fit lines
for i = 1:3
    xi = xall(i,:);
    yi = behav(1:maxdays);
    
    ind = isnan(xi);
    
    xi(ind) = [];
    yi(ind) = [];
    
    
    coefficients = polyfit(xi, yi, 1);
    xFit = linspace(min(xi), max(xi), 1000);
    yFit = polyval(coefficients , xFit);
    
    hfit(i) = line(ax(i),xFit,yFit, ...
        'Color',max(cm(i,:),0), ...
        'LineWidth',3);
    
    [R,P] = corrcoef(xi,yi);
    PR{i} = R;
    PRP{i} = P;
end

fprintf('Pre R = %s, p = %s \n', num2str(PR{1}(2)), num2str(PRP{1}(2)))
fprintf('Active R = %s, p = %s \n', num2str(PR{2}(2)), num2str(PRP{2}(2)))
fprintf('Post R = %s, p = %s \n', num2str(PR{3}(2)), num2str(PRP{3}(2)))
