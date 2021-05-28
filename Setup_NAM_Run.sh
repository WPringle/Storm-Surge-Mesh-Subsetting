#!/bin/bash

# Setup My Environment
module load matlab

# Setting the file names and storm names
fn="HSOFS_120m_v1"
dln="dl_arch-nam.sh"
mf15="Make_f15_storm.m"
storms=("Barry") # "Imelda" "Olga" "Dorian" "Nestor")
jobscript="run_storm.job"
np=360
yy=2019

# loop over the years
for s in "${storms[@]}"; do
  echo $s
  # remove directory if already exist
  rm -r $s

  # make the new directory and step in
  mkdir $s
  cd $s

  # Setting the dates of the storms
  if [ $s == "Barry" ]; then
    ms=07
    me=07
    ds=11
    de=16
  elif [ $s == "Imelda" ]; then
    ms=09
    me=09
    ds=16
    de=21
  elif [ $s == "Olga" ]; then
    ms=10
    me=10
    ds=23
    de=28
  elif [ $s == "Dorian" ]; then
    ms=08
    me=09
    ds=24
    de=10
  elif [ $s == "Nestor" ]; then
    ms=10
    me=10
    ds=16
    de=21
  fi

  # copy over and configure the NAM dl script
  cp ../$dln .
  sed -i -- 's/ms=XX/ms='$ms'/g' $dln
  sed -i -- 's/me=XX/me='$me'/g' $dln
  sed -i -- 's/ds=XX/ds='$ds'/g' $dln
  sed -i -- 's/de=XX/de='$de'/g' $dln
  sed -i -- 's/yy=XXXX/yy='$yy'/g' $dln

  # link all the mesh input files
  ln -s ../$fn".24" fort.24
  ln -s ../$fn".14" fort.14
  ln -s ../$fn".13" fort.13
  ln -s ../elev_stat.151 .
  ln -s ../adcprep .
  ln -s ../padcirc .
  # copy over the acdprep scripts and add np
  cp ../adcprepall.sh .
  cp ../adcprep15.sh .
  sed -i -- 's/XXX/'$np'/g' adcprepall.sh
  sed -i -- 's/XXX/'$np'/g' adcprep15.sh

  # make new fort.15
  cp ../$mf15 .
  sed -i -- 's/STORM/'$s'/g' $mf15
  sed -i -- 's/MMS/'$ms'/g' $mf15
  sed -i -- 's/DDS/'$ds'/g' $mf15
  sed -i -- 's/MME/'$me'/g' $mf15
  sed -i -- 's/DDE/'$de'/g' $mf15
  sed -i -- 's/YYYY/'$yy'/g' $mf15
  sed -i -- 's/MESH/'$fn'/g' $mf15
  matlab -nosplash -nodesktop -nodisplay <$mf15

  # download the NAM winds
  # submit job
  cp ../$jobscript .
  sed -i -- 's/STORM/'$s'/g' $jobscript
  sed -i -- 's/XXX/'$np'/g' $jobscript
  sed -i -- 's/MESH/'$fn'/g' $jobscript
  #   qsub $jobscript

  #step out
  cd ../
done
