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
% Input Storm related polygon 
bou = [LONMIN LONMAX; % the boundary that defines the subset to extract
       LATMIN LATMAX]; 

% Parameters
buff = 1.0;       % the buffer for the plot
lines = '--';     % bbox line style
linew = 1;        % bbox line width
figres = '-r300'; % figure resolution

% Making buffer for plot
bou_buff(:,1) = bou(:,1) - buff;
bou_buff(:,2) = bou(:,2) + buff;

% Output Plot Names
outname = ['HSOFS+Coarse_' storm];

% Load the mesh
load([outname '.mat'])

%% Plot mesh subsets
% Plot the mesh quality
plot(m,'qual',1,[],bou_buff);
m_rectangle(bou(1,1),bou(2,1),bou(1,2)-bou(1,1),bou(2,2)-bou(2,1),...
            0,'EdgeColor','g','lines',lines,'linew',linew);
print([outname '_meshqual.png'],figres,'-dpng')

% Plot the mesh reolution
plot(m,'resomeshlog',1,[],bou_buff);
m_rectangle(bou(1,1),bou(2,1),bou(1,2)-bou(1,1),bou(2,2)-bou(2,1),...
            0,'EdgeColor','k','lines',lines,'linew',linew);
print([outname '_resomesh.png'],figres,'-dpng')

% Plot the bathy
plot(m,'b',1,[],bou_buff);
demcmap([-100 10])
m_rectangle(bou(1,1),bou(2,1),bou(1,2)-bou(1,1),bou(2,2)-bou(2,1),...
            0,'EdgeColor','r','lines',lines,'linew',linew);
print([outname '_bathy.png'],figres,'-dpng')

% Plot the bottom friction
plot(m,'quad',1,[],bou_buff);
m_rectangle(bou(1,1),bou(2,1),bou(1,2)-bou(1,1),bou(2,2)-bou(2,1),...
            0,'EdgeColor','m','lines',lines,'linew',linew);
print([outname '_botfric.png'],figres,'-dpng')

%% Plot full mesh
% Plot the triangulation with boundaries
plot(m,'bd',1);
m_rectangle(bou(1,1),bou(2,1),bou(1,2)-bou(1,1),bou(2,2)-bou(2,1),...
            0,'EdgeColor','m','lines',lines,'linew',linew);
m_text(-95,40,[num2str(length(m.p)/1e6,3) 'M vertices'],'fontsize',12)
m_text(-95,38,[num2str(length(m.t)/1e6,3) 'M elements'],'fontsize',12)
print([outname '_tri+ob.png'],figres,'-dpng')
