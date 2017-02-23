#!/bin/bash
qsub -o ./results/ -j oe -N $1 -l nodes=$2:ppn=$3 -v "MODEL=$1, PODKEY=$PODKEY" starccm.sh
