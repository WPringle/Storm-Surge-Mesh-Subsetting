%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Interpolate bathymetry to a msh class example                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath('../data/')

% Inputs and parameters
inname = 'WNAT_1km';
B_filename = 'GEBCO_2020.nc';
bathy_gradient_limit = 0.1;

% Load the msh clas
load(inname);

% do the interpolation of bathymetry only
m = interp(m,B_filename,'ignoreOL',1,'nan','fill');
% limit the slope of bathmetry to 0.1 
m = lim_bathy_slope(m,bathy_gradient_limit,-1);

% save the msh class
save([inname '.mat'],'m');
