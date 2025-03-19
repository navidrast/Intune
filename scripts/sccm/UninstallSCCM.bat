@echo off
echo Starting SCCM uninstallation check... > C:\btlogs\sccmuninstall.txt

REM Total process timing:
REM - 5 minutes: Initial uninstallation
REM - 15 minutes: Required sync time
REM - 5 minutes: Final reboot warning

REM Check for existing uninstallation marker
reg query "HKLM\SOFTWARE\YourDomainName\Migration" /v "SCCMUninstalled" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SCCM uninstallation already attempted. Exiting. >> C:\btlogs\sccmuninstall.txt
    exit /b 0
)

REM Check if SCCM is present
if not exist "%windir%\ccmsetup\ccmsetup.exe" (
    echo SCCM not present, marking as uninstalled >> C:\btlogs\sccmuninstall.txt
    reg add "HKLM\SOFTWARE\YourDomainName\Migration" /v "SCCMUninstalled" /t REG_DWORD /d 1 /f
    exit /b 0
)

REM SCCM exists, proceed with uninstallation
echo SCCM found, starting uninstallation... >> C:\btlogs\sccmuninstall.txt

REM Notify user of pending work
msg * /time:0 "Your device requires important updates. Please save your work. The system will restart in 20 minutes."
echo User notification displayed >> C:\btlogs\sccmuninstall.txt

REM Uninstall SCCM
"%windir%\ccmsetup\ccmsetup.exe" /uninstall
echo Uninstall command executed >> C:\btlogs\sccmuninstall.txt

REM Wait for uninstallation to complete (5 minutes)
echo Waiting for uninstallation to complete... >> C:\btlogs\sccmuninstall.txt
timeout /t 300 /nobreak

REM Allow 15 minutes for sync
echo Waiting 15 minutes for sync to complete... >> C:\btlogs\sccmuninstall.txt
timeout /t 900 /nobreak

REM Create uninstallation marker
reg add "HKLM\SOFTWARE\YourDomainName\Migration" /v "SCCMUninstalled" /t REG_DWORD /d 1 /f
echo Created uninstallation registry marker >> C:\btlogs\sccmuninstall.txt

REM Schedule reboot after sync
shutdown /r /t 300 /c "System will restart in 5 minutes to complete updates. Please save your work." /f
echo Scheduled reboot in 5 minutes >> C:\btlogs\sccmuninstall.txt
