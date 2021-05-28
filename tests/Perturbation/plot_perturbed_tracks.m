%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_perturbed_tracks.m                                                 %
%  Plot the perturbed Hurricance Florence tracks                          %
%  By William Pringle, May 2021                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc;
%
% add paths to data and scripts
addpath('MMAPHOME')
addpath('outputs')

%%%% edit here
style = ["x-",".-"];
variables = ["along_track" "cross_track"];
direc = 'outputs/';
%%%%

%%%%%%% Setting up the domain and plotting 
m_proj('utm','lon',[-83 -60],'lat',[25 38])

for var = variables
   disp(['Plotting ' var{1} ' track perturbation'])

   filenames = dir([direc var{1} '*.22']);
   filenames = {filenames.name};
   filenames = ['original.22' filenames];

   figure;

   title(['Florence 2018 ' var{1} ' comparison'],'interpreter','none')
   m_coast('patch',[.8 .8 .8]);
   hold on

   for ff = 1:length(filenames)
       T = readtable(filenames{ff},'FileType','text');
       lats = T.Var7;
       lons = T.Var8;
       for ii = 1:length(lats)
          lat(ii) = str2double(lats{ii}(1:end-1))/10;
          lon(ii) = -str2double(lons{ii}(1:end-1))/10;
       end
       h(ff) = m_plot(lon,lat,style{min(length(style),ff)});
   end

   m_grid()

   legend(h,filenames,'interpreter','none')

   print([direc var{1} '_compare'],'-dpng','-r300')
end
