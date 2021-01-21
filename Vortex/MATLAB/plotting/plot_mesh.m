%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot_Mesh.m                                                             %
% Plot the merge mesh                                                     %
% By William Pringle, Oct 2020 - Jan 2021                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))

%% Input Setup
% Input Storm Name
stormcode = 'STORMCODE';
% Input Storm Track
maxlon = -63;
try
   trackfile = [upper(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
catch
   trackfile = [lower(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
end
track = cell2mat(shp.ncst);
track(track(:,1) > maxlon,:) = [];

% Parameters
buff = 1.0;       % the buffer for the plot
bw = 1;           % boundary line width
tw = 2;           % track line width
figres = '-r300'; % figure resolution

% Output Plot Names
outname = 'MESH_STORM';

% Load the mesh
load([outname '.mat'])

% Get the bbox from the ms subset polygon
bou = [min(ms_poly_vec)' max(ms_poly_vec)'];

% Making buffer for plot
bou_buff(:,1) = bou(:,1) - buff;
bou_buff(:,2) = bou(:,2) + buff;

% Make figure directory and save in there
mkdir('Figs/')
outname = ['Figs/' outname];

%% Plot mesh subsets
% Plot the mesh quality
plot(m,'type','qual','subset',bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'g--','linew',bw);
m_plot(track(:,1),track(:,2),'g-','linew',tw);
print([outname '_meshqual.png'],figres,'-dpng')

% Plot the mesh reolution
plot(m,'type','resomeshlog','subset',bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
m_plot(track(:,1),track(:,2),'k-','linew',tw);
print([outname '_resomesh.png'],figres,'-dpng')

% Plot the bathy
plot(m,'type','b','subset',bou_buff,'colormap',[11 -10 100]);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'r--','linew',bw);
m_plot(track(:,1),track(:,2),'r-','linew',tw);
print([outname '_bathy.png'],figres,'-dpng')

% Plot the bottom friction
%plot(m,'quad',1,[],bou_buff);
%m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
%m_plot(track(:,1),track(:,2),'k-','linew',tw);
%print([outname '_botfric.png'],figres,'-dpng')

%% Plot full mesh
% Plot the triangulation with boundaries
plot(m,'type','bd');
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'m--','linew',bw);
m_plot(track(:,1),track(:,2),'m-','linew',tw);
m_text(-95,40,[num2str(length(m.p)/1e6,3) 'M vertices'],'fontsize',12)
m_text(-95,38,[num2str(length(m.t)/1e6,3) 'M elements'],'fontsize',12)
print([outname '_tri+ob.png'],figres,'-dpng')
