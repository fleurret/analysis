function cov_combined(parname, spth, savedir, ndays, type, unit_type, condition, depth, savefile)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
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

for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        temp = {};
        b = [];
        
        % get events and calculate baseline
        for k = 1:length(U)
            
            % set session
            session = sessions(k);
            
            % pull values
            u = U(k);
            [~, ~, cAM, cNAM] = calc_mas(u, Parname, depth);
            
            if strcmp(type, 'AM')
                b = cAM;
            else
                b = cNAM;
            end
            
            if isempty(b)
                b = NaN;
            end
            
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
output.Properties.VariableNames = ["Unit", "Subject", "Sex","Day", "Type", "Session", "CoV"];

% save as file
if savefile == 1
    sf = fullfile(savedir,append(Parname,'_',type, 'CoV.csv'));
    fprintf('Saving file %s \n', sf)
    writetable(output,sf);
    fprintf(' done\n')
end

% plot
cm = [3, 7, 30; 55, 6, 23; 106, 4, 15; 157, 2, 8; 208, 0, 0; 220, 47, 2; 232, 93, 4;]./255; % session colormap
f = figure;
f.Position = [0, 0, 500, 625];

x = 1:3;

ax = gca;
set(gca, 'TickDir', 'out',...
    'XTickLabelRotation', 0,...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3);
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

for d = 1:length(ndays)
    ucm = cm(1,:);
    hold on
    
    smean = nan(1,3);
    for i = 1:length(sessions)
        sidx = output.Session == sessions{i};
        sdata = output(sidx,:);
        smean(i) = mean(table2array(sdata(:,7)), 'omitnan');
    end
    
    plot(smean,...
        'Color', ucm,...
        'Marker', 'o',...
        'MarkerFaceColor', ucm,...
        'MarkerSize', 18,...
        'LineWidth', 2)
    
    units = table2struct(output);
    
    currentday = [units.Day] == d;
    means = [units.CoV];
    currentmeans = means(currentday);
    sess = [units.Session];
    currentsessions = sess(currentday);
    
    for j = 1:3
        seidx = currentsessions == sessions(j);
        meantable(j,:) = currentmeans(seidx);
    end
    
    [~, cols] = size(meantable);
    
    for j = 1:cols
        if d == 1 && j == 10
            scatter(x,meantable(:,j), 120,...
                'Marker','o',...
                'MarkerFaceColor', '#cb83e6',...
                'MarkerFaceAlpha', 0.5,...
                'MarkerEdgeAlpha', 1)
            
            line(x,meantable(:,j),...
                'Color', '#cb83e6',...
                'LineWidth',0.75,...
                'LineStyle', ':')
        else
            
            scatter(x,meantable(:,j),120,...
                'Marker','o',...
                'MarkerFaceColor', ucm,...
                'MarkerFaceAlpha', 0.3,...
                'MarkerEdgeAlpha', 0)
            
            line(x,meantable(:,j),...
                'Color', ucm,...
                'LineWidth',0.75,...
                'LineStyle', ':')
        end
    end
    
    clear meantable
    
end

xticks([1:3])
xlim([0.8 3])
set(gca,'XTickLabelMode','auto',...
    'FontSize', 36)
xticklabels({'Pre','Task','Post'})

xlabel(ax,'Session','FontSize',36,...
    'FontWeight','bold')
ylabel(ax,'CoV',...
    'FontSize', 36);

if strcmp(Parname, 'trial_firingrate')
    ylim([0 2])
end

if strcmp(Parname, 'cl_calcpower')
    ylim([0 5])
end

if strcmp(Parname, 'vector_strength_cycle_by_cycle')
    ylim([0 50])
end