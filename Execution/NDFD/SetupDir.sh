#!/bin/bash

# Setup My Environment
module load matlab

# Setting the file names and storm names
fn="../../mesh/WNAT_v14"
ndfddir="..\/..\/data\/2019_"
dlnam="dl_arch-nam.sh" 
pndfd="NDFD_Process.sh" 
mf15="Generate_f15_files.m" 
jobscript="run_NDFD.job"
#storms=("Barry" "Imelda" "Olga" "Dorian" "Nestor")
storms=("BARRY")
yy=2019

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
      # NAM start
      nms=07
      nds=03
      # NDFD start/end
      ms=07
      me=07
      ds=13
      de=16
      hs=03
      he=00
      WSPD="YCUZ98_KWBN_201907130147" #filename of wind-speed grb2
      WDIR="YBUZ98_KWBN_201907130146" #filename of wind-direction grb2
   elif [ $s == "Imelda" ]
   then
      ms=09
      me=09
      ds=16
      de=21
      WSPD='YCUZ98_KWBN_201907130147' #filename of wind-speed grb2
      WDIR='YBUZ98_KWBN_201907130146' #filename of wind-direction grb2
   elif [ $s == "Olga" ]
   then
      ms=10
      me=10
      ds=23
      de=28
      WSPD='YCUZ98_KWBN_201907130147' #filename of wind-speed grb2
      WDIR='YBUZ98_KWBN_201907130146' #filename of wind-direction grb2
   elif [ $s == "Dorian" ]
   then
      ms=08
      me=09
      ds=24
      de=10
      WSPD='YCUZ98_KWBN_201907130147' #filename of wind-speed grb2
      WDIR='YBUZ98_KWBN_201907130146' #filename of wind-direction grb2
   elif [ $s == "Nestor" ]
   then
      ms=10
      me=10
      ds=16
      de=21
      WSPD='YCUZ98_KWBN_201907130147' #filename of wind-speed grb2
      WDIR='YBUZ98_KWBN_201907130146' #filename of wind-direction grb2
   fi

   # copy over and configure the NAM dl script
   cp ../$dlnam .     
   sed -i -- 's/ms=XX/ms='$nms'/g' $dlnam  
   sed -i -- 's/me=XX/me='$me'/g' $dlnam  
   sed -i -- 's/ds=XX/ds='$nds'/g' $dlnam  
   sed -i -- 's/de=XX/de='$de'/g' $dlnam  
   sed -i -- 's/yy=XXXX/yy='$yy'/g' $dlnam  
   
   # copy over and configure the NDFD processing script
   cp ../$pndfd .
   sed -i -- 's/WSPDfilename/'$ndfddir$s'\/'$WSPD'/g' $pndfd  
   sed -i -- 's/WDIRfilename/'$ndfddir$s'\/'$WDIR'/g' $pndfd  
   
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
   sed -i -- 's/HE/'$he'/g' $mf15  
   sed -i -- 's/YY/'$yy'/g' $mf15  
   #matlab -nosplash -nodesktop -nodisplay < $mf15

   # submit job
   cp ../$jobscript .
   sed -i -- 's/STORM/'$s'/g' $jobscript
   sed -i -- 's/F15SCRIPT/'$mf15'/g' $jobscript
   sed -i -- 's/NAMDL/'$dlnam'/g' $jobscript
   sed -i -- 's/NDFDP/'$pndfd'/g' $jobscript
   sbatch $jobscript

   #step out
   cd ../ 
done
