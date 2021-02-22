function [] = save_fort_to_mat(inname)
% [] = save_fort_to_mat(inname)
% read inname.xx (fort.14 and fort.13 ADCIRC files
% into msh class and save it into inname.mat 

% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))

% read the fort.14 and fort.13 files into msh class
m = msh('fname',[inname '.14'],'aux',{[inname '.13']});
[~,m] = setProj(m,1,'lam',1)
m

% save the msh class as .mat file
save([inname '.mat'],'m');
