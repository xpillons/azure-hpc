param (
    [Parameter(Mandatory=$true)]
    [string]$MasterName,
    [Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$User = ".\$UserName"
Write-Host $User
$PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

$psSession = New-PSSession -Credential $Credential;  

Invoke-Command -Session $psSession -Script { &net use Z: \\$MasterName\Data /user:$UserName $Password /persistent:yes | Out-Host; &net use | Out-Host; &Z:\symphony\provisionScript.bat | Out-Host  }

