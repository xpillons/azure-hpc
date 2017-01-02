# Compute grid in Azure

These templates will build a compute grid made by a single master VMs running the management services, multiple VM Scaleset for deploying compute nodes, and optionally a set of nodes to run [BeeGFS](http://www.beegfs.com/) as a parallel shared file system. Ganglia is always setup by default on all VMs, and [PBS Pro](http://www.pbspro.org/) can optionally be setup for job scheduling.

# VM Infrastructure
The following diagram shows the overall Compute, Storage and Network infrastructure which is going to be provisioning within Azure to support running HPC applications.

![Grid Infrastructure](doc/Infra.PNG)

### Network
A single VNET (__grid-vnet__) is used in which four subnets are created, one for the infrastructure (__infra-subnet__), one for the compute nodes (__compute-subnet__), one for the storage (__storage-subnet__) and one for the VPN Gateway (__GatewaySubnet__). The following addresses range is used :
* __grid-vnet 172.0.0.0/20__ allowing 4091 private IPs from 172.0.0.4 to 172.0.15.255
* __compute-subnet 172.0.0.0/21__ allowing 2043 private IPs from 172.0.0.4 to 172.0.7.255
* __infra-subnet 172.0.8.0/28__ allowing 11 private IPs from 172.0.8.4 to 172.0.8.15
* __gatewaysubnet 172.0.9.0/29__ allowing 3 private IPs from 172.0.9.4 to 172.0.9.7
* __storage-subnet 172.0.10.0/25__ allowing 251 private IPs from 172.0.10.4 to 172.0.10.255

Notice that Azure Network start each range at the x.x.x.4 address, reducing by 3 the number of available IPs in a subnet. So, this must be taken in account when designing your virtual network architecture.
Infiniband is automatically provided when HPC Azure nodes are provisioned.

For DNS, the Azure DNS is used for name resolution on the private IPs.

### Compute
Compute nodes are deployed thru VM Scale sets, made each by up to 100 VMs instances. They are all inside the compute-subnet. For each VM scale set, there can be up to 5 storage accounts to store the OS disks. The number 5 is chosen to not have more than 20 VMs stored into the same account to balance performance and resiliency.

### Storage
Depending on the workload to run on the cluster, there is a need to build a scalable file system. BeeGFS is proposed as an option, each storage node will host the storage and metadata services. Several Premium Disks are configured in RAID0 to store the metadata in addition to the real store.

### Management
A dedicated VM (the master node) is used as a jumbbox, exposing an SSH endpoint, and hosting these services :
* __Ganglia__ metadata service and monitoring web site
* __PBS Pro__ job scheduler
* __BeeGFS__ management services

# Deployment steps
To build the compute grid, three main steps need to be executed :
1. Create the networking infrastructure and the jumpbox
2. Optionally deploy the BeeGFS nodes
3. Provision the compute nodes

_The OS for this solution is CentOS 7.2. All scripts have been tested only for that version._

## Create the networking infrastructure and the jumpbox
The template __deploy-master.json__ will provision the networking infrastructure as well as a master VM exposing an SSH endpoint for remote connection.   

You have to provide these parameters to the template :
* _vmPrefix_ : a 8 characters prefix to be used to name your objects. The master VM will be named as **\[prefix\]master**
* _sharedStorage_ : to specify the shared storage to use. Allowed values are : none, beegfs.
* _scheduler_ : the job scheduler to be setup. Allowed values are : none, pbspro
* _masterImage_ : the OS to be used. Should be CentOS_7.2
* _VMSku_ : This is to specify the instance size of the master VM. For example Standard_DS3_v2
* _adminUsername_ : This is the name of the administrator account to create on the VM
* _adminPassword_ : Password to associate to the administrator account. It is highly encourage to use SSH authentication and passwordless instead.
* _sshKeyData_ : The public SSH key to associate to the administrator user



<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fxpillons%2Fazure-hpc%2Fmaster%2FCompute-Grid-Infra%2Fdeploy-master.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Once the deployment succeed, use the output **masterFQDN** to retrieve the master name. The output **GangliaURI** contains the URI of the Ganglia monitoring page.

## Optionally deploy the BeeGFS nodes

## Provision the compute nodes
