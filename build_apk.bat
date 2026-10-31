@echo off
setlocal EnableDelayedExpansion
title Sunday School - APK Build Menu
cd /d "%~dp0"

:MENU
cls
echo ======================================================================
echo             Sunday School - Android APK Build Menu
echo ======================================================================
echo.
echo   [1] Build Release APK (Single universal APK for all devices)
echo   [2] Build Split-per-ABI APKs (Smaller file size for each architecture)
echo   [3] Build Debug APK (Fast build for testing and debugging)
echo   [4] Build All (Release + Split)
echo   [5] Open Output Folder (dist\apk)
echo   [6] Exit
echo.
echo ======================================================================
set /p CHOICE="Enter your choice [1-6]: "

if "%CHOICE%"=="1" goto BUILD_RELEASE
if "%CHOICE%"=="2" goto BUILD_SPLIT
if "%CHOICE%"=="3" goto BUILD_DEBUG
if "%CHOICE%"=="4" goto BUILD_ALL
if "%CHOICE%"=="5" goto OPEN_DIR
if "%CHOICE%"=="6" exit /b 0

echo Invalid choice, please try again.
pause
goto MENU

:BUILD_RELEASE
call "%~dp0build_apk_release.bat"
goto MENU

:BUILD_SPLIT
call "%~dp0build_apk_split.bat"
goto MENU

:BUILD_DEBUG
call "%~dp0build_apk_debug.bat"
goto MENU

:BUILD_ALL
call "%~dp0build_apk_release.bat"
call "%~dp0build_apk_split.bat"
goto MENU

:OPEN_DIR
if not exist "%~dp0dist\apk" mkdir "%~dp0dist\apk"
explorer "%~dp0dist\apk"
goto MENU
