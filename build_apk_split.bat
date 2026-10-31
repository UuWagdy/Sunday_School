@echo off
setlocal EnableDelayedExpansion
title Sunday School - Build Split-per-ABI APKs
cd /d "%~dp0"

echo ======================================================================
echo    Sunday School - Build Split-per-ABI APKs (Smaller file size)
echo ======================================================================
echo.

echo [1/3] Checking Flutter environment...
call flutter --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Building Flutter APKs (Split per ABI)...
echo Please wait, this may take a few minutes...
call flutter build apk --split-per-abi
if %ERRORLEVEL% neq 0 (
    echo.
    echo ======================================================================
    echo [ERROR] Flutter APK Split build failed!
    echo ======================================================================
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Staging output APKs...
set "OUT_DIR=%~dp0dist\apk\split"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "SRC_DIR=%~dp0build\app\outputs\flutter-apk"
if exist "%SRC_DIR%\app-armeabi-v7a-release.apk" (
    copy /y "%SRC_DIR%\app-armeabi-v7a-release.apk" "%OUT_DIR%\SundaySchool_arm32.apk" >nul
    copy /y "%SRC_DIR%\app-arm64-v8a-release.apk" "%OUT_DIR%\SundaySchool_arm64.apk" >nul
    if exist "%SRC_DIR%\app-x86_64-release.apk" copy /y "%SRC_DIR%\app-x86_64-release.apk" "%OUT_DIR%\SundaySchool_x86_64.apk" >nul
    echo.
    echo ======================================================================
    echo   [SUCCESS] Split APKs built successfully!
    echo   Output Folder: %OUT_DIR%
    echo   - SundaySchool_arm64.apk (For modern phones 64-bit)
    echo   - SundaySchool_arm32.apk (For older phones 32-bit)
    echo ======================================================================
    echo Opening output folder...
    explorer "%OUT_DIR%"
) else (
    echo [WARNING] Split APKs not found at default location.
    echo Check build\app\outputs\flutter-apk\
)

echo.
pause
