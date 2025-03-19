# SCCM Management Tools

This directory contains a collection of tools and scripts for managing SCCM (System Center Configuration Manager) agents, particularly focused on uninstallation verification and management.

## Tools Overview

### 1. SCCM Agent Uninstallation Verification Tool
- **File**: `SCCM_Agent_uninstall_verification_bulkversion.ps1`
- **Author**: Navid Rastegani, Triforce
- **Purpose**: Verifies the uninstallation status of SCCM agents across single or multiple computers
- **Features**:
  - GUI-based interface
  - Single computer verification
  - Bulk verification using CSV input
  - Detailed HTML report generation
  - Real-time status checking
  - Comprehensive system analysis

### 2. Uninstallation Script
- **File**: `UninstallSCCM.bat`
- **Purpose**: Batch script for uninstalling SCCM agent

### 3. Verification Script
- **File**: `VerifySCCM.bat`
- **Purpose**: Quick verification of SCCM status

### 4. Intune Enrollment Script
- **File**: `Intune Enrollment.bat`
- **Purpose**: Handles Intune enrollment process

## Usage Instructions

### SCCM Verification Tool

1. **Single Computer Check**:
   - Run the PowerShell script
   - Select option 1
   - Enter the computer name when prompted
   - View the generated HTML report

2. **Bulk Verification**:
   - Prepare a CSV file with a 'ComputerName' column
   - Run the PowerShell script
   - Select option 2
   - Choose your CSV file when prompted
   - View the generated bulk HTML report

### Verification Results Include:
- Computer online status
- SCCM installation status
- Required actions
- Detailed system information
- Service status
- File system checks

## Requirements

- Windows PowerShell 5.1 or later
- Administrative privileges
- Network connectivity to target machines
- Required PowerShell modules:
  - System.Windows.Forms
  - System.Drawing

## Report Generation

The tool generates HTML reports containing:
- Computer Name
- Status
- Required Actions
- Detailed Information
- Timestamp of verification

## Support

For support or questions, contact:
Email: navid.rastegani@triforce.com.au

## Notes

- Ensure you have appropriate permissions before running these tools
- Always verify target systems are accessible before bulk operations
- Reports are saved in the same directory as the scripts
