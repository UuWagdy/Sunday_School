@echo off
setlocal EnableDelayedExpansion
title Sunday School - Build Debug APK
cd /d "%~dp0"

echo ======================================================================
echo           Sunday School - Build Debug APK (Android)
echo ======================================================================
echo.

echo [1/3] Checking Flutter environment...
call flutter --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Building Flutter APK (Debug)...
echo Please wait...
call flutter build apk --debug
if %ERRORLEVEL% neq 0 (
    echo.
    echo ======================================================================
    echo [ERROR] Flutter APK Debug build failed!
    echo ======================================================================
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Staging output APK...
set "OUT_DIR=%~dp0dist\apk"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "SRC_APK=%~dp0build\app\outputs\flutter-apk\app-debug.apk"
if exist "%SRC_APK%" (
    copy /y "%SRC_APK%" "%OUT_DIR%\SundaySchool_Debug.apk" >nul
    echo.
    echo ======================================================================
    echo   [SUCCESS] Debug APK built successfully!
    echo   File: %OUT_DIR%\SundaySchool_Debug.apk
    echo ======================================================================
    echo Opening output folder...
    explorer "%OUT_DIR%"
) else (
    echo [WARNING] app-debug.apk not found at default location.
    echo Check build\app\outputs\flutter-apk\
)

echo.
pause
