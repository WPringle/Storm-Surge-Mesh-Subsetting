#!/bin/bash
# downloads the 6-hrly ndfd forecasts
rm NDFD_WDIR.grb2 
rm NDFD_WSPD.grb2 

# setting starting and end month/dates
yy=YYYY
mm=MMS
dd=DDS
hs=HHS
# the hour we download is one hour behind the one we want
hh=$((hs-1))
hh=`printf %02d $hh`

# base url
URLb="https://www.ncei.noaa.gov/data/national-digital-forecast-database/access/historical"

## first 72 hours 
# WDIR
for tta1 in {16..20}; do
   WDIRa=$URLb"/"$yy$mm"/"$yy$mm$dd"/YBUZ98_KWBN_"$yy$mm$dd$hh$tta1
   wget -O NDFD_WDIR.grb2 $WDIRa
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
done
# WSPD
for tta2 in {16..20}; do
   WSPDa=$URLb"/"$yy$mm"/"$yy$mm$dd"/YCUZ98_KWBN_"$yy$mm$dd$hh$tta2
   wget -O NDFD_WSPD.grb2 $WSPDa
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
done
## post 72 hours
# WDIR
for ttb1 in {29..33}; do
   WDIRb=$URLb"/"$yy$mm"/"$yy$mm$dd"/YBUZ97_KWBN_"$yy$mm$dd$hh$ttb1
   wget -O WDIR_temp.grb2 $WDIRb
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
done
# WSPD
for ttb2 in {29..34}; do
   WSPDb=$URLb"/"$yy$mm"/"$yy$mm$dd"/YCUZ97_KWBN_"$yy$mm$dd$hh$ttb2
   wget -O WSPD_temp.grb2 $WSPDb
   if [[ $? -ne 0 ]]; then
      echo "wget failed"
   else
      break 
   fi
done
wgrib2 WDIR_temp.grb2 -append -grib NDFD_WDIR.grb2
wgrib2 WSPD_temp.grb2 -append -grib NDFD_WSPD.grb2
rm *_temp.grb2 
