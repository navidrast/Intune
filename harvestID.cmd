@ECHO OFF
set /p drvltr= Enter the drive letter of the USB drive:

PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %drvltr%:\get-WindowsAutoPilotInfo.ps1 -OutputFile %drvltr%:\NNA_AutopilotHash.csv -append
ECHO Device Autopilot hash has been collected,Now get back to work !
