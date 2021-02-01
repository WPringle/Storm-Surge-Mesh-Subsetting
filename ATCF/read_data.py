#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pandas    as pd
import sys,os





def read_csv(obs_dir, name, year, label):
    """
    

    
    """
    outt    = os.path.join(obs_dir, name+year,label)
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
    
	
	
	
if __name__ == "__main__":

obs_dir = 'path_2_dir'
name = 'IRENE'   #capital
year = '2011'    #string
	
ssh_table,ssh          = read_csv (obs_dir, name, year, label='coops_ssh' )
wnd_obs_table,wnd_obs  = read_csv (obs_dir, name, year, label='coops_wind')
wnd_ocn_table,wnd_ocn  = read_csv (obs_dir, name, year, label='ndbc_wind' )
wav_ocn_table, wav_ocn = read_csv (obs_dir, name, year, label='ndbc_wave' )
