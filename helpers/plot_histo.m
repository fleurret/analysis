function plot_histo(savedir, parname, ndays, unit_type, condition, cn)

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
            y.Position = [0, 0, 500, 1500];
            z = tiledlayout('flow');
            
            for l = 1:numel(ev)
                nexttile([1 length(ev)])
                h = epa.plot.PSTH(Ck,'event',"AMDepth",'eventvalue',ev);
                [fr,b,uv] = Ck.psth(h);
                
                depths = round(Ck.UserData.(Parname).vals);
                depth = depths(l);
                
                ptitle = append(mat2str(depth),' dB');
                bar(b,fr(l,:),...
                    'EdgeAlpha',0,...
                    'FaceColor','k');
                
                ylim([0 150]);
%                 if max(fr(:)) < 100
%                     ylim([0 100]);
%                 end
%                 
%                 if 100 <= max(fr(:)) && max(fr(:)) < 200
%                     ylim([0 200]);
%                 end
%                 
%                 if 200 <= max(fr(:)) && max(fr(:)) <= 300
%                     ylim([0 300]);
%                 end
                
                title(ptitle);
            end
            
            sn = Ck.SessionName;
            cluster = Ck.TitleStr;
            
            ztitle = append(cluster, ' ',sn);
            title(z, ztitle)
            
            % save figure
%             s = split(cluster, '_');
%             subject = s(1);
%             
%             mkdir(savedir,'PSTH\')
%             folder = append(savedir,'\PSTH');
%             filename = append(subject,'-Day',mat2str(i),'-',cluster,'-',sn);
%             ffn = fullfile(folder,filename);
%             
%             saveas(y, ffn, 'pdf')
%             close(y)
        end
    end
end