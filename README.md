# Storm-Surge-Mesh-Subsetting

Table of contents
=================

<!--ts-->
   * [Storm-Surge-Mesh-Subsetting](#storm-surge-mesh-subsetting)
   * [Table of contents](#table-of-contents)
   * [Starting out](#starting-out)
   * [Requirements](#requirements)
   * [References](#references)
   * [Gallery](#gallery)
   * [Changelog](#changelog)
<!--te-->

Starting Out
============

## Edit header of the Setup*.sh scripts and execute to create the run directory and submit the job 
- Setup_ATCF_Run.sh : for running a synthetic vortex-forced ADCIRC storm tide simulation based on ATCF best-track
- Setup_NAM_Run.sh : for running a NAM analysis-forced ADCIRC storm tide simulation
- Setup_NDFD_Run.sh : for running a NDFD forecast-forced ADCIRC storm tide simulation

NB: currently ATCF one is the most mature and likely to work correctly in the current directory setup

### Probably also need to edit job script located inside one of ATCF, NAM or NDFD directories to make sure the correct modules are loaded for your system 

### Look at the readmes inside the data, mesh, and exec directories to see what you need to add in each of these directories

Requirements
==============

- ADCIRC Version 55 (fortran program - add these into exec directory)
- OceanMesh2D (matlab program - expecting to be located at: ~/MATLAB/OceanMesh2D/ )
- ADCIRCpy (python program - expecting it to be installed onto conda environment)

References
==============

```
OceanMesh2D:
- Roberts, K. J., Pringle, W. J., and Westerink, J. J., 2019.
      OceanMesh2D 1.0: MATLAB-based software for two-dimensional unstructured mesh generation in coastal ocean modeling,
      Geoscientific Model Development, 12, 1847-1868. https://doi.org/10.5194/gmd-12-1847-2019.

ADCIRC V55:
- Pringle, W. J., Wirasaet, D., Roberts, K. J., and Westerink, J. J., 2020.
      Global Storm Tide Modeling with ADCIRC v55: Unstructured Mesh Design and Performance,
      Geoscientific Model Development, accepted. https://doi.org/10.5194/gmd-2020-123.
```

GALLERY:
=========

<p align="center">
  <img src = "imgs/Florence_maxele.png"> &nbsp &nbsp &nbsp &nbsp
  <img src = "imgs/Florence_bathy.png"> &nbsp &nbsp &nbsp &nbsp
  <img src = "imgs/Florence_resomesh.png"> &nbsp &nbsp &nbsp &nbsp
</p>

Changelog
=========

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## Unreleased

### Added

### Changed

### Fixed

### Deleted
