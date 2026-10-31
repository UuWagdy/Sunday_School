@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "SERVER_URL=http://192.168.1.100:5050/"
if exist "server_url.txt" (
    set /p SERVER_URL=<"server_url.txt"
)

start "" wscript.exe //B //Nologo "%~dp0SundaySchoolLauncher.vbs"
