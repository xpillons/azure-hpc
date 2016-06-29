set MASTER_NAME=%1

net use Z: \\%MASTER_NAME%\Data

cmd /c Z:\Symphony\provisionScript.bat
