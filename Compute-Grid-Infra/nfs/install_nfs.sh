#!/bin/bash

set -x
#set -xeuo pipefail

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

# Shares
NFS_DATA=/data

# User
HPC_USER=hpcuser
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007

is_centos()
{
	python -mplatform | grep -qi CentOS
	return $?
}

is_suse()
{
	python -mplatform | grep -qi Suse
	return $?
}


# Installs all required packages.
#
install_pkgs_centos()
{
	yum -y install nfs-utils nfs-utils-lib
}

install_pkgs_suse()
{
	zypper -n install nfs-client nfs-kernel-server
}

# Partitions all data disks attached to the VM 
#
setup_data_disks()
{
    mountPoint="$1"
    filesystem="$2"
    devices="$3"
    raidDevice="$4"
    createdPartitions=""

    # Loop through and partition disks until not found
    for disk in $devices; do
        fdisk -l /dev/$disk || break
        fdisk /dev/$disk << EOF
n
p
1


p
w
EOF
        createdPartitions="$createdPartitions /dev/${disk}1"
    done
    
    sleep 10

	mkfs -t $filesystem $createdPartitions
	echo "$createdPartitions $mountPoint $filesystem defaults,nofail 0 2" >> /etc/fstab
	
	mount $createdPartitions
}

setup_disks()
{      
    # Dump the current disk config for debugging
    fdisk -l
    
    # Dump the scsi config
    lsscsi
    
    # Get the root/OS disk so we know which device it uses and can ignore it later
    rootDevice=`mount | grep "on / type" | awk '{print $1}' | sed 's/[0-9]//g'`
    
    # Get the TMP disk so we know which device and can ignore it later
    tmpDevice=`mount | grep "on /mnt/resource type" | awk '{print $1}' | sed 's/[0-9]//g'`

    # Get the data disk sizes from fdisk, we ignore the disks above
    dataDiskSize=`fdisk -l | grep '^Disk /dev/' | grep -v $rootDevice | grep -v $tmpDevice | awk '{print $3}' | sort -n -r | tail -1`

	# Compute number of disks
	nbDisks=`fdisk -l | grep '^Disk /dev/' | grep -v $rootDevice | grep -v $tmpDevice | wc -l`
	echo "nbDisks=$nbDisks"
	
	dataDevices="`fdisk -l | grep '^Disk /dev/' | grep $dataDiskSize | awk '{print $2}' | awk -F: '{print $1}' | sort | head -$nbDisks | tr '\n' ' ' | sed 's|/dev/||g'`"

	mkdir -p $NFS_DATA
	setup_data_disks $NFS_DATA "xfs" "$dataDevices" "nfsdata"

    chown $HPC_USER:$HPC_GROUP $NFS_DATA
	
	echo "$NFS_DATA    *(rw,async)" >> /etc/exports
	exportfs
	exportfs -a
	exportfs 
}


SETUP_MARKER=/var/local/install_nfs.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

if is_centos; then
	install_pkgs_centos
elif is_suse; then
	install_pkgs_suse
fi

setup_disks

# Create marker file so we know we're configured
touch $SETUP_MARKER

exit 0
