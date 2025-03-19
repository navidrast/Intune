@echo off
echo Starting Intune enrollment check...
REM Check if SCCM is verified as removed
reg query "HKLM\SOFTWARE\FleetPartners\Migration" /v
"SCCMVerified" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
echo SCCM removal not verified. Skipping enrollment.
exit /b 1
)
REM Check if already enrolled
reg query "HKLM\SOFTWARE\FleetPartners\Migration" /v
"IntuneEnrolled" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
echo Intune enrollment already attempted. Exiting.
exit /b 0
)
REM Configure MDM settings
reg add
"HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"
/v "AutoEnrollMDM" /t REG_DWORD /d 1 /f
reg add
"HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"
/v "UseAADCredentialType" /t REG_DWORD /d 1 /f
REM Mark enrollment configured
reg add "HKLM\SOFTWARE\FleetPartners\Mi