#!/bin/bash

#SBATCH --job-name=MESH_STORM
#SBATCH --account=ACCNT
#SBATCH --partition=PARTN
#SBATCH --nodes=NODES
#SBATCH --ntasks-per-node=NTPN
#SBATCH --output=MESH_STORM.out
#SBATCH --error=MESH_STORM.error
#SBATCH --mail-user=wpringle@anl.gov
#SBATCH --time=HH:MM:SS

## set up environment
module load mvapich2
module load netcdf-fortran/4.4.4-ojwazvy
module load matlab
module load python
module load anaconda
# loading our virtual env
source activate pyaos

## Setting up inputs
date >run.timing

# Download storm track GIS information
./DLGIS

date >>run.timing

# Doing the subset and merge if required
if SUBSET; then
  # run the merging script
  matlab -nosplash -nodesktop -nodisplay <MERGEFN

  date >>run.timing

  # plot the merged mesh
  matlab -nosplash -nodesktop -nodisplay <PLOTMESH

  date >>run.timing
fi

# Reading and writing the station data
if READDATA; then
  python STADATA write
fi

# Running the make new f15 script
matlab -nosplash -nodesktop -nodisplay <MAKEF15

date >>run.timing

# Download storm ATCF file
./DLATCF

date >>run.timing

## COLDSTART
# Prepping coldstart
ln -s MESH_STORM_CS.15 fort.15
./run_adcprep-all.sh

# Run the coldstart
srun -n NP ./padcirc

date >>run.timing

## HOTSTART
# Prepping hotstart
rm fort.15
ln -s MESH_STORM_HS.15 fort.15
./run_adcprep-15.sh

# Run the hotstart
srun -n NP ./padcirc

date >>run.timing

# Plotting the figures
matlab -nosplash -nodesktop -nodisplay <PLOTRESULTS

matlab -nosplash -nodesktop -nodisplay <PLOTSTA
#python STADATA plot

# exit with end date
date >>run.timing

# delete the unnecessary PE directories
rm -r PE*
