#!/bin/bash

# setting starting and end month/dates
yy=YYYY
ms=MMS
ds=DDS
me=MME
de=DDE

# the constant stuff
URLb="https://www.ncei.noaa.gov/data/north-american-mesoscale-model/access/historical/analysis/"
he=18
hs=00
te=005
ts=000

# looping over all the days/times
for m in $(eval echo {$ms..$me..01}); do
  # get day for end of this month
  if [ $m -eq 4 ] || [ $m -eq 6 ] || [ $m -eq 9 ] || [ $m -eq 11 ]; then
    med=30
  else
    med=31
  fi
  if [ $ms -eq $me ]; then
    dee=$de
    dss=$ds
  else
    if [ $m -eq $ms ]; then
      dss=$ds
      dee=$med
    else
      dee=$de
      dss=01
    fi
  fi
  for d in $(eval echo {$dss..$dee..01}); do
    for h in $(eval echo {$hs..$he..06}); do
      for t in $(eval echo {$ts..$te..003}); do
        URL=$URLb$yy$m"/"$yy$m$d"/namanl_218_"$yy$m$d"_"$h"00_"$t
        echo $URL".inv"
        get_inv.pl $URL".inv" >my_inv
        grep "GRD:10 m above ground" <my_inv | get_grib.pl $URL".grb2" ugrd.grb2
        grep ":MSLET:" <my_inv | get_grib.pl $URL".grb2" prmsl.grb2
        wgrib2 "prmsl.grb2" -append -grib "NAM.221.grb2"
        wgrib2 "ugrd.grb2" -append -grib "NAM.222.grb2"
      done
    done
  done
done
rm prmsl.grb2
rm ugrd.grb2
rm my_inv
