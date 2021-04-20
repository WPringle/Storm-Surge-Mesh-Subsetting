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
from math import exp, inf
from sys import argv
from pandas import DataFrame
from random import gauss
from numpy import interp

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
    variable_list = ["max_sustained_wind_speed"]
    p_var = "central_pressure" 
    vmax_var = "max_sustained_wind_speed" 
    rho_air = 1.15 # density of air [kg/m3]
    Pb = 1013.0    # background pressure [mbar]
    kts2ms = 0.514444444 # kts to m/s
    mbar2pa = 100 # mbar to Pa
    e1 = exp(1.0) # e 
    number_of_perturbations = 3
    Initial_Vmax = intensity_class(df_original[vmax_var].iloc[0]) #The initial Vmax which defines the mean absolute errors
    print(Initial_Vmax)
    Storm_VT = (df_original["datetime"] - BT.start_date) / timedelta(hours=1)
    for var in variable_list:
       print(var)
       # Make the random pertubations based on the mean errors 
       # Interpolate from the given VT to the Storm_VT 
       #print(mean_absolute_errors[var][Initial_Vmax])
       xp = mean_absolute_errors[var][Initial_Vmax].index
       yp = mean_absolute_errors[var][Initial_Vmax].values.flat
       base_errors = interp(Storm_VT,xp,yp)
       #print(base_errors)
       for idx in range(1,number_of_perturbations+1):
           # make a deepcopy to preserve the original dataframe 
           df_modified = deepcopy(df_original)
           # get the random perturbation sample
           alpha = gauss(0,1)/0.7979 #mean_abs_error = 0.7979*sigma
           # add the error to the variable with bounds to some physical constraints
           df_modified[var] = perturb_bound(df_modified[var] + base_errors*alpha,var)
           print(alpha)
           if var == vmax_var:
               # In case of Vmax need to change the central pressure
               # incongruence with it (obeying Holland B relationship)
               print(df_modified[var])
               #Vmax = df_original[vmax_var]*kts2ms  
               #DelP = (Pb - df_modified[var])*mbar2pa 
               #print(DelP)
               #Holland_B = Vmax*Vmax*rho_air*e1/DelP
               #print(Holland_B)
           # reset the dataframe
           BT._df = df_modified  
           # write out the modified fort.22
           BT.write(var + "_" + str(idx) + ".22",overwrite=True)

################################################################
## Sub functions and dictionaries...
################################################################
# physical bounds of different variables
lower_bound = {
    "max_sustained_wind_speed": 25,      #[kt]
    "radius_of_maximum_wind_speed": 1,   #[nm]
    "cross_track": -inf,
    "along_track": -inf
}
upper_bound = {
    "max_sustained_wind_speed": 165,     #[kt]
    "radius_of_maximum_wind_speed": 200, #[nm]
    "cross_track": +inf,
    "along_track": +inf
}
# perturbing the variable with physical bounds
def perturb_bound(test_list,var):
    LB = lower_bound[var]
    UB = upper_bound[var]
    bounded_result = [min(UB,max(ele, LB)) for ele in test_list]
    return bounded_result
# Category for Vmax based intensity
def intensity_class(x):
  if x < 50:
    return "<50kt" #weak
  elif x > 95:
    return ">95kt" #strong
  else:
    return "50-95kt" #medium
# Index of absolute errors (forecast times [hrs)]
VT=[0, 12, 24, 36, 48, 72, 96, 120] 
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
