% Make a global mesh multiscale
clearvars; clc; close all
addpath(genpath('~/MATLAB/'));

%% STEP 1: set mesh extents and set parameters for mesh. 
%% The greater US East Coast and Gulf of Mexico region
min_el    = 90;                 % minimum resolution in meters.  
max_el_ns = min_el*5; 
max_el   = [25e3 0 -inf;
            max_el_ns inf 0]; 

grade     = 0.20;               % mesh grade in decimal percent. 
R         = -5; 			    % Number of elements to resolve feature.
bo        = 2.5;                % min underwater depth
elev      = 10;                % max overland height
CFL       = 0.75;               % set target CFL
g         = 9.81;
U         = sqrt(g*max(bo,1)) + sqrt(g./max(bo,1));
dt        = round(CFL*min_el/U,0);  % set target dt
itmax     = 200;
djc       = 0.01;

bathy    = '../BATHY/SRTM15+V2.nc';  % the bathy data
shp      = '../SRTM3/SWBD/';
hgt      = '../SRTM3/HGT/';    

outdir   = 'SRTM3_';

lonmin    = -110;
lonmax    = - 91;
latmin    = +  0;
latmax    = + 59;

jj = 0;
for ii = lonmin:lonmax
    for jj = latmin:latmax

        bbox = [ii ii+1; jj jj+1];
        
        lonstr = pad(num2str(abs(ii)),3,'left','0');
        if ii >= 0; londir = 'e'; else; londir = 'w'; end
        latstr = pad(num2str(abs(jj)),2,'left','0');
        if jj >= 0; latdir = 'n'; else; latdir = 's'; end
        
        % lmsl filename
        lmsl = [shp londir lonstr latdir latstr];
        listing = dir([lmsl '*']);
        if isempty(listing); continue; end

        [~,lmsl] = fileparts(listing(1).name);
        lmsl = [listing(1).folder '/' lmsl];
        
        % topo filenames
        topo = [hgt upper(latdir) latstr upper(londir) lonstr '.nc'];     
       
        if ~exist(topo,'file'); continue; end 
        
        outname = [outdir londir lonstr latdir latstr '.mat'];
        if exist(outname,'file'); continue; end
        
        %% Calculate ocean only portion 
       
        disp(['Processing ' lmsl])
 
        % Geodata
        gdat = geodata('dem',bathy,'shp',lmsl,'h0',min_el,'bbox',bbox);
          
        if isempty(gdat.mainland) && isempty(gdat.inner)
            continue;
        end
        pgon = polyshape([gdat.mainland; gdat.inner]);
        if pgon.area < 1e-2
            disp('not enough water area skipping')
            continue; 
        end

        % Edgefx
        fh   = edgefx('geodata',gdat,'fs',R,'max_el',max_el,...
                      'max_el_ns',max_el_ns,'dt',dt,'g',grade); 

        % Mesh
        mshopts = meshgen('ef',fh,'bou',gdat,'dj_cutoff',1e-3,...
                          'itmax',itmax,'plot_on',0,'proj','utm');
        mshopts = mshopts.build;
        mo      = mshopts.grd; % get out the msh object      
        
        % Get the fixed edges
        [egfix,pfix] = extdom_edges2(mo.t,mo.p) ;
        egfix = renumberEdges(egfix) ;
        fixboxes(1) = 1;

        %% Get full ocean + land mesh with fixed edges
        % Geodata
        gdat = geodata('dem',bathy,'bbox',bbox,'h0',min_el);
        gdatl = geodata('dem',topo,'shp',lmsl,'bbox',bbox,'h0',min_el);
       
        % Mesh
        ittt = 0;
        while ittt < 25
            ittt = ittt + 1;
            try 
                mshopts = meshgen('ef',fh,'bou',gdat,'plot_on',0,...
                                  'proj','utm',...
                                  'itmax',itmax,'pfix',pfix,...
                                  'egfix',egfix,'fixboxes',fixboxes);
                mshopts = mshopts.build;     
                break;
            catch
                gdat.inpoly_flip = mod(1,gdat.inpoly_flip);
            end
        end
        if ittt >= 25
            disp('too many loops')
            return
        end

        mlo     = mshopts.grd; % get out the msh object  
        
        %% Interp bathy and trim mesh
        % Interp bathy
        m = interpFP(mlo,gdatl,mo,gdat,bo) ;

        % Delete above 10 m flooplain
        m = pruneOverlandMesh(m,elev,djc); 

        % Make sure 10 sec timestep possible
        m = CheckTimestep(m,dt,0.75,djc);
        
        save(outname,'m')
    end
end
