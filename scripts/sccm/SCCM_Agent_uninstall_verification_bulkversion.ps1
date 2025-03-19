# SCCM Uninstallation Verification Tool
# Author: Navid Rastegani, Triforce
# Email: navid.rastegani@triforce.com.au
# Created: 19 March 2025

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to generate an HTML report
function Generate-HTMLReport {
    param (
        [array]$Results,
        [string]$FilePath
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>SCCM Uninstallation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>SCCM Uninstallation Report</h1>
    <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm")</p>
    <table>
        <tr>
            <th>Computer Name</th>
            <th>Status</th>
            <th>Action Required</th>
            <th>Details</th>
        </tr>
"@

    foreach ($result in $Results) {
        $html += @"
        <tr>
            <td>$($result.ComputerName)</td>
            <td>$($result.Status)</td>
            <td>$($result.ActionRequired)</td>
            <td>$($result.Details)</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Out-File -FilePath $FilePath -Encoding utf8
    Write-Host "HTML Report saved: $FilePath" -ForegroundColor Green
}

# Function to verify SCCM status on a remote computer
function Test-SCCMStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 60
    )

    try {
        Write-Host "Checking SCCM status on $ComputerName..." -ForegroundColor Cyan

        # Test if computer is online
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            return [PSCustomObject]@{
                ComputerName = $ComputerName
                IsOnline = $false
                Status = "Offline/Error"
                ActionRequired = "Check connectivity"
                Details = "Computer is offline or unreachable"
            }
        }

        Write-Host "Connecting to $ComputerName..." -ForegroundColor Yellow

        $results = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $obj = [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                IsOnline = $true
                CCMFolderExists = $false
                CCMSetupExists = $false
                ServiceExists = $false
                ServiceRunning = $false
                Status = ""
                ActionRequired = ""
                Details = ""
            }

            # Check folder existence
            if (Test-Path "C:\Windows\CCM") { $obj.CCMFolderExists = $true }
            if (Test-Path "C:\Windows\ccmsetup\ccmsetup.exe") { $obj.CCMSetupExists = $true }

            # Check CCMExec service
            $service = Get-Service -Name "CcmExec" -ErrorAction SilentlyContinue
            if ($service) {
                $obj.ServiceExists = $true
                $obj.ServiceRunning = ($service.Status -eq 'Running')
            }

            # Determine SCCM status
            if ($obj.ServiceExists -or $obj.CCMSetupExists) {
                $obj.Status = "SCCM Installed"
                $obj.ActionRequired = "Run uninstallation script"
            }
            elseif ($obj.CCMFolderExists) {
                $obj.Status = "Uninstalled with Remnants"
                $obj.ActionRequired = "Safe to remove CCM folder"
            }
            else {
                $obj.Status = "Fully Uninstalled"
                $obj.ActionRequired = "No action needed"
            }

            return $obj
        } -ErrorAction Stop
        
        return $results
    }
    catch {
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            IsOnline = $false
            Status = "Offline/Error"
            ActionRequired = "Check connectivity"
            Details = "Error: $($_.Exception.Message)"
        }
    }
}

# Function to check a single computer with a GUI input box
function Check-SingleComputer {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Enter Computer Name"
    $form.Size = New-Object System.Drawing.Size(300, 150)
    $form.StartPosition = "CenterScreen"

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20, 50)
    $textBox.Size = New-Object System.Drawing.Size(240, 20)
    $form.Controls.Add($textBox)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = "OK"
    $button.Location = New-Object System.Drawing.Point(110, 80)
    $button.Add_Click({ $form.Close() })
    $form.Controls.Add($button)

    $form.ShowDialog()
    $computerName = $textBox.Text

    if ([string]::IsNullOrWhiteSpace($computerName)) {
        Write-Host "Computer name cannot be empty!" -ForegroundColor Red
        return
    }

    $timeout = 60
    $result = Test-SCCMStatus -ComputerName $computerName -TimeoutSeconds $timeout

    # Generate HTML Report
    $htmlPath = "$PSScriptRoot\SCCM_Single_Status_Report.html"
    Generate-HTMLReport -Results @($result) -FilePath $htmlPath
    Start-Process $htmlPath
}

# Function to check multiple computers from CSV with GUI selection
function Check-MultipleComputers {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "CSV Files (*.csv)|*.csv"
    $openFileDialog.Title = "Select CSV File with Computer Names"

    if ($openFileDialog.ShowDialog() -ne "OK") {
        Write-Host "No file selected." -ForegroundColor Red
        return
    }

    $csvPath = $openFileDialog.FileName
    $computers = Import-Csv -Path $csvPath
    if (-not ($computers | Get-Member -Name "ComputerName")) {
        Write-Host "CSV file must have a 'ComputerName' column." -ForegroundColor Red
        return
    }

    $timeout = 60
    $results = @()

    foreach ($computer in $computers) {
        $computerName = $computer.ComputerName.Trim()
        if ([string]::IsNullOrWhiteSpace($computerName)) { continue }
        
        Write-Host "Checking SCCM status for $computerName..."
        $results += Test-SCCMStatus -ComputerName $computerName -TimeoutSeconds $timeout
    }

    # Generate HTML Report
    $htmlPath = "$PSScriptRoot\SCCM_Bulk_Status_Report.html"
    Generate-HTMLReport -Results $results -FilePath $htmlPath
    Start-Process $htmlPath
}

# Main menu
Write-Host "SCCM Uninstallation Verification Tool" -ForegroundColor Cyan
Write-Host "1. Check Single Computer"
Write-Host "2. Check Multiple Computers (CSV)"
Write-Host "3. Exit"

$choice = Read-Host "Select an option (1-3)"
switch ($choice) {
    "1" { Check-SingleComputer }
    "2" { Check-MultipleComputers }
    "3" { Write-Host "Exiting..."; exit }
    default { Write-Host "Invalid choice! Exiting..." -ForegroundColor Red; exit }
}