#!/bin/bash
#################################################################################
# This script sets up the run directories and submits job script                #
# for the desired storm number (in ALXXYYYY format)                             #
# By William Pringle, Dec 2020 - Feb 2021                                       #
# Argonne National Laboratory                                                   # 
# HSOFS_Ensemble project for NOAA Office of Coast Survey                        #
#################################################################################

#################################################################################
############## Edit the input info here #########################################
#################################################################################

## Setting some parameters and vortex codes
# storm names: Florence    Matthew
vortexcodes=("al062018") # "al142016") # vortex codes
meshname="HSOFS" # name of the mesh[.mat] file
coarsename="WNAT_1km"; # name of the coarse mesh properties[.mat] file
explicit=true    # true for explicit, false for implicit time stepping 
subset=false     # true for doing the mesh subset + merge
readdata=true    # true for using the python station data reader/writer/plotter
nodes=5          # number of computational nodes
np_per_node=36   # number of processors per computational node
job_time="3:30:00" # time allowed for job in hh:mm:ss format
account="HSOFS_Ensemble" # account name for job submission
partition="bdwall" # optional compute partition selection
scheduler="slurm" # choose SGE (qsub) or slurm (sbatch)

# ----------------------------------------------------------------------------- #
# Do not need to edit following unless you want to rename and move things around
# ----------------------------------------------------------------------------- #
# Enter location of various items
datadir="data/" # where station location data is located 
execdir="exec/" # where the ADCIRC-related executable files are located
scriptdir="ATCF/" # where the various bash and MATLAB scripts are located
meshdir="mesh/" # where mesh data is located [NOTE: this one must use back-slash before any forward slashes because it is used in a sed command]

# Enter data names
#stafile="us-east-gulf_sta.128"

# Enter script filenames
gis_download_script="dl_storm_gis.sh" 
atcf_download_script="dl_storm_atcf.sh" 
make_f15_script="make_f15_vortex_and_write_mesh.m" 
subset_merge_script="subset_fine_and_merge_to_coarse.m" 
plot_mesh_script="plot_mesh.m" 
plot_result_script="plot_max_results.m" 
plot_sta_script="plot_timeseries.m" 
sta_data_script="station_data.py" 
job_script="run_storm."$scheduler # choose .SGE (qsub) or .slurm (sbatch)

#################################################################################
############## Scripting processes below [do not edit] ##########################
#################################################################################

# Append pwd to the directories
datadir=$(pwd)"/"$datadir
execdir=$(pwd)"/"$execdir
scriptdir=$(pwd)"/"$scriptdir
meshdir=$(pwd)"/"$meshdir
# modify meshdir and datadir for sed usage
meshdir="${meshdir//\//\\/}"
datadirsed="${datadir//\//\\/}"

# compute total number of processors based on nodes and tasks per node
np=$(( nodes*$np_per_node ))
echo "Number of computational processors is: $np"

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

   # echo the storm code and current path 
   echo "Storm code is: $code" 
   pwd 

   # this is the out filename
   fn=$meshname"_"$subsetdir"_"$code

   # pre-link the input and exec files
   ln -s $fn".24" fort.24
   ln -s $fn".14" fort.14
   ln -s $fn".13" fort.13
   ln -s $execdir"adcprep" .
   ln -s $execdir"padcirc" .
   ln -s $execdir"aswip" .
   # copy over the acdprep scripts and add np variable
   cp $scriptdir"run_adcprep-all.sh" .
   cp $scriptdir"run_adcprep-15.sh" .
   sed -i -- 's/NP/'$np'/g' run_adcprep*.sh  
  
   # link the station file or copy over the data reader
   if $readdata; then
      cp $scriptdir$sta_data_script .
      sed -i -- 's/STORMCODE/'$code'/g' $sta_data_script
      sed -i -- 's/DATA_DIR/'$datadirsed'/g' $sta_data_script
   else
      ln -s $datadir$stafile elev_stat.151
   fi

   # copy over and configure the GIS and ALCF download scripts
   cp $scriptdir$gis_download_script .     
   sed -i -- 's/STORMCODE/'$code'/g' $gis_download_script  
   cp $scriptdir$atcf_download_script .     
   sed -i -- 's/STORMCODE/'$code'/g' $atcf_download_script  
  
   # if we are subsetting and merging the coarse mesh with fine mesh
   if $subset; then
      # copy over and edit mesh subset+merge script
      cp $scriptdir$subset_merge_script .     
      sed -i -- 's/MESH_DIR/'$meshdir'/g' $subset_merge_script 
      sed -i -- 's/DATA_DIR/'$datadirsed'/g' $subset_merge_script 
      sed -i -- 's/STORMCODE/'$code'/g' $subset_merge_script 
      sed -i -- 's/MESH_STORM/'$fn'/g' $subset_merge_script 
      sed -i -- 's/FINE/'$meshname'/g' $subset_merge_script 
      sed -i -- 's/COARSE/'$coarsename'/g' $subset_merge_script 
      # copy over and edit mesh plotting script
      cp $scriptdir$plot_mesh_script .     
      sed -i -- 's/STORMCODE/'$code'/g' $plot_mesh_script
      sed -i -- 's/MESH_STORM/'$fn'/g' $plot_mesh_script
   fi
   
   # copy over and edit the result plotting script  
   cp $scriptdir$plot_result_script .     
   sed -i -- 's/STORMCODE/'$code'/g' $plot_result_script
   sed -i -- 's/MESH_STORM/'$fn'/g' $plot_result_script 
   cp $scriptdir$plot_sta_script .     
      
   # copy over and edit make fort.15 and write mesh script
   cp $scriptdir$make_f15_script .     
   sed -i -- 's/MESH_DIR/'$meshdir'/g' $make_f15_script 
   sed -i -- 's/STORMCODE/'$code'/g' $make_f15_script 
   sed -i -- 's/MESH_STORM/'$fn'/g' $make_f15_script
   if $subset; then
      # use the subsetted mesh as mesh input
      sed -i -- 's/MESH/'$fn'/g' $make_f15_script
   else
      # no subsetting just use the original fine mesh
      sed -i -- 's/MESH/'$meshname'/g' $make_f15_script
   fi
   sed -i -- 's/EXPLICIT_INT/'$explicit'/g' $make_f15_script
      
   # edit job submission script and submit
   new_job_script="run_"$code".job"
   cp $scriptdir$job_script $new_job_script
   sed -i -- 's/NP/'$np'/g' $new_job_script 
   sed -i -- 's/NODES/'$nodes'/g' $new_job_script 
   sed -i -- 's/NTPN/'$np_per_node'/g' $new_job_script 
   sed -i -- 's/HH:MM:SS/'$job_time'/g' $new_job_script 
   sed -i -- 's/MESH_STORM/'$fn'/g' $new_job_script 
   sed -i -- 's/ACCNT/'$account'/g' $new_job_script 
   sed -i -- 's/PARTN/'$partition'/g' $new_job_script 
   sed -i -- 's/DLGIS/'$gis_download_script'/g' $new_job_script  
   sed -i -- 's/DLATCF/'$atcf_download_script'/g' $new_job_script  
   sed -i -- 's/SUBSET/'$subset'/g' $new_job_script 
   sed -i -- 's/MERGEFN/'$subset_merge_script'/g' $new_job_script 
   sed -i -- 's/PLOTMESH/'$plot_mesh_script'/g' $new_job_script 
   sed -i -- 's/MAKEF15/'$make_f15_script'/g' $new_job_script 
   sed -i -- 's/PLOTRESULTS/'$plot_result_script'/g' $new_job_script 
   sed -i -- 's/PLOTSTA/'$plot_sta_script'/g' $new_job_script 
   sed -i -- 's/READDATA/'$readdata'/g' $new_job_script 
   sed -i -- 's/STADATA/'$sta_data_script'/g' $new_job_script 
   # submission based on job scheduler
   if [ $scheduler = "SGE" ]; then 
      qsub $new_job_script
   else
      sbatch $new_job_script
   fi

   #step out
   cd ../
done
