#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pandas    as pd
import sys,os
import netCDF4   as nc
import matplotlib
matplotlib.use("Agg") # so we don't need X-server


def read_csv(obs_dir, name, label):
    """
    

    
    """
    outt    = os.path.join(obs_dir, name, label)
    outd    = os.path.join(outt,'data')  
    if not os.path.exists(outd):
       sys.exit('ERROR',outd )

    table = pd.read_csv(os.path.join(outt,'table.csv')).set_index('station_name')
    table['station_code'] = table['station_code'].astype('str')
    stations = table['station_code']

    data     = []
    metadata = []
    for ista in range(len(stations)):
        sta   = stations [ista]
        fname8 = os.path.join(outd,sta)+'.csv'
        df = pd.read_csv(fname8,parse_dates = ['date_time']).set_index('date_time')
        
        fmeta = os.path.join(outd,sta) + '_metadata.csv'
        meta  = pd.read_csv(fmeta, header=0, names = ['names','info']).set_index('names')
        
        meta_dict = meta.to_dict()['info']
        meta_dict['lon'] = float(meta_dict['lon'])
        meta_dict['lat'] = float(meta_dict['lat'])        
        df._metadata = meta_dict
        data.append(df)
    
    return table,data
    
	
def read_fort61(name):

    ds = nc.Dataset(name) 
    h = ds.variables['zeta']
    stations = ds.variables['station_name']
    times = ds.variables['time']
    #datetime = nc.num2date(round_seconds(times),times.units)
    datetime = set_time(times)
    #print(datetime)
    data = []
    for sta in range(len(stations)):
       df = pd.Series(h[:,sta],index=datetime)
       data.append(df)
    # need to make dataframe type
    return data

def set_time(time):
    '''
        Converts time data into a pandas date object.

        Parameters
        ----------
        time: netcdf
            Contains time information.

        Returns
        -------
        pandas.DatetimeIndex
    '''
    times = nc.num2date(time[:].squeeze(), time.units,
                     only_use_cftime_datetimes=False,
                     only_use_python_datetimes=True)
    time = pd.DatetimeIndex(pd.Series(times)) #, tz=self.location.tz) 
    return time

	
def write_sta(table, name):
    """
    Writes out the table into the ADCIRC .151 format for station outputs
    
    """
    
    table.to_csv(name, header=[table.shape[0],'',''], sep='\t', index=False, columns=['lon','lat','station_code'])    


def plot_sta(obs, mod, sta_dat):
    """
      Plots the observed time series versus the simulated one

    """
    
    # loop over all the stations and make new figs
    for ind in range(len(sta_dat)):
       sta_code = sta_dat.station_code[ind]
       print("Plotting Station: " + sta_code)
       # plot the mod
       ax = mod[ind].plot() 
       # plot the obs
       obs[ind].plot()
       
       # save and close the figure 
       fig = ax.get_figure()
       fig.savefig('Figs/' + sta_code + '.png')
       matplotlib.pyplot.close(fig)
	
if __name__ == "__main__":


    obs_dir = 'DATA_DIR'
    name = 'STORMCODE'  
    name = name.upper() #capital
    
    ssh_table,ssh_obs      = read_csv (obs_dir, name, label='coops_ssh' )
    wnd_obs_table,wnd_obs  = read_csv (obs_dir, name, label='coops_wind')
    #wnd_ocn_table,wnd_ocn  = read_csv (obs_dir, name, label='ndbc_wind' )
    #wav_ocn_table,wav_ocn  = read_csv (obs_dir, name, label='ndbc_wave' )
	
    if sys.argv[1] == 'write':
       write_sta (ssh_table, 'elev_stat.151')    
       write_sta (wnd_obs_table, 'met_stat.151')    
    elif sys.argv[1] == 'plot':
       ssh_adc = read_fort61 ('fort.61.nc')
       plot_sta(ssh_obs, ssh_adc, ssh_table) 
