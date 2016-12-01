#!/bin/bash

set -x
#set -xeuo pipefail

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# != 2 ]; then
    echo "Usage: $0 <ManagementHost> <Mount>"
    exit 1
fi

# Use the first storage server for management server
MGMT_HOSTNAME=$1

# Shares
SHARE_SCRATCH=$2
SHARE_HOME=/share/home

# User
HPC_USER=hpcuser
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007

# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release
    yum -y install zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs gcc gcc-c++ nfs-utils rpcbind mdadm wget python-pip kernel kernel-devel openmpi openmpi-devel automake autoconf
	
	#systemctl stop firewalld
	#systemctl disable firewalld	
}


install_beegfs()
{
    # Install BeeGFS repo
    wget -O beegfs-rhel6.repo http://www.beegfs.com/release/beegfs_2015.03/dists/beegfs-rhel6.repo
    mv beegfs-rhel6.repo /etc/yum.repos.d/beegfs.repo
    rpm --import http://www.beegfs.com/release/beegfs_2015.03/gpg/RPM-GPG-KEY-beegfs
    
    # Disable SELinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    yum install -y beegfs-client beegfs-helperd beegfs-utils
        
    # setup client
	/opt/beegfs/sbin/beegfs-setup-client -m $MGMT_HOSTNAME
    sed -i 's/^connMaxInternodeNum.*/connMaxInternodeNum = 16/g' /etc/beegfs/beegfs-client.conf

    echo "$SHARE_SCRATCH /etc/beegfs/beegfs-client.conf" > /etc/beegfs/beegfs-mounts.conf
	
    /etc/init.d/beegfs-helperd start
    /etc/init.d/beegfs-client start
}

tune_tcp()
{
    echo "net.ipv4.neigh.default.gc_thresh1=1100" >> /etc/sysctl.conf
    echo "net.ipv4.neigh.default.gc_thresh2=2200" >> /etc/sysctl.conf
    echo "net.ipv4.neigh.default.gc_thresh3=4400" >> /etc/sysctl.conf
}

setup_user()
{
    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_SCRATCH

	echo "$MGMT_HOSTNAME:$SHARE_HOME $SHARE_HOME    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab
	mount -a
	mount

    # disable selinux
    sed -i 's/enforcing/disabled/g' /etc/selinux/config
    setenforce permissive
    
    groupadd -g $HPC_GID $HPC_GROUP

    # Don't require password for HPC user sudo
    echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

	useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

    chown $HPC_USER:$HPC_GROUP $SHARE_SCRATCH	
}

SETUP_MARKER=/var/local/install_beegfs_client.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

mkdir -p $SHARE_SCRATCH

install_pkgs
setup_user
install_beegfs
tune_tcp

# Create marker file so we know we're configured
touch $SETUP_MARKER

#shutdown -r +1 &
exit 0

