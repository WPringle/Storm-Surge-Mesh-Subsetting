%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make_f15_vortex_and_write_mesh.m                                        %
% Script to make new f15 for the current vortex                           %
% and write out the ADCIRC mesh files                                     %
% By William Pringle Oct 2020 - Jan 2021                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; close all

addpath(genpath('~/MATLAB/OceanMesh2D/'))
addpath('~/datasets/')

outname = 'HSOFS_nosubset_al062018';
load([outname '.mat'])

%% Set integration logical
explicit = true;

%% Set Storm Code
stormcode = 'al062018';

% Some constantds
f22 = 'fort.22'; % ATCF storm data filename
spinupdays = 10; % spinup time [days]
rampdays = 5;    % ramping time [days]
outg = 3;        % global elevation output interval [hours]
outs = 12;       % station elevation output interval [min]
BLAdj = 0.9;     % wind speed adjustment factor to the boundary layer
geofactor = 1;   % geofactor is one to consider Coriolis effect

%% get the storm start/end times from the downloaded data
fid = fopen(f22);
% start
% find from when the storm enters the domain
lon = -999; lat = -999;
while lon > max(m.p(:,1)) || lon < min(m.p(:,1)) || ...
      lat > max(m.p(:,2)) || lat > max(m.p(:,2))
   firstline = fgetl(fid);
   lat = str2num(firstline(36:38))/10;
   lon = str2num(firstline(43:45))/10;
   if strcmp(firstline(39),'S'); lat = -lat; end
   if strcmp(firstline(46),'W'); lon = -lon; end
end
ys = str2num(firstline(9:12));
ms = str2num(firstline(13:14));
ds = str2num(firstline(15:16));
hs = str2num(firstline(17:18));
% end (at end of file)
while ~feof(fid)
  lastline = fgetl(fid);
end
ye = str2num(lastline(9:12));
me = str2num(lastline(13:14));
de = str2num(lastline(15:16));
he = str2num(lastline(17:18));
fclose(fid);

%% make the cold start

% Set time step
if explicit
   % based on CFL of 0.7 making sure that the
   % time step is divisable by minutes
   minutes_divisor = floor(60/(0.7*min(CalcCFL(m))));
   DT = 60/minutes_divisor %[s]
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
m.f15.nws = 8; %20;
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
