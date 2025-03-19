@echo off
echo Starting SCCM verification...

REM Check if verification already completed
reg query "HKLM\SOFTWARE\YourDomainName\Migration" /v "SCCMVerified" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SCCM verification already completed. Exiting.
    exit /b 0
)

REM Check for uninstallation marker
reg query "HKLM\SOFTWARE\YourDomainName\Migration" /v "SCCMUninstalled" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo SCCM uninstallation not yet attempted. Exiting.
    exit /b 1
)

REM Verify SCCM removal
set SCCM_PRESENT=0

REM Check key components
echo Checking for SCCM components...

if exist "%windir%\ccmsetup\ccmsetup.exe" (
    echo CCMSetup.exe still present
    set SCCM_PRESENT=1
)

if exist "%windir%\CCM" (
    echo CCM folder still present
    set SCCM_PRESENT=1
)

sc query "ccmexec" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo CCMExec service still present
    set SCCM_PRESENT=1
)

sc query "ccmrestart" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo CCMRestart service still present
    set SCCM_PRESENT=1
)

reg query "HKLM\SOFTWARE\Microsoft\CCM" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo CCM registry keys still present
    set SCCM_PRESENT=1
)

reg query "HKLM\SOFTWARE\Microsoft\SMS" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SMS registry keys still present
    set SCCM_PRESENT=1
)

if %SCCM_PRESENT% EQU 0 (
    echo SCCM removal verified successfully
    reg add "HKLM\SOFTWARE\YourDomainName\Migration" /v "SCCMVerified" /t REG_DWORD /d 1 /f
) else (
    echo SCCM components still present
    exit /b 1
)
