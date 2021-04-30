#! /usr/bin/env python3
"""
Script to extract an ATCF best track dataset; randomly 
perturb different parameters (e.g., intensity, size)
to generate an ensemble; and write out each ensemble
member to the fort.22 ATCF storm format file. 

- max_sustained_wind_speed (Vmax) is made weaker/stronger
  based on random gaussian distribution with sigma scaled by
  historical mean absolute errors. central_pressure (pc) 
  is then changed proportionally based on Holland B

- radius_of_maximum_winds (Rmax) is made small/larger
  based on random number in a range bounded by 15% and 85%
  CDF of historical forecast errors. 

- cross-track/along track to do...

By William Pringle, Mar 2021 -
"""
from argparse import ArgumentParser
from datetime import datetime, timedelta
from dateutil.parser import parse as parse_date
from adcircpy.forcing.winds.best_track import BestTrackForcing
from copy import deepcopy
from math import exp, inf
from sys import argv
from pandas import DataFrame
from random import random, gauss
from numpy import interp, transpose

def main(number_of_perturbations,variable_list,storm_code,start_date,end_date):
    #Example: 
    #number_of_perturbations = 3
    #variable_list = ["max_sustained_wind_speed",
    #                 "radius_of_maximum_winds"]
    #storm_code="al062018" #NHC storm code
    #start_date = datetime(2018,9,11,6)
    #end_date = datetime(2018,9,17,18)

    # getting best track
    BT = BestTrackForcing(storm_code, start_date=start_date, end_date=end_date)
    
    # write out original fort.22
    BT.write("original.22",overwrite=True)
   
    # Computing Holland B and validation times from BT 
    Holland_B = compute_Holland_B(BT)
    storm_VT = compute_VT_hours(BT)
    #print(Holland_B)
    #print(Storm_VT)
    # Get the initial intensity and size  
    storm_strength = intensity_class(compute_initial(BT,vmax_var)) 
    storm_size = size_class(compute_initial(BT,rmw_var)) 
    print("Initial storm strength: " + storm_strength)
    print("Intial storm size: " + storm_size)
    
    # extracting original dataframe   
    df_original = BT.df

    # modifying the central pressure while subsequently changing 
    # Vmax using the same Holland B parameter,  
    # writing each to a new fort.22
    for var in variable_list:
       print(var)
       #print(min(df_original[var]))
       #print(max(df_original[var]))
       # Make the random pertubations based on the historical forecast errors 
       # Interpolate from the given VT to the storm_VT 
       #print(forecast_errors[var][Initial_Vmax])
       if var == "radius_of_maximum_winds":
           storm_classification = storm_size
       else:
           storm_classification = storm_strength
       xp = forecast_errors[var][storm_classification].index
       yp = forecast_errors[var][storm_classification].values
       base_errors = [ interp(storm_VT,xp,yp[:,ncol]) 
                       for ncol in range(len(yp[0])) ]
       #print(base_errors)
       for idx in range(1,number_of_perturbations+1):
           # make a deepcopy to preserve the original dataframe 
           df_modified = deepcopy(df_original)
           # get the random perturbation sample
           if random_variable_type[var] == 'gauss':
               alpha = gauss(0,1)/0.7979 #mean_abs_error = 0.7979*sigma
               # add the error to the variable with bounds to some physical constraints
               print("Random gaussian variable = " + str(alpha))
               df_modified[var] = perturb_bound( df_modified[var] + 
                   base_errors[0]*alpha, var )
           elif random_variable_type[var] == 'range':
               alpha = random() 
               print("Random number in [0,1) = " + str(alpha))
               df_modified[var] = perturb_bound( df_modified[var] +
                   base_errors[0]*alpha + base_errors[1]*(1.0-alpha), var )
           if var == vmax_var:
               # In case of Vmax need to change the central pressure
               # incongruence with it (obeying Holland B relationship)
               df_modified[pc_var] = compute_pc_from_Vmax(df_modified,Holland_B)
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
# the initial value of the input variable var (Vmax or Rmax)
def compute_initial(BT_test,var):    
    ini_val = BT_test.df[var].iloc[0] 
    return ini_val
# some constants
rho_air = 1.15 # density of air [kg/m3]
Pb = 1013.0    # background pressure [mbar]
kts2ms = 0.514444444 # kts to m/s
mbar2pa = 100  # mbar to Pa
pa2mbar = 0.01 # Pa to mbar
nm2sm   = 1.150781 # nautical miles to statute miles
sm2nm   = 0.868976 # statute miles to nautical miles    
e1 = exp(1.0)  # e
# variable names
pc_var = "central_pressure" 
pb_var = "background_pressure" 
vmax_var = "max_sustained_wind_speed" 
rmw_var = "radius_of_maximum_winds"
# Compute Holland B at each time snap
def compute_Holland_B(BT_test):
    df_test = BT_test.df 
    Vmax = df_test[vmax_var]*kts2ms  
    DelP = (df_test[pb_var] - df_test[pc_var])*mbar2pa 
    B = Vmax*Vmax*rho_air*e1/DelP
    return B 
# Compute central pressure from Vmax based on Holland B
def compute_pc_from_Vmax(df_test,B):
    Vmax = df_test[vmax_var]*kts2ms  
    DelP = Vmax*Vmax*rho_air*e1/B
    pc = df_test[pb_var] - DelP*pa2mbar
    return pc
# random variable types (Gaussian or just a range)
random_variable_type = {
    "max_sustained_wind_speed": "gauss",
    "radius_of_maximum_winds": "range",
    "cross_track": "gauss",
    "along_track": "guass"
}
# physical bounds of different variables
lower_bound = {
    "max_sustained_wind_speed": 25, #[kt]
    "radius_of_maximum_winds": 5,   #[nm]
    "cross_track": -inf,
    "along_track": -inf
}
upper_bound = {
    "max_sustained_wind_speed": 165,#[kt]
    "radius_of_maximum_winds": 200, #[nm]
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
def intensity_class(vmax):
  if vmax < 50:
    return "<50kt" #weak
  elif vmax > 95:
    return ">95kt" #strong
  else:
    return "50-95kt" #medium
# Category for Rmax based size
def size_class(rmw_nm):
  # convert from nautical miles to statute miles
  rmw_sm = rmw_nm*nm2sm
  if rmw_sm < 15:
    return "<15sm" #very small
  elif rmw_sm < 25:
    return "15-25sm" #small
  elif rmw_sm < 35:
    return "25-35sm" #medium
  elif rmw_sm < 45:
    return "35-45sm" #large
  else:
    return ">45sm"   #very large
# Index of absolute errors (forecast times [hrs)]
VT=[0, 12, 24, 36, 48, 72, 96, 120] # no 60-hr data 
VTR=[0, 12, 24, 36, 48, 60, 72, 96, 120] # has 60-hr data (for Rmax)
# Mean absolute Vmax errors based on initial intensity
Vmax_weak_errors = DataFrame(data=[1.45, 4.01, 6.17, 8.42, 10.46, 14.28, 18.26, 19.91],index=VT,columns=["mean error [kt]"]) 
Vmax_medium_errors = DataFrame(data=[2.26, 5.75, 8.54, 9.97, 11.28, 13.11, 13.46, 12.62],index=VT,columns=["mean error [kt]"]) 
Vmax_strong_errors = DataFrame(data=[2.80, 7.94, 11.53, 13.27, 12.66, 13.41, 13.46, 13.55],index=VT,columns=["mean error [kt]"]) 
# RMW errors bound based on initial size
RMW_vsmall_errors = DataFrame(data=sm2nm*transpose([[0.0, -13.82, -19.67, -21.37, -26.31,-32.71, -39.12, -46.80, -52.68],
                                   [0.0, 1.27, 0.22, 1.02, 0.00, -2.59, -5.18, -7.15, -12.91]]),
                              index=VTR,columns=["minimum error [nm]", "maximum error [nm]"]) 
RMW_small_errors = DataFrame(data=sm2nm*transpose([[0.0, -10.47, -14.54, -20.35, -23.88, -21.78, -19.68,-24.24, -28.30],
                                  [0.0, 4.17, 6.70, 6.13, 6.54, 6.93, 7.32, 9.33, 8.03]]),
                             index=VTR,columns=["minimum error [nm]", "maximum error [nm]"]) 
RMW_medium_errors = DataFrame(data=sm2nm*transpose([[0.0, -8.57, -13.41, -10.87, -9.26, -9.34, -9.42, -7.41, -7.40],
                                   [0.0, 8.21, 10.62, 13.93, 15.62, 16.04, 16.46, 16.51, 16.70]]),
                              index=VTR,columns=["minimum error [nm]", "maximum error [nm]"]) 
RMW_large_errors = DataFrame(data=sm2nm*transpose([[0.0, -10.66, -7.64, -5.68, -3.25, -1.72, -0.19, 3.65, 2.59],
                                  [0.0, 14.77, 17.85, 22.07, 27.60, 27.08, 26.56, 26.80, 28.30]]),
                             index=VTR,columns=["minimum error [nm]", "maximum error [nm]"]) 
RMW_vlarge_errors = DataFrame(data=sm2nm*transpose([[0.0, -15.36, -10.37, 3.14, 12.10, 12.21, 12.33, 6.66, 7.19],
                                   [0.0, 21.43, 29.96, 37.22, 39.27, 39.10, 38.93, 34.40, 35.93]]),
                              index=VTR,columns=["minimum error [nm]", "maximum error [nm]"]) 
# Mean absolute cross-track errors based on initial intensity
ct_weak_errors = DataFrame(data=[1.45, 4.01, 6.17, 8.42, 10.46, 14.28, 18.26, 19.91],index=VT,columns=["mean error [nm]"]) 
ct_medium_errors = DataFrame(data=[2.26, 5.75, 8.54, 9.97, 11.28, 13.11, 13.46, 12.62],index=VT,columns=["mean error [nm]"]) 
ct_strong_errors = DataFrame(data=[2.80, 7.94, 11.53, 13.27, 12.66, 13.41, 13.46, 13.55],index=VT,columns=["mean error [nm]"]) 
# Mean absolute along-track errors based on initial intensity
at_weak_errors = DataFrame(data=[1.45, 4.01, 6.17, 8.42, 10.46, 14.28, 18.26, 19.91],index=VT,columns=["mean error [nm]"]) 
at_medium_errors = DataFrame(data=[2.26, 5.75, 8.54, 9.97, 11.28, 13.11, 13.46, 12.62],index=VT,columns=["mean error [nm]"]) 
at_strong_errors = DataFrame(data=[2.80, 7.94, 11.53, 13.27, 12.66, 13.41, 13.46, 13.55],index=VT,columns=["mean error [nm]"]) 
# Dictionary of historical forecast errors by variable
forecast_errors = {
    "max_sustained_wind_speed": {
        "<50kt": Vmax_weak_errors,  
        "50-95kt": Vmax_medium_errors, 
        ">95kt":   Vmax_strong_errors
    },
    "radius_of_maximum_winds": {
        "<15sm": RMW_vsmall_errors,  
        "15-25sm": RMW_small_errors,  
        "25-35sm": RMW_medium_errors, 
        "35-45sm": RMW_large_errors,
        ">45sm": RMW_vlarge_errors
    },
    "cross_track": {
        "<50kt": ct_weak_errors,  
        "50-95kt": ct_medium_errors, 
        ">95kt":   ct_strong_errors
    },
    "along_track": {
        "<50kt": at_weak_errors,  
        "50-95kt": at_medium_errors, 
        ">95kt":   at_strong_errors
    }
}

if __name__ == '__main__':
    argument_parser = ArgumentParser()
    argument_parser.add_argument('number_of_perturbations',
                                 help='number of perturbations')
    argument_parser.add_argument('storm_code',
                                 help='storm name/code')
    argument_parser.add_argument('start_date', nargs='?',
                                 help='start date')
    argument_parser.add_argument('end_date', nargs='?', help='end date')
    arguments = argument_parser.parse_args()

    # Parse number of perturbations
    num = arguments.number_of_perturbations
    if num is not None:
        num = int(num)
    # Parse storm code
    stormcode = arguments.storm_code
    # Parse the start and end dates, e.g., YYYY-MM-DD-HH
    start_date = arguments.start_date
    if start_date is not None:
        start_date = parse_date(start_date)
    end_date = arguments.end_date
    if end_date is not None:
        end_date = parse_date(end_date)
    # hardcoding variable list for now
    variables = ["max_sustained_wind_speed",
                 "radius_of_maximum_winds"]
    #variables = ["max_sustained_wind_speed"]
    #variables = ["radius_of_maximum_winds"]
    # Enter function
    main(num,variables,stormcode,start_date,end_date)
