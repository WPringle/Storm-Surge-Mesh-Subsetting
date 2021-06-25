%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_perturbed_tracks.m                                                 %
%  Plot the perturbed Hurricance Florence tracks                          %
%  By William Pringle, May 2021                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc; close all
%
% add paths to data and scripts
addpath('MMAPHOME/')

%%%% edit here
style = ["x-",".-"];
variables = ["along_track" "cross_track" "max_sustained_wind_speed" "radius_of_maximum_winds"];
direc = 'outputs/';
addpath(direc)
%%%%

%%%%%%% Setting up the domain and plotting 
m_proj('utm','lon',[-86 -60],'lat',[24 44])

for var = variables
   disp(['Plotting ' var{1} ' track perturbation'])
   clear h

   filenames = dir([direc var{1} '*.22']);
   filenames = {filenames.name};
   filenames = ['original.22' filenames];

   figure;

   title(['Florence 2018 ' var{1} ' comparison'],'interpreter','none')
   hold on
   
   if contains(var{1},'track')
      m_coast('patch',[.8 .8 .8]);

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

   else
      
       for ff = 1:length(filenames)
           T = readtable(filenames{ff},'FileType','text');
           VT = T.Var6;
           if contains(var{1},'speed') 
              value = T.Var9; units = ' [knots]';
           elseif contains(var{1},'radius') 
              value = T.Var20; units = ' [nm]';
           end
           h(ff) = plot(VT,value,style{min(length(style),ff)});
           %if ff == 1
           %   valueo = value;
           %else
           %   h(ff-1) = plot(VT,value-valueo,style{min(length(style),ff)});
           %end
       end
       grid on
       xlabel('Validation Time [hours]')
       ylabel([var{1} units],'interpreter','none')
   end
   legend(h,filenames,'location','best','interpreter','none')

   print([direc var{1} '_compare'],'-dpng','-r300')
end
