#!/bin/bash

set -x

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Usage: $0 <MasterHostname> <queueName>"
    exit 1
fi

# Set user args
MASTER_HOSTNAME=$1
QNAME=workq
PBS_MANAGER=hpcuser

if [ -n "$2" ]; then
	#enforce qname to be lowercase
	QNAME="$(echo ${2,,})"
fi

# Returns 0 if this node is the master node.
#
is_master()
{
    hostname | grep "$MASTER_HOSTNAME"
    return $?
}

enable_kernel_update()
{
	# enable kernel update
	sed -i.bak -e '28d' /etc/yum.conf 
	sed -i '28i#exclude=kernel*' /etc/yum.conf 

}
# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release
    yum -y install zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs gcc gcc-c++ nfs-utils rpcbind mdadm wget python-pip
}

# Downloads and installs PBS Pro OSS on the node.
# Starts the PBS Pro control daemon on the master node and
# the mom agent on worker nodes.
#
install_pbspro()
{
    
    wget -O /mnt/CentOS_7.zip  http://wpc.23a7.iotacdn.net/8023A7/origin2/rl/PBS-Open/CentOS_7.zip
    unzip /mnt/CentOS_7.zip -d /mnt
       
    if is_master; then
		enable_kernel_update
		install_pkgs

		yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl postgresql-devel python-devel tcl-devel tk-devel swig expat-devel openssl-devel libXext libXft autoconf automake expat libedit postgresql-server python sendmail tcl tk libical perl-Env perl-Switch
    
		# Required on 7.2 as the libical lib changed
		ln -s /usr/lib64/libical.so.1 /usr/lib64/libical.so.0

	    rpm -ivh --nodeps /mnt/CentOS_7/pbspro-server-14.1.0-13.1.x86_64.rpm

        cat > /etc/pbs.conf << EOF
PBS_SERVER=$MASTER_HOSTNAME
PBS_START_SERVER=1
PBS_START_SCHED=1
PBS_START_COMM=1
PBS_START_MOM=0
PBS_EXEC=/opt/pbs
PBS_HOME=/var/spool/pbs
PBS_CORE_LIMIT=unlimited
PBS_SCP=/bin/scp
EOF
    
        /etc/init.d/pbs start
        
        # Enable job history
        /opt/pbs/bin/qmgr -c "s s job_history_enable = true"
        /opt/pbs/bin/qmgr -c "s s job_history_duration = 336:0:0"

		# add hpcuser as manager
        /opt/pbs/bin/qmgr -c "s s managers = $PBS_MANAGER@*"

    else

		yum install -y hwloc-devel expat-devel tcl-devel expat

	    rpm -ivh --nodeps /mnt/CentOS_7/pbspro-execution-14.1.0-13.1.x86_64.rpm

        cat > /etc/pbs.conf << EOF
PBS_SERVER=$MASTER_HOSTNAME
PBS_START_SERVER=0
PBS_START_SCHED=0
PBS_START_COMM=0
PBS_START_MOM=1
PBS_EXEC=/opt/pbs
PBS_HOME=/var/spool/pbs
PBS_CORE_LIMIT=unlimited
PBS_SCP=/bin/scp
EOF

		echo '$clienthost '$MASTER_HOSTNAME > /var/spool/pbs/mom_priv/config
        /etc/init.d/pbs start

		# setup the self register script
		cp pbs_selfregister.sh /etc/init.d/pbs_selfregister
		chmod +x /etc/init.d/pbs_selfregister
		chown root /etc/init.d/pbs_selfregister
		chkconfig --add pbs_selfregister

		# if queue name is set update the self register script
		if [ -n "$QNAME" ]; then
			sed -i '/qname=/ s/=.*/='$QNAME'/' /etc/init.d/pbs_selfregister
		fi

		# register node
		/etc/init.d/pbs_selfregister start

    fi

    echo 'export PATH=/opt/pbs/bin:$PATH' >> /etc/profile.d/pbs.sh
    echo 'export PATH=/opt/pbs/sbin:$PATH' >> /etc/profile.d/pbs.sh

    cd ..
}

SETUP_MARKER=/var/local/install_pbspro.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi



install_pbspro

# Create marker file so we know we're configured
touch $SETUP_MARKER
