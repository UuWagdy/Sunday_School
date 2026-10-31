[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallRoot,
    [switch]$PreserveData
)

$ErrorActionPreference = 'SilentlyContinue'

Unregister-ScheduledTask -TaskName 'Sunday School Server Manager' -Confirm:$false -ErrorAction SilentlyContinue

& taskkill.exe /F /IM 'SundaySchoolServerManager.exe' /T 2>&1 | Out-Null
& taskkill.exe /F /IM 'SundaySchool.SyncServer.exe' /T 2>&1 | Out-Null
Get-Process -Name 'sunday_school','SundaySchoolServerManager','SundaySchool.SyncServer' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

& netsh.exe advfirewall firewall delete rule name='Sunday School Sync Server' 2>&1 | Out-Null

if (-not $PreserveData) {
    $serverData = Join-Path $InstallRoot 'SundaySchool_ServerData'
    if (Test-Path -LiteralPath $serverData) {
        Remove-Item -LiteralPath $serverData -Recurse -Force -ErrorAction SilentlyContinue
    }
}

exit 0
