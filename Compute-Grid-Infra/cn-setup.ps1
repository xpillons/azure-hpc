param (
    [Parameter(Mandatory=$true)]
    [string]$MasterName,
    [Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$User = ".\$UserName"
$PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

&net use Z: \\$MasterName\Data /user:$UserName $Password /persistent:yes

Start-Process "C:\Windows\System32\cmd.exe" -WorkingDirectory "C:\" -Credential ($Credential) -ArgumentList " /c"
