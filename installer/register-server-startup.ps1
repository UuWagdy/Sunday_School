[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallRoot,
    [string]$TaskName = 'Sunday School Server Manager'
)

$ErrorActionPreference = 'Stop'
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
$managerRoot = Join-Path $InstallRoot 'ServerManager'
$managerExe = Join-Path $managerRoot 'SundaySchoolServerManager.exe'
if (-not (Test-Path -LiteralPath $managerExe -PathType Leaf)) {
    throw "Server Manager is missing: $managerExe"
}

# A group principal runs in the interactive session of the user logging on,
# including a standard user when setup was elevated with another admin account.
# No password, elevation prompt, or network connection is needed at logon.
$action = New-ScheduledTaskAction -Execute $managerExe `
    -Argument "--background --install-root `"$InstallRoot`"" -WorkingDirectory $managerRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn
$trigger.Delay = 'PT15S'
$principal = New-ScheduledTaskPrincipal -GroupId 'S-1-5-32-545' -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings `
    -Description 'Start Sunday School PostgreSQL and sync server in the notification area at Windows sign-in.' `
    -Force | Out-Null

# Retire the old shortcut only after registration succeeds. Startup shortcuts
# can be disabled independently by Windows and were not restored by repair.
$legacyShortcut = Join-Path ([Environment]::GetFolderPath('CommonStartup')) 'Sunday School Server Manager.lnk'
if (Test-Path -LiteralPath $legacyShortcut -PathType Leaf) {
    Remove-Item -LiteralPath $legacyShortcut -Force
}
Write-Host 'Server Manager automatic startup registered successfully.'
