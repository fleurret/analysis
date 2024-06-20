function plot_raster(savedir, parname, ndays, unit_type, condition, cn)

% convert parname to correct label
if contains(parname,'FiringRate')
    Parname = 'trial_firingrate';
    
elseif contains(parname,'Power')
    Parname = 'cl_calcpower';
    
else contains(parname,'VScc')
    Parname = 'vector_strength_cycle_by_cycle';
end

fn = 'Cday_';
fn = strcat(fn,(parname),'.mat');

if ~exist(fullfile(savedir,fn))
    fn = 'Cday_original.mat';
end

load(fullfile(savedir,fn));

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
        Cj = Ci(uidx);

        for k = 1:3
            Ck = Cj(k);
            ev = Ck.Session.find_Event("AMDepth").DistinctValues;
            ev(ev==0) = [];
            
            y = figure;
            y.Position = [0, 0, 500, 2000];
            z = tiledlayout('flow');
            
%             if length(ev) > 5
%                 ev = ev(end-4:end);
%             end

            h = epa.plot.Raster(Ck,'event',"AMDepth",'eventvalue',ev);
            
            figure
            h.plot;
            
            sn = Ck.SessionName;
            cluster = Ck.TitleStr;
            
            ztitle = append(cluster, ' ',sn);
            title(z, ztitle)
            
        end
    end
end