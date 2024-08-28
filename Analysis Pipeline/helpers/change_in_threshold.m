function output = change_in_threshold(savedir, spth, parx, pary, ndays, unit_type, condition)

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
f.Position = [0, 0, 1700, 250];
tiledlayout(1, length(ndays))

for i = ndays
    % make subplot
    ax(i) = nexttile;
    
    % set axes etc.
    axis(ax(i),'equal');
    axis(ax(i),'square');
    set(ax(i),'xlim', [-15 15],...
        'ylim', [-15 15],...
        'LineWidth', 1.2,...
        'TickDir', 'out',...
        'TickLength', [0.02,0.02]);
    
    xline(0)
    yline(0)
    
    output = [];
    
    Ci_x = filterunits(savedir, parx, Cday, i, unit_type, condition);
    Ci_y = filterunits(savedir, pary, Cday, i, unit_type, condition);
    
    Ci = union(Ci_x, Ci_y);
    
    % only valid clusters
    id = [Ci.Name];
    uid = unique(id);
    
    % isolate units across sessions
    for j = 1:length(uid)
        ind = uid(j) == id;
        U = Ci(ind);
        
        % create output
        clear temp
        temp = {};
        
        % get thresholds
        x = nan(1,2);
        y = nan(1,2);
        
        for k = 1:3
            u = U(k);
            sn = u.SessionName;
            
            if contains(sn, 'Post')
                continue
            elseif contains(sn, 'Pre')
                xthr = u.UserData.(parx).threshold;
                ythr = u.UserData.(pary).threshold;
                
                if isnan(xthr)
                    x(1) = 0;
                else
                    x(1) = xthr;
                end
                
                if isnan(ythr)
                    y(1) = 0;
                else
                    y(1) = ythr;
                end
            else
                xthr = u.UserData.(parx).threshold;
                ythr = u.UserData.(pary).threshold;
                
                if isnan(xthr)
                    x(2) = 0;
                else
                    x(2) = xthr;
                end
                
                if isnan(ythr)
                    y(2) = 0;
                else
                    y(2) = ythr;
                end
            end
        end
        
        % ignore units that didnt change between pre and active
        if sum(x) == 0 && sum(y) == 0
            continue
        end
        
        % calculate vector components
        xcomp = x(2)- x(1);
        ycomp = y(2)- y(1);
        V = sqrt(xcomp^2 + ycomp^2);
        a = rad2deg(atan(ycomp/xcomp));
        
        % add to list
        temp{1} = uid(j);
        temp{2} = i;
        temp{3} = V;
        temp{4} = xcomp;
        temp{5} = ycomp;
        temp{6} = a;
        
        output = [output; temp];
    end
    
    % plot
    %         for k = 1:2
    %             hold on
    %             scatter(ax(i),x(k),y(k), 75,...
    %                 'Marker','o',...
    %                 'MarkerFaceColor',cm(i,:),...
    %                 'MarkerFaceAlpha', 0.3,...
    %                 'MarkerEdgeAlpha', 0);
    %         end
    %
    %         h = annotation('arrow');
    %         set(h,'parent', gca, ...
    %             'X', x,...
    %             'Y', y,...
    %             'HeadLength', 4, 'HeadWidth', 4, 'HeadStyle', 'ellipse');
    %
    %         set(ax(i), 'xdir', 'reverse',...
    %             'ydir', 'reverse',...
    %             'xlim', [-25 5],...
    %             'ylim', [-25 5]);
    
    % calculate average vector
    %     avgM = mean([output{:,3}], 'omitnan');
    avgX = mean([output{:,4}], 'omitnan');
    avgY = mean([output{:,5}], 'omitnan');
    %     avgA = mean([output{:,6}], 'omitnan');
    
    % plot individual vectors
    for j = 1:length(output)
        hold on
        X(1) = 0;
        Y(1) = 0;
        X(2) = [output{j,4}];
        Y(2) = [output{j,5}];
        
        for k = 1:2
            scatter(ax(i),X(k), Y(k),...
                'Marker', 'none')
        end
        
        h1 = annotation('arrow');
        set(h1,'parent', gca, ...
            'X', X,...
            'Y', Y,...
            'HeadLength', 4,...
            'HeadWidth', 4,...
            'HeadStyle', 'vback2');
    end
    
    % plot mean vector
    xm = [0 avgX];
    ym = [0 avgY];
    
    h2 = annotation('arrow');
    set(h2, 'parent', gca,...
        'X', xm,...
        'Y', ym,...
        'LineWidth', 1,...
        'Color', '#cb83e6',...
        'HeadLength', 3,...
        'HeadWidth', 3,...
        'HeadStyle', 'ellipse');
    
    title('Day ', i)
    xlabel(append('\Delta', x_label, ' threshold'))
    ylabel(append('\Delta', y_label, ' threshold'))
end


