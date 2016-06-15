param (
    [Parameter(Mandatory=$true)]
    [string]$StorageAccount,
    [Parameter(Mandatory=$true)]
    [string]$StorageKey,
    [Parameter(Mandatory=$true)]
    [string]$UserName
)

&runas /user:$UserName cmdkey /add:$StorageAccount.file.core.windows.net /user:$StorageAccount /pass:$StorageKey

&runas /user:$UserName  net use Z: \\$StorageAccount.file.core.windows.net\lsf
