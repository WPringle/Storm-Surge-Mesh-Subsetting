# ! /usr/bin/env python
from os import getcwd, system, rename
from pathlib import Path
from dateutil.parser import parse as parse_date
from datetime import timedelta
from numpy import savetxt, array
from adcircpy.forcing.winds.best_track import BestTrackForcing
from matplotlib.pyplot import savefig, close

def get_vortex_track(output_directory,storm,start_date,duration,isotachs):

    if not output_directory.exists():
        output_directory.mkdir(parents=True, exist_ok=True)

    # set end date based on duration [days]
    end_date = start_date + timedelta(days=duration)

    # get the ATCF best track file
    cyclone = BestTrackForcing(
                storm,
                start_date=start_date,
                end_date=end_date,
    )
     
    # write out in fort.22 format
    cyclone.write(
                output_directory / f'{storm}.22', overwrite=True
    )
 
    # extract the wind swaths
    for isotach in isotachs:
        output_file = output_directory / f'{storm}_{str(isotach)}kt'
        # save the wind swath polygon as a file
        cyclone.plot_wind_swath(isotach=isotach)
        savefig(f'{output_file}.png')
        close()
        # save the wind swath polygon as a file
        swath = cyclone.wind_swath(isotach=isotach)
        savetxt(f'{output_file}.csv', array(swath.exterior.coords), delimiter=",")
 
def subset_merge_mesh(output_directory,coarse_mesh,fine_mesh,storm,depths,isotachs):
        
    if not output_directory.exists():
        output_directory.mkdir(parents=True, exist_ok=True)
    
    for depth in depths:
        for isotach in isotachs:
            #subset+merge process
            mcl = f'matlab -nodisplay -r "subset_HSOFS "{fine_mesh}" "{coarse_mesh}" "{storm}" "{isotach}" "{depth}";exit"' 
            print(mcl)
            system(mcl) 
      
    # move the output .mat & fort.1X files to the output_directory
    for f in Path('./').glob(f'*{storm}*'):
        f.rename(output_directory / f)       

if __name__ == '__main__':

    ## Setting up
    # get the directory we want to use in a "Path-like" format
    directory = getcwd()
    directory = Path(directory)
    # set the inputs / parameters
    storm_duration = 5 #[days]
    coarse_mesh = 'WNAT_1km'
    fine_mesh = 'HSOFS_2016'
    depths = [150] #[m] (d_{ref})
    isotachs = [34, 50, 64] #[kt]

    ## Florence 2018
    storm = 'Florence2018'
    start_date = parse_date('2018-09-11 00:00')
    # Get the track data and wind swaths 
    output_directory = directory / 'Florence' / 'data'
    get_vortex_track(output_directory,storm,start_date,storm_duration,isotachs)
    # Execute the subset and merging for different isotachs and cutoff depths
    #output_directory = directory / 'Florence' / 'mesh'
    #subset_merge_mesh(output_directory,coarse_mesh,fine_mesh,storm,depths,isotachs) 
    
    ## Sandy 2012
    storm = 'Sandy2012'
    start_date = parse_date('2012-10-26 00:00')
    ## Get the track data and wind swaths 
    output_directory = directory / 'Sandy' / 'data'
    get_vortex_track(output_directory,storm,start_date,storm_duration,isotachs)
    ## Execute the subset and merging for different isotachs and cutoff depths
    #output_directory = directory / 'Sandy' / 'mesh'
    #subset_merge_mesh(output_directory,coarse_mesh,fine_mesh,storm,depths,isotachs) 
    
    ## Irma 2017
    storm = 'Irma2017'
    start_date = parse_date('2017-09-07 00:00')
    # Get the track data and wind swaths 
    output_directory = directory / 'Irma' / 'data'
    get_vortex_track(output_directory,storm,start_date,storm_duration,isotachs)
    # Execute the subset and merging for different isotachs and cutoff depths
    #output_directory = directory / 'Irma' / 'mesh'
    #subset_merge_mesh(output_directory,coarse_mesh,fine_mesh,storm,depths,isotachs) 
    
    ## Matthew 2016
    #storm = 'Matthew2016'
    #start_date = parse_date('2016-10-05 00:00')
    # Get the track data and wind swaths 
    #output_directory = directory / 'Matthew' / 'data'
    #get_vortex_track(output_directory,storm,start_date,storm_duration,isotachs)
    # Execute the subset and merging for different isotachs and cutoff depths
    #output_directory = directory / 'Matthew' / 'mesh'
    #subset_merge_mesh(output_directory,coarse_mesh,fine_mesh,storm,depths,isotachs) 
