#!/bin/bash
####################################################
# This is a test for the ensemble perturbations of #
# Hurricane Florence                               #
# - Perturbs Vmax, Rmw, cross-track, along-track   #
####################################################

## load your environment before running script or enter here:
##Ex.
## load modules
#module load python anaconda matlab 
## load python environment
#source activate pyaos

# Enter m_map home directory location
MMAP='~/MATLAB/OceanMesh2D/m_map'
# Enter into .m files
MMAPsed="${MMAP//\//\\/}"
sed -i -- 's/MMAPHOME/'$MMAPsed'/g' *.m

ln -s ../../ATCF/make_storm_ensemble.py .

date >run.timing
## run the make_ensemble script
                    #no. ensembles #stormname/code #start-date #end-date
python3 make_storm_ensemble.py 2 Florence2018 2018-09-11-00 #2018-09-17-06

date >>run.timing

mkdir outputs
mv *.22 outputs/

matlab -nosplash -nodesktop -nodisplay <plot_perturbed_tracks.m

date >>run.timing

# clean up and reset
rm make_storm_ensemble.py
sed -i -- 's/'$MMAPsed'/MMAPHOME/g' *.m
