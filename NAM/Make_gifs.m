% Plot gifs of maxeles and wind streamlines
clc; clearvars; close all
addpath(genpath('~/MATLAB/'))

stormtide = 1;

if stormtide
   cmin = -2; cmax = 2;
else 
   cmin = 0;  cmax = 0.5;
end

RUNL = 5; % days

% regions
regions = {[-98,24,16,8]};
regionnames = ["GOM"];
regionlongnames = ["Gulf of Mexico"];

% filename
fort63 = 'fort.63.nc';

% setting up
x = ncread(fort63,'x');
y = ncread(fort63,'y');
b = ncread(fort63,'depth');
t = ncread(fort63,'time');
ele = ncread(fort63,'element')';
tss = ncreadatt(fort63, 'time', 'base_date');
stf = strfind(tss,'UTC');
if ~isempty(stf)
   tss = tss(1:stf-1);
end
tss = datetime(tss);
t = t/3600/24 + tss;
ztot = 0*x;
nn = 1;

%% Make regional gifs
figure;
figc = gcf;
figc.Position(3) = figc.Position(3)*2;
figc.Position(4) = figc.Position(4)*2;
for r = 1:length(regions)
    m_proj('lam','long',[regions{r}(1) regions{r}(1)+regions{r}(3)],...
                 'lat',[regions{r}(2) regions{r}(2)+regions{r}(4)])
    
    for tt = 1:length(t)   
        height = ncread(fort63,'zeta',[1 tt],[length(x) 1]);
        h = m_trisurf(ele,x,y,height);
        ax = gca;
        ax.Color = [166 132	97]/255;
        m_grid()
        if stormtide
           cmocean('balance',32)
        else
           colormap(lansey)
        end
        caxis([cmin cmax])
        cb = colorbar;
        if stormtide
            cb.Label.String = 'storm tide elevation [m]';
            title([datestr(t(tt),'yyyy-mm-dd HH:MM') ' UTC'])
        else
            cb.Label.String = 'storm surge height [m]';
            title([datestr(t(tt),'yyyy-mm-dd HH:MM') ' UTC'])
        end
        if tt == 1
            gif(['StormTide_' regionnames{r} '.gif'],...
                 'frame',gcf,'DelayTime',0.5); 
        else
            gif('frame',gcf)
        end
        clf;
    end
end
