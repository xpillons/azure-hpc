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

# Returns 0 if this node is the management node.
#
is_mgmt()
{
    hostname | grep "$MGMT_HOSTNAME"
    return $?
}

install_ganglia_gmetad()
{
	echo "Installing Ganglia gmetad"
    yum -y install epel-release
	
	#web server
	# curl-devel is commented as it can't be sucessfully downloaded from the endpoints used in Azure VMs.
    yum -y install httpd php php-mysql php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl #curl-devel

	#ganglia server
	yum -y install rrdtool rrdtool-devel ganglia-web ganglia-metad ganglia-gmond ganglia-gmond-python httpd apr-devel zlib-devel libconfuse-devel expat-devel pcre-devel


	GMETAD_CONFIG=/etc/ganglia/gmetad.conf	

	#configure Ganglia server	
	sed -i 's/^data_source.*/data_source "'$MGMT_HOSTNAME' cluster" '$MGMT_HOSTNAME'/g' $GMETAD_CONFIG
	sed -i 's/# gridname "MyGrid".*/gridname "Azure Grid"/g' $GMETAD_CONFIG
	sed -i 's/# setuid off.*/setuid off/g' $GMETAD_CONFIG
	sed -i 's/setuid_username ganglia.*/#setuid_username ganglia/g' $GMETAD_CONFIG
	

	#TODO add authority server	
	#sed -i 's,^#authority .*,authority "http://dnsname/ganglia/",g' $GMETAD_CONFIG
	
	#configure Ganglia web server
	sed -i '0,/Require local/{s/Require local/Require all granted/}' /etc/httpd/conf.d/ganglia.conf
	
	# not sure if this is required
	chown root:root -R /var/lib/ganglia/rrds/
	
	systemctl restart httpd
	systemctl restart gmetad

	systemctl enable httpd
	systemctl enable gmetad	

}

install_gmond()
{
	echo "Installing Ganglia gmond"

    yum -y install epel-release	
	yum -y install ganglia-gmond

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

mkdir -p /var/local
SETUP_MARKER=/var/local/install_ganglia.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

# Disable SELinux
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Disable firewall
systemctl stop firewalld
systemctl disable firewalld

if is_mgmt; then
	install_ganglia_gmetad
fi

install_gmond

# Create marker file so we know we're configured
touch $SETUP_MARKER

