param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

(Get-AzureRmVmss -ResourceGroupName $ResourceGroupName) | Foreach-Object {
    $vmssName = $_.Name
    $vms = Get-AzureRmVmssVM -ResourceGroupName $ResourceGroupName -VMScaleSetName $vmssName
    $vms | Foreach-Object {
        $vmIndex = $_.InstanceId
        $vmName = $_.OsProfile.ComputerName
        $ip = (Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -VirtualMachineScaleSetName $vmssName -VirtualMachineIndex $vmIndex).IpConfigurations[0].PrivateIpAddress
        Write-Output "$vmName $ip"
    }
}