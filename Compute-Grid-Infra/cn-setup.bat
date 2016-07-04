set MASTER_NAME=%1

cmdkey /add:%COMPUTERNAME% /user:%COMPUTERNAME%\%2 /pass:%3
cmdkey /add:%COMPUTERNAME% /user:%2 /pass:%3
cmdkey /add:%COMPUTERNAME% /user:.\%2 /pass:%3

cmdkey /list

net use Z: \\%MASTER_NAME%\Data /user:%2 %3 /persistent:yes

runas /savecred /user:%2 "cmd /c Z:\Symphony\provisionScript.bat"
