#!/bin/bash
####################################################
# This script downloads the HSOFS fort.xx files    #
# and saves into a msh class                       #
####################################################

## Load MATLAB module required
module load matlab

# download the HSOFS fort.13 and fort.14 files
wget "ftp://ocsftp.ncd.noaa.gov/estofs/hsofs-atl/fort13nomad1elowerwaterdrag" -O HSOFS.13
wget "ftp://ocsftp.ncd.noaa.gov/estofs/hsofs-atl/fort.14" -O HSOFS.14

# run the merging script
matlab -nosplash -nodesktop -nodisplay -r "save_fort_to_mat('HSOFS');exit"

# clean up
rm HSOFS.13 HSOFS.14
