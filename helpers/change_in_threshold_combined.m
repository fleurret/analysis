function output = change_in_threshold_combined(savedir, spth, parx, pary, ndays, unit_type, condition)

% convert parnames to correct label
if strcmp(parx,'FiringRate')
    parx = 'trial_firingrate';
    x_label = 'Firing Rate';
end

if strcmp(pary,'FiringRate')
    pary = 'trial_firingrate';
    y_label = 'Firing Rate';
end

if strcmp(parx,'Power')
    parx = 'cl_calcpower';
    x_label = 'Power';
end

if strcmp(pary,'Power')
    pary = 'cl_calcpower';
    y_label = 'Power';
end

if strcmp(parx,'VScc')
    parx = 'vector_strength_cycle_by_cycle';
    x_label = 'VScc';
end

if strcmp(pary,'VScc')
    pary = 'vector_strength_cycle_by_cycle';
    y_label = 'VScc';
end

% load neural
fn = 'Cday_original.mat';
load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% plot settings
f = figure;
f.Position = [0, 0, 600, 600];
ax = gca;
axis(ax,'equal');
axis(ax,'square');
set(ax,'xlim', [-15 15],...
    'ylim', [-15 15],...
    'LineWidth', 1.2,...
    'TickDir', 'out',...
    'TickLength', [0.02,0.02]);
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

xline(0)
yline(0)

output = [];
sex = ["M", "F"];
av = {'Aversive', 'Active'};

for i = ndays
    Ci_x = filterunits(savedir, parx, Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, pary, Cday, i, unit_type, condition);
    
    Ci = union(Ci_x, Ci_y);
    
    % replace NaN with 0
    for j = 1:length(Ci)
        if isnan(Ci(j).UserData.(parx).threshold)
            Ci(j).UserData.(parx).threshold = 0;
        end
        
        if isnan(Ci(j).UserData.(pary).threshold)
            Ci(j).UserData.(pary).threshold = 0;
        end
    end
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for k = 1:length(uid)
        ind = uid(k) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        x = ones(1,3);
        y = ones(1,3);
        px = ones(1,3);
        py = ones(1,3);
        temp = {};
        
        for j = 1:length(U)
            
            if contains(U(j).SessionName,'Pre')
                x(1) = U(j).UserData.(parx).threshold;
                y(1) = U(j).UserData.(pary).threshold;
                px(1) = U(j).UserData.(parx).p_val;
                py(1) = U(j).UserData.(pary).p_val;
            end
            
            if contains(U(j).SessionName, av)
                x(2) = U(j).UserData.(parx).threshold;
                y(2) = U(j).UserData.(pary).threshold;
                px(2) = U(j).UserData.(parx).p_val;
                py(2) = U(j).UserData.(pary).p_val;
            end
            
            if contains(U(j).SessionName, 'Post')
                x(3) = U(j).UserData.(parx).threshold;
                y(3) = U(j).UserData.(pary).threshold;
                px(3) = U(j).UserData.(parx).p_val;
                py(3) = U(j).UserData.(pary).p_val;
            end
        end
        
        x = x(1:2);
        y = y(1:2);
        
        % set to nan if invalid
        if all(px > 0.05)
            x = zeros(1,3);
        end
        
        if all(py > 0.05)
            y = zeros(1,3);
        end

        % ignore units that didnt change between pre and active
        if sum(x) == 0 && sum(y) == 0
            continue
        end
        
        % calculate vector components
        xcomp = x(2)- x(1);
        ycomp = y(2)- y(1);
        V = sqrt(xcomp^2 + ycomp^2);
        
        if isnan(V)
            V = 0;
        end
        
        a = atand(ycomp/xcomp);
        
        % correct angle
        if xcomp < 0
            a = a - 180;
        end
        
        if ycomp < 0
            a = a - 180;
        end
        
        a = deg2rad(abs(a));
        
        % get subject
        subjid = split(U(1).Name, '_');
        
        % get sex
        if contains(subjid(1), '228') || contains(subjid(1), '267')
            s = sex(1);
        else
            s = sex(2);
        end
        
        % add to list
        temp{1} = uid(k);
        temp{2} = subjid(1);
        temp{3} = s;
        temp{4} = i;
        temp{5} = V;
        temp{6} = xcomp;
        temp{7} = ycomp;
        temp{8} = a;
        
        output = [output; temp];
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Unit", "Subject", "Sex", "Day", "Magnitude", "X component", "Y component", "Angle"];

% save as file
sf = fullfile(savedir,append('vectors.csv'));
fprintf('Saving file %s \n', sf)
writetable(output,sf);
fprintf(' done\n')

% calculate average vector
%     avgM = mean([output{:,3}], 'omitnan');
avgX = mean([output{:,6}], 'omitnan');
avgY = mean([output{:,7}], 'omitnan');
%     avgA = mean([output{:,6}], 'omitnan');

% plot individual vectors
for j = 1:height(output)
    hold on
    X(1) = 0;
    Y(1) = 0;
    X(2) = [output{j,6}];
    Y(2) = [output{j,7}];
    
    for k = 1:2
        scatter(ax,X(k), Y(k),...
            'Marker', 'none')
    end
    
    h1 = annotation('arrow');
    set(h1, 'parent', gca,...
        'X', X,...
        'Y', Y,...
        'LineWidth', 1.2,...
        'Color', '#c4c4c4',...
        'HeadLength', 10,...
        'HeadWidth', 10,...
        'HeadStyle', 'vback3');
end

% plot mean vector
xm = [0 avgX];
ym = [0 avgY];

h2 = annotation('arrow');
set(h2, 'parent', gca,...
    'X', xm,...
    'Y', ym,...
    'LineWidth', 2.5,...
    'HeadLength', 7,...
    'HeadWidth', 7,...
    'HeadStyle', 'ellipse');
xlabel(ax, append('\Delta', x_label, ' threshold'),...
    'FontWeight','bold',...
    'FontSize', 15);
ylabel(ax,append('\Delta', y_label, ' threshold'),...
    'FontWeight','bold',...
    'FontSize', 15);






