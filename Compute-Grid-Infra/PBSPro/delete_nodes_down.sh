#!/bin/bash

IFS=' ' 

while read -r line; do
  read -r -a node <<< $line
  echo "removing node $node"
  qmgr -c "delete node $node" 
done <<< "`pbsnodes -l`"


