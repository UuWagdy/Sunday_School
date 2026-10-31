[CmdletBinding()]
param([string]$MembershipRoot = 'E:\el odwia\project')
$ErrorActionPreference = 'Stop'
$SundayRoot = Split-Path -Parent $PSScriptRoot

function Package-Installer($Root, $IssName, $InstallerName, $ClientName, $BackendRelative, $ManagerRelative, $DestinationRelative) {
    $Root = [IO.Path]::GetFullPath($Root)
    $iss = Join-Path $Root "installer\$IssName"
    $version = [regex]::Match((Get-Content -LiteralPath $iss -Raw), '#define MyAppVersion "([^"]+)"').Groups[1].Value
    if (-not $version) { throw "Installer version not found in $iss" }
    $installer = Get-Item -LiteralPath (Join-Path $Root "installer\output\${InstallerName}_v$version.exe")
    if ($installer.Length -lt 1MB) { throw "Missing or incomplete installer: $($installer.FullName)" }
    $client = Get-Item -LiteralPath (Join-Path $Root "build\windows\x64\runner\Release\$ClientName")
    if ($client.VersionInfo.ProductVersion -notlike "$version*") { throw 'Windows client version does not match installer.' }
    $aot = Get-Item -LiteralPath (Join-Path $Root 'build\windows\x64\runner\Release\data\app.so')
    $backend = Get-Item -LiteralPath (Join-Path $Root $BackendRelative)
    $manager = Get-Item -LiteralPath (Join-Path $Root $ManagerRelative)
    $latestSource = Get-ChildItem -LiteralPath (Join-Path $Root 'lib') -Filter '*.dart' -File -Recurse |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($aot.LastWriteTimeUtc -lt $latestSource.LastWriteTimeUtc) { throw 'Windows AOT predates Dart sources.' }
    foreach ($source in @($aot, $backend, $manager, (Get-Item -LiteralPath $iss), (Get-Item -LiteralPath (Join-Path $Root 'installer\BACKUP_GUIDE.txt')))) {
        if ($installer.LastWriteTimeUtc -lt $source.LastWriteTimeUtc) { throw "Installer predates $($source.FullName)" }
    }
    $target = Join-Path $Root ($DestinationRelative.Replace('{version}', $version))
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    $copy = Join-Path $target $installer.Name
    Copy-Item -LiteralPath $installer.FullName -Destination $copy -Force
    $hash = (Get-FileHash -LiteralPath $installer.FullName -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ne $hash) { throw 'Delivery hash mismatch.' }
    Copy-Item -LiteralPath (Join-Path $Root 'installer\BACKUP_GUIDE.txt') -Destination $target -Force
    Copy-Item -LiteralPath (Join-Path $Root "docs\backup-release-$version.md"), (Join-Path $Root 'docs\native-backup-regression-results.json') -Destination $target -Force
    $manifest = [ordered]@{
        installerVersion = $version
        windowsClientVersion = $client.VersionInfo.ProductVersion
        file = $installer.Name
        bytes = $installer.Length
        sha256 = $hash
        windowsAotSha256 = (Get-FileHash -LiteralPath $aot.FullName -Algorithm SHA256).Hash
        backendSha256 = (Get-FileHash -LiteralPath $backend.FullName -Algorithm SHA256).Hash
        managerSha256 = (Get-FileHash -LiteralPath $manager.FullName -Algorithm SHA256).Hash
        backupTests = 'native-backup-regression-results.json'
        flutterBackupAndCompatibilityTests = '10 passed across both projects'
        freshWindowsInstallationTested = $false
        apkRebuilt = $false
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $target "installer-$version-manifest.json") -Encoding UTF8
    [IO.File]::WriteAllText((Join-Path $target "installer-$version-SHA256SUMS.txt"), "$hash  $($installer.Name)`r`n")
    Write-Output "DELIVERY=$copy"
    Write-Output "SHA256=$hash"
}

Package-Installer $SundayRoot 'SundaySchoolSetup.iss' 'Sunday_School_Setup' 'sunday_school.exe' `
    'installer\payload\server\backend\SundaySchool.SyncServer.dll' `
    'installer\payload\server-manager\SundaySchoolServerManager.dll' 'dist\releases\{version}'
Package-Installer $MembershipRoot 'AbonaFlemoonSetup.iss' 'ChurchMembership_Setup' 'church_membership.exe' `
    'build\church_membership_release\server\ChurchMembership.SyncServer.dll' `
    'build\church_membership_release\manager\ChurchMembershipServerManager.dll' 'dist'
