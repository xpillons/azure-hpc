param (
    [Parameter(Mandatory=$true)]
    [string]$MasterName,
    [Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [string]$Password
)


function RunSetup($shareName, $user, $pwd)
{
	&net use Z: \\$shareName\Data /user:$user $pwd /persistent:yes | Out-Host
	&net use | Out-Host 
	&Z:\symphony\provisionScript.bat | Out-Host 
}


# Enable Remote Powershell Execution From The Master Node
# don't put these lines into the script called by the session because it will close the session :-)
Enable-PSRemoting -Force
$trustedHosts="@{TrustedHosts=\""$MasterName\""}"

&winrm s winrm/config/client $trustedHosts
Restart-Service WinRM -Force


# Create local credential to run the installation script
$User = ".\$UserName"
$PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

$psSession = New-PSSession -Credential $Credential;  
Invoke-Command -Session $psSession -Script ${function:RunSetup} -ArgumentList $MasterName,$UserName,$Password

Invoke-Command -Session $psSession -FilePath Z:\symphony\createReversePtr.ps1 

