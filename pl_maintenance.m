%% Fit thresholds
caraslab_behav_pipeline(savedir, behaviordir, 'intan');

%% Determine behavioral asymptote

% load file
spth = 'C:\Users\rose\Documents\Caras\Analysis\IC recordings\Behavior';
subjects = dir(spth);
subjects(~[subjects.isdir]) = [];
subjects(ismember({subjects.name},{'.','..'})) = [];

maxdays = 7;

% extract output
for subj = 1%:length(subjects)
    spth = fullfile(subjects(subj).folder,subjects(subj).name);
    d = dir(fullfile(spth,'*.mat'));
    ffn = fullfile(d.folder,d.name);
    
    fprintf('Loading subject %s ...',subjects(subj).name)
    load(ffn)
    fprintf(' done\n')
    
    for i = 1:length(output)
        a(i) = output(i).fitdata;
    end
    
    y = [a.threshold];
    x = [1:length(y)];
    
    clear a
    
    % fit data
    tbl = table(x(:), y(:));
    modelfun = @(b,x) b(1)-b(2)./x(:, 1);
    mdl = fitnlm(tbl, modelfun, [0,0]);
    coefficients = mdl.Coefficients{:, 'Estimate'};
    yfit = coefficients(1)-coefficients(2)./x;
    
    hold on;
    plot(x, yfit, 'r-', 'LineWidth', 2);
    plot(x, y, 'b*', 'LineWidth', 2);
end