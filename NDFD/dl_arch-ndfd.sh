#!/bin/bash
##############################################################
# Downloads the historical NDFD wind forecasts
# and historical NAM pressure forecasts
##############################################################

# setting starting date
yy=YYYY
mm=MMS
dd=DDS
hs=HHS
# the hour of NDFD we download is one hour behind hs
hh=$((hs-1))
hh=`printf %02d $hh`
secondhalf=false # select to download the second half of NDFD

###############################################################
### DOWNLOAD THE NAM PRESSURE FORECASTS 
###############################################################
# base url
URLb="https://www.ncei.noaa.gov/data/north-american-mesoscale-model/access/historical/forecast/"
# the start and end forecast times (0-72 hrs)
ts=000
te=036
for t in $( eval echo {$ts..$te..001} ) 
do
   URL=$URLb$yy$mm"/"$yy$mm$dd"/nam_218_"$yy$mm$dd"_"$hs"00_"$t
   echo $URL".inv"
   get_inv.pl $URL".inv" > my_inv
   grep ":MSLET:" < my_inv | get_grib.pl $URL".grb2" prmsl.grb2
   wgrib2 "prmsl.grb2" -append -grib "NAM_1hr.221.grb2"
done
ts=039
te=072
for t in $( eval echo {$ts..$te..003} ) 
do
   URL=$URLb$yy$mm"/"$yy$mm$dd"/nam_218_"$yy$mm$dd"_"$hs"00_"$t
   echo $URL".inv"
   get_inv.pl $URL".inv" > my_inv
   grep ":MSLET:" < my_inv | get_grib.pl $URL".grb2" prmsl.grb2
   wgrib2 "prmsl.grb2" -append -grib "NAM_1hr.221.grb2"
done
rm prmsl.grb2

###############################################################
### DOWNLOAD THE NDFD WIND FORECASTS 
###############################################################
# base url
URLb="https://www.ncei.noaa.gov/data/national-digital-forecast-database/access/historical"

## first 72 hours 
# WDIR
for tta1 in {15..20}; do
   WDIRa=$URLb"/"$yy$mm"/"$yy$mm$dd"/YBUZ98_KWBN_"$yy$mm$dd$hh$tta1
   wget -O WDIR_ta.grb2 $WDIRa
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
done
# WSPD
for tta2 in {15..20}; do
   WSPDa=$URLb"/"$yy$mm"/"$yy$mm$dd"/YCUZ98_KWBN_"$yy$mm$dd$hh$tta2
   wget -O WSPD_ta.grb2 $WSPDa
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
done

## post 72 hours if desired
if $secondhalf; then
   # WDIR
   for ttb1 in {29..34}; do
   WDIRb=$URLb"/"$yy$mm"/"$yy$mm$dd"/YBUZ97_KWBN_"$yy$mm$dd$hh$ttb1
   wget -O WDIR_tb.grb2 $WDIRb
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
   done
   # WSPD
   for ttb2 in {29..34}; do
   WSPDb=$URLb"/"$yy$mm"/"$yy$mm$dd"/YCUZ97_KWBN_"$yy$mm$dd$hh$ttb2
   wget -O WSPD_tb.grb2 $WSPDb
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
   done
   # append to the first half
   wgrib2 WDIR_tb.grb2 -append -grib WDIR_ta.grb2
   wgrib2 WSPD_tb.grb2 -append -grib WSPD_ta.grb2
   rm *_tb.grb2 
fi
# remove non-uniqe values and move into WSPD and WDIR filenames 
wgrib2 WSPD_ta.grb2 -submsg 1 | unique.pl | wgrib2 -i WSPD_ta.grb2 -GRIB NDFD_WSPD.grb2
wgrib2 WDIR_ta.grb2 -submsg 1 | unique.pl | wgrib2 -i WDIR_ta.grb2 -GRIB NDFD_WDIR.grb2
rm *_ta.grb2 
#rm *_tb.grb2 
