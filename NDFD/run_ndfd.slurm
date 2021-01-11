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

# Setup My Environment
module load matlab
module load mvapich2
module load netcdf
module load netcdf-fortran/4.4.4-ojwazvy

## data downloading/pre-processing 
date > run.timing

# Generate the fort.15 files   
matlab -nosplash -nodesktop -nodisplay < F15SCRIPT
   
# download the NAM winds
./DLNAM

# download the NDFD winds
./DLNDFD

# process the NDFD winds into usable format
./PRNDFD

date >> run.timing

## Performing the simulations
# Link and prep the cold-start files
ln -s NAM.221.grb2 fort.221.grb2
ln -s NAM.222.grb2 fort.222.grb2
ln -s MESH_STORM_CS.15 fort.15
./run_adcprep-all.sh

date >> run.timing

# Run the cold-start tide+NAM forcing
srun -n NP ./padcirc

date >> run.timing

# Link and prep hot-start files
rm *.inv
rm fort.221.grb2
rm fort.222.grb2
ln -s NAM_1hr.221.grb2 fort.221.grb2
ln -s NDFD_1hr.222.grb2 fort.222.grb2
rm fort.15
ln -s MESH_STORM_HS.15 fort.15
./run_adcprep-15.sh

date >> run.timing

# Run the hostart with tide+NDFD forcing
srun -n NP ./padcirc

# exit with end date
date >> run.timing
