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

def main(number_of_perturbations,storm_code,start_date,end_date):
    #Example: 
    #number_of_perturbations = 3
    #storm_code="al062018" #NHC storm code
    #start_date = datetime(2018,9,11,6)
    #end_date = datetime(2018,9,17,18)

    # getting best track
    BT = BestTrackForcing(storm_code, start_date=start_date, end_date=end_date)
    
    # write out original fort.22
    BT.write("original.22",overwrite=True)
   
    # Computing Holland B and validation times from BT 
    Holland_B = compute_Holland_B(BT)
    Storm_VT = compute_VT_hours(BT)
    Storm_Strength = intensity_class(compute_Vmax_initial(BT)) 
    #print(Holland_B)
    #print(Storm_VT)
    print(Storm_Strength)
    
    # extracting original dataframe   
    df_original = BT.df

    # modifying the central pressure while subsequently changing 
    # Vmax using the same Holland B parameter,  
    # writing each to a new fort.22
    variable_list = ["max_sustained_wind_speed"]
    for var in variable_list:
       print(var)
       # Make the random pertubations based on the mean errors 
       # Interpolate from the given VT to the Storm_VT 
       #print(mean_absolute_errors[var][Initial_Vmax])
       xp = mean_absolute_errors[var][Storm_Strength].index
       yp = mean_absolute_errors[var][Storm_Strength].values.flat
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
               df_modified[pc_var] = compute_pc_from_Vmax(df_modified[var],Holland_B)
           # reset the dataframe
           BT._df = df_modified  
           # write out the modified fort.22
           BT.write(var + "_" + str(idx) + ".22",overwrite=True)

################################################################
## Sub functions and dictionaries...
################################################################
# get the validation time of storm in hours 
def compute_VT_hours(BT_test):
    VT = (BT_test.datetime - BT_test.start_date) / timedelta(hours=1)
    return VT
# the initial Vmax which defines the mean absolute errors
def compute_Vmax_initial(BT_test):    
    vmax_ini = BT_test.df[vmax_var].iloc[0] 
    return vmax_ini
# some constants
rho_air = 1.15 # density of air [kg/m3]
Pb = 1013.0    # background pressure [mbar]
kts2ms = 0.514444444 # kts to m/s
mbar2pa = 100  # mbar to Pa
pa2mbar = 0.01 # Pa to mbar
e1 = exp(1.0)  # e
# variable names
pc_var = "central_pressure" 
vmax_var = "max_sustained_wind_speed" 
# Compute Holland B at each time snap
def compute_Holland_B(BT_test):
    df_test = BT_test.df 
    Vmax = df_test[vmax_var]*kts2ms  
    DelP = (Pb - df_test[pc_var])*mbar2pa 
    B = Vmax*Vmax*rho_air*e1/DelP
    return B 
# Compute central pressure from Vmax based on Holland B
def compute_pc_from_Vmax(Vmax_kts,B):
    Vmax = Vmax_kts*kts2ms  
    DelP = Vmax*Vmax*rho_air*e1/B
    pc = Pb - DelP*pa2mbar
    return pc
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
    # Parse number of perturbations
    try:
       num = int(argv[1])
    except IndexError:
       print("Number of perturbations must be supplied as first argument on the command line")
       raise
    # Parse storm code
    try:
       stormcode = argv[2]
    except IndexError:
       print("Storm name/code must be supplied as second argument on the command line")
       raise
    start_date=None
    end_date=None
    if len(argv) > 3:
       start_date=datetime.strptime(argv[3], '%Y%m%d%H')
    if len(argv) > 4:
       end_date=datetime.strptime(argv[4], '%Y%m%d%H')
    # Enter function
    main(num,stormcode,start_date,end_date)
