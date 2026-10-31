[CmdletBinding()]
param(
    [string]$InstallRoot,
    [string]$DataRoot
)

$ErrorActionPreference = 'Stop'

# Repair updates the machine-wide firewall and automatic startup task. The Start
# menu shortcut normally runs as the signed-in standard user, so elevate before
# stopping anything or copying data.
$repairIdentity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $repairIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $repairArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) { $repairArguments += " -InstallRoot `"$InstallRoot`"" }
    if (-not [string]::IsNullOrWhiteSpace($DataRoot)) { $repairArguments += " -DataRoot `"$DataRoot`"" }
    $repairProcess = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList $repairArguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
    exit $repairProcess.ExitCode
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $InstallRoot 'SundaySchool_ServerData'
}

Write-Host 'Stopping Sunday School Server Manager...' -ForegroundColor Cyan
& taskkill.exe /F /IM 'SundaySchoolServerManager.exe' /T 2>&1 | Out-Null
& taskkill.exe /F /IM 'SundaySchool.SyncServer.exe' /T 2>&1 | Out-Null

$backupRoot = Join-Path $InstallRoot 'SundaySchool_ServerBackups'
$backupPath = Join-Path $backupRoot "repair-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (Test-Path -LiteralPath $DataRoot) {
    New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
    & robocopy.exe $DataRoot $backupPath /E /COPY:DAT /R:2 /W:1 /NP /NFL /NDL 2>&1 | Out-Null
}

$installScript = Join-Path $InstallRoot 'Server\installer\install-server.ps1'
if (Test-Path -LiteralPath $installScript -PathType Leaf) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript -InstallRoot $InstallRoot -DataRoot $DataRoot
    if ($LASTEXITCODE -ne 0) { throw 'Server preparation failed. See SundaySchool_ServerData\logs\install-server.log.' }
}

$managerExe = Join-Path $InstallRoot 'ServerManager\SundaySchoolServerManager.exe'
if (Test-Path -LiteralPath $managerExe -PathType Leaf) {
    Start-Process -FilePath $managerExe -ArgumentList @('--background', '--install-root', "`"$InstallRoot`"") -WorkingDirectory (Split-Path -Parent $managerExe) -WindowStyle Hidden
}

Write-Host 'Sunday School Server repaired and restarted successfully.' -ForegroundColor Green
