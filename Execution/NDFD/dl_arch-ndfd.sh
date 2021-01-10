#!/bin/bash
# downloads the 6-hrly ndfd forecasts
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
## post 72 hours
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
wgrib2 WDIR_tb.grb2 -append -grib WDIR_ta.grb2
wgrib2 WSPD_tb.grb2 -append -grib WSPD_ta.grb2
wgrib2 WSPD_ta.grb2 -submsg 1 | unique.pl | wgrib2 -i WSPD_ta.grb2 -GRIB NDFD_WSPD.grb2
wgrib2 WDIR_ta.grb2 -submsg 1 | unique.pl | wgrib2 -i WDIR_ta.grb2 -GRIB NDFD_WDIR.grb2
rm *_ta.grb2 
rm *_tb.grb2 
