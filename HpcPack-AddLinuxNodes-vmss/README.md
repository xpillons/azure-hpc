# Create a Scaleset of Linux nodes inside an HPC Pack cluster
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fxpillons%2Fazure-hpc%2Fmaster%2FHpcPack-AddLinuxNodes-vmss%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template allows you to create Linux nodes thru a VM Scaleset that will join an existing HPC Pack cluster which can be deployed using this template [Create an HPC cluster](https://azure.microsoft.com/documentation/templates/create-hpc-cluster)

In order to scale your set, you can use the vmss-scale template. Be careful to use the same VM size.
 