@echo off
setlocal EnableDelayedExpansion
title Sunday School - Build Full System (Flutter + .NET 8 + PostgreSQL + SignalR + Server Manager)
cd /d "%~dp0"

echo ======================================================================
echo   Sunday School - Full Build (Client + .NET 8 SyncServer + Manager)
echo ======================================================================
echo.

echo [1/5] Publishing .NET 8 Sync Server (SundaySchool.SyncServer)...
dotnet publish "SundaySchool.SyncServer\SundaySchool.SyncServer.csproj" -c Release -r win-x64 --self-contained true -o "installer\payload\server\backend"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to publish SundaySchool.SyncServer!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/5] Publishing Server Manager (SundaySchoolServerManager)...
dotnet publish "SundaySchoolServerManager\SundaySchoolServerManager.csproj" -c Release -r win-x64 --self-contained true -o "installer\payload\server-manager"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to publish SundaySchoolServerManager!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/5] Checking Portable PostgreSQL binaries...
if not exist "installer\payload\server\postgresql\bin\postgres.exe" (
    if exist "E:\POWER\Offline_First_Sync\sales_flutter_app\installer\payload\server\postgresql\bin\postgres.exe" (
        echo Copying portable PostgreSQL from E:\POWER\Offline_First_Sync\sales_flutter_app\installer\payload\server\postgresql ...
        robocopy "E:\POWER\Offline_First_Sync\sales_flutter_app\installer\payload\server\postgresql" "installer\payload\server\postgresql" /E /NFL /NDL /NJH /NJS /NC /NS
    ) else (
        echo [ERROR] Portable PostgreSQL is required in installer\payload\server\postgresql.
        exit /b 1
    )
) else (
    echo Portable PostgreSQL is already staged in installer\payload\server\postgresql.
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "installer\validate-server-payload.ps1" -BackendRoot "installer\payload\server\backend" -ManagerRoot "installer\payload\server-manager" -PostgresRoot "installer\payload\server\postgresql"
if errorlevel 1 exit /b 1
for %%A in (x64 x86) do (
    if not exist "installer\downloads\VC_redist.%%A.exe" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; New-Item -ItemType Directory -Force 'installer\downloads' | Out-Null; Invoke-WebRequest -UseBasicParsing 'https://aka.ms/vs/17/release/vc_redist.%%A.exe' -OutFile 'installer\downloads\VC_redist.%%A.exe'; $signature = Get-AuthenticodeSignature 'installer\downloads\VC_redist.%%A.exe'; if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notlike '*Microsoft Corporation*') { throw 'Invalid Microsoft redistributable signature' }"
        if errorlevel 1 exit /b 1
    )
)

echo.
echo [4/5] Building Flutter Windows Release...
echo Please wait, this may take a few minutes...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo.
    echo ======================================================================
    echo [ERROR] Flutter Windows build failed! Check errors above.
    echo ======================================================================
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [5/5] Searching for Inno Setup compiler (ISCC.exe)...
set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"
) else (
    where ISCC.exe >nul 2>&1
    if !ERRORLEVEL! equ 0 set "ISCC=ISCC.exe"
)

if not defined ISCC (
    echo.
    echo ======================================================================
    echo [ERROR] Inno Setup 6 was not found in default installation paths!
    echo Please install Inno Setup 6 to compile the installer.
    echo ======================================================================
    pause
    exit /b 1
)

echo Found Inno Setup: "!ISCC!"
echo Compiling Setup Installer with Inno Setup...
"!ISCC!" "installer\SundaySchoolSetup.iss"
if %ERRORLEVEL% neq 0 (
    echo.
    echo ======================================================================
    echo [ERROR] Inno Setup compilation failed!
    echo ======================================================================
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ======================================================================
echo   [SUCCESS] Full Setup installer built successfully!
echo   Installer file:
echo   %~dp0installer\output\Sunday_School_Setup_v1.0.6.exe
echo ======================================================================
echo.
pause
