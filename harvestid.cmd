@echo off
setlocal enabledelayedexpansion

:input_drive
cls
set "driveLetter="
set /p "driveLetter=Please specify the USB drive letter: "

if not defined driveLetter (
    echo Drive letter cannot be empty. Please try again.
    goto input_drive
)

set "driveLetter=!driveLetter:~0,1!"
if not exist !driveLetter!:\ (
    echo The drive !driveLetter!:\ does not exist. Please try again.
    pause
    goto input_drive
)

set "scriptPath=!driveLetter!:\CollectAutoPilotInfo.ps1"
set "outputPath=!driveLetter!:\AutoPilotHash_!computername!.csv"

if not exist "!scriptPath!" (
    echo Error: AutoPilot script not found at !scriptPath!
    echo Please ensure the script is present on the USB drive.
    pause
    exit /b 1
)

echo Collecting AutoPilot hash information...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '!scriptPath!' -OutputFile '!outputPath!' -Append"

if %errorlevel% neq 0 (
    echo An error occurred while collecting the AutoPilot hash.
    echo Please check the USB drive and try again.
) else (
    echo AutoPilot hash collection completed successfully.
    echo Results saved to: !outputPath!
)

echo.
echo Press any key to exit...
pause >nul
exit /b 0