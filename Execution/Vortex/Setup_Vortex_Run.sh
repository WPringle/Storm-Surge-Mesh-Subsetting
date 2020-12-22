#!/bin/bash
# By William Pringle, Dec 2020

#################################################################################
############## Edit the input info here #########################################
#################################################################################

## Enter full paths of the location of various items
meshdir="/lcrc/project/HSOFS_Ensemble/HSOFS/mesh/"
datadir="/lcrc/project/HSOFS_Ensemble/HSOFS/data/"
execdir="/lcrc/project/HSOFS_Ensemble/HSOFS/executables/"
scriptdir="/lcrc/project/HSOFS_Ensemble/HSOFS/scripts/"

## Enter script filenames
vortex_download_script="dl_storm_vortex.sh" 
make_f15_script="Make_f15_vortex.m" 
subset_merge_script="Subset_Fine_and_Merge_to_Coarse.m" 
plot_mesh_script="Plot_Mesh.m" 
job_script="run_storm.job"

## Setting some parameters and vortex codes
# storm names: Florence    Matthew
vortexcodes=("al062018" "al062012") # vortex codes
meshname="HSOFS" #name of the mesh[.mat] file
explicit=true  # true for explicit, false for implicit
subset=false # true for doing the mesh subsett + merge
np=24 # number of computational processors

#################################################################################
############## Scripting processes below [do not edit] ##########################
#################################################################################

# make the folder for the mesh the mesh and move into it
echo "Mesh is: $meshname"
if [ ! -d $meshname ]; then
  mkdir $meshname
fi
cd $meshname

# make the folder for the subset yes/no and move into
echo "Subset and merge mesh?: "$subset
if $subset; then
   subsetdir=subset
else
   subsetdir=nosubset
fi
if [ ! -d $subsetdir ]; then
   mkdir $subsetdir
fi
cd $subsetdir

# loop over all the storms, setup up run directory/scripts and run
for code in "${vortexcodes[@]}"
do
    
   # remove directory if already exist
   if [ -d $code ]; then
      rm -r $code
   fi

   # make the new directory and step in
   mkdir $code
   cd $code
   
   # echo the current path 
   pwd  
 
   # pre-link the input and exec files
   fn=$meshname"_"$subsetdir"_"$code
   ln -s $fn".24" fort.24
   ln -s $fn".14" fort.14
   ln -s $fn".13" fort.13
   ln -s $datadir"elev_stat.151" .
   ln -s $execdir"adcprep" .
   ln -s $execdir"padcirc" .
   ln -s $execdir"aswip" .
   # copy over the acdprep scripts and add np variable
   cp $scriptdir"adcprepall.sh" .
   cp $scriptdir"adcprep15.sh" .
   sed -i -- 's/XXX/'$np'/g' adcprepall.sh  
   sed -i -- 's/XXX/'$np'/g' adcprep15.sh  
   
   # copy over and configure the ALCF download script
   cp $scriptdir$vortex_download_script .     
   sed -i -- 's/STORMCODE/'$code'/g' $vortex_download_script  
   sed -i -- 's/XXXX/'$yy'/g' $vortex_download_script 
  
   if $subset; then 
      # copy over and edit mesh subset+merge script
      cp $scriptdir$subset_merge_script .     
      sed -i -- 's/STORMNAME/'$s'/g' $subset_merge_script
      sed -i -- 's/STORMCODE/'$code'/g' $subset_merge_script 
   
      # copy over and edit mesh plotting script
      cp $scriptdir$plot_mesh_script .     
      sed -i -- 's/STORMCODE/'$code'/g' $plot_mesh_script
   fi

   # copy over and edit make fort.15 script
   cp $scriptdir$make_f15_script .     
   sed -i -- 's/STORMCODE/'$code'/g' $make_f15_script 
   sed -i -- 's/MESH/'$fn'/g' $make_f15_script 
   sed -i -- 's/EXPLICIT_INT/'$explicit'/g' $make_f15_script

   # submit job
   new_job_script="run_"$code".job"
   cp $scriptdir$job_script $new_job_script
   sed -i -- 's/XXX/'$np'/g' $new_job_script 
   sed -i -- 's/MESH/'$fn'/g' $new_job_script 
   sed -i -- 's/SUBSET/'$subset'/g' $new_job_script 
   sed -i -- 's/MERGEFN/'$subset_merge_script'/g' $new_job_script 
   sed -i -- 's/PLOTF/'$plot_mesh_script'/g' $new_job_script 
   sed -i -- 's/MAKEF15/'$make_f15_script'/g' $new_job_script 
   #qsub $new_job_script

   #step out
   cd ../
done
