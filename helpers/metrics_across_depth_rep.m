function metrics_across_depth_rep(spth, savedir, parname, ndays, unit_type, condition, cn)

% Plot individual unit thresholds and means across days

% correlation coefficient is set to Spearman's

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

% load neural
fn = 'Cday_';
fn = strcat(fn,(Parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

minNumSpikes = 0;
maxNumDays = 7;

% set properties
sessionName = ["Pre","Active","Post"];
av = {'Aversive', 'Active'};

cm = [77,127,208; 52,228,234; 2,37,81;]./255;% session colormap
mk = '^^^';

f = figure;
f.Position = [0, 0, 500, 450];

ax = gca;
xlim([-28, -6])
ylim([-0.4, 0.8]);

set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

DV = cell(size(days));
sidx = DV;
didx = DV;

% neural data
for i = ndays
    Ci = filterunits(savedir, Parname, Cday, i, unit_type, condition);
    
    s = [Ci.Name];
    units = unique(s);
    
    if cn > length(units)
        error('Unit does not exist :(')
    end
    
    % only the representative unit
    for j = cn
        uidx = units(j) == s;
        U = Ci(uidx);
        dd = arrayfun(@(a) a.UserData.(Parname),U,'uni',0);
        
        dd = [dd{:}];
        dprimes = {dd.dprime};
        dsz = cellfun('size', dprimes, 1);
        
        for b = 1:length(dprimes)
            z = flip(dprimes{b});
            if all(dsz == dsz(1))
                DP(b,:) = z;
            else
                if length(dprimes{b})~= max(dsz)
                    dif = max(dsz)-length(dprimes{b});
                    Dif = 1:dif;
                    
                    for k = 1:length(Dif)
                        z(length(dprimes{b})+Dif(k)) = NaN;
                    end
                    DP(b,:) = z;
                else
                    DP(b,:) = z;
                end
            end
        end
        
        sn = [U.Session];
        sn = [sn.Name];
        sidx{i}(contains(sn,"Pre")) = 1;
        sidx{i}(contains(sn,av)) = 2;
        sidx{i}(contains(sn,"Post")) = 3;
        
        vals = {dd.vals};
        %         weights = {dd.weights};
        
        %       get values
        for j = 1:3
            u = U(j);
            depths = vals{j};
            
            clear yvals
            clear stds
          
            for k = 1:length(depths)
                depth = depths(k);
                [mAM, mNAM, cAM, cNAM] = calc_mas(u, Parname, depth);
                yvals(k) = mAM;
                stds(k) = cAM*mAM;
            end
            
            hold on
            scatter(depths, yvals, 120,...
                'MarkerFaceColor', cm(j,:),...
                'MarkerEdgeAlpha',0)
            scatter(-26, mNAM, 120,...
                'MarkerFaceColor', cm(j,:),...
                'MarkerEdgeAlpha',0)
            line(depths,yvals,...
                'Color', cm(j,:),...
                'LineWidth', 2)
            errorbar(depths,yvals,stds,...
                'Color', cm(j,:),...
                'CapSize', 0,...
                'LineWidth', 0.75)
            errorbar(-26, mNAM, cNAM*mNAM,...
                'Color', cm(j,:),...
                'CapSize', 0,...
                'LineWidth', 0.75)
            legend('Pre','','Active','','Post',...
                'location', 'northwest',...
                'FontSize', 24)
            legend boxoff
        end
    end
end

% % axes etc
set([ax.XAxis], ...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3,...
    'FontSize',36);
set([ax.YAxis],...
    'TickDir','out',...
    'TickLength', [0.02,0.02],...
    'LineWidth', 3,...
    'FontSize',36);
ax(1).YAxis.Label.Rotation = 90;

xlabel(ax,'dB SPL re: 100%',...
    'FontWeight','bold',...
    'FontSize', 36);
ylabel(ax,parname,...
    'FontWeight','bold',...
    'FontSize', 36);
