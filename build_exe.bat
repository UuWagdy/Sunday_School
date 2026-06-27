@echo off
echo ======================================
echo   Building Betros Bols DB Converter
echo ======================================
echo.

REM Check if PyInstaller is installed
pip show pyinstaller >nul 2>&1
if errorlevel 1 (
    echo Installing PyInstaller...
    pip install pyinstaller
)

REM Check if pyodbc is installed
pip show pyodbc >nul 2>&1
if errorlevel 1 (
    echo Installing pyodbc...
    pip install pyodbc
)

echo.
echo Building EXE...
pyinstaller --onefile --windowed --name ConvertBetrosBols --icon=NONE migrate_access.py

echo.
echo ======================================
if exist "dist\ConvertBetrosBols.exe" (
    echo   Build successful!
    echo   EXE: dist\ConvertBetrosBols.exe
) else (
    echo   Build failed. Check errors above.
)
echo ======================================
pause
