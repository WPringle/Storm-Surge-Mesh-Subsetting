#!/bin/bash

# Setup My Environment
module load matlab

# Setting the file names and storm names
fn="../../mesh/WNAT_v14"
ndfd="../../data/2019_"
dln="dl_arch-nam.sh" 
mf15="Make_new_f15_HR.m" 
#storms=("Barry" "Imelda" "Olga" "Dorian" "Nestor")
storms=("BARRY")
jobscript="run_HR_forecast.job"

# loop over the years
for s in "${storms[@]}"
do
   echo $s
   # remove directory if already exist
   rm -r $s

   # make the new directory and step in
   mkdir $s
   cd $s
   
   # Setting the dates of the storms 
   if [ $s == "BARRY" ]
   then
      ms=07
      me=07
      ds=13
      de=16
      hs=03
   elif [ $s == "Imelda" ]
   then
      ms=09
      me=09
      ds=16
      de=21
   elif [ $s == "Olga" ]
   then
      ms=10
      me=10
      ds=23
      de=28
   elif [ $s == "Dorian" ]
   then
      ms=08
      me=09
      ds=24
      de=10
   elif [ $s == "Nestor" ]
   then
      ms=10
      me=10
      ds=16
      de=21
   fi

   # copy over and configure the NAM dl script
   cp ../$dln .     
   sed -i -- 's/ms=07/ms='$ms'/g' $dln  
   sed -i -- 's/me=08/me='$me'/g' $dln  
   sed -i -- 's/ds=28/ds='$ds'/g' $dln  
   sed -i -- 's/de=02/de='$de'/g' $dln  
   # link the NDFD file 
   ln -s $ndfd$s"/NDFD_1hr.222.grb2" fort.222.grb2
   # link all the mesh input files
   ln -s $fn".24" fort.24
   ln -s $fn".14" fort.14
   ln -s $fn".13" fort.13
   ln -s ../elev_stat.151 .
   ln -s ../adcprep .
   ln -s ../padcirc .
   # copy over the acdprep scripts
   cp ../adcprepall.sh .
   cp ../adcprep15.sh .

   # make new fort.15
   cp ../$mf15 .     
   sed -i -- 's/STORM/'$s'/g' $mf15
   sed -i -- 's/MS/'$ms'/g' $mf15  
   sed -i -- 's/DS/'$ds'/g' $mf15  
   sed -i -- 's/ME/'$me'/g' $mf15  
   sed -i -- 's/DE/'$de'/g' $mf15  
   sed -i -- 's/HSS/'$hs'/g' $mf15  
   matlab -nosplash -nodesktop -nodisplay < $mf15

   # download the NAM winds
   # submit job
   cp ../$jobscript .
   sed -i -- 's/STORM/'$s'/g' $jobscript
   sbatch $jobscript

   #step out
   cd ../ 
done
