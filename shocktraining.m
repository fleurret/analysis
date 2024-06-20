spth = 'D:\Caras\Analysis\MGB recordings\Shock';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% figure properties
f = figure;
f.Position = [0, 0, 800 500];
f.Resize = 'off';
hold on

xlabel('Associative Training Day',...
    'FontSize', 20,...
    'FontWeight', 'bold')
ylabel('d''',...
    'FontSize', 20,...
    'FontWeight', 'bold')
yticks([0, 1, 2, 3, 4])
ax = gca;
ax.FontSize = 20;
ax.LineWidth = 3;
ax.TickDir = 'out';
ax.TickLength = [0.02,0.02];
ax.FontSize = 20;
set(findobj(ax,'-property','FontName'),...
    'FontName','Arial')

cm = [223, 143, 234; 155, 95, 224; 40, 83, 221; 145, 209, 249; 58, 186, 137; 190, 232, 163]./255; % session colormap

% extract output
for subj = 1:length(subjects)
    spth = fullfile(subjects(subj).folder,subjects(subj).name);
    d = dir(fullfile(spth,'*.mat'));
    ffn = fullfile(d.folder,d.name);
    
    fprintf('Loading subject %s ...',subjects(subj).name)
    load(ffn)
    fprintf(' done\n')
    
    clear dprimes
    dprimes = nan(1,length(output));
    
    % get dprimes
    for i = 1:length(output)
        if ~isempty(output(i).dprimemat)
            dp = output(i).dprimemat;
            dprimes(i) = dp(2);
        else
            continue
        end
    end
    
    dprimes(isnan(dprimes))=[];
    
    % plot
    x = 1:length(dprimes);
    line(x, dprimes,...
        Marker = 'o',...
        MarkerSize = 8,...
        MarkerFaceColor =  cm(subj,:),...
        MarkerEdgeColor = cm(subj,:),...
        Color = cm(subj,:),...
        LineWidth = 2);
end

% add days after surgery
% for IC animals
% A = [1.4861 2.1998; 1.6459 2.2778; 2.2290 NaN; 2.9698 NaN; 1.8781 2.5641; 2.6480 NaN];

% MGN animals
A = [2.5212 NaN NaN NaN NaN; 2.5887 NaN NaN NaN NaN; 2.0385 2.0795 NaN NaN NaN; 1.6331 2.0252 1.8570 2.3694 NaN; 1.1139, 1.9478, 1.6735, 2.0756, 2.5810];

% plot
for i = 1:length(A)
    x = [11 12 13 14 15];
% x = [11 12];
y = A(i,:);
    
    line(x, y,...
        Marker = 'o',...
        MarkerSize = 8,...
        MarkerFaceColor =  cm(i,:),...
        MarkerEdgeColor = cm(i,:),...
        Color = cm(i,:),...
        LineWidth = 2);
end
