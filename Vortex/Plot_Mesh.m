%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot_Mesh.m                                                             %
% Plot the merge mesh                                                     %
% By William Pringle, Oct 2020                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath(genpath('~/MATLAB/m_map/'))

%% Input Setup
% Input Storm Name
storm = 'STORMNAME';
stormcode = 'STORMCODE';
% Input Storm Track
try
   trackfile = [upper(stormcode) '_pts.shp'];
   shp = shaperead(trackfile);
catch
   trackfile = [lower(stormcode) '_pts.shp'];
   shp = shaperead(trackfile);
end
trackx = [shp.X];
tracky = [shp.Y];

% Parameters
buff = 1.0;       % the buffer for the plot
bw = 1;           % boundary line width
tw = 2;           % track line width
figres = '-r300'; % figure resolution

% Output Plot Names
outname = ['HSOFS+Coarse_' storm];

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
plot(m,'qual',1,[],bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'g--','linew',bw);
m_plot(trackx,tracky,'g-','linew',tw);
print([outname '_meshqual.png'],figres,'-dpng')

% Plot the mesh reolution
plot(m,'resomeshlog',1,[],bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
m_plot(trackx,tracky,'k-','linew',tw);
print([outname '_resomesh.png'],figres,'-dpng')

% Plot the bathy
plot(m,'b',1,[],bou_buff);
demcmap([-100 10])
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'r--','linew',bw);
m_plot(trackx,tracky,'r-','linew',tw);
print([outname '_bathy.png'],figres,'-dpng')

% Plot the bottom friction
plot(m,'quad',1,[],bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
m_plot(trackx,tracky,'k-','linew',tw);
print([outname '_botfric.png'],figres,'-dpng')

%% Plot full mesh
% Plot the triangulation with boundaries
plot(m,'bd',1);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'m--','linew',bw);
m_plot(trackx,tracky,'m-','linew',tw);
m_text(-95,40,[num2str(length(m.p)/1e6,3) 'M vertices'],'fontsize',12)
m_text(-95,38,[num2str(length(m.t)/1e6,3) 'M elements'],'fontsize',12)
print([outname '_tri+ob.png'],figres,'-dpng')
