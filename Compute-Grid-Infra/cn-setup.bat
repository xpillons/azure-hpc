set MASTER_NAME=%1

net use Z: \\%MASTER_NAME%\Data /user:%2 %3

cmd /c Z:\Symphony\provisionScript.bat
