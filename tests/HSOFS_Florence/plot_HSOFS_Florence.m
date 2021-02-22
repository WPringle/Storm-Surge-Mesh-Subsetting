%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_HSOFS_Florence.m                                                   %
%  Plot the merged mesh (HSOFS fine mesh at Hurricance Florence landfall) %
%  By William Pringle, Feb 2021                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('OM2DHOME'))

%% Input Setup
% Input Storm Name
stormcode = 'AL062018';
% Input mesh name/Output plot name
outname = 'HSOFS_Florence';
% Parameters
buff = 1.0;       % the buffer for the plot
bw = 1;           % boundary line width
tw = 2;           % track line width
figres = '-r300'; % figure resolution

% Input Storm Track
trackfile = [stormcode '_pts'];
shp = m_shaperead(trackfile);
track = cell2mat(shp.ncst);

% Load the mesh
load([outname '.mat'])
ms_poly_vec = fine_poly.Vertices;

% Get the bbox from the ms subdomain polygon
bou = [min(ms_poly_vec)' max(ms_poly_vec)'];

% Making buffer for plot
bou_buff(:,1) = bou(:,1) - buff;
bou_buff(:,2) = bou(:,2) + buff;

% Make figure directory and save in there
mkdir('Figs/')
outname = ['Figs/' outname];

%% Plot mesh subdomains
% Plot the mesh quality
plot(m,'type','qual','subdomain',bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'g--','linew',bw);
m_plot(track(:,1),track(:,2),'g-','linew',tw);
print([outname '_meshqual.png'],figres,'-dpng')

% Plot the mesh reolution
plot(m,'type','resomeshlog','subdomain',bou_buff);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
m_plot(track(:,1),track(:,2),'k-','linew',tw);
print([outname '_resomesh.png'],figres,'-dpng')

% Plot the bathy
plot(m,'type','b','subdomain',bou_buff,'colormap',[11 -10 100]);
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'r--','linew',bw);
m_plot(track(:,1),track(:,2),'r-','linew',tw);
print([outname '_bathy.png'],figres,'-dpng')

% Plot the f13 attributes
for ii = 1:m.f13.nAttr
   attname = m.f13.defval.Atr(ii).AttrName; 
   plot(m,'type',attname,'subdomain',bou_buff);
   m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
   m_plot(track(:,1),track(:,2),'k-','linew',tw);
   print([outname '_' attname '.png'],figres,'-dpng')
end

%% Plot full mesh
% Plot the triangulation with boundaries
plot(m,'type','bd');
m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'m--','linew',bw);
m_plot(track(:,1),track(:,2),'m-','linew',tw);
m_text(-95,40,[num2str(length(m.p)/1e6,3) 'M vertices'],'fontsize',12)
m_text(-95,38,[num2str(length(m.t)/1e6,3) 'M elements'],'fontsize',12)
print([outname '_tri+ob.png'],figres,'-dpng')
