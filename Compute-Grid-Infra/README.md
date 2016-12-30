# Compute grid infrastructure in Azure

These templates will build a compute grid made by a single master VMs running the management services, multiple VM Scaleset for deploying compute nodes, and optionally a set of nodes to run [BeeGFS](http://www.beegfs.com/) as a parallel shared file system. Ganglia is always setup by default on all VMs, and [PBS Pro](http://www.pbspro.org/) can optionally be setup for job scheduling.

# VM infrastructure
The following diagram shows the overall Compute, Storage and Network infrastructure which is going to be provisioning within Azure to support running HPC applications.

![Grid Infrastructure](/doc/Infra.PNG)
