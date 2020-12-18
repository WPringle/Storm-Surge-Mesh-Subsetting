#!/bin/sh
#
# use wgrib2 to convert wind speed and direction to UGRID and VGRID 
# then interpolate 3-hrly forecasts to 1-hrly forecasts
#
# Input/Output filenames
#WSPDin='YCUZ98_KWBN_201907130147' #example filename of wind-speed grb2
#WDIRin='YBUZ98_KWBN_201907130146' #example filename of wind-direction grb2
WSPDin='WSPDfilename' #the wind-speed grb2
WDIRin='WDIRfilename' #the wind-direction grb2
# these are temp files deleted at end of script
WINDin='NDFD_WIND_1hr.grb2'       #the combined wind-speed and wind-direction
UVin='NDFD_UV_1hr.grb'            #the input U10/V10 grb2 (hourly)
# these is the final output filename
UVout='NDFD_1hr.222.grb'          #the output interpolated U10/V10 grb2 (hourly)

####################### Operations below ###########################

# First we need to convert wind speed and direction to UGRD/VGRD

# append the wind speed and direction
cp $WSPDin $WINDin
wgrib2 $WDIRin -append -grib $WINDin

# sort for use with the wind_uv
wgrib2 $WINDin -start_ft -s | sort -t: -k3 | wgrib2 -i $WINDin -grib $WINDin"2"

# Compute the U10/V10 and output as UVin
wgrib2 $WINDin"2" -wind_uv $UVin

# doing conversion using native reverse polish notation 
# keep for reference
#for i in {1..70}
#do
## Do the operation
#wgrib2 $WINDin -match ":$i hour fcst:" \
#  -if ":WIND:" -rpn "sto_1" -fi \
#  -if ":WDIR:" -rpn "sto_2" -fi \
#  -if_reg 1:2 \
#     -rpn "rcl_2:-180:/:pi:*:sin:rcl_1:*" -set_var UGRD -append -grib_out $UVin \
#  -if_reg 1:2 \
#     -rpn "rcl_2:-180:/:pi:*:cos:rcl_1:*" -set_var VGRD -append -grib_out $UVin
#done

## Interpolation of the 3-hr forecasts after 36hrs to 1-hr forecast
cp $UVin $UVout
for i in {37..67..3} 
do
# setting the original forecast times we want
j=$((i+3))
a="$i hour fcst"  # the prior forecast
b="$j hour fcst"  # the next forecast
# setting the new interpolation times
i1=$((i+1))
i2=$((i+2))
d1="$i1 hour fcst" # the 1-hr after interpolated forecast
d2="$i2 hour fcst" # the 2-hr after interpolated forecast
# UGRD
# extracting out the forecasts we want
wgrib2 $UVin -match ":UGRD:10 m above ground:$a:" -grib_out $UVin"1"
wgrib2 $UVin -match ":UGRD:10 m above ground:$b:" -grib_out $UVin"2"
# doing the time-interpolation
wgrib2 $UVin"1" -rpn sto_1 -import_grib $UVin"2" -rpn sto_2 \
   -rpn "rcl_1:2:*:rcl_2:1:*:+:3:/" -set_ftime "$d1" -append -grib_out $UVout \
   -rpn "rcl_1:1:*:rcl_2:2:*:+:3:/" -set_ftime "$d2" -append -grib_out $UVout

# VGRD
# extracting out the forecasts we want
wgrib2 $UVin -match ":VGRD:10 m above ground:$a:" -grib_out $UVin"1"
wgrib2 $UVin -match ":VGRD:10 m above ground:$b:" -grib_out $UVin"2"
# doing the time-interpolation
wgrib2 $UVin"1" -rpn sto_1 -import_grib $UVin"2" -rpn sto_2 \
   -rpn "rcl_1:2:*:rcl_2:1:*:+:3:/" -set_ftime "$d1" -append -grib_out $UVout \
   -rpn "rcl_1:1:*:rcl_2:2:*:+:3:/" -set_ftime "$d2" -append -grib_out $UVout
done

#sort times and output grb2
wgrib2 $UVout -start_ft -s | sort -t: -k3 | wgrib2 -i $UVout -grib $UVout"2"
rm $UVout $WINDin $WINDin"2" $UVin $UVin"1" $UVin"2"
