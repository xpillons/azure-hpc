#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTDIR=/data/jobs

log()
{
	echo "$1"
}

usage() { echo "Usage: $0 [-x <jobId>] [-i <input URI>] [-c <cores per node>] [-n <nodes>] [-q <queuename>] [-r <rRunner>]" 1>&2; exit 1; }

while getopts :x:i:c:n:r:q: optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    x)  # job ID
		export PINTA_JOBID=${OPTARG}
		;;
    i)  # input URI
		export MODEL_URI=${OPTARG}
		;;
    c)  # cores per node
		export CORES_PER_NODE=${OPTARG}
		;;
    n)  # nodes
		export NB_NODES=${OPTARG}
		;;
    r)  # runner
                export RUNNER=${OPTARG}
                ;;
    q)  # queue name
		export QNAME=${OPTARG}
		;;
	*)
		usage
		;;
  esac
done

jobdir=${OUTDIR}/${PINTA_JOBID}
if [ ! -d "$jobdir" ]; then
    mkdir $jobdir
fi

#extract account, container, model name and sas key from the URI
account=`echo $MODEL_URI | awk -F'[/.]' '{print $3}'`
echo "account is $account"
container=`echo $MODEL_URI | awk -F'[/]' '{print $4}'`
echo "container is $container"
saskey=`echo $MODEL_URI | awk -F'[?]' '{print $2}'`
echo "saskey is $saskey"
package=`echo $MODEL_URI | awk -F'[?]' '{print $1}' | awk -F'[/]' '{print $5}'`
echo "package is $package"
model=`echo $package | awk -F'[.]' '{print $1}'`
echo "model is $model" 

GETJOBID=`qsub -f -o $jobdir -j oe -N "get-$package" -q datamvt -v "jobdir=$jobdir, az_account=$account, container=$container, saskey=$saskey, package=$package" $DIR/download.pbs` 

RUNJOBID=`qsub -f -o $jobdir -j oe -N $model -q $QNAME -l nodes=$NB_NODES:ppn=$CORES_PER_NODE -W depend=afterany:$GETJOBID -v "jobdir=$jobdir, runner=$RUNNER, nodes=$NB_NODES, ppn=$CORES_PER_NODE" $DIR/openfoam.pbs`

UPLOADJOBID=`qsub -f -o $OUTDIR -j oe -N "copy-$RUNJOBID" -q datamvt -W depend=afterany:$RUNJOBID -v "jobdir=$jobdir, JOBID=$RUNJOBID, pintajobid=$PINTA_JOBID" $DIR/copydata.pbs`
echo $RUNJOBID
