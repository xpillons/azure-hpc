#!/bin/bash

set -x
#set -xeuo pipefail

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# != 3 ]; then
    echo "Usage: $0 <ManagementHost> <ClusterName> <ClusterPort>"
    exit 1
fi

# management server
MGMT_HOSTNAME=$1
CLUSTER_NAME=$2
CLUSTER_PORT=$3

# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release	
	yum -y install ganglia-gmond
}

install_gmond()
{
    systemctl stop firewalld
    systemctl disable firewalld

    # Disable SELinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
	GMOND_CONFIG=/etc/ganglia/gmond.conf	
	#configure Ganglia monitoring
	sed -i '0,/name = "unspecified"/{s/name = "unspecified"/name = "'$CLUSTER_NAME'"/}'  $GMOND_CONFIG 
	sed -i '0,/mcast_join = 239.2.11.71/{s/mcast_join = 239.2.11.71/host = '$MGMT_HOSTNAME'/}'  $GMOND_CONFIG
	sed -i '0,/mcast_join = 239.2.11.71/{s/mcast_join = 239.2.11.71//}'  $GMOND_CONFIG
	sed -i '0,/bind = 239.2.11.71/{s/bind = 239.2.11.71//}'  $GMOND_CONFIG
	sed -i '0,/retry_bind = true/{s/retry_bind = true//}'  $GMOND_CONFIG
	sed -i '0,/send_metadata_interval = 0/{s/send_metadata_interval = 0/send_metadata_interval = 60/}'  $GMOND_CONFIG
	sed -i '0,/port = 8649/{s/port = 8649/port = '$CLUSTER_PORT'/}'  $GMOND_CONFIG
	sed -i '0,/port = 8649/{s/port = 8649/port = '$CLUSTER_PORT'/}'  $GMOND_CONFIG
	sed -i '0,/port = 8649/{s/port = 8649/port = '$CLUSTER_PORT'/}'  $GMOND_CONFIG
	sed -i 's/#bind_hostname = yes.*/bind_hostname = yes/g' $GMOND_CONFIG
	#sed -i 's/deaf = no.*/deaf = yes/g' $GMOND_CONFIG

	# ovveride hostname to avoid using reverse DNS
	#name=`hostname`
	#sed -i 's/# override_hostname = "mywebserver.domain.com".*/override_hostname ="'${name,,}'"/g' $GMOND_CONFIG

	systemctl restart gmond
	systemctl enable gmond
}

SETUP_MARKER=/var/local/install_ganglia.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

install_pkgs
install_gmond

# Create marker file so we know we're configured
touch $SETUP_MARKER

