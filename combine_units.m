% get unique cluster names from both tables
a = table2array(FR(:,1));
b = table2array(VScc(:,1));
c = [a;b];
clusters = unique(c);
r = length(clusters)-1;
clusters = clusters(1:r);

% populate new array
allunits = NaN(length(clusters),6);
for i = 1:length(allunits)
    allunits(i,:) = clusters(1);
end