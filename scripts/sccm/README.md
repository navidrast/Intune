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

#### 3️⃣ SCCM Uninstallation Verification
- Deploy a verification script that ensures SCCM is fully removed, checking:
  - CCMSetup.exe
  - CCM folder
  - CCMExec service
  - SCCM registry entries

#### 4️⃣ Intune Enrollment Phase
- Deploy a **GPO-based enrollment** script to:
  - Enable **MDM auto-enrollment**.
  - Configure **registry settings**.
  - Mark the device as **Intune enrolled**.

### 🔹 Deployment Process

The migration follows a **phased deployment approach**:

- **Wave 1: Pilot Phase** – Deploy to 10 test devices.
- **Wave 2: Initial Rollout** – Deploy to 20% of devices.
- **Wave 3: Full Deployment** – Deploy in **batches**.

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

## 🛠 SCCM Management & Validation Scripts

These scripts are used to verify SCCM removal, manage bulk verification, and validate Intune enrollment.

### 🔹 SCCM Verification Tool (GUI & Bulk Support)

#### 1️⃣ Single Computer Verification
- Run `SCCM_Agent_uninstall_verification_bulkversion.ps1`
- Select **option 1**.
- Enter the **computer name**.
- View the **generated HTML report**.

#### 2️⃣ Bulk Verification
- Prepare a **CSV file** with a `ComputerName` column.
- Run the PowerShell script.
- Select **option 2** and choose the CSV file.
- View the **generated bulk HTML report**.

#### 3️⃣ SCCM Removal Script
- **File:** `UninstallSCCM.bat`
- **Purpose:** Batch script to remove SCCM agent from devices.

#### 4️⃣ SCCM Verification Script
- **File:** `VerifySCCM.bat`
- **Purpose:** Ensures SCCM has been completely removed.

#### 5️⃣ Intune Enrollment Script
- **File:** `IntuneEnrollment.bat`
- **Purpose:** Handles device enrollment into **Microsoft Intune**.

### 🔹 Verification Results Include:
✔ Computer online status  
✔ SCCM installation status  
✔ Required actions  
✔ Detailed system information  
✔ Service status  

### 🔹 Requirements
- **Windows PowerShell 5.1** or later.
- **Administrative privileges**.
- **Network connectivity** to target machines.
- **Required PowerShell modules**:
  - `System.Windows.Forms`
  - `System.Drawing`

### 🔹 Report Generation
The tool generates **HTML reports** containing:
- **Computer Name**
- **Status**
- **Required Actions**
- **Detailed Information**
- **Timestamp of verification**

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
