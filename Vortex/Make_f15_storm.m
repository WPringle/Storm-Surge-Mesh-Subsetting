%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make_f15_storm.m                                                        %
% Script to make new f15 for the current storm                            %
% By William Pringle Oct, 2020                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; close all

addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath(genpath('~/MATLAB/m_map/'))
addpath('/pontus/wpringle/tidedata')

outname = 'MESH';
load([outname '.mat'])

%% Set integration logical
explicit = EXPLICIT_INT;

%% Set Storm Formation Time and duration
stormname = 'STORMNAME';
stormcode = 'STORMCODE';
year = YYYY;
ms = MMS;
ds = DDS;
me = MME;
de = DDE;
hr = 0;

% Some constantds
spinupdays = 10; % spinup time [days]
rampdays = 5;    % ramping time [days]
outg = 3;        % global elevation output interval [hours]
outs = 12;       % station elevation output interval [min]
BLAdj = 0.78;    % wind speed adjustment factor to the boundary layer
geofactor = 1;   % geofactor is one to consider Coriolis effect
%% make the cold start

% Set time step
if explicit
   DT = 3; %[s]
else
   DT = 12; %16; %[s]
end

% Make f15 data using the following times, constituents and stations
TS = datetime(year,ms,ds,hr,0,0) - spinupdays; % simulation start time
TE = datetime(year,me,de,hr,0,0); % simulation end time
TS = datestr(TS);
TE = datestr(TE);

% List of constituents for tidal potential and SAL terms (also for boundary
% conditions but SA and SSA will be omitted automatically)
CONST = "major8";
tpxoh = 'h_tpxo9.v1.nc'; 

% Make the fort.15 struct
m = Make_f15(m,TS,TE,DT,'const',CONST,'tidal_database',tpxoh); 

% metadata
m.f15.nscreen = ceil(24*3600/m.f15.dtdp);
m.f15.rundes = ['Storm: ' stormname '(' stormcode ')']; % Run description
m.f15.runid = [outname '-CS']; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = 'Tide Only';

% ramping
m.f15.nramp = 1;
m.f15.dramp = rampdays;

% numerical parameters
m.f15.ics = 22;
m.f15.elsm = -0.2;

if ~explicit
  m = Calc_tau0(m,'opt',DT,'kappa',0.5);
  m.f15.im = 511113;
  m.f15.AttrName(1) = [];
  m.f15.nwp = length(m.f15.AttrName);
end

% tidal harmonic output 
m.f15.outhar = [0 0 0 0];
m.f15.outhar_flag = [0 0 0 0];
% global elevation output
m.f15.outge = [0 0 0 0]; 
m.f15.outgv = [0 0 0 0]; 
% station elevation output
m.f15.oute =  [5 0 m.f15.rndy ceil(outs*60/m.f15.dtdp)]; 
m.f15.nstae = -128;
rndy = m.f15.rndy;
m.f15.rndy = spinupdays;

% set hotstart output
m.f15.nhstar = [-5 ceil(spinupdays*24*3600/m.f15.dtdp)];

% writing out the coldstart
write(m,[outname '_CS'],'15');

%% make the hot start
m.f15.nhstar = [0 0];
m.f15.ihot = 567;
m.f15.nramp = 8;
m.f15.dramp = [0 0 0 0 0 0 1 0 spinupdays];
m.f15.nws = 20;
               %YYYY MM DD HH24 StormNumber BLAdj geofactor
m.f15.wtimnc = [year ms ds hr stormcode BLAdj geofactor];
m.f15.rndy = rndy;

% elevation output
m.f15.oute =  [5 spinupdays m.f15.rndy ceil(outs*60/m.f15.dtdp)]; 
m.f15.outge = [5 spinupdays m.f15.rndy ceil(outg*3600/m.f15.dtdp)]; 
% met output
m.f15.outgm = [5 spinupdays m.f15.rndy ceil(outg*3600/m.f15.dtdp)]; 

% metadata
m.f15.runid = [outname '-HS']; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = 'Tide + GAHM vortex forcing';

% writing out the hotstart
write(m,[outname '_HS'],'15');

% write out the f13 and f14 files
write(m,outname,{'13','14'});
