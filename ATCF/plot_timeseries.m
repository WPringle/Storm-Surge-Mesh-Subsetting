%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_timeseries.m                                                       %
% Plot the simulated station timeseries against NOAA obs, if available    %
% By William Pringle, Feb 2021 -                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
%% Input Setup
runs = ["Obs (CO-OPS)" "GESTOFS IMP"];
coops_pre = 'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?';
coops_for = 'format=csv';
coops_dat = 'datum=MSL';
coops_pro = 'product=water_level';
coops_uni = 'units=metric';
coops_tz  = 'time_zone=gmt';
options = weboptions('ContentType','table');

% Parameters
figres = '-r300';        % figure resolution

% Make figure directory and save in there
mkdir('Figs/')

% filenames
sta_ele = 'fort.61.nc';

% Reading spatial-temporal info from the max_ele file
t = ncread(sta_ele,'time');
tss = ncreadatt(sta_ele, 'time', 'base_date');
stf = strfind(tss,'UTC');
if ~isempty(stf)
   tss = tss(1:stf-1);
end
tss = datetime(tss);
t = t/3600/24 + tss;
height = ncread(sta_ele,'zeta')';
staname = string(strtrim(ncread(sta_ele,'station_name')'));

coops_ts = ['begin_date=' datestr(t(1),'YYYYmmdd HH:00')]
coops_te = ['end_date=' datestr(t(end),'YYYYmmdd HH:00')]

%% Make max ele
figure;
for ii = 1:size(height,2)
   disp(staname{ii})
   obs_avail = false;
   hold on
   % NOAA ID
   coops_sta = ['station=' staname{ii}];
   url = [coops_pre coops_ts '&' coops_te '&' coops_tz '&' coops_dat '&' ...
          coops_for '&' coops_pro '&' coops_uni '&' coops_sta];
   try 
     T = webread(url,options);
     plot(T.DateTime,T.WaterLevel,'k-'); hold on
     obs_avail = true; 
   end
   plot(t,height(:,ii));
   if obs_avail
      legend(runs) 
   else
      legend(runs(2:end))
   end 
   title(['Storm Tide - ' staname{ii}])
   ylabel('elevation [m]')
   outname = ['Figs/' staname{ii}];
   print(outname,figres,'-dpng')
   clf;
end
