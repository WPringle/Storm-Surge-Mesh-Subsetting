#!/bin/bash

# setting the stormcode
code="STORMCODE"
yyyy=XXXX

# the urls for the best track data 
ATCF="ftp://ftp.nhc.noaa.gov/atcf/archive/" 
GIS="https://www.nhc.noaa.gov/gis/best_track/" 

# download the GIS data and decompress it 
URL=$GIS$code"_best_track.zip"
wget $URL
unzip $code"_best_track.zip"

# download the ATCF .dat file and decompress it 
URL=$ATCF$yyyy"/b"$code".dat.gz"
wget $URL
gzip -d "b"$code".dat.gz"

# make sure ATCF format is correct for GAHM
mv "b"$code".dat" fort.22 
./aswip -n 20 -m 4 -z 2
mv fort.22 Orig_fort.22
mv NWS_20_fort.22 fort.22
