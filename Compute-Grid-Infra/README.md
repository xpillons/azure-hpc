# Compute grid infrastructure
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fxpillons%2Fazure-hpc%2Fmaster%2FCompute-Grid-Infra%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template will build a compute grid made by a single jumpbox VMs and multiple VM Scaleset. The jumpbox have its own subnet and all scalesets are inside a global subnet. Accessing the jumpbox can be done thru SSH and its public address
