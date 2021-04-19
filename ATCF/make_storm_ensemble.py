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
from pandas import DataFrame

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
    alpha = [0.9]
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
          #print("here")
          #Vmax = df_original[vmax_var]*kts2ms  
          Initial_Vmax = intensity_class(df_original[vmax_var].iloc[0])
          print(Initial_Vmax)
          #DelP = (Pb - df_modified[var])*mbar2pa 
          #print(DelP)
          #Holland_B = Vmax*Vmax*rho_air*e1/DelP
          #print(Holland_B)
          print(mean_absolute_errors[vmax_var][Initial_Vmax])
       # reset the dataframe
       BT._df = df_modified  
       # write out the modified fort.22
       BT.write(var + ".22",overwrite=True)

VT=[0, 12, 24, 36, 48, 72, 96, 120] 
# Category for Vmax based intensity
def intensity_class(x):
  if x < 50:
    return "<50kt" #weak
  elif x > 95:
    return ">95kt" #strong
  else:
    return "50-95kt" #medium
# Mean absolute errors for Vmax based on initial intensity
Vmax_weak_errors = DataFrame(data=[1.45, 4.01, 6.17, 8.42, 10.46, 14.28, 18.26, 19.91],index=VT,columns=["mean error [kt]"]) 
Vmax_medium_errors = DataFrame(data=[2.26, 5.75, 8.54, 9.97, 11.28, 13.11, 13.46, 12.62],index=VT,columns=["mean error [kt]"]) 
Vmax_strong_errors = DataFrame(data=[2.80, 7.94, 11.53, 13.27, 12.66, 13.41, 13.46, 13.55],index=VT,columns=["mean error [kt]"]) 
# Dictionary of mean absolute errors for Vmax 
Vmax_errors = {
    "<50kt": Vmax_weak_errors,  
    "50-95kt": Vmax_medium_errors, 
    ">95kt":   Vmax_strong_errors
}
# Dictionary of mean absolute errors by variable
mean_absolute_errors = {
    "max_sustained_wind_speed": Vmax_errors,
    "radius_of_maximum_wind_speed": "N/A",
    "cross_track": "N/A",
    "along_track": "N/A",
}

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
