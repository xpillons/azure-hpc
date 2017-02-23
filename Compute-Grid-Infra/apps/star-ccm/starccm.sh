#!/bin/bash
STAR_ROOT=/data/apps/star
DATA_ROOT=/data/input/star
export PATH=$STAR_ROOT/STAR-CCM+11.04.012-R8/star/bin:$PATH

source /opt/intel/impi/5.1.3.181/bin64/mpivars.sh

export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com


nproc=`cat $PBS_NODEFILE | wc -l`
starccm+ -np $nproc -machinefile $PBS_NODEFILE -power -podkey $PODKEY -rsh ssh -mpi intel -cpubind bandwidth,v -mppflags "-genv I_MPI_DAPL_PROVIDER ofa-v2-ib0 -genv I_MPI_DAPL_UD 0 -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FALLBACK_DEVICE=disable" -batch $DATA_ROOT/runAndRecord.java $DATA_ROOT/$MODEL.sim
