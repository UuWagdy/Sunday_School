#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$taskRuleName = 'ChurchApps-LAN-Sync-5050-5060'
if (Get-NetFirewallRule -Name $taskRuleName -ErrorAction SilentlyContinue) {
    Remove-NetFirewallRule -Name $taskRuleName
}
New-NetFirewallRule -Name $taskRuleName -DisplayName 'Church Apps LAN Sync (5050,5060)' `
    -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5050,5060 `
    -RemoteAddress LocalSubnet -Profile Any | Out-Null
foreach ($taskInfo in @(
    @{ Source = 'E:/Sunday School/SERVER_INFO.txt'; Folder = 'SundaySchool' },
    @{ Source = 'E:/AbonaFlemoon/SERVER_INFO.txt'; Folder = 'AbonaFlemoon' }
)) {
    if (Test-Path -LiteralPath $taskInfo.Source) {
        $taskInfoFolder = Join-Path $env:ProgramData $taskInfo.Folder
        New-Item -ItemType Directory -Path $taskInfoFolder -Force | Out-Null
        Copy-Item -LiteralPath $taskInfo.Source -Destination (Join-Path $taskInfoFolder 'SERVER_INFO.txt') -Force
    }
}
Write-Host 'LAN sync is allowed. Sunday School: port 5050. Church Membership: port 5060.'
Write-Host 'Connect other devices to the same Wi-Fi, then use the server Wi-Fi IPv4 address.'
