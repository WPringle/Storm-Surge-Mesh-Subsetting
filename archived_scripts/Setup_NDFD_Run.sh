#!/bin/bash
# By William Pringle, Jan 2021 -
# Argonne National Laboratory
# HEADOUT Enhancement Project, April 2020 - March 2021

#################################################################################
############## Edit the input info here #########################################
#################################################################################

## Enter full paths of the location of various items
meshdir="/lcrc/project/HSOFS_Ensemble/HEADOUT/mesh/"        # where mesh data is located
datadir="/lcrc/project/HSOFS_Ensemble/HEADOUT/data/"        # where station location data is located
execdir="/lcrc/project/HSOFS_Ensemble/HEADOUT/executables/" # where the ADCIRC-related executable files are located
scriptdir="/lcrc/project/HSOFS_Ensemble/HEADOUT/scripts/"   # where the various bash and MATLAB scripts are located

## Enter script filenames
nam_download_script="dl_arch-nam.sh"
ndfd_download_script="dl_arch-ndfd.sh"
ndfd_process_script="process_ndfd.sh"
make_f15_script="make_f15_ndfd_and_write_mesh.m"
job_script="run_ndfd.slurm" # choose .SGE (qsub) or .slurm (sbatch)
#subset_merge_script="Subset_Fine_and_Merge_to_Coarse.m"
#plot_mesh_script="Plot_Mesh.m"

## Setting some parameters and storm names
stormnames=("BARRY" "IMELDA" "OLGA" "DORIAN" "NESTOR")
meshname="HSOFS"   # name of the mesh[.mat] file
explicit=true      # true for explicit, false for implicit
subset=false       # true for doing the mesh subsett + merge
nodes=5            # number of computational nodes
np_per_node=36     # number of processors per computational node
job_time="1:30:00" # time allowed for job in hh:mm:ss format

#################################################################################
############## Scripting processes below [do not edit] ##########################
#################################################################################

# compute total number of processors based on nodes and tasks per node
np=$((nodes * $np_per_node))
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
for storm in "${stormnames[@]}"; do

  # remove directory if already exist
  if [ -d $storm ]; then
    rm -r $storm
  fi

  # make the new directory and step in
  mkdir $storm
  cd $storm

  # echo the storm name and current path
  echo "Storm name is: $storm"
  pwd

  ##############################################
  #### HARDCODING STORM DATES ##################
  ysa=2019
  ysi=2019
  if [ $storm == "BARRY" ]; then
    # NDFD forecast ini date
    msi=07
    dsi=12
    hsi=06
    # ARCHIVE start date (10 days earlier)
    msa=07
    dsa=02
  elif [ $storm == "IMELDA" ]; then
    # NDFD forecast ini date
    msi=09
    dsi=17
    hsi=06
    # ARCHIVE start date (10 days earlier)
    msa=09
    dsa=07
  elif [ $storm == "OLGA" ]; then
    # NDFD forecast ini date
    msi=10
    dsi=25
    hsi=06
    # ARCHIVE start date (10 days earlier)
    msa=10
    dsa=15
  elif [ $storm == "DORIAN" ]; then
    # NDFD forecast ini date
    msi=09
    dsi=02
    hsi=06
    # ARCHIVE start date (10 days earlier)
    msa=08
    dsa=23
  elif [ $storm == "NESTOR" ]; then
    # NDFD forecast ini date
    msi=10
    dsi=18
    hsi=06
    # ARCHIVE start date (10 days earlier)
    msa=10
    dsa=08
  fi
  ##############################################

  # pre-link the input and exec files
  fn=$meshname"_"$storm"_NDFD"
  ln -s $meshdir$meshname".mat" $fn".mat"
  ln -s $fn".24" fort.24
  ln -s $fn".14" fort.14
  ln -s $fn".13" fort.13
  ln -s $datadir"elev_stat.151" .
  ln -s $execdir"adcprep" .
  ln -s $execdir"padcirc" .
  # copy over the acdprep scripts and add np variable
  cp $scriptdir"run_adcprep-all.sh" .
  cp $scriptdir"run_adcprep-15.sh" .
  sed -i -- 's/NP/'$np'/g' run_adcprep-*.sh

  # copy over and configure the met download scripts
  # NAM
  cp $scriptdir$nam_download_script .
  sed -i -- 's/YYYY/'$ysa'/g' $nam_download_script
  sed -i -- 's/MMS/'$msa'/g' $nam_download_script
  sed -i -- 's/DDS/'$dsa'/g' $nam_download_script
  sed -i -- 's/MME/'$msi'/g' $nam_download_script
  sed -i -- 's/DDE/'$dsi'/g' $nam_download_script
  # NDFD
  cp $scriptdir$ndfd_download_script .
  sed -i -- 's/YYYY/'$ysi'/g' $ndfd_download_script
  sed -i -- 's/MMS/'$msi'/g' $ndfd_download_script
  sed -i -- 's/DDS/'$dsi'/g' $ndfd_download_script
  sed -i -- 's/HHS/'$hsi'/g' $ndfd_download_script
  # NDFD processing script
  cp $scriptdir$ndfd_process_script .

  # if we are subsetting and merging the coarse mesh with fine mesh
  if $subset; then
    # copy over and edit mesh subset+merge script
    cp $scriptdir$subset_merge_script .
    sed -i -- 's/storm/'$storm'/g' $subset_merge_script

    # copy over and edit mesh plotting script
    cp $scriptdir$plot_mesh_script .
    sed -i -- 's/storm/'$storm'/g' $plot_mesh_script
  fi

  # copy over and edit make fort.15 and write mesh script
  cp $scriptdir$make_f15_script .
  sed -i -- 's/STORMNAME/'$storm'/g' $make_f15_script
  sed -i -- 's/MESH/'$fn'/g' $make_f15_script
  sed -i -- 's/EXPLICIT_INT/'$explicit'/g' $make_f15_script
  sed -i -- 's/MMS/'$msi'/g' $make_f15_script
  sed -i -- 's/DDS/'$dsi'/g' $make_f15_script
  sed -i -- 's/HHS/'$hsi'/g' $make_f15_script
  sed -i -- 's/YYYY/'$ysi'/g' $make_f15_script

  # edit job submission script and submit
  new_job_script="run_"$storm".job"
  cp $scriptdir$job_script $new_job_script
  sed -i -- 's/NP/'$np'/g' $new_job_script
  sed -i -- 's/NODES/'$nodes'/g' $new_job_script
  sed -i -- 's/NTPN/'$np_per_node'/g' $new_job_script
  sed -i -- 's/HH:MM:SS/'$job_time'/g' $new_job_script
  sed -i -- 's/MESH_STORM/'$fn'/g' $new_job_script
  sed -i -- 's/SUBSET/'$subset'/g' $new_job_script
  sed -i -- 's/MERGEFN/'$subset_merge_script'/g' $new_job_script
  sed -i -- 's/DLNAM/'$nam_download_script'/g' $new_job_script
  sed -i -- 's/DLNDFD/'$ndfd_download_script'/g' $new_job_script
  sed -i -- 's/PRNDFD/'$ndfd_process_script'/g' $new_job_script
  sed -i -- 's/PLOTF/'$plot_mesh_script'/g' $new_job_script
  sed -i -- 's/F15SCRIPT/'$make_f15_script'/g' $new_job_script
  # submission based on job scheduler
  scheduler=${job_script: -3}
  if [ $scheduler = "SGE" ]; then
    qsub $new_job_script
  else
    sbatch $new_job_script
  fi

  #step out
  cd ../
done
