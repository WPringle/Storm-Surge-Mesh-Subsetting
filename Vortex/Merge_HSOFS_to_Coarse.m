%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Merge_HSOFS_to_Coarse.m                                                 %
% Script to merge subset of HSOFS to ~1-km coarse WNAT mesh               %
% By William Pringle Oct 18-20 2020                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OM_Mesh2D_Stuff'))
addpath(genpath('~/MATLAB/OceanMesh2D'))
addpath(genpath('~/MATLAB/m_map'))
addpath('/pontus/wpringle/Bathy/GEBCO')
addpath('/pontus/wpringle/tidedata')
addpath('/pontus/wpringle/ECGC/HSOFS_Ensemble/data')
%
% Setting up the projection variables
global MAP_PROJECTION MAP_COORDS MAP_VAR_LIST
%
%% Input Setup
% Input Storm Name
storm = 'STORMNAME';
% Input Storm related polygon 
bou = [LONMIN LONMAX; % the boundary that defines the subset to extract
       LATMIN LATMAX]; 
% Input Coarse mesh bathy data
B_filename = 'GEBCO_2020.nc';
% Input buoyancy frequency values
N_filename = 'Gridded_N_values_WOA2018_2005-2017.mat';
%
% Input Mesh
HSOFS = 'Model_120m_Release_v1_nof24.mat';
% Input Coarse Mesh Property
WNAT  = 'WNAT_1km_properties.mat';

% Output Mesh Name
outname = ['HSOFS+Coarse_' storm];

% Set some parameters
centroid = 0;  % = 0 [default] inpolygon test is based on whether all vertices
               % of the element are inside (outside) the bou polygon
               % = 1 inpolygon test is based on whether the element centroid
               % is inside (outside) the bou polygon
dbc = 0.35;    % The allowable boundary quality of coarse outer mesh
con = 9;       % The allowable element connectivity of coarse outer mesh
bc_points = [-60.0000   45.7;   % the start and end points of 
             -60.0000    8.8];  % the open boundary
     
%% Load the outer coarse mesh properties,
%% the HSOFS mesh and extract the desired subset
tic
% Coarse Mesh
load(WNAT); 

% Fine HSOFS Mesh
load(HSOFS);
% Extract the subdomain
[ms,ind] = ExtractSubDomain(m,bou,0,centroid,0);
% Map back mesh properties
ms = mapMeshProperties(ms,ind);
clear m
% project the vertices in ms using the WNAT coarse mesh projection
[p1(:,1),p1(:,2)] = m_ll2xy(ms.p(:,1),ms.p(:,2)) ;
ms.p = p1;
% clean the mesh to make sure it is traversable
ms = ms.clean('passive','proj',0,'con',0);
%
toc
%% Get boundary of the HSOFS subset mesh and subtract from the outer one
tic
% get the ms polygonal boundary as a cell
ms_bound = getBoundaryOfMesh(ms,1);
% determine the area of each polygon
area = size(ms_bound);
for ib = 1:length(ms_bound)
    area(ib) = polyarea(ms_bound{ib}(1:end-1,1),ms_bound{ib}(1:end-1,2));
end
% sort polygons by area largest to smallest
[~,AS] = sort(area,'descend');
% set the outer most polygon to the largest area
ms_poly_vec = ms_bound{AS(1)}; 
for ib = 2:length(AS)
    % append other polygons if they lie outside the rest of the polygon
    edge = Get_poly_edges(ms_poly_vec);
    in = inpoly(ms_bound{AS(ib)},ms_poly_vec,edge);
    % completely outside, let's append
    if sum(in) == 0
        ms_poly_vec = [ms_poly_vec; ms_bound{AS(ib)}];
    end
end
% make sure ms polygon is clockwise
[ms_xcw, ms_ycw] = poly2cw(ms_poly_vec(:,1), ms_poly_vec(:,2));
% Subtract the HSOFS boundary from the outer one
[xn, yn] = polybool('-', poly_vec(:,1), poly_vec(:,2), ms_xcw, ms_ycw);
poly_vec = [xn, yn];
toc
%% Make the delaunay-refinement mesh based on size function and the subtracted polygon
tic
opts.iter = 100;
opts.kind = 'delaunay';
opts.ref1 = 'preserve';
[node,edge] = getnan2(poly_vec);
% make the delaunay refinement mesh
[pc,etri,tc,tnum] = refine2_om(node,edge,[],opts,@(p)F(p));  
% smooth the mesh 
[pc,~,tc,~] = smooth2(pc,etri,tc,tnum);

% Put into msh class and clean up a little
mc = msh('points',pc,'elements',tc);
mc.proj = MAP_PROJECTION;
mc.coord = MAP_COORDS;
mc.mapvar = MAP_VAR_LIST;
mc = clean(mc,'passive','db',dbc,'proj',0,'con',con);
toc
%% Concatenate meshes together and carry over attributes
tic
m = cat(ms,mc); % this order is important as cat will carry over info from ms not mc
% make sure m is using the full outer projection
m.proj   = MAP_PROJECTION;
m.coord  = MAP_COORDS;
m.mapvar = MAP_VAR_LIST;
% Make sure to reset bd and op
m.bd = []; m.op = [];
% if HSOFS subset contains weirs carry these over...
if ~isempty(ms.bd) && any(ms.bd.ibtype == 24)
    m = carryoverweirs(m,ms);
end
% project back to lat-lon
[m.p(:,1),m.p(:,2)] = m_xy2ll(m.p(:,1),m.p(:,2)) ;
toc
%% Add on open bc, bathy, and recompute global f13 attributes
tic
% make the outer bc
bc_k = ourKNNsearch(m.p',bc_points',1);
m = make_bc(m,'outer',0,bc_k(1),bc_k(2),2);
% interpolate the NaN parts of mesh using B_filename data
m = interp(m,B_filename,'K',find(isnan(m.b)),'type','depth',...
           'ignoreOL',1,'nan','fill');
% interpolate the NaN parts of mesh using B_filename data
m = interp(m,B_filename,'K',find(isnan(m.bx)),'type','slope',....
           'ignoreOL',1,'nan','fill');
% recompute the tau0 (-3 option)
m = Calc_tau0(m);
% recompute the internal tide using N_filename data
m = Calc_IT_Fric(m,N_filename,'cutoff_depth',250,'Cit',2.75);
% save the mesh
save([outname '.mat'],'m');
toc
