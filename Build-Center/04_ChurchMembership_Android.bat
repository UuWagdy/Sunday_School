@echo off
setlocal DisableDelayedExpansion
chcp 65001 >nul
title Build Center - membership-android
set "plan_switch="
if /I "%~1"=="--plan" set "plan_switch=-PlanOnly"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0_tools\build.ps1" -Target membership-android %plan_switch%
set "build_exit=%ERRORLEVEL%"
if not "%build_exit%"=="0" echo [ERROR] Build failed. See the message above and the Logs folder.
if "%build_exit%"=="0" echo [OK] Build Center finished. Output folder: "%~dp0Output"
if /I "%~1"=="--plan" goto done
if /I "%~1"=="--no-pause" goto done
pause
:done
exit /b %build_exit%
