#!/bin/bash

#SBATCH --mem=4GB
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/%a_%A.out
#SBATCH --error=logs/%a_%A.err

module purge
module load matlab/2019a

cd /scratch/$USER/HighwayVehicular/CapacitySimulation/data

mkdir -p data
mkdir -p logs

echo "$SLURM_ARRAY_TASK_ID"


matlab -nodisplay -r "OffloadCountParser, exit"


