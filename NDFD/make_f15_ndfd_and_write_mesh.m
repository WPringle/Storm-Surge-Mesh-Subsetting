%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make_f15_ndfd_and_write_mesh.m                                          %
% Script to make new f15 for the current NDFD forecast                    %
% and write out the ADCIRC mesh files                                     %
% By William Pringle Jan 2021 -                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; close all

addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath('~/datasets/')

outname = 'MESH';
load([outname '.mat'])

%% Set integration logical
explicit = EXPLICIT_INT;

%% Set Storm Name and Start/End Times
stormname = 'STORMNAME';
ys = YYYY;
ms = MMS;
ds = DDS;
hs = HHS;

% Some constantds
spinupdays = 10;  % spinup time [days]
rampdays = 5;     % ramping time [days]
forecastdays = floor(dlmread('last-ndfd-fcst-time.txt')/60)/24 % forecast duration [days]
outg = 3;         % global elevation output interval [hours]
outs = 12;        % station elevation output interval [min]
wtmh_nam = 3;     % NAM wind time interval [hours]
wtmh_ndfd = 3;    % NDFD wind time interval [hours]

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
TE = datetime(ys,ms,ds,hs,0,0) + forecastdays; % simulation end time
TSS = datestr(TS)
TES = datestr(TE)

% List of constituents for tidal potential and SAL terms (also for boundary
% conditions but SA and SSA will be omitted automatically)
CONST = "major8";
tpxoh = 'h_tpxo9.v1.nc'; 

% Make the fort.15 struct
m = Make_f15(m,TSS,TES,DT,'const',CONST,'tidal_database',tpxoh); 

% metadata
m.f15.nscreen = round(24*3600/m.f15.dtdp);
m.f15.rundes = ['Storm Name: ' stormname]; % Run description
m.f15.runid = [outname '-CS']; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = ['Tide + ' str2num(wtmh_ndfd) '-hrly NAM'];

% ramping
m.f15.nramp = 1;
m.f15.dramp = rampdays;

% numerical parameters
m.f15.ics = 22;
m.f15.elsm = -0.2;
m.f15.nws = 14;
m.f15.wtimnc = 3600*wtmh_nam; %[s]

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
m.f15.oute =  [5 0 m.f15.rndy round(outs*60/m.f15.dtdp)]; 
m.f15.nstae = -128;
rndy = m.f15.rndy;
m.f15.rndy = spinupdays; % Makes sure number of time steps is correct

% set hotstart output
m.f15.nhstar = [-5 floor(spinupdays*24*3600/m.f15.dtdp)];

% writing out the coldstart
write(m,[outname '_CS'],'15');

%% make the hot start
m.f15.nhstar = [0 0];
m.f15.ihot = 567;
m.f15.nramp = 0; %8;
m.f15.dramp = 0; %[0 0 0 0 0 0 0.5 0 spinupdays]; % ramping met up for half a day
m.f15.rndy = rndy;
m.f15.nws = 14; %20;
m.f15.wtimnc = 3600*wtmh_ndfd; %[s]

% elevation output
m.f15.oute =  [5 spinupdays m.f15.rndy round(outs*60/m.f15.dtdp)]; 
m.f15.outge = [5 spinupdays m.f15.rndy round(outg*3600/m.f15.dtdp)]; 
% met output
m.f15.outgm = [5 spinupdays m.f15.rndy round(outg*3600/m.f15.dtdp)]; 

% metadata
m.f15.runid = [outname '-HS']; % Run description
m.f15.extraline(1).msg = m.f15.rundes;
m.f15.extraline(6).msg = ['Tide + ' str2num(wtmh_ndfd) '-hrly NDFD forecast'];

% writing out the hotstart
write(m,[outname '_HS'],'15');

% write out the f13 and f14 files
write(m,outname,{'13','14'});
