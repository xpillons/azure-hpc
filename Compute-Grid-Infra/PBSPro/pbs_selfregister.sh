#!/bin/bash
# chkconfig: 345 99 10
# description: auto start pbs_selfregister
#
PBS_MANAGER=hpcuser
nodename=`hostname`
qname=workq

case "$1" in
 'start')
    echo "adding node $nodename to queue manager"
    sudo -u $PBS_MANAGER /opt/pbs/bin/qmgr -c "create node $nodename"
    sudo -u $PBS_MANAGER /opt/pbs/bin/qmgr -c "set node $nodename queue=$qname"
    ;;
 'stop')
    echo "removing node $nodename from queue manager"
    sudo -u $PBS_MANAGER /opt/pbs/bin/qmgr -c "delete node $nodename"
    ;;
esac
