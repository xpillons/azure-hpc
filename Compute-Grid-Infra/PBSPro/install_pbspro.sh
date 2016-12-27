#!/bin/bash

set -x

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# != 1 ]; then
    echo "Usage: $0 <MasterHostname>"
    exit 1
fi

# Set user args
MASTER_HOSTNAME=$1

# Returns 0 if this node is the master node.
#
is_master()
{
    hostname | grep "$MASTER_HOSTNAME"
    return $?
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
    yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl postgresql-devel python-devel tcl-devel tk-devel swig expat-devel openssl-devel libXext libXft autoconf automake expat libedit postgresql-server python sendmail tcl tk libical perl-Env perl-Switch
    
    # Required on 7.2 as the libical lib changed
    ln -s /usr/lib64/libical.so.1 /usr/lib64/libical.so.0
    
    wget http://wpc.23a7.iotacdn.net/8023A7/origin2/rl/PBS-Open/CentOS_7.zip
    unzip CentOS_7.zip
    cd CentOS_7
    rpm -ivh --nodeps pbspro-server-14.1.0-13.1.x86_64.rpm
    
    echo 'export PATH=/opt/pbs/bin:$PATH' >> /etc/profile.d/pbs.sh
    echo 'export PATH=/opt/pbs/sbin:$PATH' >> /etc/profile.d/pbs.sh
    
    if is_master; then
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
    else
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

        /etc/init.d/pbs start
    fi

    cd ..
}

SETUP_MARKER=/var/local/install_pbspro.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi


install_pkgs
install_pbspro

# Create marker file so we know we're configured
touch $SETUP_MARKER
