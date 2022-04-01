#!/bin/sh
#
# use wgrib2 to convert wind speed and direction to UGRID and VGRID
# then interpolate 3-hrly forecasts to 1-hrly forecasts
#
# Input/Output filenames
WSPDin='NDFD_WSPD.grb2'     #the wind-speed grb2 [example NDFD filename: YCUZ98_KWBN_201907130147]
WDIRin='NDFD_WDIR.grb2'     #the wind-direction grb2 [example NDFD filename: YBUZ98_KWBN_201907130146]
# these are temp files deleted at end of script
WINDin='NDFD_WIND_1hr.grb2' #the combined wind-speed and wind-direction
UVin='NDFD_UV_1hr.grb'      #the input U10/V10 grb2 (hourly)
# these is the final output filename
UVout='NDFD_1hr.222.grb' #the output U10/V10 grb2 file (the 2 will appended by the script)
# setting the temporal interpolation parameters
interp=true #turn interp on/off
#units="hour"                      #units of forecast/interpolaton [hour/min]
#ts=72 #37                         #start time to interpolate from
#te=156 #67                        #end time to interpolate to
#step=6 #3                         #original step time of interpolation range
#newstep=3 #1                      #desired step time for interpolation
units="min" #units of forecast/interpolaton [hour/min]
ts=2190     #start time to interpolate from
te=4170     #end time to interpolate to
step=180    #original step time of interpolation range
newstep=60  #desired step time for interpolation
####################### Operations below ###########################

# First we need to convert wind speed and direction to UGRD/VGRD

# Swap out the null values for 0
wgrib2 $WSPDin -rpn "0:swap:merge" -grib_out $WINDin
wgrib2 $WDIRin -rpn "0:swap:merge" -append -grib_out $WINDin

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

### Interpolation....
cp $UVin $UVout
if $interp; then
  ## Interpolation of the Step [hours/minutes] forecasts
  ## after Start time to NewStep forecast
  for i in $(eval echo {$ts..$te..$step}); do
    # setting the original forecast times we want
    j=$((i + step))
    a="$i $units fcst" # the prior forecast
    b="$j $units fcst" # the next forecast
    echo $a
    echo $b
    # loop over UGRD and VGRD variables and do interpolation
    for var in {"UGRD","VGRD"}; do
      echo $var
      # extracting out the forecasts we want
      wgrib2 $UVin -match ":$var:10 m above ground:$a:" -grib_out $UVin"1"
      wgrib2 $UVin -match ":$var:10 m above ground:$b:" -grib_out $UVin"2"
      file=$UVin"2"
      filesize=$(wc -c "$file" | awk '{print $1}')
      if [ $filesize -lt 10 ]; then
        # exit from both loops if the file is essentially empty
        echo "next forecast time does not exist, breaking out of interpolation"
        echo $i >last-ndfd-fcst-time.txt
        break 2
      fi
      t_start=$((i + newstep))
      t_end=$((j - newstep))
      w1=$step # interpolation weight left
      w2=0     # interpolation weight right
      for interp_time in $(eval echo {$t_start..$t_end..$newstep}); do
        d1="$interp_time $units fcst" # the new interpolation forecast
        w1=$((w1 - newstep))
        w2=$((w2 + newstep))
        echo $d1
        # doing the time-interpolation
        wgrib2 $UVin"1" -rpn sto_1 -import_grib $UVin"2" -rpn sto_2 \
          -rpn "rcl_1:$w1:*:rcl_2:$w2:*:+:$step:/" -set_ftime "$d1" -append -grib_out $UVout
      done
    done
  done
fi

#sort times and output grb2
wgrib2 $UVout -start_ft -s | sort -t: -k3 | wgrib2 -i $UVout -grib $UVout"2"
rm $UVout $WINDin $WINDin"2" $UVin $UVin"1" $UVin"2"
