@echo off
setlocal
chcp 65001 >nul
title Build Center - Sunday School LAN Client Installer
cd /d "%~dp0"

echo ===================================================
echo [Build Center] Building Sunday School LAN Client Setup
echo (Windows 7 / 8 / 10 / 11 Lightweight Shortcut Installer)
echo ===================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0_tools\build.ps1" -Target sunday-client-installer
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed with error code %errorlevel%.
    pause
    exit /b %errorlevel%
)

echo.
echo [SUCCESS] Client installer built and published to Output directory.
