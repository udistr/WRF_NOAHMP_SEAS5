#!/bin/bash -l

#SBATCH --mem=600GB
##SBATCH -N 6
##SBATCH -n 120
##SBATCH -t 7-00:00:00
#SBATCH --job-name=GEOGRID   # Job name
#SBATCH --nodes=1           # Number of nodes
#SBATCH --ntasks-per-node=1     # Number of tasks per node
#SBATCH --ntasks 1
#SBATCH --mem=300G                # Memory per node
#SBATCH --qos=qn

#module --purge
#module load cesga/2020
#module load miniconda3/4.9.2

cd /home/ARO.local/udist/arch/WRF_NOAMP/WPS_SEAS5_20141101

. /data/bin/miniconda2/envs/tcsh-v6.22.03/env_tcsh.sh;
. /data/bin/miniconda2/envs/cdo-v1.9.9/env_cdo.sh
. /data/bin/miniconda2/envs/ncl-v6.6.2/env_ncl.sh;
. /data/bin/miniconda2/envs/ncview-v2.1.7/env_ncview.sh;
. /data/bin/miniconda2/envs/pythonUdi-v1.0/env_pythonUdi.sh

echo $SLURM_NTASKS
echo "finshed"
##srun -n $SLURM_NTASKS --mpi=pmi2 real.exe
##python updateLowinp.py
srun -n $SLURM_NTASKS --mpi=pmi2 geogrid.exe
