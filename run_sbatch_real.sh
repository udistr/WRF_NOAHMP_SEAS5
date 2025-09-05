#!/bin/bash -l

#SBATCH --mem=600GB
#SBATCH --job-name=WRF_SEAS5   # Job name
#SBATCH --nodes=1           # Number of nodes
#SBATCH --ntasks-per-node=1     # Number of tasks per node
#SBATCH --ntasks 1
#SBATCH --mem=100G                # Memory per node
#SBATCH --qos=mpi

#module --purge
#module load cesga/2020
#module load miniconda3/4.9.2

cd WRFRUN

echo $SLURM_NTASKS
./real.exe
