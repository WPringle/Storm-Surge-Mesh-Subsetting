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
bgc = [0.7 0.7 0.7];   % background color
fs = 10;               % fontsize
bbox = [-94 -87; 28 32];% subdomain zoom-in
figres = '-r300';      % figure resolution

%% Plot fine mesh 
load([fine '.mat'])
plot(m,'type','resolog','proj','lam',...
     'colormap',[10 200 25e3],'fontsize',fs);
plot(m,'type','bdnotri','proj','lam',...
    'backcolor',bgc,'fontsize',fs,'holdon',1);
title('')
%l = legend; l.Location = 'bestoutside';
print([direc fine '_resolog.png'],figres,'-dpng')

% Plot zoom-in to Louisiana
plot(m,'type','resomeshlog','proj','lam','subdomain',bbox,...
     'colormap',[10 200 10e3],'fontsize',fs);
plot(m,'type','bdnotri','proj','lam','subdomain',bbox,...
     'fontsize',fs,'holdon',1,'backcolor',bgc);
title('')
l = legend; l.Visible = 'off';
print([direc fine '_LA_resolog.png'],figres,'-dpng')
