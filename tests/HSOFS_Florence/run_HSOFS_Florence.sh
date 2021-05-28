#!/bin/bash
####################################################
# This is a test for the subsetting and merge tool #
# for Hurricane Florence based on the HSOFS mesh   #
####################################################
# IMPORTANT NOTE:
# the "get_HSOFS.sh" script will download fort.xx
# mesh files into the msh directory and save as
# "HSOFS.mat" file (179MB) if it doesn't already exist

# OceanMesh2D home directory location
OM2D='~/MATLAB/OceanMesh2D'
# Enter into .m files
OM2Dsed="${OM2D//\//\\/}"
sed -i -- 's/OM2DHOME/'$OM2Dsed'/g' *.m

## Load MATLAB module required
module load matlab

## Unzip input track file
unzip al062018_best_track.zip

date >run.timing

# move into the mesh directory
cd ../../mesh/
if [ ! -f "HSOFS.mat" ]; then
  # download HSOFS files into msh class and save as mat file
  ./get_HSOFS.sh
fi
# move back into this test directory
cd ../tests/HSOFS_Florence/

date >>run.timing

# run the merging script
matlab -nosplash -nodesktop -nodisplay <subset_HSOFS_Florence.m

date >>run.timing

# plot the merged mesh
matlab -nosplash -nodesktop -nodisplay <plot_HSOFS_Florence.m

date >>run.timing

# cleaning up
rm AL*
