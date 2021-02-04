%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_max_results.m                                                      %
% Plot the maxmum simulation fields                                       %
% By William Pringle, Jan 2021 -                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))

%% Input Setup

% Parameters
figres = '-r300';        % figure resolution

% Make figure directory and save in there
mkdir('Figs/')
runname = 'MESH_STORM';

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
staname = string(strtrim(ncread(sta_ele,'station_name')'))

%% Make max ele
figure;
for ii = 1:size(height,2) 
   plot(t,height(:,ii))
   title([staname{ii} ' - ' outname],'interpreter','none')
   ylabel('elevation [m]')
   outname = ['Figs/' runname '_' staname{ii}];
   print(outname,figres,'-dpng')
   clf;
end
