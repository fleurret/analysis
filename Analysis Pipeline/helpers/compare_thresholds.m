function compare_thresholds(savedir, parx, pary, ndays, unit_type, condition, shownans, savefile)

% convert parnames to correct label
if strcmp(parx,'FiringRate')
    parx = 'trial_firingrate';
end

if strcmp(pary,'FiringRate')
    pary = 'trial_firingrate';
end

if strcmp(parx,'Power')
    parx = 'cl_calcpower';
end

if strcmp(parx,'Power')
    pary = 'cl_calcpower';
end

if strcmp(parx,'VScc')
    parx = 'vector_strength_cycle_by_cycle';
end

if strcmp(pary,'VScc')
    pary = 'vector_strength_cycle_by_cycle';
end

output = [];
sessions = ["Pre", "Active", "Post"];
sex = ["M", "F"];
av = {'Aversive', 'Active'};

% load clusters
load(fullfile(savedir,'Cday_original.mat'));

thr = cell(size(ndays));
sidx = thr;
didx = thr;

for i = ndays
    Ci_x = filterunits(savedir, parx, Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, pary, Cday, i, unit_type, condition);
    Ci = union(Ci_x, Ci_y);
    
    % replace NaN thresholds
    if shownans == 1
        for j = 1:length(Ci)
            if isnan(Ci(j).UserData.(parx).threshold)
                Ci(j).UserData.(parx).threshold = 5;
            end
            
            if isnan(Ci(j).UserData.(pary).threshold)
                Ci(j).UserData.(pary).threshold = 5;
            end
        end
    end
    
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        temp = {};
        bx = [];
        by = [];
        
        % get threshold
        for k = 1:length(U)
            
            % set session
            session = sessions(k);
            
            % find the right session in cluster
            sns = [U.SessionName];
            
            if k == 1
                cind = contains(sns, "Pre");
            elseif k == 2
                cind = contains(sns, av);
            elseif k == 3
                cind = contains(sns, "Post");
            end

            u = U(cind);
            bx = u.UserData.(parx).threshold;
            by = u.UserData.(pary).threshold;
            
            % get subject
            subjid = split(u.Name, '_');
            
            % get sex
            if contains(subjid(1), '228') || contains(subjid(1), '267')
                s = sex(1);
            else
                s = sex(2);
            end
            
            % add to lists
            temp{1} = u.SessionName;
            temp{2} = subjid(1);
            temp{3} = s;
            temp{4} = i;
            temp{5} = u.Type;
            temp{6} = session;
            temp{7} = bx;
            temp{8} = by;
            output = [output; temp];
        end
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit", "Subject", "Sex","Day", "Type", "Session", parx, pary];

% save as file
if savefile == 1
    sf = fullfile(savedir,append('comparethresholds.csv'));
    fprintf('Saving file %s \n', sf)
    writetable(output,sf);
    fprintf(' done\n')
end

% plot
cm = [77,127,208; 96,216,216; 2,37,81;]./255;% session colormap
f = figure;
f.Position = [0, 0, 1200, 500];

% plot by session
for i = 1:3
    
    session = sessions(i);
    ind = output.Session == session;
    data = output(ind,:);

    % set plot
    ax(i) = subplot(1,3,i);
    set(gca, 'TickDir', 'out',...
        'XTickLabelRotation', 0,...
        'TickLength', [0.02,0.02],...
        'TickDir', 'out',...
        'LineWidth', 1.5,...
        'XDir', 'reverse',...
        'YDir', 'reverse',...
        'XLim', [-21 5],...
        'YLim', [-21 5],...
        'XAxisLocation', "origin",...
        'YAxisLocation', "origin");
    set(findobj(ax,'-property','FontName'),...
        'FontName','Arial')
    hold on
    
    tx = table2array(data(:,7));
    ty = table2array(data(:,8));
    
    scatter(ax(i),tx,ty,...
        'Marker','o',...
        'SizeData', 100,...
        'MarkerFaceColor',cm(i,:),...
        'MarkerEdgeColor', 'none',...
        'MarkerFaceAlpha', 0.3);
    
    xline(0)
    yline(0)
    axis(ax(i),'equal');
    axis(ax(i),'square');
    
    xlabel(ax(i),{'Threshold (dB)';parx});
    ylabel(ax(i),{'Threshold (dB)';pary});
    set(findobj(ax(i),'-property','FontName'),...
        'FontName','Arial')
end



sgtitle(f,'Threshold Coding Comparisons Across Days');

clear output