#!/bin/bash

## the parameters
code="STORMCODE"      #NHC storm code
ts="STARTDATE"        #yyyymmddHH format for start date

## download ATCF file into fort.22 using adcircpy
best_track_file --save-path fort.22 --start-date $ts $code

## make sure ATCF format is correct for GAHM
# ASWIP option descriptor
#-n = nws option
#-m = methods using isotachs, 1 = use the 34 isotach, 2 = use the 64 isotach, 3 = use the 50 isotach, 4 = use all available isotachs (use 4 for NWS=20)
#-z = approaches solving for Rmax, 1 = only rotate wind vectors afterward, 2 = rotate wind vectors before and afterwards (use this for NWS=20)
./aswip -n 20 -m 4 -z 2
mv fort.22 Orig_fort.22
mv NWS_20_fort.22 fort.22
