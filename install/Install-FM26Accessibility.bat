@echo off
:: FM26 Accessibility Mod Installer Launcher
:: Double-click this file to run the installer

:: Change to the directory where this batch file is located
cd /d "%~dp0"

echo ============================================
echo   FM26 Accessibility Mod Installer
echo ============================================
echo.
echo Launching installer...
echo.

:: Run the PowerShell installer script with bypass execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-FM26Accessibility.ps1"

:: If PowerShell failed, show a message
if %ERRORLEVEL% neq 0 (
    echo.
    echo Installation encountered an issue. See messages above.
    echo.
)

:: Keep the window open so the user can read the output
pause
