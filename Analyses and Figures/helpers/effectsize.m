d = 7;

day = x(x.Day == d,:);
pre = day(day.Session == 'Pre',:);
task = day(day.Session == 'Task',:);
m1 = mean(pre.Threshold);
m2 = mean(task.Threshold);

es = (m1 - m2)/std([pre.Threshold; task.Threshold]);