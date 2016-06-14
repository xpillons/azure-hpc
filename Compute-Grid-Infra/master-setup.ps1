param (
    [Parameter(Mandatory=$true)]
    [string]$StorageAccount,
    [Parameter(Mandatory=$true)]
    [string]$StorageKey
)

&cmdkey /add:$StorageAccount.file.core.windows.net /user:$StorageAccount /pass:$StorageKey

&net use Z: \\$StorageAccount.file.core.windows.net\lsf
