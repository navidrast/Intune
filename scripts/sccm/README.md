# SCCM to Intune Bulk Migration & Management Tools

## Overview

This repository provides a structured guide for migrating from **System Center Configuration Manager (SCCM)** to **Microsoft Intune**. It includes step-by-step instructions, deployment strategies, and validation scripts to ensure successful migration. Additionally, this repository contains tools to verify SCCM removal and manage post-migration validation.

## 📌 Features

- **Comprehensive SCCM to Intune Migration Guide**
- **Automated SCCM Agent Removal**
- **Validation Scripts for SCCM Removal & Intune Enrollment**
- **Bulk Device Management Support**
- **Real-time Status Reporting via PowerShell**

---

## 🚀 SCCM to Intune Migration Guide

### 🔹 Prerequisites

Before starting the migration, ensure the following requirements are met:

- **Azure AD Connect** is configured and syncing devices.
- Devices must be **Hybrid Azure AD Joined**.
- **Network connectivity** to Intune endpoints is verified.
- **Required Intune licenses** are assigned to users.

### 🔹 Network Connectivity Verification

Ensure the following endpoints are accessible over HTTPS (port 443):

- `enterpriseregistration.windows.net`
- `login.microsoftonline.com`
- `device.login.microsoftonline.com`
- `autologon.microsoftazuread-sso.com`

### 🔹 Implementation Steps

#### 1️⃣ Security Group Setup
- Create a security group named **MDM-Devices**.
- This group controls **Group Policy Object (GPO)** application and deployment during migration.

#### 2️⃣ SCCM Removal Phase
- Deploy a **Startup Script via GPO** to uninstall SCCM.
- The script follows this sequence:
  - **Verify SCCM presence**.
  - **Trigger user notification** before uninstallation.
  - **Execute SCCM uninstallation**.
  - **Schedule a reboot** to finalize changes.

```batch
@echo off
echo Starting SCCM uninstallation check...

REM Check if SCCM is present
if not exist "%windir%\ccmsetup\ccmsetup.exe" (
    echo SCCM not present, marking as uninstalled
    reg add "HKLM\SOFTWARE\Migration" /v "SCCMUninstalled" /t REG_DWORD /d 1 /f
    exit /b 0
)

REM SCCM exists, proceed with uninstallation
echo SCCM found, starting uninstallation...
"%windir%\ccmsetup\ccmsetup.exe" /uninstall
timeout /t 300 /nobreak
shutdown /r /t 300 /c "System will restart in 5 minutes to complete updates." /f
```

#### 3️⃣ SCCM Uninstallation Verification
- Deploy a verification script that ensures SCCM is fully removed.

```batch
@echo off
echo Starting SCCM verification...
reg query "HKLM\SOFTWARE\Migration" /v "SCCMVerified" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SCCM verification already completed. Exiting.
    exit /b 0
)

REM Verify SCCM removal
set SCCM_PRESENT=0
if exist "%windir%\ccmsetup\ccmsetup.exe" set SCCM_PRESENT=1
if exist "%windir%\CCM" set SCCM_PRESENT=1
sc query "ccmexec" >nul 2>&1 && set SCCM_PRESENT=1

if %SCCM_PRESENT% EQU 0 (
    echo SCCM removal verified successfully
    reg add "HKLM\SOFTWARE\Migration" /v "SCCMVerified" /t REG_DWORD /d 1 /f
) else (
    echo SCCM components still present
    exit /b 1
)
```

#### 4️⃣ Intune Enrollment Phase
- Deploy a **GPO-based enrollment** script to:
  - Enable **MDM auto-enrollment**.
  - Configure **registry settings**.
  - Mark the device as **Intune enrolled**.

```batch
@echo off
echo Starting Intune enrollment check...
reg query "HKLM\SOFTWARE\Migration" /v "SCCMVerified" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo SCCM removal not verified. Skipping enrollment.
    exit /b 1
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM" /v "AutoEnrollMDM" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM" /v "UseAADCredentialType" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Migration" /v "IntuneEnrolled" /t REG_DWORD /d 1 /f
```

### 🔹 Verification Steps

#### ✅ SCCM Removal Check
Run the following commands to confirm SCCM is uninstalled:

```cmd
if exist "%windir%\ccmsetup\ccmsetup.exe" echo CCMSetup still present
if exist "%windir%\CCM" echo CCM folder still present
sc query "ccmexec" >nul 2>&1 && echo CCMExec service still present
```

#### ✅ Intune Enrollment Check
Run the following commands to confirm Intune enrollment:

```cmd
dsregcmd /status | findstr "AzureAdJoined"
certutil -store MY | findstr "Microsoft Intune MDM Device CA"
```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

## 🤝 Contributing

Contributions are welcome! Please **fork** the repository and submit a **pull request** with improvements.

## 🛠 Issues

If you encounter any issues, please open an **issue** in the repository.

## 📞 Contact

For inquiries, open a **discussion** or submit a **support request**.

---

This **README.md** provides a structured guide for SCCM to Intune migration and SCCM management tools, ensuring easy adoption for IT administrators and automation professionals. 🚀
