## Introduction

This repository includes the code needed to reproduce the simulation results in

> Caglar Tunc, Mustafa F. Ozkoc, Shivendra Panwar, 
> "Millimeter Wave Coverage and Blockage Duration Analysis for Vehicular Communications",
> IEEE VTC 2019

## Run the simulation

To run the simulation, just run

```
*	ssh prince
*	cd $SCRATCH
*	rm -rf HighwayVehicular   ## Removes the old simulations
*	git clone https://github.com/mustafafu/HighwayVehicular.git
*	cd HighwayVehicular/CapacitySimulation
*	sbatch --array=0-959 submitAllLanes.sbatch
```

in either MATLAB or Octave. The simulation will generate two data files:

* One with a matrix of probabilities
* One with a matrix of blockage durations.

These can be used to reproduce Figure 5a and 5b in the referenced paper.

## Run on HPC

To run on NYU's High Performance Computing cluster, run

```
cd CapacitySimulation
sbatch --array=0-959 submitAllLanes.sbatch
```
