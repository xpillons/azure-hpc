#!/bin/bash

SHARE_APPS=/data/apps
BLOB_SOURCE=https://paedwar.blob.core.windows.net/public
APP_DIR=$SHARE_APPS/OpenFOAM
OPENFOAM_PKG=OpenFOAM-4.x_gcc48.tgz

mkdir -p $SHARE_APPS 

wget -q $BLOB_SOURCE/$OPENFOAM_PKG -O $SHARE_APPS/$OPENFOAM_PKG

tar -xzf $SHARE_APPS/$OPENFOAM_PKG -C $SHARE_APPS

# update RunFunctions to support MPI arguments
sed -i 's/mpirun -np/mpirun $MPI_ARGS -np/g' $APP_DIR/OpenFOAM-4.x/bin/tools/RunFunctions

