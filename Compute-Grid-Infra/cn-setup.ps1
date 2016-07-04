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

$User = ".\$UserName"
Write-Host $User
$PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

$psSession = New-PSSession -Credential $Credential;  

# Enable Remote Powershell Execution From The Master Node
Enable-PSRemoting -Force
&winrm s winrm/config/client '@{TrustedHosts=\"symmaster\"}'
Restart-Service WinRM -Force


Invoke-Command -Session $psSession -Script ${function:RunSetup} -ArgumentList $MasterName,$UserName,$Password

