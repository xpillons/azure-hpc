# 4 nodes PBS Pro Infiniband Cluster

_This sample needs 68 cores_

The current sample will build a 4 nodes Infiniband cluster with a master node running PBS Pro and Ganglia.
In order to proceed, download locally the **master.param.json** and **nodes.param.json** files, and update them with **your own SSH key**.

Then run these azure CLI 2.0 commands

    az login
    az account set --subscription [subscriptionId]

    az group create -l [location] -n hpc-master
    az group deployment create -g hpc-master --template-uri https://raw.githubusercontent.com/xpillons/azure-hpc/master/Compute-Grid-Infra/deploy-master.json --parameters @master.param.json


After few minutes when succeeded, the master VM is now ready. The ganglia URI will be listed in the output of the command like shown below for a West Europe deployment. The masterFQDN can be used to SSH into the machine.

    "outputs": {
      "gangliaURI": {
        "type": "String",
        "value": "http://[name].westeurope.cloudapp.azure.com/ganglia"
      },
      "masterFQDN": {
        "type": "String",
        "value": "[name].westeurope.cloudapp.azure.com"
      }      


To deploy the compute nodes, run these azure CLI 2.0 commands

    az group create -l [location] -n hpc-nodes
    az group deployment create -g hpc-nodes --template-uri https://raw.githubusercontent.com/xpillons/azure-hpc/master/Compute-Grid-Infra/deploy-nodes.json --parameters @nodes.param.json
