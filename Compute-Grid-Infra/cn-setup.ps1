param (
    [Parameter(Mandatory=$true)]
    [string]$MasterName,
    [Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [string]$Password
)


function RegisterReverseDNS($shareName)
{
	&reg add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /v Domain /d southcentralus.cloudapp.azure.com /f
	&reg add HKLM\System\currentcontrolset\services\tcpip\parameters /v SearchList /d southcentralus.cloudapp.azure.com /f
	&netsh interface ipv4 add dnsserver "Ethernet" address=10.0.8.4 index=1
	&ipconfig /registerdns

	#Import-Module ServerManager
	#Install-WindowsFeature RSAT-DNS-Server

	#$ip = test-connection $env:COMPUTERNAME -timetolive 2 -count 1 | Select -ExpandProperty IPV4Address 

	#$array=$ip.IPAddressToString.Split('.')
	#$name=$array[3]+"."+$array[2]
	#$zone=$array[1]+"."+$array[0]+".in-addr.arpa"

	#Add-DnsServerResourceRecordPtr -ComputerName $shareName -Name $name -ZoneName $zone -PtrDomainName $env:COMPUTERNAME
}

function AddRunCommands()
{
	#$command = "reg add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /v Domain /d southcentralus.cloudapp.azure.com /f"
	#&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v Domain /f /d $command

	#$command = "reg add HKLM\System\currentcontrolset\services\tcpip\parameters /v SearchList /d southcentralus.cloudapp.azure.com /f"
	#&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v SearchList /f /d $command
	
	$command = "netsh interface ipv4 add dnsserver 'Ethernet' address=10.0.8.4 index=1"
	&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v adddns /f /d $command
	
	$command = "ipconfig /registerdns"
	&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v registerdns /f /d $command

}


function RunSetup($shareName, $user, $pwd)
{

	&net use Z: \\$shareName\Data /user:$user $pwd /persistent:yes | Out-Host
	&net use | Out-Host 

	&Z:\symphony\provisionScript.bat | Out-Host 
}

function Main()
{
	# Enable Remote Powershell Execution From The Master Node
	# don't put these lines into the script called by the session because it will close the session :-)
	Enable-PSRemoting -Force
	$trustedHosts="@{TrustedHosts=\""$MasterName\""}"

	&winrm s winrm/config/client $trustedHosts
	Restart-Service WinRM -Force

	AddRunCommands 

	# Create local credential to run the installation script
	$User = ".\$UserName"
	$PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
	$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

	$psSession = New-PSSession -Credential $Credential
	Invoke-Command -Session $psSession -Script ${function:RunSetup} -ArgumentList $MasterName,$UserName,$Password
    New-Item -Path C:\ -Name customscript.txt -ItemType File
}

RegisterReverseDNS $MasterName

$touch = (Test-Path -Path C:\customscript.txt)

if ($touch -eq $false)
{
    Main
}


