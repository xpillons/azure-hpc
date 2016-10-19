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
	Write-Host "Register Reverse DNS $shareName"
	$ip = test-connection $shareName -timetolive 2 -count 1 | Select -ExpandProperty IPV4Address 

	Write-Host "$shareName is $ip.IPAddressToString"
	$ip4Value = $ip.IPAddressToString

	&reg add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /v Domain /d southcentralus.cloudapp.azure.com /f
	&reg add HKLM\System\currentcontrolset\services\tcpip\parameters /v SearchList /d southcentralus.cloudapp.azure.com /f

	Write-Host "running netsh"
	&netsh interface ipv4 add dnsserver "Ethernet" address=$ip4Value index=1

	Write-Host "running IPCONFIG"
	&ipconfig /registerdns

	#Import-Module ServerManager
	#Install-WindowsFeature RSAT-DNS-Server

	#$ip = test-connection $env:COMPUTERNAME -timetolive 2 -count 1 | Select -ExpandProperty IPV4Address 

	#$array=$ip.IPAddressToString.Split('.')
	#$name=$array[3]+"."+$array[2]
	#$zone=$array[1]+"."+$array[0]+".in-addr.arpa"

	#Add-DnsServerResourceRecordPtr -ComputerName $shareName -Name $name -ZoneName $zone -PtrDomainName $env:COMPUTERNAME
}

function AddRunCommands($shareName)
{
	$ip = test-connection $shareName -timetolive 2 -count 1 | Select -ExpandProperty IPV4Address 
	$ip4Value = $ip.IPAddressToString

	#$command = "reg add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters /v Domain /d southcentralus.cloudapp.azure.com /f"
	#&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v Domain /f /d $command

	#$command = "reg add HKLM\System\currentcontrolset\services\tcpip\parameters /v SearchList /d southcentralus.cloudapp.azure.com /f"
	#&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v SearchList /f /d $command
	
	$command = "netsh interface ipv4 add dnsserver 'Ethernet' address=$ip4Value index=1"
	&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v adddns /f /d $command
	
	$command = "ipconfig /registerdns"
	&reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v registerdns /f /d $command

}


function RunSetup($shareName, $user, $pwd)
{
	Write-Host "Run setup $shareName $user"
	&net use Z: \\$shareName\Data /user:$user $pwd /persistent:yes 
	&net use  

	Write-Host "Run provisionScript"
	&Z:\symphony\provisionScript.bat 
}

function Main()
{
	# Enable Remote Powershell Execution From The Master Node
	# don't put these lines into the script called by the session because it will close the session :-)
	try {
		Write-Host "Enable-PSRemoting"
		Enable-PSRemoting -Force
		$trustedHosts="@{TrustedHosts=\""$MasterName\""}"
		Write-Host "Config WinRM for $trustedHosts"
		&winrm s winrm/config/client $trustedHosts

		Write-Host "Restart WinRM"
		Restart-Service WinRM -Force
	}
	catch {

	}
	Write-Host "Add commands to run on startup"
	AddRunCommands $MasterName

	# Create local credential to run the installation script
	#Write-Host "Create Local Credentials"
	#$User = ".\$UserName"
	#$PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
	#$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

	#Write-Host "Create New PS Session"
	#$psSession = New-PSSession -Credential $Credential
	#Write-Host "Invoke RunSetup"
	#Invoke-Command -Session $psSession -Script ${function:RunSetup} -ArgumentList $MasterName,$UserName,$Password

	RunSetup $MasterName $UserName $Password

	Write-Host "Create Marker"
    New-Item -Path C:\ -Name customscript.txt -ItemType File
}

RegisterReverseDNS $MasterName

$touch = (Test-Path -Path C:\customscript.txt)

Write-Host "Restart LIM"
&net stop LIM
&net start LIM

Write-Host "set env variables"
&setx PLATCOMMDRV_TCP_RECV_BUFFER_SIZE 1000000 /m
&setx PLATCOMMDRV_TCP_SEND_BUFFER_SIZE 1000000 /m

if ($touch -eq $false)
{
	Write-Host "Marker file doesn't exists"
    Main
}


