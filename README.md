## Introduction

This repository includes the code needed to reproduce the simulation results in

> Farrukh Abdinov, Mustafa F. Ozkoc, Fraida Fund, Shivendra S. Panwar,
> "Can 5G Networks Meet the Requirements ofConnected Vehicle Applications?",


## Run the simulation

To run the simulation, just run

```
cd CapacitySimulation
SimulateCapacityAllLanes.m
```

in either MATLAB or Octave. The simulation will generate two data files:

* One with a matrix of probabilities
* One with a matrix of blockage durations.

These can be used to reproduce Figure 5a and 5b in the referenced paper.

## Run on HPC

To run on NYU's High Performance Computing cluster, run

```
*	ssh prince
*	cd $SCRATCH
*	rm -rf HighwayVehicular   ## Removes the old simulations
*	git clone https://github.com/mustafafu/HighwayVehicular.git
*	cd HighwayVehicular/CapacitySimulation
*	sbatch --array=0-959 submitAllLanes.sbatch
```
