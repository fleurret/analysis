% x = x(~isnan(x.Threshold),:);

ind1 = x.Session == "Pre";
ind2 = x.Session == "Active";
ind3 = x.Session == "Post";

pre = table2array(x(ind1,7));
task = table2array(x(ind2,7));
post = table2array(x(ind3,7));

m1 = mean(task-pre);
m2 = mean(task-post);
m3 = mean(post-pre);

s1 = std(task-pre)/sqrt(length(task-pre));
s2 = std(task-post)/sqrt(length(task-post));
s3 = std(post-pre)/sqrt(length(post-pre));

d1 = m1/std([task;pre],'omitnan');
d2 = m2/std([task;post],'omitnan');
d3 = m3/std([pre;post],'omitnan');

%%
x = FiringRatethreshold;
% x = x(~isnan(x.Threshold),:);

ind1 = x.Session == "Pre";
ind2 = x.Session == "Active";
ind3 = x.Session == "Post";

pre = table2array(x(ind1,5));
task = table2array(x(ind2,5));
post = table2array(x(ind3,5));

m1 = mean(task-pre,'omitnan');
m2 = mean(task-post,'omitnan');
m3 = mean(post-pre,'omitnan');

s1 = std(task-pre,'omitnan')/sqrt(length(task-pre));
s2 = std(task-post,'omitnan')/sqrt(length(task-post));
s3 = std(post-pre,'omitnan')/sqrt(length(post-pre));

pre = table2array(x(ind1,5));
task = table2array(x(ind2,5));
post = table2array(x(ind3,5));

d1 = (mean(task,'omitnan') - mean(pre,'omitnan'))/std([task;pre],'omitnan');
d2 = (mean(task,'omitnan') - mean(post,'omitnan'))/std([task;post],'omitnan');
d3 = (mean(post,'omitnan') - mean(pre,'omitnan'))/std([pre;post],'omitnan');

