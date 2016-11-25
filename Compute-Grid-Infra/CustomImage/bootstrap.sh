set -x
#set -xeuo pipefail

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# != 1 ]; then
    echo "Usage: $0 <ManagementHost>"
    exit 1
fi

MGMT_HOSTNAME=$1

# Shares
SHARE_SCRATCH=/share/scratch

if [ ! -d $SHARE_SCRATCH ] 
then

if [ -f $SHARE_SCRATCH/nodesetup.sh ]
then
    bash $SHARE_SCRATCH/nodesetup.sh $MGMT_HOSTNAME
fi

fi