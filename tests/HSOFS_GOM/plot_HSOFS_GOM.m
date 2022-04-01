%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_HSOFS_GOM.m                                                  %
%  Plot the merged mesh (HSOFS fine mesh at user-defined region)    %
%  By William Pringle, Mar 2021                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D'))

%% Input Setup
% Input regions
regions = dlmread('regions.txt');
% Parameters
buff = 1.0;       % the buffer for the plot
bw = 1;           % boundary line width
figres = '-r300'; % figure resolution

for rr = 1:size(regions,1)
    % Output Mesh Name
    outname = ['HSOFS_GOM_' num2str(rr)];
    dir = [outname '/'];
    % Load the mesh
    load([dir outname '.mat'])
    ms_poly_vec = fine_poly2.Vertices;

    % Get the bbox from the ms subdomain polygon
    bou = [min(ms_poly_vec)' max(ms_poly_vec)'];

    % Making buffer for plot
    bou_buff(:,1) = bou(:,1) - buff;
    bou_buff(:,2) = bou(:,2) + buff;

    % Make figure directory and save in there
    mkdir([dir 'mesh_figs/'])
    outname = [dir 'mesh_figs/' outname];

    %% Plot mesh subdomains
    % Plot the triangulation with boundaries
    plot(m,'type','bd','subdomain',bou_buff);
    print([outname '_tri+ob.png'],figres,'-dpng')
    
    % Plot the mesh quality
    plot(m,'type','qual','subdomain',bou_buff);
    m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'g--','linew',bw);
    print([outname '_meshqual.png'],figres,'-dpng')

    % Plot the mesh reolution
    plot(m,'type','resomeshlog','subdomain',bou_buff);
    m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
    print([outname '_resomesh.png'],figres,'-dpng')

    % Plot the bathy
    plot(m,'type','b','subdomain',bou_buff,'colormap',[11 -10 100]);
    m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'r--','linew',bw);
    print([outname '_bathy.png'],figres,'-dpng')

    % Plot the f13 attributes
    for ii = 1:m.f13.nAttr
      attname = m.f13.defval.Atr(ii).AttrName; 
      plot(m,'type',attname,'subdomain',bou_buff);
      m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'k--','linew',bw);
      print([outname '_' attname '.png'],figres,'-dpng')
    end

    %% Plot full mesh
    % Plot the triangulation with boundaries
    plot(m,'type','bd');
    m_plot(ms_poly_vec(:,1),ms_poly_vec(:,2),'m--','linew',bw);
    m_text(-87,20,[num2str(length(m.p)/1e3,3) 'K vertices'],'fontsize',12)
    m_text(-87,19.5,[num2str(length(m.t)/1e3,3) 'K elements'],'fontsize',12)
    print([outname '_tri+ob_full.png'],figres,'-dpng')
end
