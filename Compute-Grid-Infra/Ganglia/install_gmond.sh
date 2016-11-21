#!/bin/bash

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

# management server
MGMT_HOSTNAME=$1

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
		
	#configure Ganglia monitoring
	sed -i '0,/setuid = yes/{s/setuid = no/}'  /etc/ganglia/gmond.conf 
	sed -i '0,/name = "unspecified"/{s/name = "unspecified"/name = "'$MGMT_HOSTNAME' cluster"/}'  /etc/ganglia/gmond.conf 
	sed -i '0,/mcast_join = 239.2.11.71/{s/mcast_join = 239.2.11.71/host = '$MGMT_HOSTNAME'/}'  /etc/ganglia/gmond.conf
	sed -i '0,/mcast_join = 239.2.11.71/{s/mcast_join = 239.2.11.71//}'  /etc/ganglia/gmond.conf 	
	sed -i '0,/bind = 239.2.11.71/{s/bind = 239.2.11.71//}'  /etc/ganglia/gmond.conf 
	sed -i '0,/retry_bind = true/{s/retry_bind = true//}'  /etc/ganglia/gmond.conf 
	
	systemctl restart gmond
	systemctl enable gmond
}

SETUP_MARKER=/var/tmp/install_ganglia.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

install_pkgs
install_gmond

# Create marker file so we know we're configured
touch $SETUP_MARKER

