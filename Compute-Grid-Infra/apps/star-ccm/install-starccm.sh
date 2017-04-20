#!/bin/bash

SHARE_APPS=/data/apps
BLOB_SOURCE=http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage
APP_DIR=$SHARE_APPS/star
STAR_VER=11.04.012
STAR_PKG=STAR-CCM+${STAR_VER}_01_linux-x86_64-r8.tar.gz
BENCHMARK_DIR=/data/input/star

mkdir -p $BENCHMARK_DIR
mkdir -p $APP_DIR

wget -q $BLOB_SOURCE/runAndRecord.java -O $BENCHMARK_DIR/runAndRecord.java
wget -q $BLOB_SOURCE/$STAR_PKG -O $APP_DIR/$STAR_PKG

tar -xzf $APP_DIR/$STAR_PKG -C $APP_DIR

cd $APP_DIR/starccm+_$STAR_VER

sh STAR-CCM+11.04.012_01_linux-x86_64-2.5_gnu4.8-r8.bin -i silent -DINSTALLDIR=$APP_DIR -DCOMPUTE_NODE=true -DNODOC=true -DINSTALLFLEX=false


