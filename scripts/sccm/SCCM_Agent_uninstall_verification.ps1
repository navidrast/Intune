V# Improved SCCM Uninstallation Verification Script
# This script checks for SCCM components and provides more accurate status information
# Author: Navid Rastegani, Triforce
# Email: navid.rastegani@triforce.com.au
# Created: 19 March 2025

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to get a computer name from the user
function Get-ComputerName {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "SCCM Uninstallation Verification"
    $form.Size = New-Object System.Drawing.Size(400,200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(380,20)
    $label.Text = "Enter the name of the endpoint computer to check:"
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,50)
    $textBox.Size = New-Object System.Drawing.Size(360,20)
    $textBox.Text = "HOSTNAME"  # Default value from your example
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(100,100)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(200,100)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    # Show the form and get the result
    $result = $form.ShowDialog()

    # Return the computer name if OK was clicked
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $computerName = $textBox.Text.Trim()
        
        # Validate computer name is not empty
        if ([string]::IsNullOrWhiteSpace($computerName)) {
            [System.Windows.Forms.MessageBox]::Show("Computer name cannot be empty.", "Error", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error)
            return $null
        }
        
        return $computerName
    } else {
        return $null
    }
}

# Function to verify SCCM status on a remote computer
function Test-SCCMStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    
    Write-Host "Connecting to $ComputerName to verify SCCM uninstallation status..." -ForegroundColor Cyan
    
    try {
        $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Create a results object
            $results = [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                CCMFolderExists = $false
                CCMFolderPath = "C:\Windows\CCM"
                CCMSetupExists = $false
                CCMSetupPath = "C:\Windows\ccmsetup\ccmsetup.exe"
                ServiceExists = $false
                ServiceRunning = $false
                RegistryMarkerExists = $false
                RegistryMarkerValue = $null
                RegistryMarkerPath = "HKLM:\SOFTWARE\FleetPartners\Migration"
                LogFileExists = $false
                LogFileContent = $null
                LogFilePath = "C:\btlogs\sccmuninstall.txt"
                CCMFolderContents = $null
                AdditionalInfo = ""
            }
            
            # Check the CCM folder
            if (Test-Path "C:\Windows\CCM") {
                $results.CCMFolderExists = $true
                # Get folder size and content info
                $folderItems = Get-ChildItem -Path "C:\Windows\CCM" -Recurse -ErrorAction SilentlyContinue
                $folderSize = ($folderItems | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $results.CCMFolderContents = @{
                    "FileCount" = ($folderItems | Where-Object { !$_.PSIsContainer }).Count
                    "FolderCount" = ($folderItems | Where-Object { $_.PSIsContainer }).Count
                    "SizeInBytes" = $folderSize
                    "SizeInMB" = [math]::Round($folderSize / 1MB, 2)
                    "TopLevelItems" = (Get-ChildItem -Path "C:\Windows\CCM" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
                }
            }
            
            # Check ccmsetup.exe
            $results.CCMSetupExists = Test-Path "C:\Windows\ccmsetup\ccmsetup.exe"
            
            # Check CCM service
            $service = Get-Service -Name "CcmExec" -ErrorAction SilentlyContinue
            if ($service -ne $null) {
                $results.ServiceExists = $true
                $results.ServiceRunning = ($service.Status -eq 'Running')
            }
            
            # Check registry marker
            $regPath = "HKLM:\SOFTWARE\FleetPartners\Migration"
            if (Test-Path $regPath) {
                $regKey = Get-ItemProperty -Path $regPath -Name "SCCMUninstalled" -ErrorAction SilentlyContinue
                if ($regKey -ne $null) {
                    $results.RegistryMarkerExists = $true
                    $results.RegistryMarkerValue = $regKey.SCCMUninstalled
                }
            }
            
            # Check log file
            $logPath = "C:\btlogs\sccmuninstall.txt"
            if (Test-Path $logPath) {
                $results.LogFileExists = $true
                $results.LogFileContent = Get-Content -Path $logPath -Raw
            }
            
            # Look for SMS_Agent registry keys (alternative detection method)
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client") {
                $results.AdditionalInfo += "Found SMS Mobile Client registry keys. "
            }
            
            # Look for any SMS services
            $smsServices = Get-Service -Name "SMS*" -ErrorAction SilentlyContinue
            if ($smsServices -ne $null -and $smsServices.Count -gt 0) {
                $results.AdditionalInfo += "Found $($smsServices.Count) SMS-related services. "
            }
            
            return $results
        }
        
        # Analyze the results and determine real SCCM status
        $activeComponentsFound = @()
        $remnantComponentsFound = @()
        
        # Check for active components that indicate SCCM is functional
        if ($result.ServiceExists -and $result.ServiceRunning) {
            $activeComponentsFound += "CcmExec service is running"
        }
        
        if ($result.CCMSetupExists) {
            $activeComponentsFound += "CCMSetup.exe exists"
        }
        
        # Check for remnants that might remain after uninstallation
        if ($result.CCMFolderExists -and -not $result.ServiceExists -and -not $result.CCMSetupExists) {
            $remnantComponentsFound += "CCM folder exists but service and setup file are missing"
        }
        
        if ($result.CCMFolderExists -and $result.CCMFolderContents.FileCount -lt 10) {
            $remnantComponentsFound += "CCM folder exists but contains very few files (likely remnants)"
        }
        
        # Display the results in a user-friendly format
        Write-Host "`nSCCM Status for $($result.ComputerName):" -ForegroundColor Green
        Write-Host "---------------------------------------------" -ForegroundColor Green
        
        if ($activeComponentsFound.Count -gt 0) {
            Write-Host "SCCM IS STILL ACTIVELY INSTALLED" -ForegroundColor Red -BackgroundColor White
            Write-Host "Active components found:" -ForegroundColor Red
            foreach ($component in $activeComponentsFound) {
                Write-Host "- $component" -ForegroundColor Red
            }
        } 
        elseif ($remnantComponentsFound.Count -gt 0) {
            Write-Host "SCCM AGENT HAS BEEN SUCCESSFULLY UNINSTALLED" -ForegroundColor Green -BackgroundColor Black
            Write-Host "Some remnant files remain but can be safely removed:" -ForegroundColor Yellow
            foreach ($component in $remnantComponentsFound) {
                Write-Host "- $component" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "SCCM IS FULLY UNINSTALLED" -ForegroundColor Green -BackgroundColor Black
        }
        
        Write-Host "`nDetailed Component Status:" -ForegroundColor Cyan
        Write-Host "CCM Folder: " -NoNewline
        if ($result.CCMFolderExists) {
            Write-Host "Present" -ForegroundColor Yellow
            Write-Host "  Path: $($result.CCMFolderPath)" -ForegroundColor Gray
            Write-Host "  Size: $($result.CCMFolderContents.SizeInMB) MB" -ForegroundColor Gray
            Write-Host "  Files: $($result.CCMFolderContents.FileCount)" -ForegroundColor Gray
            Write-Host "  Top-level items: $($result.CCMFolderContents.TopLevelItems -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "Not Present" -ForegroundColor Green
        }
        
        Write-Host "CCMSetup.exe: " -NoNewline
        if ($result.CCMSetupExists) {
            Write-Host "Present" -ForegroundColor Red
            Write-Host "  Path: $($result.CCMSetupPath)" -ForegroundColor Gray
        } else {
            Write-Host "Not Present" -ForegroundColor Green
        }
        
        Write-Host "CcmExec Service: " -NoNewline
        if ($result.ServiceExists) {
            if ($result.ServiceRunning) {
                Write-Host "Running" -ForegroundColor Red
            } else {
                Write-Host "Stopped" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Not Present" -ForegroundColor Green
        }
        
        Write-Host "`nUninstallation Tracking:" -ForegroundColor Cyan
        Write-Host "Registry Marker: " -NoNewline
        if ($result.RegistryMarkerExists) {
            if ($result.RegistryMarkerValue -eq 1) {
                Write-Host "Present (Value = 1, indicates uninstallation completed)" -ForegroundColor Green
            } else {
                Write-Host "Present (Value = $($result.RegistryMarkerValue), unexpected value)" -ForegroundColor Yellow
            }
            Write-Host "  Path: $($result.RegistryMarkerPath)" -ForegroundColor Gray
        } else {
            Write-Host "Not Present" -ForegroundColor Yellow
            Write-Host "  Expected Path: $($result.RegistryMarkerPath)" -ForegroundColor Gray
        }
        
        Write-Host "Log File: " -NoNewline
        if ($result.LogFileExists) {
            Write-Host "Present" -ForegroundColor Green
            Write-Host "  Path: $($result.LogFilePath)" -ForegroundColor Gray
            Write-Host "`nLog File Content:" -ForegroundColor Yellow
            Write-Host $result.LogFileContent
        } else {
            Write-Host "Not Present" -ForegroundColor Yellow
            Write-Host "  Expected Path: $($result.LogFilePath)" -ForegroundColor Gray
        }
        
        if (-not [string]::IsNullOrEmpty($result.AdditionalInfo)) {
            Write-Host "`nAdditional Information:" -ForegroundColor Magenta
            Write-Host $result.AdditionalInfo -ForegroundColor White
        }
        
        # Recommendations
        Write-Host "`nRecommendations:" -ForegroundColor Green
        if ($activeComponentsFound.Count -gt 0) {
            Write-Host "- SCCM is still actively installed. Run the uninstallation script." -ForegroundColor White
        } 
        elseif ($remnantComponentsFound.Count -gt 0) {
            Write-Host "- The SCCM agent has been successfully uninstalled." -ForegroundColor White
            Write-Host "- Remaining files and folders can be safely removed." -ForegroundColor White
            if ($result.CCMFolderExists) {
                Write-Host "- To remove CCM folder: RD /S /Q C:\Windows\CCM" -ForegroundColor White
            }
        }
        else {
            Write-Host "- SCCM appears to be fully uninstalled." -ForegroundColor White
            if (-not $result.RegistryMarkerExists) {
                Write-Host "- Registry marker is missing. Create it to prevent future reinstallation attempts." -ForegroundColor White
            }
        }
        
        return $true
    } catch {
        Write-Host "Error connecting to $ComputerName or running verification script:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "`nPlease ensure:" -ForegroundColor Yellow
        Write-Host "- The computer name is correct" -ForegroundColor Yellow
        Write-Host "- The computer is online and accessible on the network" -ForegroundColor Yellow
        Write-Host "- WinRM is enabled on the remote computer" -ForegroundColor Yellow
        Write-Host "- Your credentials have sufficient permissions" -ForegroundColor Yellow
        
        return $false
    }
}

# Display script header with author information
function Show-ScriptHeader {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCCM UNINSTALLATION VERIFICATION TOOL" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  Author: Navid Rastegani" -ForegroundColor White
    Write-Host "  Company: Triforce" -ForegroundColor White
    Write-Host "  Email: navid.rastegani@triforce.com.au" -ForegroundColor White
    Write-Host "  Created: 19 March 2025" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Main script execution
Show-ScriptHeader
$computerName = Get-ComputerName

if ($computerName) {
    Test-SCCMStatus -ComputerName $computerName
    
    # Keep console window open if script was double-clicked
    Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
}
