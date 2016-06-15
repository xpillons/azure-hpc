param (
    [Parameter(Mandatory=$true)]
    [string]$StorageAccount,
    [Parameter(Mandatory=$true)]
    [string]$StorageKey
)

&net use Z: \\$StorageAccount.file.core.windows.net\lsf /u:$StorageAccount $StorageKey /persistent:yes

&net use


