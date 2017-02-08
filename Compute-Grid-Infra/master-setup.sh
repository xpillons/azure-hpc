#!/bin/bash

#############################################################################
log()
{
	echo "$1"
}

while getopts :a:k:u:t:p optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    a)  # storage account
		export AZURE_STORAGE_ACCOUNT=${OPTARG}
		;;
    k)  # storage key
		export AZURE_STORAGE_ACCESS_KEY=${OPTARG}
		;;
  esac
done

# Shares
SHARE_HOME=/share/home
SHARE_SCRATCH=/share/scratch
SHARE_APPS=/share/apps

# User
HPC_USER=hpcuser
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007

MASTER_NAME=`hostname`

setup_disks()
{
    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_SCRATCH
	mkdir -p $SHARE_APPS

	chown $HPC_USER:$HPC_GROUP $SHARE_APPS
}

setup_user()
{
    # disable selinux
    sed -i 's/enforcing/disabled/g' /etc/selinux/config
    setenforce permissive
    
    groupadd -g $HPC_GID $HPC_GROUP

    # Don't require password for HPC user sudo
    echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers
   
	useradd -c "HPC User" -g $HPC_GROUP -m -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

	mkdir -p $SHARE_HOME/$HPC_USER/.ssh
	
	# Configure public key auth for the HPC user
	ssh-keygen -t rsa -f $SHARE_HOME/$HPC_USER/.ssh/id_rsa -q -P ""
	cat $SHARE_HOME/$HPC_USER/.ssh/id_rsa.pub >> $SHARE_HOME/$HPC_USER/.ssh/authorized_keys

	echo "Host *" > $SHARE_HOME/$HPC_USER/.ssh/config
	echo "    StrictHostKeyChecking no" >> $SHARE_HOME/$HPC_USER/.ssh/config
	echo "    UserKnownHostsFile /dev/null" >> $SHARE_HOME/$HPC_USER/.ssh/config
	echo "    PasswordAuthentication no" >> $SHARE_HOME/$HPC_USER/.ssh/config

	# Fix .ssh folder ownership
	chown -R $HPC_USER:$HPC_GROUP $SHARE_HOME/$HPC_USER

	# Fix permissions
	chmod 700 $SHARE_HOME/$HPC_USER/.ssh
	chmod 644 $SHARE_HOME/$HPC_USER/.ssh/config
	chmod 644 $SHARE_HOME/$HPC_USER/.ssh/authorized_keys
	chmod 600 $SHARE_HOME/$HPC_USER/.ssh/id_rsa
	chmod 644 $SHARE_HOME/$HPC_USER/.ssh/id_rsa.pub
	
	chown $HPC_USER:$HPC_GROUP $SHARE_SCRATCH
}

mount_nfs()
{
	log "install NFS"

	yum -y install nfs-utils nfs-utils-lib

    echo "$SHARE_HOME    *(rw,async)" >> /etc/exports
    systemctl enable rpcbind || echo "Already enabled"
    systemctl enable nfs-server || echo "Already enabled"
    systemctl start rpcbind || echo "Already enabled"
    systemctl start nfs-server || echo "Already enabled"
		
}

######################################################################
install_azure_cli()
{
	curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
	yum -y install nodejs

	[[ -z "$HOME" || ! -d "$HOME" ]] && { echo 'fixing $HOME'; HOME=/root; } 
	export HOME
	
	npm install -g azure-cli
	azure telemetry --disable
}

######################################################################
install_azure_files()
{
	log "install samba and cifs utils"
	yum -y install samba-client samba-common cifs-utils
	mkdir /mnt/azure
	
	#log "create azure share"
	#azure storage share create --share lsf #-a $SA_NAME -k $SA_KEY
	
	log "mount share"
	mount -t cifs //$AZURE_STORAGE_ACCOUNT.file.core.windows.net/lsf /mnt/azure -o vers=3.0,username=$AZURE_STORAGE_ACCOUNT,password=''${AZURE_STORAGE_ACCESS_KEY}'',dir_mode=0777,file_mode=0777
	echo //$AZURE_STORAGE_ACCOUNT.file.core.windows.net/lsf /mnt/azure cifs vers=3.0,username=$AZURE_STORAGE_ACCOUNT,password=''${AZURE_STORAGE_ACCESS_KEY}'',dir_mode=0777,file_mode=0777 >> /etc/fstab
	
}

install_beegfs()
{
	yum -y install wget
    wget -O install_beegfs_mgmt.sh https://raw.githubusercontent.com/xpillons/azure-hpc/master/Compute-Grid-Infra/BeeGFS/install_beegfs_mgmt.sh
    wget -O install_beegfs_client.sh https://raw.githubusercontent.com/xpillons/azure-hpc/master/Compute-Grid-Infra/BeeGFS/install_beegfs_client.sh

	bash install_beegfs_mgmt.sh ${MASTER_NAME}
	bash install_beegfs_client.sh ${MASTER_NAME}
}

install_ganglia()
{
	yum -y install wget
    wget -O install_gmond.sh https://raw.githubusercontent.com/xpillons/azure-hpc/master/Compute-Grid-Infra/Ganglia/install_gmond.sh
    wget -O install_gmetad.sh https://raw.githubusercontent.com/xpillons/azure-hpc/master/Compute-Grid-Infra/Ganglia/install_gmetad.sh
	bash install_gmetad.sh
	bash install_gmond.sh ${MASTER_NAME} "Master" 8649
}

SETUP_MARKER=/var/tmp/master-setup.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

#install_azure_cli
#install_azure_files
setup_disks
mount_nfs
setup_user
#install_ganglia
#install_beegfs

# Create marker file so we know we're configured
touch $SETUP_MARKER

shutdown -r +1 &
exit 0
