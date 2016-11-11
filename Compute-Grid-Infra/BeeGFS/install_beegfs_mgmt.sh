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

# Shares
SHARE_SCRATCH=/share/scratch


# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release
    yum -y install zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs gcc gcc-c++ nfs-utils rpcbind mdadm wget python-pip kernel kernel-devel openmpi openmpi-devel automake autoconf
}


install_beegfs()
{
    # Install BeeGFS repo
    wget -O beegfs-rhel7.repo http://www.beegfs.com/release/latest-stable/dists/beegfs-rhel7.repo
    mv beegfs-rhel7.repo /etc/yum.repos.d/beegfs.repo
    rpm --import http://www.beegfs.com/release/latest-stable/gpg/RPM-GPG-KEY-beegfs
    
    # Disable SELinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    yum install -y beegfs-mgmtd beegfs-client beegfs-helperd beegfs-utils beegfs-admon
        
    # Install management server and client
    mkdir -p /data/beegfs/mgmtd
    sed -i 's|^storeMgmtdDirectory.*|storeMgmtdDirectory = /data/beegfs/mgmt|g' /etc/beegfs/beegfs-mgmtd.conf
    sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-admon.conf
    systemctl daemon-reload
    systemctl enable beegfs-mgmtd.service
	systemctl enable beegfs-admon.service

    # setup client
    sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-client.conf
    #sed -i  's/Type=oneshot.*/Type=oneshot\nRestart=always\nRestartSec=5/g' /usr/lib/systemd/system/beegfs-client.service
    echo "$SHARE_SCRATCH /etc/beegfs/beegfs-client.conf" > /etc/beegfs/beegfs-mounts.conf
	
    systemctl daemon-reload
    systemctl enable beegfs-helperd.service
    systemctl enable beegfs-client.service
}

SETUP_MARKER=/var/tmp/install_beegfs_mgmt.marker
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

