%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_max_results.m                                                      %
% Plot the maxmum simulation fields                                       %
% By William Pringle, Jan 2021 -                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
%% Input Setup
%% Set Storm Code
stormcode = 'STORMCODE';
% Parameters
maxlon = -63;            % maximum longitude for the track
maxhwm = +5;             % max HWM level to plot
buff = 1.0;              % the buffer for the plot
bw = 1;                  % boundary line width
tw = 2;                  % track line width
bgc = [166 132 97]/255;  % background color
figres = '-r300';        % figure resolution
cmin = 0;                % colormap minimum 
wmax = 50;               % wind speed colormap maximum

% Add path to data
addpath(genpath('DATA_DIR'))
% Reading HMW file (for some reason readtable does not work properly after loading OceanMesh)
try
   hwm_file = [upper(stormcode) '_HWM.csv'];
   hwm = readtable(hwm_file);
catch
   hwm_file = [lower(stormcode) '_HWM.csv'];
   hwm = readtable(hwm_file);
end
% delete HWMs above maxhwm
hwm(hwm.elev_m > maxhwm,:) = [];

% Addpath to OceanMesh2D
addpath(genpath('~/MATLAB/OceanMesh2D'))

% Read the GIS track file
try
   trackfile = [upper(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
catch
   trackfile = [lower(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
end
track = cell2mat(shp.ncst);
track(track(:,1) > maxlon,:) = [];

% Get the bbox from storm track (for now)
%bou = [min(track)' max(track)'];
%bou(1,2) = min(-70,bou(1,2));
% Get the bbox from HWMs
bou = [min(hwm.longitude) max(hwm.longitude);
       min(hwm.latitude)  max(hwm.latitude)];

% Making buffer for plot
bou_buff(:,1) = bou(:,1) - buff;
bou_buff(:,2) = bou(:,2) + buff;
disp(bou_buff)

% Make figure directory and save in there
mkdir('Figs/')
outname = 'MESH_STORM';
outname = ['Figs/' outname];

% filenames
max_ele = 'maxele.63.nc';
max_wind = 'maxwvel.63.nc';

% Reading spatial-temporal info from the max_ele file
x = ncread(max_ele,'x');
y = ncread(max_ele,'y');
ele = ncread(max_ele,'element')';
t = ncread(max_ele,'time');
tss = ncreadatt(max_ele, 'time', 'base_date');
stf = strfind(tss,'UTC');
if ~isempty(stf)
   tss = tss(1:stf-1);
end
tss = datetime(tss);
t = t/3600/24 + tss;

% Forming the projection space
m_proj('lam','long',bou_buff(1,:),'lat',bou_buff(2,:))

%% Make max ele
figure;
height = ncread(max_ele,'zeta_max');
m_trisurf(ele,x,y,height);
hold on
m_scatter(hwm.longitude,hwm.latitude,8,hwm.elev_m,...
          'filled','MarkerEdgeColor','k','LineWidth',0.25)
m_plot(track(:,1),track(:,2),'k-','linew',tw);
ax = gca;
ax.Color = bgc;
m_grid()
colormap(lansey)
caxis([cmin maxhwm])
cb = colorbar;
cb.Label.String = 'elevation [m]';
title(['Maximum Storm Tide - ' outname])
print([outname '_maxele.png'],figres,'-dpng')

%% Make max wind
figure;
height = ncread(max_wind,'wind_max');
m_trisurf(ele,x,y,height);
hold on
m_plot(track(:,1),track(:,2),'k-','linew',tw);
ax = gca;
ax.Color = bgc;
m_grid()
cmocean('speed',10)
caxis([cmin wmax])
cb = colorbar;
cb.Label.String = 'wind speed [m/s]';
title(['Maximum Wind Speed - ' outname])
print([outname '_maxwind.png'],figres,'-dpng')
