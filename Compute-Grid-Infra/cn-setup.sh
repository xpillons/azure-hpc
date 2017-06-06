#!/bin/bash

# Shares
SHARE_HOME=/share/home
SHARE_SCRATCH=/share/scratch
NFS_ON_MASTER=/data
NFS_MOUNT=/data

# User
HPC_USER=hpcuser
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007

#############################################################################
log()
{
	echo "$1"
}

usage() { echo "Usage: $0 [-m <masterName>] [-s <pbspro>] [-q <queuename>] [-S <beegfs, nfsonmaster>] [-n <ganglia>] [-c <postInstallCommand>]" 1>&2; exit 1; }

while getopts :m:S:s:q:n:c: optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    m)  # master name
		export MASTER_NAME=${OPTARG}
		;;
    S)  # Shared Storage (beegfs, nfsonmaster)
		export SHARED_STORAGE=${OPTARG}
		;;
    s)  # Scheduler (pbspro)
		export SCHEDULER=${OPTARG}
		;;
    n)  # monitoring
		export MONITORING=${OPTARG}
		;;
    c)  # post install command
		export POST_INSTALL_COMMAND=${OPTARG}
		;;
    q)  # queue name
		export QNAME=${OPTARG}
		;;
	*)
		usage
		;;
  esac
done

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

is_ubuntu()
{
	python -mplatform | grep -qi Ubuntu
	return $?
}

mount_nfs()
{
	log "install NFS"

	if is_centos; then
		yum -y install nfs-utils nfs-utils-lib
	elif is_suse; then
		zypper -n install nfs-client
	elif is_ubuntu; then
		apt -qy install nfs-common 
	fi
	
	mkdir -p ${NFS_MOUNT}

	log "mounting NFS on " ${MASTER_NAME}
	showmount -e ${MASTER_NAME}
	mount -t nfs ${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT}
	
	echo "${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT} nfs defaults,nofail  0 0" >> /etc/fstab
}

install_beegfs_client()
{
	bash install_beegfs.sh ${MASTER_NAME} "client"
}

install_ganglia()
{
	bash install_ganglia.sh ${MASTER_NAME} "Cluster" 8649
}

install_pbspro()
{
	bash install_pbspro.sh ${MASTER_NAME} ${QNAME}
}

install_blobxfer()
{
	if is_centos; then
		yum install -y gcc openssl-devel libffi-devel python-devel
		curl https://bootstrap.pypa.io/get-pip.py | python
		pip install --upgrade blobxfer
	fi
}

setup_user()
{
	if is_centos; then
		yum -y install nfs-utils nfs-utils-lib
	elif is_suse; then
		zypper -n install nfs-client
	elif is_ubuntu; then
		apt-get -qy install nfs-common 
	fi

    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_SCRATCH

	echo "$MASTER_NAME:$SHARE_HOME $SHARE_HOME    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab
	mount -a
	mount
   
    groupadd -g $HPC_GID $HPC_GROUP

    # Don't require password for HPC user sudo
    echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

	useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

    chown $HPC_USER:$HPC_GROUP $SHARE_SCRATCH	
}

setup_intel_mpi()
{
	if is_suse; then
		if [ -d "/opt/intelMPI" ]; then
			rpm -v -i --nodeps /opt/intelMPI/intel_mpi_packages/*.rpm
			impi_version=`ls /opt/intel/impi`
			ln -s /opt/intel/impi/${impi_version}/intel64/bin/ /opt/intel/impi/${impi_version}/bin
			ln -s /opt/intel/impi/${impi_version}/lib64/ /opt/intel/impi/${impi_version}/lib
		fi		
	fi
}

mkdir -p /var/local
SETUP_MARKER=/var/local/cn-setup.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

if is_centos; then
	# disable selinux
	sed -i 's/enforcing/disabled/g' /etc/selinux/config
	setenforce permissive
fi

if is_ubuntu; then
	# there is an issue here because apt may be already running the first time the machine is booted
	while true;
	do
		if [[ $(ps -A | grep -c apt)  -ne 1 ]]; then
			echo "apt is running, wait 1m"
		else
			break
		fi
		sleep 1m
	done
fi

setup_user
if [ "$MONITORING" == "ganglia" ]; then
	install_ganglia
fi

if [ "$SCHEDULER" == "pbspro" ]; then
	install_pbspro
fi

if [ "$SHARED_STORAGE" == "beegfs" ]; then
	install_beegfs_client
elif [ "$SHARED_STORAGE" == "nfsonmaster" ]; then
	mount_nfs
fi

setup_intel_mpi
#install_blobxfer

if [ -n "$POST_INSTALL_COMMAND" ]; then
	echo "running $POST_INSTALL_COMMAND"
	eval $POST_INSTALL_COMMAND
fi
# Create marker file so we know we're configured
touch $SETUP_MARKER

shutdown -r +1 &
exit 0
