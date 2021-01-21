%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subset_fine_and_merge_to_coarse.m                                       %
%    Script to merge subset of a fine mesh to a coarser mesh              %
%    based on a given wind swath of the Hurricane track                   %
%                                                                         %
%    By William Pringle Oct 2020 - Jan 2021                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D'))
addpath('~/datasets/')
addpath('MESH_DIR')
%
% Setting up the projection variables
global MAP_PROJECTION MAP_COORDS MAP_VAR_LIST
%
%% Input Setup
% Input Storm Code
stormcode = 'STORMCODE';
% Input Coarse mesh bathy data
B_filename = 'GEBCO_2020.nc';
% Input buoyancy frequency values
N_filename = 'Gridded_N_values_WOA2018_2005-2017.mat';
%
% Input Mesh
fine = 'MESH';
% Input Coarse Mesh Property
coarse  = 'COARSE';

% Output Mesh Name
outname = 'MESH_STORM';

% Set some parameters
centroid = 0;  % = 0 [default] inpolygon test is based on whether all vertices
               % of the element are inside (outside) the bou polygon
               % = 1 inpolygon test is based on whether the element centroid
               % is inside (outside) the bou polygon
dbc = 0.35;    % The allowable boundary quality of coarse outer mesh
con = 9;       % The allowable element connectivity of coarse outer mesh
bc_points = [-60.0000   45.7;   % the start and end points of [lons, lats;
             -60.0000    8.8];  % the open boundary            lone, late]
wind_swath = 34; %[kt] wind speed at which to set the TC edge (34, 50, or 64)
deep_water = 250; %[m] the cutoff depth for "deep-water"
small_portion = 0.1; %fraction of the mesh that's considered a small disconnected portion to keep if cutoff
KCP = false;  % keep collinear points when making polyshape?
bathy_gradient_limit = 0.1; % the allowable gradient of bathymetry
     
%% Load the track data and determine the high-res region
try
   trackfile = [upper(stormcode) '_windswath'];
   shp = m_shaperead(trackfile);
catch
   trackfile = [lower(stormcode) '_windswath'];
   shp = m_shaperead(trackfile);
end
% Set high-res region to the "wind_swath"-kt wind speed boundary...
rad = cell2mat(shp.dbf.RADII); WI = find(rad == wind_swath,1,'last');
swath_poly = shp.ncst{WI};
% make sure only get the outer polygon component. 
WI = find(isnan(swath_poly(:,1)),1,'first');
if ~isempty(WI)
   swath_poly = swath_poly(1:WI-1,:);
end

%% Load the meshes, extract properties of coarse mesh 
%% and extract the desired subset of fine mesh
tic
% Load coarse mesh 
mc = load(coarse); mc = mc.m;
% Load fine mesh
load(fine)
% Add Lambert projection based on maximum extents of both meshes
bb = [min(min(m.p)',min(mc.p)') max(max(m.p)',max(mc.p)')];
m_proj('lam','lon',bb(1,:),'lat',bb(2,:))

% Get coarse mesh properties
% The outer polygon
[p2(:,1),p2(:,2)] = m_ll2xy(mc.p(:,1),mc.p(:,2)) ;
mc.p = p2;
poly_vec = getBoundaryOfMesh(mc);
% The edgesize function
bars = GetBarLengths(mc);
bm = 0.5*(p2(bars(:,1),:) + p2(bars(:,2),:));
bl = p2(bars(:,1),:) - p2(bars(:,2),:);
bl = hypot(bl(:,1),bl(:,2));
F = scatteredInterpolant(bm(:,1),bm(:,2),bl);
clear p2 bars bm bl

m.bd = [];
% Extract the subdomain from fine mesh
ms = extract_subdomain(m,swath_poly,0,centroid);
% Extract the inverse of the subdomain
mi = extract_subdomain(m,swath_poly,1,centroid);
% Keep the small disconnected portions 
mi = extract_small_portion( mi, small_portion, 0, 1 );
% add back small disconnected portions to ms
ms = cat(ms,mi); 
% reset mesh properties for ms back to those of original m 
ms.b = m.b; ms.bx = m.bx; ms.by = m.by; 
ms.bd = m.bd; ms.f13 = m.f13; 
% get the indice to map the original mesh properties to ms
ind = ourKNNsearch(m.p',ms.p',1);
% Map mesh properties
ms = map_mesh_properties(ms,ind);
clear m
% get element depths
[~,bc] = baryc(ms);
% remove the parts in deep water
ms.t(bc > deep_water,:) = [];
% project the vertices in ms 
[p1(:,1),p1(:,2)] = m_ll2xy(ms.p(:,1),ms.p(:,2)) ;
ms.p = p1;
% clean the mesh to make sure it is traversable
ms = ms.clean('passive','proj',0,'con',0);
%
toc
%% Get boundary of the fine subset mesh and subtract from the outer one
tic
% get the ms polygonal boundary as a cell
ms_bound = getBoundaryOfMesh(ms,1);
% determine the area of each polygon
area = zeros(size(ms_bound));
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
% fine polyshape
fine_pg = polyshape(ms_poly_vec,'KeepCollinearPoints',KCP);
% coarse polyshape
coarse_pg = polyshape(poly_vec,'KeepCollinearPoints',KCP);
% the substracted polygon (fine substracted from coarse)
diff_pg = subtract(coarse_pg,fine_pg);
poly_vec = diff_pg.Vertices;
poly_vec(end+1,:) = [NaN NaN]; % append NaN to end to avoid error
% remove vertices not in coarse or fine polygons
[~,Id] = setdiff(poly_vec,[fine_pg.Vertices; coarse_pg.Vertices],'rows');
Id = Id(~isnan(poly_vec(Id,1)));
poly_vec(Id,:) = [];
% turn into node edge (automatically removes less than 3 edge polygons) 
[node,edge] = getnan2(poly_vec,0,3);
%x = node(:,1); y = node(:,2);
%x = x(edge); y = y(edge);
%xt = diff(x,[],2);
%yt = diff(y,[],2);
%dd = hypot(xt,yt);
%disp(min(dd)*6378e3) % display minimum distance between vertices
toc
%% Make the delaunay-refinement mesh based on size function and the subtracted polygon
tic
opts.iter = 100;
opts.kind = 'delaunay';
opts.ref1 = 'preserve';
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
% if fine subset contains weirs carry these over...
if ~isempty(ms.bd) && any(ms.bd.ibtype == 24)
    m = carryoverweirs(m,ms);
end
% project back to lat-lon
[m.p(:,1),m.p(:,2)] = m_xy2ll(m.p(:,1),m.p(:,2)) ;
[ms_poly_vec(:,1),ms_poly_vec(:,2)] = m_xy2ll(ms_poly_vec(:,1),ms_poly_vec(:,2)) ;
toc
%% Add on open bc, bathy, and recompute global f13 attributes
tic
% make the outer bc
bc_k = ourKNNsearch(m.p',bc_points',1);
m = make_bc(m,'outer',0,bc_k(1),bc_k(2),2);
% interpolate the NaN parts of mesh using B_filename data
m = interp(m,B_filename,'K',find(isnan(m.b)),'type','depth',...
           'ignoreOL',1,'nan','fill');
% limit the slope of bathmetry to 0.1 
m = lim_bathy_slope(m,bathy_gradient_limit,-1);
% interpolate the NaN parts of mesh using B_filename data
%m = interp(m,B_filename,'K',find(isnan(m.bx)),'type','slope',....
%           'ignoreOL',1,'nan','fill');
% recompute the tau0 (-3 option)
m = Calc_tau0(m);
% recompute the internal tide using N_filename data
%m = Calc_IT_Fric(m,N_filename,'cutoff_depth',250,'Cit',2.75);
% save the mesh
save([outname '.mat'],'m','ms_poly_vec');
toc
