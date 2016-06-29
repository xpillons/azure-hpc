set MASTER_NAME=%1

net use Z: \\%MASTER_NAME%\Data

Z:\Symphony\provisionScript.bat
