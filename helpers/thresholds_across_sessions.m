function thresholds_across_sessions(spth, savedir, parname, day, unit_type, condition,  savefile)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
elseif contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

output = [];

% set static variables
parnames = ["trial_firingrate"; "cl_calcpower"; "vector_strength_cycle_by_cycle"];
sessions = ["Pre", "Active", "Post"];
sex = ["M", "F"];

for i = day
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        presented = round(U(1).UserData.(Parname).vals);
        
        % create output
        clear temp
        temp = {};
        B = [];
        
        % get events and calculate baseline
        for k = 1:length(U)
            
            % pull values
            u = U(k);
            
            if ~isfield(u.UserData.(Parname),'threshold')
                b = NaN;
            else
                b = u.UserData.(Parname).threshold;
            end
            
            % set session
            session = sessions(k);
            
            
            % get subject
            subjid = split(u.Name, '_');
            
            % get sex
            if contains(subjid(1), '228') || contains(subjid(1), '267')
                s = sex(1);
            else
                s = sex(2);
            end
            
            % add to list
            temp{1} = uid(j);
            temp{2} = subjid(1);
            temp{3} = s;
            temp{4} = i;
            temp{5} = u.Type;
            temp{6} = session;
            temp{7} = b;
            output = [output; temp];
        end
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit","Subject", "Sex", "Day", "Type", "Session","Threshold"];

% save as file
if savefile == 1
    sf = fullfile(savedir,append(parname,'_Day', mat2str(day), '_thresholds.csv'));
    fprintf('Saving file %s \n', sf)
    writetable(output,sf);
    fprintf(' done\n')
end

% replace nans with 5 for visualization
output.Threshold(isnan(output.Threshold)) = 5;

% plot
cm = [3, 7, 30; 55, 6, 23; 106, 4, 15; 157, 2, 8; 208, 0, 0; 220, 47, 2; 232, 93, 4;]./255; % session colormap

f = figure;
f.Position = [0, 0, numel(ndays)*200, 250];


x = 1:3;


for d = day
    ax = subplot(1,day,d);
    set(gca, 'TickDir', 'out',...
        'XTickLabelRotation', 0,...
        'TickLength', [0.02,0.02],...
        'LineWidth', 1.5);
    set(findobj(ax,'-property','FontName'),...
        'FontName','Arial')
    ucm = cm(d,:);
    hold on
    
    for i = 1:length(sessions)
        % only on that day
        didx = output.Day == d;
        daydata = output(didx,:);
        
        % get each session
        sidx = contains(daydata{:,:}, sessions{i});
        [row,~] = find(sidx);
        onesession = daydata(row,:);
        smean = mean(table2array(onesession(:,7)), 'omitnan');
        
        daymeans(i) = smean;
    end
    
    plot(daymeans,...
        'Color', ucm,...
        'Marker', 'o',...
        'MarkerFaceColor', ucm,...
        'MarkerSize', 8,...
        'LineWidth', 2)
    
    units = table2struct(output);
    
    for i = day
        currentday = [units.Day] == i;
        means = [units.Threshold];
        currentmeans = means(currentday);
        sess = [units.Session];
        currentsessions = sess(currentday);
        
        for j = 1:3
            seidx = currentsessions == sessions(j);
            meantable(j,:) = currentmeans(seidx);
        end
    end
    
    for i = 1:length(meantable)
        scatter(x,meantable(:,i),...
            'Marker','o',...
            'MarkerFaceColor', ucm,...
            'MarkerFaceAlpha', 0.3,...
            'MarkerEdgeAlpha', 0)
        
        line(x,meantable(:,i),...
            'Color', ucm,...
            'LineWidth',0.75,...
            'LineStyle', ':')
    end
end

xticks([1:3])
xticklabels({'Pre','Active','Post'})
title('Day ', d)
ylabel('Threshold (dB re: 100%)')
ylim([-20 5])

