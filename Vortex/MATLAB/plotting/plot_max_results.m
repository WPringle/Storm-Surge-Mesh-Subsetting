%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot_MaxResults.m                                                             %
% Plot the max results                                                     %
% By William Pringle, Jan 2021 -                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))

%% Input Setup
%% Set Storm Code
stormcode = 'STORMCODE';
% Input Storm Track
try
   trackfile = [upper(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
catch
   trackfile = [lower(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
end
track = cell2mat(shp.ncst);
track(track(:,1) > -60,:) = [];

% Parameters
buff = 1.0;              % the buffer for the plot
bw = 1;                  % boundary line width
tw = 2;                  % track line width
bgc = [166 132 97]/255;  % background color
figres = '-r300';        % figure resolution
cmin = 0;                % colormap minimum 
cmax = 3;                % colormap maximum

% Get the bbox from storm track (for now)
bou = [min(track)' max(track)'];
bou(1,2) = min(-70,bou(1,2));

% Making buffer for plot
bou_buff(:,1) = bou(:,1) - buff;
bou_buff(:,2) = bou(:,2) + buff;
disp(bou_buff)

% Make figure directory and save in there
mkdir('Figs/')
outname = 'MESH';
outname = ['Figs/' outname];

% filenames
max_ele = 'maxele.63.nc';
max_wind = 'maxwind.63.nc';

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

%% Make regional gifs
figure;
m_proj('lam','long',bou_buff(1,:),'lat',bou_buff(2,:))
height = ncread(max_ele,'zeta_max');
m_trisurf(ele,x,y,height);
hold on
m_plot(track(:,1),track(:,2),'k-','linew',tw);
ax = gca;
ax.Color = bgc;
m_grid()
colormap(lansey)
caxis([cmin cmax])
cb = colorbar;
cb.Label.String = 'elevation [m]';
title(['Maximum Storm Tide - ' outname])
print([outname '_maxele.png'],figres,'-dpng')
