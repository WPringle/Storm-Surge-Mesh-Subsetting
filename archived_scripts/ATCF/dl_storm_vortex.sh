#!/bin/bash

## setting the stormcode and year
code="STORMCODE"
yyyy=${code: -4}

## the urls for the best track data
ATCF="ftp://ftp.nhc.noaa.gov/atcf/archive/"
GIS="https://www.nhc.noaa.gov/gis/best_track/"

## download the GIS data and decompress it
URL=$GIS$code"_best_track.zip"
wget $URL
unzip $code"_best_track.zip"

## download the ATCF .dat file and decompress it
URL=$ATCF$yyyy"/b"$code".dat.gz"
wget $URL
gzip -d "b"$code".dat.gz"

## make sure ATCF format is correct for GAHM
mv "b"$code".dat" fort.22
# ASWIP option descriptor
#-n = nws option
#-m = methods using isotachs, 1 = use the 34 isotach, 2 = use the 64 isotach, 3 = use the 50 isotach, 4 = use all available isotachs (use 4 for NWS=20)
#-z = approaches solving for Rmax, 1 = only rotate wind vectors afterward, 2 = rotate wind vectors before and afterwards (use this for NWS=20)
./aswip -n 20 -m 4 -z 2
mv fort.22 Orig_fort.22
mv NWS_20_fort.22 fort.22
