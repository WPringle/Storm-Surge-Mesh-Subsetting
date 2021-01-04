#!/bin/bash

#SBATCH --job-name=MESH_STORM
#SBATCH --account=HSOFS_Ensemble
#SBATCH --partition=bdwall
#SBATCH --nodes=NODES
#SBATCH --ntasks-per-node=NTPN
#SBATCH --output=MESH_STORM.out
#SBATCH --error=MESH_STORM.error
#SBATCH --mail-user=wpringle@anl.gov
#SBATCH --time=0:10:00

## set up environment
module load mvapich2
module load netcdf
module load matlab

## Setting up inputs
date > run.timing

# download storm track and vortex information
./dl_storm_vortex.sh

date >> run.timing

if SUBSET; then
   # run the merging script
   matlab -nosplash -nodesktop -nodisplay < MERGEFN 

   date >> run.timing

   # plot the merged mesh
   matlab -nosplash -nodesktop -nodisplay < PLOTF

   date >> run.timing
fi
   
## running the make new f15 script
#matlab -nosplash -nodesktop -nodisplay < MAKEF15 

#date >> run.timing

## Setup cold start
#rm *.inv
#rm *.nc
#rm fort.15
#ln -s MESH_CS.15 fort.15
#./adcprepall.sh

## Run My Program
#mpiexec -n NP ./padcirc

# Setup hot start
#rm fort.15
#ln -s MESH_HS.15 fort.15
#./adcprep15.sh

## Run My Program
#mpiexec -n NP ./padcirc
#
#date >> run.timing
