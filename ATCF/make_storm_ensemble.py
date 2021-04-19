#! /usr/bin/env python3
"""
Script to extract an ATCF best track dataset and modify it 
e.g., Make it more intense or larger in size

- central_pressure is made weaker and stronger, and
  the Vmax is proportionally changed based on Holland B

By William Pringle, Mar 2021 - 
"""

from datetime import datetime, timedelta
from adcircpy.forcing.winds.best_track import BestTrackForcing
from copy import deepcopy
from math import exp
from sys import argv

def main(storm_code,start_date,end_date):
    #Example: 
    #storm_code="al062018" #NHC storm code
    #start_date = datetime(2018,9,11,6)
    #end_date = datetime(2018,9,17,18)

    # getting best track
    BT = BestTrackForcing(storm_code, start_date=start_date, end_date=end_date)
    
    # write out original fort.22
    BT.write("original.22",overwrite=True)
   
    # extracting original dataframe   
    df_original = BT.df

    # modifying the central pressure while subsequently changing 
    # Vmax using the same Holland B parameter,  
    # writing each to a new fort.22
    variable_list = ["central_pressure"]
    alpha = [0.9]  # the multiplier for each variable
    vmax_var = "max_sustained_wind_speed" 
    rho_air = 1.15 # density of air [kg/m3]
    Pb = 1013.0    # background pressure [mbar]
    kts2ms = 0.514444444 # kts to m/s
    mbar2pa = 100 # mbar to Pa
    e1 = exp(1.0) # e 
    for idx, var in enumerate(variable_list):
       print(var)
       # make a deepcopy to preserve the original dataframe 
       df_modified = deepcopy(df_original)
       df_modified[var] = df_modified[var]*alpha[idx]
       if var == "central_pressure":
          print("here")
          Vmax = df_original[vmax_var]*kts2ms  
          print(Vmax)
          DelP = (Pb - df_modified[var])*mbar2pa 
          print(DelP)
          Holland_B = Vmax*Vmax*rho_air*e1/DelP
          print(Holland_B)
       # reset the dataframe
       BT._df = df_modified  
       # write out the modified fort.22
       BT.write(var + ".22",overwrite=True)

if __name__ == '__main__':
    # Parse storm code
    try:
       stormcode = argv[1]
    except IndexError:
       print("Storm name/code must be supplied on the command line")
       raise
    start_date=None
    end_date=None
    if len(argv) > 2:
       start_date=datetime.strptime(argv[2], '%Y%m%d%H')
    if len(argv) > 3:
       end_date=datetime.strptime(argv[3], '%Y%m%d%H')
    # Enter function
    main(stormcode,start_date,end_date)
