## Storm-Surge-Mesh-Subsetting

# Edit header of the Setup*.sh scripts and execute to create the run directory and submit the job 
- Setup_ATCDF_Run.sh : for running a synthetic vortex-forced ADCIRC storm tide simulation based on ATCF best-track
- Setup_NAM_Run.sh : for running a NAM analysis-forced ADCIRC storm tide simulation
- Setup_NDFD_Run.sh : for running a NDFD forecast-forced ADCIRC storm tide simulation

NB: currently ATCF one is the most mature and likely to work correctly in the current directory setup

# Probably also need to edit job script located inside one of ATCF, NAM or NDFD directories to make sure the correct modules are loaded for your system 

# Look at the readmes inside the data, mesh, and exec directories to see what you need to add.

# Requirements:
- ADCIRC (fortran program)
- OceanMesh2D (matlab program)
- ADCIRCpy (python program)
