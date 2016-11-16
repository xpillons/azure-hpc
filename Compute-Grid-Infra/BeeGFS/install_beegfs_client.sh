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

# Use the first storage server for management server
MGMT_HOSTNAME=$1

# Shares
SHARE_SCRATCH=/share/scratch


# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release
    yum -y install zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs gcc gcc-c++ nfs-utils rpcbind mdadm wget python-pip kernel kernel-devel openmpi openmpi-devel automake autoconf
	
	systemctl stop firewalld
	systemctl disable firewalld	
}


install_beegfs()
{
    # Install BeeGFS repo
    wget -O beegfs-rhel7.repo http://www.beegfs.com/release/beegfs_2015.03/dists/beegfs-rhel7.repo
    mv beegfs-rhel7.repo /etc/yum.repos.d/beegfs.repo
    rpm --import http://www.beegfs.com/release/beegfs_2015.03/gpg/RPM-GPG-KEY-beegfs
    
    # Disable SELinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    yum install -y beegfs-client beegfs-helperd beegfs-utils
        
    # setup client
    sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-client.conf
    #sed -i  's/Type=oneshot.*/Type=oneshot\nRestart=always\nRestartSec=5/g' /usr/lib/systemd/system/beegfs-client.service	
    echo "$SHARE_SCRATCH /etc/beegfs/beegfs-client.conf" > /etc/beegfs/beegfs-mounts.conf
	
    systemctl daemon-reload
    systemctl enable beegfs-helperd.service
    systemctl enable beegfs-client.service
}

SETUP_MARKER=/var/tmp/install_beegfs_client.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

mkdir -p $SHARE_SCRATCH

install_pkgs
install_beegfs

# Create marker file so we know we're configured
touch $SETUP_MARKER

#shutdown -r +1 &
exit 0

