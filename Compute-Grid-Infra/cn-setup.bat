set MASTER_NAME=%1

cmdkey /add:%COMPUTERNAME% /user:%2 /pass:%3

net use Z: \\%MASTER_NAME%\Data /user:%2 %3

runas /savecred /user:%COMPUTERNAME%\%2 "cmd /c Z:\Symphony\provisionScript.bat"
