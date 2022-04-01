# ! /usr/bin/env python
from os import getcwd
from io import BytesIO
from pathlib import Path
from dateutil.parser import parse as parse_date
from datetime import timedelta
import geopandas
from urllib.request import urlretrieve

from adcircpy.forcing.winds.best_track import BestTrackForcing

def get_vortex_track(output_directory,storm,start_date):

    if not output_directory.exists():
        output_directory.mkdir(parents=True, exist_ok=True)

    # 5-day run
    end_date = start_date + timedelta(days=5)

    # get the ATCF best track file
    cyclone = BestTrackForcing(
                storm,
                start_date=start_date,
                end_date=end_date,
    )

    cyclone.write(
                output_directory / f'{storm}.22', overwrite=True
    )

    mask = cyclone.data['isotach'] == 34
    neq = cyclone.data['radius_for_NEQ'][mask] 
    seq = cyclone.data['radius_for_SEQ'][mask] 
    nwq = cyclone.data['radius_for_NWQ'][mask] 
    swq = cyclone.data['radius_for_SWQ'][mask] 
    breakpoint()

    # get the GIS data
    #gis_url = f'https://www.nhc.noaa.gov/gis/best_track/'  \
    #            + cyclone.storm_id.lower() + '_best_track.zip'
    # 
    #output_file = output_directory / f'{storm}_gis.zip' 
    #urlretrieve(gis_url,output_file)
    #
    # read and trim wind-swath based on times in cyclone data
    #try:
    #   input_file = output_directory / f'{storm}_gis.zip!{cyclone.storm_id}_windswath.shp'
    #   input_file = 'zip://' + str(input_file)
    #   df = geopandas.read_file(input_file)
    #except:
    #   input_file = output_directory / f'{storm}_gis.zip!{cyclone.storm_id.lower()}_windswath.shp'
    #   input_file = 'zip://' + str(input_file)
    #   df = geopandas.read_file(input_file)
    #print(df)
  
    #swath_vec(swath_vec(:,1) > maxlon,1) = maxlon;
    #swath_vec(swath_vec(:,2) < minlat,2) = minlat;
    #swath_poly = polyshape(swath_vec);
 
 
if __name__ == '__main__':
    # get the directory we want to use in a "Path-like" format
    directory = getcwd()
    directory = Path(directory)
    # set output directory
    output_directory = directory / 'data'

    # Florence 2018
    storm = 'Florence2018'
    start_date = parse_date('2018-09-11 00:00')
    get_vortex_track(output_directory,storm,start_date)
    
    # Matthew 2016
    storm = 'Matthew2016'
    start_date = parse_date('2016-10-04 12:00')
    get_vortex_track(output_directory,storm,start_date)
