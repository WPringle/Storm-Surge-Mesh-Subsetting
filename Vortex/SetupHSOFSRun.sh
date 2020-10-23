#!/bin/bash

# Setup My Environment
module load matlab

# Setting the file names which do not change
fnpre="HSOFS+Coarse_"
dln="dl_arch-alcf.sh" 
mf15="Make_f15_storm.m" 
mergef="Merge_HSOFS_to_Coarse.m" 
plotf="Plot_Mesh.m" 
jobscript="run_storm.job"
# Setting some parameters and storm names
np=24 # number of processors
storms=("Florence") # "Sandy" "Barry") # storm names
expint=true #true for explicit, false for implicit

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
   if [ $s == "Barry" ]
   then
      yy=2019
      ms=07
      me=07
      ds=11
      de=16
      code="AL062018"
   elif [ $s == "Sandy" ]
   then
      yy=2012
      ms=10
      me=11
      ds=22
      de=2
      code="AL062018"
   elif [ $s == "Florence" ]
   then
      yy=2018
      ms=08
      me=09
      ds=31
      de=18
      code="AL062018"
   fi

   # copy over and configure the ALCF dl script
   #cp ../$dln .     
   #sed -i -- 's/ms=XX/ms='$ms'/g' $dln  
   #sed -i -- 's/me=XX/me='$me'/g' $dln  
   #sed -i -- 's/ds=XX/ds='$ds'/g' $dln  
   #sed -i -- 's/de=XX/de='$de'/g' $dln  
   #sed -i -- 's/yy=XXXX/yy='$yy'/g' $dln  
   
   # pre-link the input and run files
   fn=$fnpre$s
   #ln -s $fn".24" fort.24
   ln -s $fn".14" fort.14
   ln -s $fn".13" fort.13
   ln -s ../elev_stat.151 .
   ln -s ../adcprep .
   ln -s ../padcirc .
   # copy over the acdprep scripts and add np var
   cp ../adcprepall.sh .
   cp ../adcprep15.sh .
   sed -i -- 's/XXX/'$np'/g' adcprepall.sh  
   sed -i -- 's/XXX/'$np'/g' adcprep15.sh  
   
   # copy over and edit make merging file
   cp ../$mergef .     
   sed -i -- 's/STORMNAME/'$s'/g' $mergef
   sed -i -- 's/STORMCODE/'$code'/g' $mergef 
   
   # copy over and edit make plotting file
   cp ../$plotf .     
   sed -i -- 's/STORMNAME/'$s'/g' $plotf

   # copy over and edit make fort.15 file
   cp ../$mf15 .     
   sed -i -- 's/STORMNAME/'$s'/g' $mf15
   sed -i -- 's/MMS/'$ms'/g' $mf15  
   sed -i -- 's/DDS/'$ds'/g' $mf15  
   sed -i -- 's/MME/'$me'/g' $mf15  
   sed -i -- 's/DDE/'$de'/g' $mf15  
   sed -i -- 's/YYYY/'$yy'/g' $mf15  
   sed -i -- 's/MESH/'$fn'/g' $mf15 
   sed -i -- 's/EXPLICIT_INT/'$expint'/g' $mf15

   # download the NAM winds
   # submit job
   cp ../$jobscript .
   sed -i -- 's/XXX/'$np'/g' $jobscript 
   sed -i -- 's/MESH/'$fn'/g' $jobscript 
   sed -i -- 's/MERGEFN/'$mergef'/g' $jobscript 
   sed -i -- 's/PLOTF/'$plotf'/g' $jobscript 
   sed -i -- 's/MAKEF15/'$mf15'/g' $jobscript 
   qsub $jobscript

   #step out
   cd ../
done
