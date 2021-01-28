#!/bin/bash

## setting the stormcode and year
code="STORMCODE"
yyyy=${code: -4}

## download the GIS data and decompress it 
GIS="https://www.nhc.noaa.gov/gis/best_track/" 
URL=$GIS$code"_best_track.zip"
wget $URL
unzip $code"_best_track.zip"
