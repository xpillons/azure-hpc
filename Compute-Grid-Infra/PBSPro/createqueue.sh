#!/bin/bash

queuename=$1
echo "creating queue $queuename"
qmgr -c "create queue $queuename"
qmgr -c "set queue $queuename queue_type=e"
qmgr -c "set queue $queuename started=true"
qmgr -c "set queue $queuename enabled=true"

qstat -Q
