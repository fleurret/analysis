%% Load files
% expecting invidual SUBJ folders with Session mat files, one for each day
pth = 'C:\Users\Rose\OneDrive\Documents\Caras\Data';

% subj = '202';
subj = '222';
% subj = '223';
% subj = '224';

pth = fullfile(pth,subj);

d = dir(fullfile(pth,'*.mat'));

%% ONLY NEED TO RUN ONCE TO CONVERT CLUSTERS TO SESSIONS
% strips waveforms, rebuilds any clusters into sessions
for i = 1:length(d)
    ffn = fullfile(d(i).folder,d(i).name);
    
    clear S
    
    fprintf('Loading %s ...',d(i).name)
    load(ffn)
    fprintf(' done\n')
    
    
    
%     if ~isempty(who('-file',ffn,'S'))
%         fprintf(2,'"%s" already contains a Session object, skipping\n',d(i).name)
%         arrayfun(@disp,[S.Name])
%         continue
%     end
    

    if ~exist('S','var')


        % an array of Cluster objects was saved and not just the Session
        % objects, but we can recover the original Session from its property.
        S = unique([C.Session]);
    end


    S = [S.find_Session("Pre"), S.find_Session("Aversive"), S.find_Session("Post")];
    
    
    for j = 1:length(S)
        arrayfun(@remove_waveforms,S(j).Clusters);
        S(j).Subject = subj;
    end
    
    arrayfun(@disp,[S.Name])
    
    
    fprintf('Saving %s ...',d(i).name);
    save(ffn,'S')
    fprintf(' done\n')
    
    clear S
end


%% Analyses specified metric

logTransformEventValues = true;

par = [];
par.event = "AMdepth";
par.referenceval = 0;
par.window = [0 1];
par.modfreq = 5;


parname = [];

% par.metric = @epa.metric.trial_firingrate; parname = 'FiringRate';
% par.metric = @epa.metric.tmtf; parname = 'TMTF'; % use the temporal Modualation Transfer Function metric
% par.metric = @epa.metric.vector_strength; parname = 'VS';
% par.metric = @epa.metric.vector_strength_phase_projected; parname = 'VSpp';
% par.metric = @epa.metric.vector_strength_cycle_by_cycle; parname = 'VScc';
par.metric = @epa.metric.cl_calcpower; parname = 'Power';


if isequal(parname,'Power') && isempty(which('chronux.m'))
    addpath(genpath('C:\Users\Rose\OneDrive\Documents\GitHub\chronux'));
%     addpath(genpath('C:\Users\Daniel\src\chronux_2_12\'));
end


for i = 1:length(d)
    
    ffn = fullfile(d(i).folder,d(i).name);
    
    fprintf('Loading %s ...',ffn)
    load(ffn)
    fprintf(' done\n')
        
    
    C = [S.Clusters];
    

    for k = 1:numel(C) % DO NOT USE PARFOR!
        Ck = C(k);
        fprintf('Computing %s and neurometric d'' for %s %s - %s\n', ...
            parname,Ck.Subject,Ck.TitleStr,Ck.SessionName)
        
        tpar = par;
        
        CkS = Ck.Session;
    
        % remove reminder trials
        ev = CkS.find_Event("Reminder");
        ind = ev.Values == 1;
        ev.remove_trials(ind);
        
        CkS.find_Event(par.event).remove_trials(ind);
        
        [dp,v,M,V] = Ck.neurometric_dprime(tpar);
        
        
        if logTransformEventValues
            ind = v == 0;
            v(~ind) = 20*log10(v(~ind));
            v(ind)  = -120;
            
            ind = V == 0;
            V(~ind) = 20*log10(V(~ind));
            V(ind)  = -120;
        end
        
        % store the results along with the Cluster object
        Ck.UserData.(parname) = [];
        Ck.UserData.(parname).M      = M;
        Ck.UserData.(parname).V      = V;
        Ck.UserData.(parname).dprime = dp;
        Ck.UserData.(parname).vals   = v;
        Ck.UserData.(parname).lastUpdate = datestr(clock);
    end
    
    fprintf('Saving %s ...',ffn);
    save(ffn,'S')
    fprintf(' done\n')
end





%% Compute neurometric fits


minNTrials = 5;

minNValues = 3;

targDPrimeThreshold = 1;



% parname = 'FiringRate';
% parname = 'VScc';
% parname = 'VSpp';
% parname = 'VS';
parname = 'Power';

for i = 1:length(d)
    
    ffn = fullfile(d(i).folder,d(i).name);
    
    fprintf('Loading %s ...',ffn)
    load(ffn)
    fprintf(' done\n')
        
    
    C = [S.Clusters];
    
    for k = 1:numel(C) % DO NOT USE PARFOR!
        dprimeThreshold = targDPrimeThreshold;
        
        Ck = C(k);
        
        
        fprintf('Fitting "%s" neurometric d'' for %s %s\n',parname,Ck.TitleStr,Ck.Session.Name)
        
        
        if ~isfield(Ck.UserData,parname) || isfield(Ck.UserData.(parname),'ERROR')
            fprintf(2,'Cluster "%s" does not have "%s" analysed\n',Ck.TitleStr,parname)
            continue
        end
        
        ndp = Ck.UserData.(parname);
        
        v = ndp.vals;
        dp = ndp.dprime;
        V = ndp.V;
        M = ndp.M;
        
        dp(isinf(dp)) = nan;
        if isempty(dp) || all(isnan(dp))
            Ck.UserData.(parname).ERROR = dp;
            fprintf(2,'Failed to compute for Cluster "%s"\n',Ck.TitleStr)
            continue
        end
        
        % weight fit by the number of trials per value
        w = arrayfun(@(a) sum(V==a),v);
        
        ind = w < minNTrials;
        
        v(ind) = [];
        dp(ind) = [];
        w(ind) = [];
        
        if isempty(v) || all(isnan(dp))
            Ck.UserData.(parname).ERROR = dp;
            fprintf(2,'No trials remaining or all NaN for "%s"\n',Ck.TitleStr)
            continue
        end
        
        % fit the data with a sigmoidal function
        [xfit,yfit,p_val] = epa.analysis.fit_sigmoid(v,dp,w);
        
        
        
        % determine where on the x-axis intersects with the neurometric curve
        % at dprimeThreshold
        if length(v) >= minNValues && max(yfit) >= dprimeThreshold
            try
                valAtThreshold = spline(yfit,xfit,dprimeThreshold);
            catch
                % spline doesn't like some extreme fits, so fall back on
                % finding the nearest point
                [~,m] = min((yfit - dprimeThreshold).^2);
                valAtThreshold = xfit(m);
            end
        else
            valAtThreshold = nan;
        end
        
        % make sure threshold is within the limits of the actual stimulus
        if valAtThreshold > max(v)
            valAtThreshold = nan;
        end
        
        % pick the lowest d' if all d' values are greater than
        % dprimeThreshold
        if valAtThreshold <= min(xfit) && any(dp > 1)
            [m,q] = min(yfit);
            if m >= dprimeThreshold
                dprimeThreshold = m;
                valAtThreshold = xfit(q);
            else
                valAtThreshold = nan;
            end
        end
        
        % find inflection point, if there is one
        dy = gradient(yfit,xfit);
        [m_infl,idy] = max(dy);
        x_infl = xfit(idy);
        y_infl = yfit(idy);
        
        if any(x_infl == [min(v) max(v)])
            x_infl = nan;
            y_infl = nan;
            m_infl = nan;
        end
        
        %             h = plot(v,dp,'o',xfit,yfit,'-k',...
        %                 valAtThreshold,dprimeThreshold,'sm', ...
        %                 x_infl,y_infl,'+r');
        %             ylabel('d''');
        %             xlabel(par.event)
        %             title(Ck.TitleStr)
        %             set(h([3 4]),'LineWidth',2)
        %             grid on
        %             pause
        
        % store the results along with the Cluster object
        Ck.UserData.(parname).xfit   = xfit;
        Ck.UserData.(parname).yfit   = yfit;
        Ck.UserData.(parname).x_infl = x_infl;
        Ck.UserData.(parname).y_infl = y_infl;
        Ck.UserData.(parname).m_infl = m_infl;
        Ck.UserData.(parname).fit_gradient = dy;
        Ck.UserData.(parname).p_val  = p_val;
        Ck.UserData.(parname).weights = w;
        Ck.UserData.(parname).threshold = valAtThreshold;
        Ck.UserData.(parname).dprimeThreshold = dprimeThreshold;
        Ck.UserData.(parname).lastUpdate = datestr(clock);
    end
    
    fprintf('Saving %s ...',ffn);
    save(ffn,'S')
    fprintf(' done\n')
end





%% Plot neurometric d'
% parname = 'FiringRate';
% parname = 'VScc';
parname = 'VSpp';
% parname = 'VS';
% parname = 'Power';


day = 2;
ffn = fullfile(d(day).folder,d(day).name);

fprintf('Loading %s ...',d(day).name)
load(ffn)
fprintf(' done\n')


C = [S.Clusters];


f = figure('color','w');

ncol = 3;

ucid = unique([C.ID]);
nrow = length(ucid);


t = tiledlayout(f,nrow,ncol);
t.TileSpacing = 'none';
t.Padding = 'none';



for i = 1:numel(C)
    Ck = C(i);
    
%     row = double(Ck.ID);
    ind = ucid == Ck.ID;
    row = find(ind);

    
    if contains(Ck.Session.Name,"Pre")
        col = 1;
    elseif contains(Ck.Session.Name,"Post")
        col = 3;
    else
        col = 2;
    end
    
    ax = nexttile(t,sub2ind([ncol nrow],col,row));
    
    ndp = Ck.UserData.(parname);
    
    if isfield(ndp,'ERROR'), continue; end
    
    h = plot(ax, ...
        ndp.vals,ndp.dprime,'--o', ...
        ndp.xfit,ndp.yfit,'-k', ...
        ndp.threshold,ndp.dprimeThreshold,'+r');
    
    h(3).MarkerSize = 10;
    h(3).LineWidth = 2;
    
    
    grid(ax,'on');
    ax.YAxis.TickLabelFormat = '%.1f';
    
    if col == 1
        ax.YAxis.Label.String = sprintf('%d %s',Ck.ID,Ck.Type);
    elseif col == 3
        ax.YAxis.Label.String = Ck.Name;
        ax.YAxisLocation = 'right';
    end
    
    if row == 1
        ax.Title.String = Ck.Session.Name;
    end
    
end
title(t,parname);








%% compare neurometric threshold to log10(day)


% parname = 'FiringRate';
parname = 'VScc';
% parname = 'VS';
% parname = 'Power';

alpha = 0.05;

thr = [];
thr_fit = [];

for day = 1:length(d)
    
    ffn = fullfile(d(day).folder,d(day).name);
    
    fprintf('Loading %s ...',d(day).name)
    load(ffn)
    fprintf(' done\n')
    
    %     C = S.common_Clusters;
    C = [S.Clusters];
    
    
    for k = 1:numel(C)
        
        for j = 1:length(S)
            
            sC = S(j).find_Cluster(C(k).Name);
            if ~isa(sC,'epa.Cluster'), continue; end
            
            if isempty(sC.UserData)
                continue
            end
            
            if ~isfield(sC.UserData.(parname),'threshold')
                continue
            end
           
            
            x = sC.UserData.(parname).threshold;
            
            if sC.UserData.(parname).p_val > alpha ...
                    || x <= 0
                x = nan;
            end
            
            thr(j,day).(sC.Name) = x;
        end
    end
    
end

fn = fieldnames(thr);
for i = 1:numel(thr)
    for j = 1:length(fn)
        if isempty(thr(i).(fn{j}))
            thr(i).(fn{j}) = nan;
        end
    end
end

% thr(Session,Day).(clusterName) -> y(Cluster,Day,Session)
y = [];
for i = 1:size(thr,1)
    for j = 1:length(fn)
        y(j,:,i) = [thr(i,:).(fn{j})];
    end
end

% linear -> dB
y = 20*log10(y./1);

% fit each Session over log10(days)
days = 1:size(y,2);
x = log10(days);
clear pfit s mu
for i = 1:size(y,3)
    ys = y(:,:,i);
    yf = []; xf = [];
    for j = 1:size(ys,2)
        t = ys(:,j);
        t(isnan(t)) = [];
        yf = [yf; t];
        xf = [xf; ones(size(t))*x(j)];
    end
    [pfit(i,:),s(i),mu(:,i)] = polyfit(xf,yf,1);
end


%


f = figure(sum(uint8(parname)));
clf(f);

set(f,'color','w');

ax = axes(f);

cm = [.4 .4 .4; .2 1 .2; .6 .6 .6]; % session colormap
mk = '^sv';
xoffset = [.99, 1, 1.01];

days = 1:size(y,2);

% y(Cluster,Day,Session)
x = 1+ones(size(y,1),1)*log10(days);
for i = 1:size(y,3)
    yi = y(:,:,i);
    xi = x*xoffset(i);
    line(xi,yi,...
        'LineStyle','none',...
        'Marker',mk(i),...
        'Color',max(cm(i,:)-.2,0), ...
        'MarkerFaceColor',cm(i,:));
    
    xfit = log10(days);
    yfit = polyval(pfit(i,:),xfit,s(i),mu(:,i));
    line(x,yfit,'Color',cm(i,:));
end

ax.XAxis.TickValues = log10(days)+1;
ax.XAxis.TickLabels = arrayfun(@(a) num2str(a,'%d'),days,'uni',0);
ax.YAxis.Label.Rotation = 90;

set(findobj(ax,'-property','FontName'),'FontName','Consolas')

xlabel(ax,'day');
% ylabel(ax,sprintf('AM depth @ d''=%d (dB)',dprimeThreshold));
title(ax,parname);

grid(ax,'on');
box(ax,'on');


%% compare thresholds from different metrics

% parx = 'Power';
% parx = 'FiringRate';
% parx = 'VS';
pary = 'VScc';


i = 1;
ffn = fullfile(d(i).folder,d(i).name);

fprintf('Loading %s ...',d(i).name)
load(ffn)
fprintf(' done\n')

C = S.common_Clusters;

f = figure('color','w');

t = tiledlayout(f,numel(C),length(S));
t.TileSpacing = 'none';
t.Padding = 'none';




for i = 1:numel(C)
    for j = 1:length(S)
        
        ax(i,j) = nexttile(t);
        sC = S(j).find_Cluster(C(i).Name);
        
        if isfield(sC.UserData.(parx),'ERROR') || isfield(sC.UserData.(pary),'ERROR'), continue; end
        
        x = sC.UserData.(parx).M;
        y = sC.UserData.(pary).M;
        v = sC.UserData.(pary).V; % should be equal for x and y
        uv = unique(v);
        depthColors = parula(length(uv));
        
        y = abs(y);
        
        cm = nan(length(v),3);
        for k = 1:length(uv)
            ind = uv(k) == v;
            cm(ind,:) = repmat(depthColors(k,:),sum(ind),1);
        end
        
        h = scatter(ax(i,j),x,y,10,cm);
        
        ylim([0 1]);
    end
end

%% Plot metric values
% parname = 'VSpp';

ffn = fullfile(d(2).folder,d(2).name);    
fprintf('Loading %s ...',ffn)
load(ffn)
fprintf(' done\n')
    
Z = S(3).find_Cluster(sprintf('cluster%d',2273));
x = Z.UserData.VSpp.V;
y = Z.UserData.VSpp.M;

xu = unique(x);

for i = 1:length(xu)
   ind = xu(i) == x;
   yi = y(ind);
   yi_m(i) = mean(yi);
end

% remove unmod data
xu(1) = [];
yi_m(1) = [];

% plot
f = figure;
    f.Position = [0, 0, 800, 350];
plot(xu, yi_m,...
    'LineWidth', 1,...
    'Marker','o',...
    'MarkerSize', 5,...
    'Color','#000000', ...
    'MarkerFaceColor','#ffffff')
xlabel('Threshold (dB re: 100%)');
ylabel(sprintf('%s',parname));

 
 
 
