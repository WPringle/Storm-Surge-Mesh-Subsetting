function subset_HSOFS(fine,coarse,stormcode,isotach,deep_water) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subset_HSOFS.m                                                          %
%                                                                         % 
%  Script to merge subset of the fine mesh with the coarser mesh          %
%  based on the [istoach]-kt wind swath for the given storm "stormcode"   %
%                                                                         %
%  Inputs:                                                                %
%  fine:       .mat file name of fine mesh                                %
%  coarse:     .mat file name of coarse mesh                              %
%  stormcode:  name of storm/hurricane                                    %
%  isotach:    wind speed at which to set the TC edge [kt]                %
%  deep_water: the cutoff depth for "deep-water" [m] for subsetting       %
%                                                                         %
%  By William Pringle Sep 2021                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath(genpath('./'))
%
% Setting up the projection variables
global MAP_PROJECTION MAP_COORDS MAP_VAR_LIST
%
% Input wind swath
swath_file = [stormcode '_' isotach 'kt.csv'];
% Output Mesh Name
outname = [fine '_' stormcode '_' isotach 'kt_' deep_water 'm'];

% Set some parameters
centroid = 0;  % = 0 [default] inpolygon test is based on whether all vertices
               % of the element are inside (outside) the bou polygon
               % = 1 inpolygon test is based on whether the element centroid
               % is inside (outside) the bou polygon
dbc = 0.35;    % The allowable boundary quality of coarse outer mesh
con = 9;       % The allowable element connectivity of coarse outer mesh
bc_points = [-60.0000   45.7;   % the start and end points of [lons, lats;
             -60.0000    8.8];  % the open boundary            lone, late]
afrac = 0.5;   % max allowable fraction of the fine mesh to append to TC
               % swath and fine mesh intersection polygon if cut off 
KCP = false;   % keep collinear points when making polyshape?
bathy_gradient_limit = 0.1; % the allowable gradient of bathymetry
deep_water = str2double(deep_water) % convert to a float

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Operations from here...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load the meshes, compute new projection extents,
%% get outer mesh boundary polygons
% Load coarse mesh and make the bathy interpolant 
mc = load(coarse); mc = mc.m;
coarse_bathy_interpolant = scatteredInterpolant(mc.p(:,1),mc.p(:,2),mc.b);
% Load fine mesh
load(fine)
% For now just removing bcs
m.bd = []; m.op = []; 
% Find the minimum CFL of the mesh we need to satisfy
DT = min(CalcCFL(m));

% Add Lambert projection based on maximum extents of both meshes
bb = [min(min(m.p)',min(mc.p)') max(max(m.p)',max(mc.p)')];
m_proj('lam','lon',bb(1,:),'lat',bb(2,:))

% Get mesh boundaries and turn into polyshapes 
fine_vec = get_boundary_of_mesh(m);
fine_poly = polyshape(fine_vec,'KeepCollinearPoints',KCP);
coarse_vec = get_boundary_of_mesh(mc);
coarse_poly = polyshape(coarse_vec,'KeepCollinearPoints',KCP);
clear fine_vec coarse_vec
     
%% Load the wind swath pilygon which defines the high-res region to keep
swath_vec = csvread(swath_file);
swath_poly = polyshape(swath_vec);

%% Perform the polygon arithmetic (1)
% 1) Find the intersection polygon between swatch_poly & fine_poly
intersect_poly = intersect(swath_poly,fine_poly);
area_int = intersect_poly.area;
% 2) Append small connected portions of the fine_poly not within swath_poly
% check diff polygon for small regions that are connected to the wind swath
diff_poly = subtract(fine_poly,swath_poly);
pg = diff_poly.regions;
for ii = 1:length(pg)
    area_pg = pg(ii).area;
    % if pg area is smaller than a user-defined fraction (afrac) of
    % intersect polygon area, check adjacency to intersect polygon and append
    if area_pg < afrac*area_int
        LIA = ismembertol(intersect_poly.Vertices,pg(ii).Vertices,'ByRows',true);
        if sum(LIA) > 0
           intersect_poly = union(intersect_poly,pg(ii));
        end
    end
end

%% Extract the portion of fine mesh we want to keep
intersect_vec = intersect_poly.Vertices;
intersect_vec(end+1,:) = [NaN NaN]; % add NaN to end to avoid inpoly error
% Extract the subdomain from fine mesh only keeping depths < deep_water
[m,ind] = extract_subdomain(m,intersect_vec,...
            'centroid',centroid,'max_depth',deep_water);
% Map mesh properties
m = map_mesh_properties(m,'ind',ind);
% clean the mesh to remove disjoint nodes and make sure it is traversable
m = m.clean('passive','proj',0,'con',0);
clear intersect_poly intersect_vec

%% Perform polygon arithmetic (2)
% 1) Find new polygon of the fine mesh
fine_vec = get_boundary_of_mesh(m);
fine_poly = polyshape(fine_vec,'KeepCollinearPoints',KCP);
clear fine_vec
% 2) Subtract the intersection polygon from the coarse poly
new_coarse_poly = subtract(coarse_poly,fine_poly);
new_coarse_vec = new_coarse_poly.Vertices;
new_coarse_vec(end+1,:) = [NaN NaN]; % append NaNs to avoid getnan2 error
clear new_coarse_poly coarse_poly
% turn into node edge (automatically removes less than 3 edge polygons) 
[coarse_node,edge] = getnan2(new_coarse_vec,0,3);

%% Make the delaunay-refinement mesh using new_coarse_vec and size function
% Perform meshgen in the projected space
[coarse_node(:,1),coarse_node(:,2)] = m_ll2xy(coarse_node(:,1),coarse_node(:,2)) ;
% The coarse edgesize function
[pc(:,1),pc(:,2)] = m_ll2xy(mc.p(:,1),mc.p(:,2)) ;
bars = GetBarLengths(mc);
bm = 0.5*(pc(bars(:,1),:) + pc(bars(:,2),:));
bl = pc(bars(:,1),:) - pc(bars(:,2),:);
bl = hypot(bl(:,1),bl(:,2));
F = scatteredInterpolant(bm(:,1),bm(:,2),bl);
clear pc bars bm bl
% The refine2 options
opts.iter = 100;
opts.kind = 'delaunay';
opts.ref1 = 'preserve';
% make the delaunay refinement mesh
[pc,etri,tc,tnum] = refine2_om(coarse_node,edge,[],opts,@(p)F(p));  
% smooth the mesh 
[pc,~,tc,~] = smooth2(pc,etri,tc,tnum);
% Put into msh class and clean up a little
mc = msh('points',pc,'elements',tc);
clear pc tc etri tnum
mc.proj = MAP_PROJECTION;
mc.coord = MAP_COORDS;
mc.mapvar = MAP_VAR_LIST;
mc = clean(mc,'passive','db',dbc,'proj',0,'con',con);
% project back mc to lat-lon
[mc.p(:,1),mc.p(:,2)] = m_xy2ll(mc.p(:,1),mc.p(:,2)) ;

%% Concatenate meshes together and carry over attributes
m = cat(m,mc); % this order is important as cat will carry over info from 
% make sure m is using the full outer projection
m.proj   = MAP_PROJECTION;
m.coord  = MAP_COORDS;
m.mapvar = MAP_VAR_LIST;
m = m.clean('passive','djc',0.25,'con',0);

%% Add on open bc, bathy, and recompute global f13 attributes
% just get the bathy from the coarse mesh where NaN
m.b(isnan(m.b)) = coarse_bathy_interpolant(m.p(isnan(m.b),:)); 
% limit the slope of bathmetry to 0.1 
m = lim_bathy_slope(m,bathy_gradient_limit,-1);
% Make sure CFL satisfies at least that of the original mesh
m = m.bound_courant_number(DT,1);

% recompute the tau0 (-3 option)
m = Calc_tau0(m);

% make the outer bc
bc_k = ourKNNsearch(m.p',bc_points',1);
m = make_bc(m,'outer',0,bc_k(1),bc_k(2),2);

% save the mesh
save([outname '.mat'],'m','fine_poly');
write(m,outname,{'13','14'})
writematrix(fine_poly.Vertices,[outname '_subsetpoly.txt'])
