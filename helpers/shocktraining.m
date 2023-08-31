spth = 'D:\Caras\Analysis\IC recordings\Shock';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

% figure properties
f = figure;
f.Position = [0, 0, 600 600];
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

cm = [250, 180, 207; 203, 131, 230; 131, 107, 209; 88, 130, 207; 51, 179, 229; 138, 222, 166; 212, 226, 97;]./255; % session colormap

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
A = [1.4861 2.1998; 1.6459 2.2778; 2.2290 NaN; 2.9698 NaN; 1.8781 2.5641; 2.6480 NaN];

% plot
for i = 1:length(A)
    x = [9 10];
    y = A(i,:);
    
    line(x, y,...
        Marker = 'o',...
        MarkerSize = 8,...
        MarkerFaceColor =  cm(i,:),...
        MarkerEdgeColor = cm(i,:),...
        Color = cm(i,:),...
        LineWidth = 2);
end
