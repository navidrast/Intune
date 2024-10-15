<#
.SYNOPSIS
Gathers Windows AutoPilot information from specified computers.

.DESCRIPTION
This script collects Windows AutoPilot deployment details from one or more computers using CIM.
It can output data to a CSV file or the PowerShell pipeline and optionally add devices to Windows AutoPilot via Intune Graph API.

.PARAMETER ComputerList
Array of computer names to process. Defaults to the local computer if not specified.

.PARAMETER CSVPath
Path to the CSV file for storing the collected data. If not provided, data is output to the pipeline.

.PARAMETER AppendCSV
Switch to append data to an existing CSV file instead of overwriting.

.PARAMETER RemoteCredential
Credentials for connecting to remote computers.

.PARAMETER PartnerFormat
Switch to use Partner Center schema (includes manufacturer and model).

.PARAMETER DeviceGroupTag
Optional group tag for Intune CSV uploads.

.PARAMETER BypassHashCheck
Switch to collect make and model even if hardware hash is available.

.PARAMETER UseIntuneAPI
Switch to add computers to Windows AutoPilot using Intune Graph API.

.EXAMPLE
.\Get-AutoPilotInfo.ps1 -ComputerList "PC01","PC02" -CSVPath ".\AutoPilotDevices.csv"

.NOTES
Version: 1.0
Author: Navid Rastegani
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias("Computers", "Hosts")]
    [string[]] $ComputerList = @($env:COMPUTERNAME),

    [string] $CSVPath,

    [switch] $AppendCSV,

    [PSCredential] $RemoteCredential,

    [switch] $PartnerFormat,

    [string] $DeviceGroupTag,

    [switch] $BypassHashCheck,

    [switch] $UseIntuneAPI
)

function Get-AutoPilotDeviceInfo {
    param (
        [string] $ComputerName,
        [PSCredential] $Credential
    )

    $cimParams = @{
        ComputerName = $ComputerName
        ErrorAction = 'Stop'
    }
    if ($Credential) { $cimParams['Credential'] = $Credential }

    try {
        $cimSession = New-CimSession @cimParams
        $biosInfo = Get-CimInstance -CimSession $cimSession -ClassName Win32_BIOS
        $serialNumber = $biosInfo.SerialNumber

        $hashInfo = Get-CimInstance -CimSession $cimSession -Namespace root/cimv2/mdm/dmmap -ClassName MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -ErrorAction SilentlyContinue
        $hardwareHash = if ($hashInfo -and -not $BypassHashCheck) { $hashInfo.DeviceHardwareData } else { $null }

        if (-not $hardwareHash -or $BypassHashCheck) {
            $csInfo = Get-CimInstance -CimSession $cimSession -ClassName Win32_ComputerSystem
            $manufacturer = $csInfo.Manufacturer.Trim()
            $model = $csInfo.Model.Trim()
        }

        $deviceInfo = [PSCustomObject]@{
            SerialNumber = $serialNumber
            HardwareHash = $hardwareHash
            Manufacturer = $manufacturer
            Model = $model
        }

        Remove-CimSession -CimSession $cimSession
        return $deviceInfo
    }
    catch {
        Write-Error "Failed to retrieve information from $ComputerName : $_"
        return $null
    }
}

function Format-AutoPilotCSV {
    param (
        [Array] $DeviceList,
        [bool] $IsPartnerFormat,
        [string] $GroupTag
    )

    $formattedList = foreach ($device in $DeviceList) {
        $deviceProperties = [ordered]@{
            "Device Serial Number" = $device.SerialNumber
            "Windows Product ID"   = ""
            "Hardware Hash"        = $device.HardwareHash
        }

        if ($IsPartnerFormat) {
            $deviceProperties["Manufacturer name"] = $device.Manufacturer
            $deviceProperties["Device model"] = $device.Model
        }
        elseif ($GroupTag) {
            $deviceProperties["Group Tag"] = $GroupTag
        }

        [PSCustomObject]$deviceProperties
    }

    return $formattedList
}

# Main script logic
$collectedDevices = @()

foreach ($computer in $ComputerList) {
    Write-Verbose "Processing $computer"
    $deviceInfo = Get-AutoPilotDeviceInfo -ComputerName $computer -Credential $RemoteCredential
    if ($deviceInfo) { $collectedDevices += $deviceInfo }
}

if ($UseIntuneAPI) {
    if (-not (Get-Module -Name WindowsAutopilotIntune -ListAvailable)) {
        Write-Host "Installing WindowsAutopilotIntune module..."
        Install-Module WindowsAutopilotIntune -Force -Scope CurrentUser
    }
    Import-Module WindowsAutopilotIntune
    Connect-MSGraph | Out-Null
    Write-Host "Connected to Intune Graph API"

    if (-not $CSVPath) {
        $CSVPath = Join-Path $env:TEMP "AutoPilotDevices_$(Get-Date -Format 'yyyyMMddHHmmss').csv"
    }
}

$formattedDevices = Format-AutoPilotCSV -DeviceList $collectedDevices -IsPartnerFormat $PartnerFormat -GroupTag $DeviceGroupTag

if ($CSVPath) {
    $csvParams = @{
        Path = $CSVPath
        NoTypeInformation = $true
    }
    if ($AppendCSV -and (Test-Path $CSVPath)) {
        $csvParams['Append'] = $true
    }
    $formattedDevices | Export-Csv @csvParams
    Write-Host "Device information exported to $CSVPath"

    if ($UseIntuneAPI) {
        Write-Host "Importing devices to Intune..."
        Import-AutoPilotCSV -CsvFile $CSVPath
    }
}
else {
    $formattedDevices
}