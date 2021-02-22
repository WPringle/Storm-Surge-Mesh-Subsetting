#!/bin/bash
####################################################
# This is a test for the subsetting and merge tool #
# for Hurricane Florence based on the HSOFS mesh   #
####################################################

## Load MATLAB module required
module load matlab

## Unzip input track file
unzip al062018_best_track.zip 

date > run.timing

# run the merging script
matlab -nosplash -nodesktop -nodisplay < subset_HSOFS_Florence.m 

date >> run.timing

# plot the merged mesh
matlab -nosplash -nodesktop -nodisplay < plot_HSOFS_Florence.m

date >> run.timing

# cleaning up
rm AL*
