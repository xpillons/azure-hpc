# Custom Image deployment at scale

> Please note that with the support of Managed Disks and custom images, these steps are no longer needed. Instead capture an image and provide its resource ID, available in Azure Portal, to the template parameter.

These templates comes in addition to the Grid Infrastructure to allow large scale deployment of custom image thru VM scalesets. There are two main steps when doing this :
* Copy the master image on each storage accounts being used by each VM scalesets
* Provision VM scalesets

Until Managed Disks are available, deploying a custom image thru VMSS has some constraints. The first one being that the image has to be stored in the same storage account than the one used to store OS disks. The second one being that you can have only a single storage account per VMSS. The third is that you are limited to 40 VMs per scaleset to avoid storage throttling (or 20 when using overprovisioning).


## Master image replication
The template **transfer-customimage.json** is taking care of automatically deploying the custom image by executing the following steps :
* Create one storage account per VM scaleset
* Build a transfer VM to stage the master image locally
* Copy the master image in each previously created storage account

The transfer VM doesn't provide a public IP, so to get access to it, you should have a jumpbox inside your VNET.

You have to provide these parameters to the template :
* _uniquePrefix_ : a 8 characters prefix to be used to name your objects.
* _VMSSCount_ : the number of VM Scaleset that will be used (it means the number of storage accounts to create). Default is 1, max is 50
* _xferVMsku_ : instance type for the transfer VM. Default is Standard_DS3_v2
* _RGvnetName_ : the name of the resource group in which the VNET *vnetName* exists
* _vnetName_ : name of the VNET in which the VM will be created. Default is *grid-vnet*
* _subnetName_ : name of the subnet inside *vnetName*. Default is *computesubnet*.
* _adminUsername_ : This is the name of the administrator account to create on the VM
* _sshKeyData_ : The public SSH key to associate with the administrator user
* _imageLocation_ : URL of the master image, in the format of https://accountname.blob.core.windows.net/container/
* _imageBlobName_ : name of the blob containing the master image in the format of dir/subdir/image.vhd
* _storageAccountKey_ : Storage Account key for accessing the master image

[![Click to deploy template on Azure](http://azuredeploy.net/deploybutton.png "Click to deploy template on Azure")](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fxpillons%2Fazure-hpc%2Fmaster%2FCompute-Grid-Infra%2FCustomImage%2Ftransfer-customimage.json)  

### Check your deployment
Once the deployment succeed, each newly created storage account will have a container named *vhds* in which the master image will be located.
A VM named transfeXXXX should also be present. It can be deallocated once finished.


## Provision the compute nodes
Compute nodes are provisioned using VM Scalesets with the **deploy-customimage.json** template, each set can have up to 20 VMs. You will have to provide the number of VM per scalesets and how many sets you want to create. All scalesets will contains the same VM instances.

You have to provide these parameters to the template :
* _uniquePrefix_ : 8 characters prefix to use to name the compute nodes. The naming pattern will be **prefixAABBBBBB** where _AA_ is two digit number of the scaleset and _BBBBBB_ is the 8 hexadecimal value inside the Scaleset
* _VMSSCount_ : the number of VM Scaleset to create. Default is 1, max is 50
* _instanceCount_ : Number of VM instances per Scaleset (20 or less for custom images and overprovisioning). Default is 2, max is 20.
* _computeVMsku_ : Instance type to provision. Default is **Standard_D3_v2**
* _RGvnetName_ : the name of the resource group in which the VNET *vnetName* exists
* _vnetName_ : name of the VNET in which the VM will be created. Default is *grid-vnet*
* _subnetName_ : name of the subnet inside *vnetName*. Default is *computesubnet*.
* _adminUsername_ : This is the name of the administrator account to create on the VM
* _adminPassword_ : This is the password of the administrator account to create on the VM
* _sshKeyData_ : The public SSH key to associate with the administrator user if any
* _imageBlobName_ : Name of the blob containing the image in the format of dir/subdir/image.vhd
* _script_ : URL of the script to download as a post script install, if any. This will allow image customization after deployment.
* _cmdLine_ : Command line to run on the _script_ upon startup

[![Click to deploy template on Azure](http://azuredeploy.net/deploybutton.png "Click to deploy template on Azure")](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fxpillons%2Fazure-hpc%2Fmaster%2FCompute-Grid-Infra%2FCustomImage%2Fdeploy-customimage.json)  

### Check your deployment
After few minutes you should see all VM scalesets deployed.

____
