%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subset_HSOFS_GOM.m                                                      %
%                                                                         % 
%  Script to merge subsets of the fine HSOFS mesh based on user-defined   %
%  regions with basin-scale "GOM_1km" mesh                                %
%                                                                         %
%  By William Pringle Mar 2021                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath(genpath('~/MATLAB/OceanMesh2D'))
addpath('../../mesh/')
addpath('~/datasets/')
%
% Setting up the projection variables
global MAP_PROJECTION MAP_COORDS MAP_VAR_LIST
%
%% Input Setup
% Input regions
regions = dlmread('regions.txt');
% Input Mesh
fine = 'HSOFS';
% Input Coarse Mesh
coarse  = 'GOM_1km';

% Set some parameters
centroid = 0;   % = 0 [default] inpolygon test is based on whether all vertices
                %   of the element are inside (outside) the bou polygon
                % = 1 inpolygon test is based on whether the element centroid
                %   is inside (outside) the bou polygon
dbc = 0.35;     % The allowable boundary quality of coarse outer mesh
con = 9;        % The allowable element connectivity of coarse outer mesh
deep_water = 250; %[m] the cutoff depth for "deep-water"
afrac = 0.5;    % max allowable fraction of the fine mesh to append to TC
                % swath and fine mesh intersection polygon if cut off 
append = false; % whether to append the extra portions of the mesh
KCP = false;    % keep collinear points when making polyshape?
bathy_gradient_limit = 0.1; % the allowable gradient of bathymetry

%% Load the meshes, compute new projection extents,
%% get outer mesh boundary polygons
% Load coarse mesh and make the bathy interpolant 
mc = load(coarse); mc = mc.m;
coarse_bathy_interpolant = scatteredInterpolant(mc.p(:,1),mc.p(:,2),mc.b);
% Load fine mesh
mf = load(fine); mf = mf.m;
% Remove the open bc
mf.op = [];   
mf = mf.remove_attribute('dir');
% Find the minimum CFL of the mesh we need to satisfy
DT = min(CalcCFL(mf));

% Add Lambert projection based on maximum extents of both meshes
bb = [min(min(mf.p)',min(mc.p)') max(max(mf.p)',max(mc.p)')];
m_proj('lam','lon',bb(1,:),'lat',bb(2,:))

% Get mesh boundaries and turn into polyshapes 
fine_vec = get_boundary_of_mesh(mf);
fine_poly = polyshape(fine_vec,'KeepCollinearPoints',KCP);
coarse_vec = get_boundary_of_mesh(mc);
coarse_poly = polyshape(coarse_vec,'KeepCollinearPoints',KCP);
clear fine_vec coarse_vec

% Loop over all the regions
for rr = 1:size(regions,1)
   % Output Mesh Name
   mkdir(['HSOFS_GOM_' num2str(rr) '/']);
   outname = ['HSOFS_GOM_' num2str(rr) '/HSOFS_GOM_' num2str(rr)];
   %% Load the high-res region data
   bbox = reshape(regions(rr,:),2,2)';
   bou_vec = bbox_to_bou(bbox);
   if append
      bou_poly = polyshape(bou_vec);
      %% Perform the polygon arithmetic (1)
      % 1) Find the intersection polygon between swatch_poly & fine_poly
      intersect_poly = intersect(bou_poly,fine_poly);
      area_int = intersect_poly.area;
      % 2) Append small connected portions of the fine_poly not within swath_poly
      % check diff polygon for small regions that are connected to the wind swath
      diff_poly = subtract(fine_poly,bou_poly);
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
   else
      intersect_vec = bou_vec;
   end
   % Extract the subdomain from fine mesh only keeping depths < deep_water
   [m,ind] = extract_subdomain(mf,intersect_vec,...
                 'centroid',centroid,'max_depth',deep_water);
   % Map mesh properties
   m = map_mesh_properties(m,'ind',ind);
   % clean the mesh to remove disjoint nodes and make sure it is traversable
   m = m.clean('passive','proj',0,'con',0);
   clear intersect_poly intersect_vec

   %% Perform polygon arithmetic (2)
   % 1) Find new polygon of the fine mesh
   fine_vec = get_boundary_of_mesh(m);
   fine_poly2 = polyshape(fine_vec,'KeepCollinearPoints',KCP);
   clear fine_vec
   % 2) Subtract the intersection polygon from the coarse poly
   new_coarse_poly = subtract(coarse_poly,fine_poly2);
   new_coarse_vec = new_coarse_poly.Vertices;
   new_coarse_vec(end+1,:) = [NaN NaN]; % append NaNs to avoid getnan2 error
   clear new_coarse_poly
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
   mc2 = msh('points',pc,'elements',tc);
   clear pc tc etri tnum
   mc2.proj = MAP_PROJECTION;
   mc2.coord = MAP_COORDS;
   mc2.mapvar = MAP_VAR_LIST;
   mc2 = clean(mc2,'passive','db',dbc,'proj',0,'con',con);
   % project back mc2 to lat-lon
   [mc2.p(:,1),mc2.p(:,2)] = m_xy2ll(mc2.p(:,1),mc2.p(:,2)) ;
   % Interpolate the bathy from the original coarse mesh
   mc2.b = coarse_bathy_interpolant(mc2.p); 

   %% Merge match meshes together and carry over attributes from fine mesh, m
   disp(['Coarse mesh vertices = ', num2str(length(mc2.p))])
   disp(['Fine mesh vertices = ', num2str(length(m.p))])
   m = plus(m,mc2,'match');  
   disp(['Combined mesh vertices = ', num2str(length(m.p))])

   %% Add on open bc, bathy, and recompute global f13 attributes
   % limit the slope of bathmetry to 0.1 
   m = lim_bathy_slope(m,bathy_gradient_limit,-1);
   % Make sure CFL satisfies at least that of the original mesh
   m = m.bound_courant_number(DT,1);

   % recompute the tau0 (-3 option)
   m = Calc_tau0(m);

   % make the outer bc
   m.op = mc.op;
   for opp = 1:mc.op.nope
      op_ind = mc.op.nbdv(1:mc.op.nvdll(opp),opp);
      bc_k = ourKNNsearch(m.p',mc.p(op_ind,:)',1);
      m.op.nbdv(1:m.op.nvdll(opp),opp) = bc_k;
   end

   %write out fort files
   ts = datetime(2005,8,1);
   te = datetime(2005,8,30);
   tss = datestr(ts);
   tes = datestr(te);
   dt = 4.6;
   m = Make_f15(m,tss,tes,dt,'const',"major8",'tidal_database','h_tpxo9.v1.nc');
   write(m,outname)

   % save the mesh
   save([outname '.mat'],'m','fine_poly2');
end
