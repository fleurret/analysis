function coding_strategy(spth, savedir, ndays, unit_type, condition)

load(fullfile(savedir,'Cday_original.mat'));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

fr = 0;
vscc = 0;
both = 0;

output = [];
s1 = ["Pre", "Active", "Post"];
s2 = ["Pre", "Aversive", "Post"];


for i = ndays
    Ci_x = filterunits(savedir, 'trial_firingrate', Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, 'vector_strength_cycle_by_cycle', Cday, i, unit_type, condition);
    Ci = union(Ci_x, Ci_y);
    
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
        fr_threshold = [U(1).UserData.trial_firingrate.threshold, U(2).UserData.trial_firingrate.threshold, U(3).UserData.trial_firingrate.threshold];
        vscc_threshold = [U(1).UserData.vector_strength_cycle_by_cycle.threshold, U(2).UserData.vector_strength_cycle_by_cycle.threshold, U(3).UserData.vector_strength_cycle_by_cycle.threshold];
        
        if sum(isnan(fr_threshold)) == 3
            vscc = vscc + 1;
            continue
        elseif sum(isnan(vscc_threshold)) == 3
            fr = fr + 1;
            continue
        else
            both = both + 1;
            
            temp{1,1} = U(1).SessionName;
            temp{1,2} = U(1).UserData.trial_firingrate.threshold;
            temp{1,3} = U(1).UserData.vector_strength_cycle_by_cycle.threshold;
            
            temp{2,1} = U(2).SessionName;
            temp{2,2} = U(2).UserData.trial_firingrate.threshold;
            temp{2,3} = U(2).UserData.vector_strength_cycle_by_cycle.threshold;
            
            temp{3,1} = U(3).SessionName;
            temp{3,2} = U(3).UserData.trial_firingrate.threshold;
            temp{3,3} = U(3).UserData.vector_strength_cycle_by_cycle.threshold;
            
            output = [output; temp];
        end
    end
end

% convert to table
output = cell2table(output);
output.Properties.VariableNames = ["Session", "FR", "VScc"];

for i = 1:height(output)
    if isnan(output.FR(i))
        output.FR(i) = 5;
    end
    
    if isnan(output.VScc(i))
        output.VScc(i) = 5;
    end
end

% plot
cm = [77,127,208; 52,228,234; 2,37,81;]./255; % session colormap
f = figure;
f.Position = [0, 0, 1200, 500];

% plot by session
for i = 1:3
    session = {str2mat(s1(i)), str2mat(s2(i))};
    ind = contains(output.Session, session);
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
    
    tx = table2array(data(:,2));
    ty = table2array(data(:,3));
    
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
    
    xlabel(ax(i),{'FR Threshold (dB)'});
    ylabel(ax(i),{'VScc Threshold (dB)'});
    set(findobj(ax(i),'-property','FontName'),...
        'FontName','Arial')
end

sgtitle(f,'Threshold Coding Comparisons Across Days');

fprintf('FR only = %s \n', num2str(fr))
fprintf('VScc only = %s \n', num2str(vscc))
fprintf('Both = %s \n', num2str(both))