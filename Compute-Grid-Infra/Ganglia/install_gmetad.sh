#!/bin/bash

set -x
#set -xeuo pipefail

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi
MGMT_HOSTNAME=`hostname`

# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release
	
	#web server
	# curl-devel is commented as it can't be sucessfully downloaded from the endpoints used in Azure VMs.
    yum -y install httpd php php-mysql php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl #curl-devel

	#ganglia server
	yum -y install rrdtool rrdtool-devel ganglia-web ganglia-metad ganglia-gmond ganglia-gmond-python httpd apr-devel zlib-devel libconfuse-devel expat-devel pcre-devel
}

install_ganglia_metad()
{
    systemctl stop firewalld
    systemctl disable firewalld

    # Disable SELinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
	
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

SETUP_MARKER=/var/tmp/install_ganglia.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

install_pkgs
install_ganglia_metad

# Create marker file so we know we're configured
touch $SETUP_MARKER

