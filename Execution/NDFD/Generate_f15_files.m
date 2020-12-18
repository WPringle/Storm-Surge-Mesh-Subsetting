% Make the f15 files for the current storm
clearvars; clc; close all

% adding data and routines to path
addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath('~/datasets/')

% setting the name of the mesh
outname = 'WNAT_v14';
load(['../../mesh/' outname '.mat'])

% setting whether we used implicit or explicit timestepping
explicit = false;

%% Set Storm Formation Time and duration
stormname = 'STORM';
year = YY;
ms = MS;
ds = DS;
me = ME;
de = DE;
hs = HSS;
he = HE;

% Some constantds
spinupdays = 10; % spinup time [days]
rampdays = 5;    % ramping time [days]
outg = 3;        % global elevation output interval [hours]
outs = 12;       % station elevation output interval [min]
wtmh = 3;        % wind time interval [hours]
%% make the cold start

% Set time step
if explicit
   DT = 2; %[s]
else
   DT = 12; %16; %[s]
end

% Make f15 data using the following times, constituents and stations
TS = datetime(year,ms,ds,hs,0,0) - spinupdays; % simulation start time
TE = datetime(year,me,de,he,0,0); % simulation end time
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
m.f15.rundes = ['Fine Model - Hurricane ' stormname]; % Run description
m.f15.runid = 'WNAT_v14-CS'; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = 'Tide + 3-hrly NAM hindcast';

% ramping
m.f15.nramp = 1;
m.f15.dramp = rampdays;

% numerical parameters
m.f15.ics = 22;
m.f15.elsm = -0.2;
m.f15.nwp = 3;
m.f15.nws = 14;
m.f15.wtimnc = 3600*wtmh; %[s]

if ~explicit
  m = Calc_tau0(m,'opt',DT,'kappa',0.5);
  m.f15.im = 511113;
  m.f15.nwp = 2;
  m.f15.AttrName(1) = [];
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
m.f15.nramp = 0;
m.f15.dramp = 0;
m.f15.rndy = rndy;

% elevation output
m.f15.oute =  [5 spinupdays m.f15.rndy ceil(outs*60/m.f15.dtdp)]; 
m.f15.outge = [5 spinupdays m.f15.rndy ceil(outg*3600/m.f15.dtdp)]; 
% met output
m.f15.outgm = [5 spinupdays m.f15.rndy ceil(outg*3600/m.f15.dtdp)]; 

% metadata
m.f15.runid = 'WNAT_v14-HS'; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = 'Tide + 3-hrly NDFD forecast';

% writing out the hotstart
write(m,[outname '_HS'],'15');
