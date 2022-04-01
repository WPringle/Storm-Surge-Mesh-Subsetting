%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_HSOFS_Florence.m                                                   %
%  Plot the merged mesh (HSOFS fine mesh at Hurricance Florence landfall) %
%  By William Pringle, Feb 2021                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; close all
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D'))
addpath('../../mesh/')

%% Input Setup
% Input Storm Name
stormcode = 'AL062018';
wind_swath = 34; %[kt] wind speed at which to set the TC edge (34, 50, or 64)
% Input Mesh
fine = 'HSOFS';
% Input Coarse Mesh Property
coarse  = 'WNAT_1km';
outname = 'HSOFS_Florence';
% Make figure directory for saving in there
direc = 'Figs/';
if ~exist(direc); mkdir(direc); end

% Parameters
buff = 1.0;       % the buffer for the plot
bw = 1;           % boundary line width
tw = 2;           % track line width
figres = '-r300'; % figure resolution

% Input Storm Track
trackfile = [stormcode '_pts'];
shp = m_shaperead(trackfile);
track = cell2mat(shp.ncst);

trackfile = [stormcode '_windswath'];
shp = m_shaperead(trackfile);
% Set high-res region to the "wind_swath"-kt wind speed boundary...
rad = cell2mat(shp.dbf.RADII); WI = find(rad == wind_swath,1,'last');
swath_vec = shp.ncst{WI};
% make sure only get the outer polygon component. 
WI = find(isnan(swath_vec(:,1)),1,'first');
if ~isempty(WI)
   swath_vec = swath_vec(1:WI-1,:);
end

%% Get landfall region
load([outname '.mat'],'fine_poly')
ms_poly_vec = fine_poly.Vertices;
bou = [min(ms_poly_vec)' max(ms_poly_vec)'];
% Making buffer for plot
bou_buff(:,1) = bou(:,1) - buff;
bou_buff(:,2) = bou(:,2) + buff;

%% Plot merged mesh zoom-in
load([outname '.mat'],'m')
plot(m,'type','bmesh','proj','lam','subdomain',bou_buff,...
    'colormap',[22 -10 100],'backcolor',[0.7 0.7 0.7],'fontsize',10);
title('')
m_plot(track(:,1),track(:,2),'r-','linew',tw);
m_plot(swath_vec(:,1),swath_vec(:,2),'r--','linew',tw);
print([direc outname '_bmesh.png'],figres,'-dpng')
