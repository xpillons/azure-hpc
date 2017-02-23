#!/bin/bash

MODEL=$1
SHARE_APPS=/data/apps
BLOB_SOURCE=http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage
APP_DIR=$SHARE_APPS/star
BENCHMARK_DIR=/data/input/star

mkdir -p $BENCHMARK_DIR

wget -q $BLOB_SOURCE/$MODEL -o wget.log -S -O $BENCHMARK_DIR/$MODEL
tar -xf $BENCHMARK_DIR/$MODEL -C $BENCHMARK_DIR
rm $BENCHMARK_DIR/$MODEL

