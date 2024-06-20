function white_noise(depth)
%This file allows the user to create unmodulated and amplitude modulated
%white noise. Written by MLC 7/10/2013.

%---------------------------------------
%CREATE A FIGURE ILLUSTRATING AN UNMODULATED NOISE, A MODULATION SIGNAL,
%AND A MODULATED NOISE

%Savepath
% savepath = '/Users/Melissa/Desktop/';

%Make unmodulated white noise
dur = 1; % duration of the noise in seconds
sampRate = 12000;
nTimeSamples = dur*sampRate; %number of time samples
t = linspace(0,dur,nTimeSamples); %time vector in samples

y=randn(1, nTimeSamples); %create a white noise vector
noise=y'; %transpose into a column (I think older versions of matlab
            %required sound vectors to be a column in order to be played)
noise = noise/max(abs(noise)); %set the max amplitude of noise to 1


%% 
%Save the unmodulated noise as an .mp4
%audiowrite([savepath,'unmodulated.mp4'],noise,sampRate);


%Plot the noise
% figure;
% s1 = subplot(3,1,1);
% plot(t,noise,'color',[0.5 0.5 0.5])
% xh = xlabel('');
% yh = ylabel('Normalized amplitude');
% th = title('Noise');

%myformat(s1,xh,yh,th);


% Make modulation signal
freq = 5; %Modulation frequency in Hz
c = (1+(depth^2)/2)^(-0.5); %Viemiester's constant to maintain constant energy
modulation = (c*(1+depth*cos((2*pi*freq*t))))';% cos modulated signal

%Make modulated white noise
modulated_noise = noise.*modulation; %modulated noise
%filename = ['modulated_12','.mp4'];
%audiowrite([savepath,filename],modulated_noise,sampRate);


%Plot the modulation signal
% s2 = subplot(3,1,2);
% plot(t,modulation,'k');
% xh = xlabel('');
% yh = ylabel('Normalized amplitude');
% th = title('Modulation signal');
%myformat(s2,xh,yh,th);

%Plot modulated noise
% s3 = subplot(3,1,3);
plot(t,modulated_noise,'color',[0.5, 0.5 0.5]);
xh = xlabel('Time (s)');
yh = ylabel('Normalized amplitude');
th = title('Modulation depth:', depth);
%myformat(s3,xh,yh,th);

%Set all y axes to [-2 2]
% linkaxes([s1,s2,s3],'y');
% set(s1,'ylim',[-2 2])

ylim([-2,2])


%% ---------------------------------------------------------------
% %PLOT AND PLAY MODULATED NOISE OF VARYING DEPTHS
% 
% depths = [1,0.71,0.5,0.35,0.25,0.18,0.12,0]; %Modulation depths
% %depths = [0.35];
% figure;
% set(gcf,'Color','w')
% tiledlayout(numel(depths),1,TileSpacing="none")
% 
% for i = 1:numel(depths)
%     depth = depths(i);
%     
%     modulation = make_modulation_signal(freq,t,depth);
%     modulated_noise = noise.*modulation;
%     
%     mynoise = [noise;noise;modulated_noise;noise;noise];
%     
%     t2 = t+1;
%     t3 = t2+1;
%     t4 = t3+1;
%     t5 = t4+1;
%     
%     mytime = [t,t2,t3,t4,t5]';
%     
%     %Plot modulated noise
%     %subplot(numel(depths),1,i)
%     nexttile
%     plot(mytime,mynoise,'color',[0.5,0.5,0.5])
%     set(gca,'box','off')
%     set(gca,'xticklabel','')
%     set(gca,'yticklabel','')
%     axis off
%     %set(gca,'xlim',[1,3])
% 
%     
%     if i == numel(depths)
%         xh = xlabel('Time (s)');
%         yh = ylabel('Normalized amplitude');
%     else
%         xh = '';
%         set(gca,'xticklabel','')
%         set(gca,'yticklabel','')
%     end
%     
%     
%     th = title('');
%     %myformat(gca,xh,yh,th);
%     set(gca,'ylim',[-1.5 1.5])
%     
%     %sound(mynoise,sampRate)
%     
%     %Save the modulated noise as an .mp4
%     %filename = ['modulated_depth_',num2str(depths(i)),'.mp4'];
%     %audiowrite([savepath,filename],mynoise,sampRate);
%     
% end
% 
% 
% 
% end
% 
% 
% 
% 
% %---------------------------------------------------------
% %ADDITIONAL FUNCTIONS
% %--------------------------------------------------------
% function modulation = make_modulation_signal(freq,t,depth);
% 
% 
% c = (1+(depth^2)/2)^(-0.5); %Viemiester's constant to maintain constant energy
% 
% %modulation = (c*(1+depth*sin((2*pi*freq*t))))';% sin modulated signal
% modulation = (c*(1+depth*cos((2*pi*freq*t))))';% cos modulated signal
% 
% 
% end
% 
% 
