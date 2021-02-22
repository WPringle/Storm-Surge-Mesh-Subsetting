#!/bin/bash
####################################################
# This is a test for the subsetting and merge tool #
# for Hurricane Florence based on the HSOFS mesh   #
####################################################
# IMPORTANT NOTE:
# the "get_HSOFS.sh" script will download fort.xx
# mesh files (about 500 mb). 
# If you already have the HSOFS.mat file in the mesh 
# directory then please comment the "get_HSFOS.sh" line

## Load MATLAB module required
module load matlab

## Unzip input track file
unzip al062018_best_track.zip 

date > run.timing

# move into the mesh directory 
cd ../../mesh/
# download HSOFS files into msh class and save as mat file 
./get_HSOFS.sh
# move back into this test directory
cd ../tests/HSOFS_Florence/

date >> run.timing

# run the merging script
matlab -nosplash -nodesktop -nodisplay < subset_HSOFS_Florence.m 

date >> run.timing

# plot the merged mesh
matlab -nosplash -nodesktop -nodisplay < plot_HSOFS_Florence.m

date >> run.timing

# cleaning up
rm AL*
