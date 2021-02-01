%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make_f15_vortex_and_write_mesh.m                                        %
% Script to make new f15 for the current vortex                           %
% and write out the ADCIRC mesh files                                     %
% By William Pringle Oct 2020 - Jan 2021                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; close all

addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath('~/datasets/')
addpath('MESH_DIR')

%% Load the mesh
load('MESH.mat')

% Set the output filename
outname = 'MESH_STORM';

%% Set integration logical
explicit = EXPLICIT_INT;

%% Set Storm Code
stormcode = 'STORMCODE';

% Some constants
spinupdays = 10; % spinup time [days]
rampdays = 5;    % ramping time [days]
outg = 3;        % global elevation output interval [hours]
outs = 12;       % station elevation output interval [min]
BLAdj = 0.9;     % wind speed adjustment factor to the boundary layer
geofactor = 1;   % geofactor is one to consider Coriolis effect
maxlon = -63;    % maximum longitude allowed for start of storm

%% Get the storm start/end times from the downloaded GIS track
% Input Storm Track
try
   trackfile = [upper(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
catch
   trackfile = [lower(stormcode) '_pts'];
   shp = m_shaperead(trackfile);
end
track = cell2mat(shp.ncst);
% Find where first enters domain (lon is less than our maxlon variable)
inside = find(track(:,1) < maxlon,1,'first');
% This is our start-date
ts = num2str(shp.dbf.DTG{inside});
ys = str2num(ts(1:4));
ms = str2num(ts(5:6));
ds = str2num(ts(7:8));
hs = str2num(ts(9:10));
% Replace start date in the atcf downloader script
system(['sed -i -- s/STARTDATE/' ts '/g dl_storm_atcf.sh']);
% End of track is our end-date
te = num2str(shp.dbf.DTG{end});
ye = str2num(te(1:4));
me = str2num(te(5:6));
de = str2num(te(7:8));
he = str2num(te(9:10));

%% make the cold start

% Set time step
if explicit
   % based on CFL of 0.7 making sure that the
   % time step is divisable by minutes
   minutes_divisor = ceil(60/(0.5*sqrt(2)*min(CalcCFL(m))));
   DT = round(60/minutes_divisor,4) %[s]
else
   % not sure how to define, just guess atm
   DT = 12 %[s]
end

% Make f15 data using the following times, constituents and stations
TS = datetime(ys,ms,ds,hs,0,0) - spinupdays; % simulation start time
TE = datetime(ye,me,de,he,0,0); % simulation end time
TSS = datestr(TS)
TES = datestr(TE)

% List of constituents for tidal potential and SAL terms (also for boundary
% conditions but SA and SSA will be omitted automatically)
CONST = "major8";
tpxoh = 'h_tpxo9.v1.nc'; 

% Make the fort.15 struct
m = Make_f15(m,TSS,TES,DT,'const',CONST,'tidal_database',tpxoh); 

% metadata
m.f15.nscreen = floor(24*3600/m.f15.dtdp);
m.f15.rundes = ['Storm Code: ' stormcode]; % Run description
m.f15.runid = [outname '-CS']; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = 'Tide Only';

% ramping
m.f15.nramp = 1;
m.f15.dramp = rampdays;

% numerical parameters
m.f15.ics = 22;
m.f15.elsm = -0.2;

if explicit
  m.f15.im = 511112;
  m.f15.tau0 = -3;
  m.f15.a00b00c00 = [0 1.0 0];
else
  m = Calc_tau0(m,'opt',DT,'kappa',0.5);
  m.f15.im = 511113;
  ind = find(contains({m.f13.defval.Atr(:).AttrName},'primitive'));
  m.f15.AttrName(ind) = [];
  m.f15.nwp = length(m.f15.AttrName);
end

% tidal harmonic output 
m.f15.outhar = [0 0 0 0];
m.f15.outhar_flag = [0 0 0 0];
% global elevation output
m.f15.outge = [0 0 0 0]; 
m.f15.outgv = [0 0 0 0]; 
% station elevation output
m.f15.oute =  [5 0 m.f15.rndy floor(outs*60/m.f15.dtdp)]; 
m.f15.nstae = -128;
rndy = m.f15.rndy;
m.f15.rndy = spinupdays;

% set hotstart output
m.f15.nhstar = [-5 floor(spinupdays*24*3600/m.f15.dtdp)];

% writing out the coldstart
write(m,[outname '_CS'],'15');

%% make the hot start
m.f15.nhstar = [0 0];
m.f15.ihot = 567;
m.f15.nramp = 8;
m.f15.dramp = [0 0 0 0 0 0 0.5 0 spinupdays]; % ramping met up for half a day
m.f15.nws = 20;
               %YYYY MM DD HH24 StormNumber BLAdj geofactor
m.f15.wtimnc = [year(TS) month(TS) day(TS) hour(TS) 1 BLAdj geofactor];
m.f15.rndy = rndy;

% elevation output
m.f15.oute =  [5 spinupdays m.f15.rndy floor(outs*60/m.f15.dtdp)]; 
m.f15.outge = [5 spinupdays m.f15.rndy floor(outg*3600/m.f15.dtdp)]; 
% met output
m.f15.outgm = [5 spinupdays m.f15.rndy floor(outg*3600/m.f15.dtdp)]; 

% metadata
m.f15.runid = [outname '-HS']; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = 'Tide + GAHM vortex forcing';

% writing out the hotstart
write(m,[outname '_HS'],'15');

% write out the f13 and f14 files
write(m,outname,{'13','14'});
