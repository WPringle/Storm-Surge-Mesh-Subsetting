#!/bin/bash

#SBATCH --job-name=MESH_STORM
#SBATCH --account=HSOFS_Ensemble
#SBATCH --partition=bdwall
#SBATCH --nodes=NODES
#SBATCH --ntasks-per-node=NTPN
#SBATCH --output=MESH_STORM.out
#SBATCH --error=MESH_STORM.error
#SBATCH --mail-user=wpringle@anl.gov
#SBATCH --time=HH:MM:SS

## set up environment
module load matlab
module load mvapich2
module load netcdf
module load netcdf-fortran/4.4.4-ojwazvy

## Setting up inputs
date > run.timing

# Download storm track and vortex information
./dl_storm_vortex.sh

date >> run.timing

# Doing the subset and merge if required
if SUBSET; then
   # run the merging script
   matlab -nosplash -nodesktop -nodisplay < MERGEFN 

   date >> run.timing

   # plot the merged mesh
   matlab -nosplash -nodesktop -nodisplay < PLOTF

   date >> run.timing
fi
   
# Running the make new f15 script
matlab -nosplash -nodesktop -nodisplay < MAKEF15 

date >> run.timing

## Setup cold start
ln -s MESH_STORM_CS.15 fort.15
./adcprepall.sh

## Run My Program
srun -n NP ./padcirc

date >> run.timing

# Setup hot start
rm fort.15
ln -s MESH_STORM_HS.15 fort.15
./adcprep15.sh

## Run My Program
srun -n NP ./padcirc

date >> run.timing
