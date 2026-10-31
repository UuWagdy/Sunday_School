function Get-TargetJobs([string]$Target) {
    switch ($Target) {
        'sunday-installer'     { return @('sunday-installer') }
        'sunday-web-installer' { return @('sunday-web-installer') }
        'sunday-android'       { return @('sunday-android') }
        'membership-installer' { return @('membership-installer') }
        'membership-android'   { return @('membership-android') }
        'sunday-all'           { return @('sunday-installer', 'sunday-web-installer', 'sunday-android') }
        'membership-all'       { return @('membership-installer', 'membership-android') }
        'everything'           { return @('sunday-installer', 'sunday-web-installer', 'sunday-android', 'membership-installer', 'membership-android') }
        default { throw "Unknown build target: $Target" }
    }
}

function Get-ProjectVersion([string]$Root) {
    $pubspec = Join-Path $Root 'pubspec.yaml'
    $text = Get-Content -LiteralPath $pubspec -Raw
    $raw = [regex]::Match($text, '(?m)^version:\s*([^\r\n#]+)').Groups[1].Value.Trim().Trim('"', "'")
    $match = [regex]::Match($raw, '^(?<name>\d+\.\d+\.\d+)(?:\+(?<build>\d+))?$')
    if (-not $match.Success) { throw "Expected version: x.y.z+number in $pubspec; found '$raw'" }
    $buildNumber = if ($match.Groups['build'].Success) { $match.Groups['build'].Value } else { '1' }
    return [pscustomobject]@{ Name = $match.Groups['name'].Value; Build = $buildNumber; Full = $raw }
}

function Get-BuildProfile($Config, [string]$Job) {
    if ($Job -eq 'sunday-web-installer') {
        $root = [IO.Path]::GetFullPath($Config.SundaySchoolRoot)
        return [pscustomobject]@{
            Root = $root; Key = 'sunday-web'; DisplayName = 'Sunday School Web Server'
            InstallerScript = 'installer\SundaySchoolWebServerSetup.iss'
            BackendProject = 'SundaySchool.SyncServer\SundaySchool.SyncServer.csproj'
            ManagerProject = 'SundaySchoolServerManager\SundaySchoolServerManager.csproj'
            Postgres = (Join-Path $root 'installer\payload\server\postgresql')
            Tools = $null; InstallerName = 'SundaySchool_WebServer_Setup.exe'; AndroidName = $null
            IsWeb = $true
        }
    }
    $sunday = $Job.StartsWith('sunday-')
    if ($sunday) {
        $root = [IO.Path]::GetFullPath($Config.SundaySchoolRoot)
        return [pscustomobject]@{
            Root = $root; Key = 'sunday'; DisplayName = 'Sunday School'
            InstallerScript = 'installer\SundaySchoolSetup.iss'
            BackendProject = 'SundaySchool.SyncServer\SundaySchool.SyncServer.csproj'
            ManagerProject = 'SundaySchoolServerManager\SundaySchoolServerManager.csproj'
            Postgres = (Join-Path $root 'installer\payload\server\postgresql')
            Tools = $null; InstallerName = 'SundaySchool_Setup.exe'; AndroidName = 'SundaySchool_Android.apk'
            IsWeb = $false
        }
    }
    $root = [IO.Path]::GetFullPath($Config.ChurchMembershipRoot)
    return [pscustomobject]@{
        Root = $root; Key = 'membership'; DisplayName = 'Church Membership'
        InstallerScript = 'installer\AbonaFlemoonSetup.iss'
        BackendProject = 'AbonaFlemoon.SyncServer\AbonaFlemoon.SyncServer.csproj'
        ManagerProject = 'AbonaFlemoonServerManager\AbonaFlemoonServerManager.csproj'
        Postgres = (Join-Path $root 'build\installer_staging\pgsql')
        Tools = (Join-Path $root 'build\installer_staging\tools')
        InstallerName = 'ChurchMembership_Setup.exe'; AndroidName = 'ChurchMembership_Android.apk'
    }
}

function Assert-BuildArtifact([string]$Path, [ValidateSet('exe', 'apk')][string]$Kind) {
    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($file.Length -lt 1MB) { throw "Build artifact is missing or incomplete: $Path" }
    if ($Kind -eq 'exe') {
        $stream = [IO.File]::OpenRead($Path)
        try {
            if ($stream.ReadByte() -ne 77 -or $stream.ReadByte() -ne 90) { throw "Invalid Windows installer: $Path" }
        } finally { $stream.Dispose() }
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($Path)
        try {
            foreach ($entry in @('AndroidManifest.xml', 'classes.dex', 'lib/armeabi-v7a/libapp.so', 'lib/arm64-v8a/libapp.so', 'lib/x86_64/libapp.so')) {
                if ($null -eq $zip.GetEntry($entry)) { throw "Incomplete universal APK: $Path (missing $entry)" }
            }
        } finally { $zip.Dispose() }
    }
}

function Get-BuildFileHash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Publish-BuildArtifact([string]$Source, [string]$Destination) {
    # Copy and verify beside the destination, then replace atomically on the same volume.
    $directory = Split-Path -Parent $Destination
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporary = Join-Path $directory ('.' + [IO.Path]::GetFileName($Destination) + '.' + [guid]::NewGuid().ToString('N') + '.new')
    try {
        [IO.File]::Copy($Source, $temporary, $false)
        $expected = Get-BuildFileHash $Source
        if ((Get-BuildFileHash $temporary) -ne $expected) { throw "Copy verification failed: $Destination" }
        if ([IO.File]::Exists($Destination)) {
            # Windows PowerShell 5 otherwise converts $null to an invalid empty backup path.
            [IO.File]::Replace($temporary, $Destination, [NullString]::Value)
        } else {
            [IO.File]::Move($temporary, $Destination)
        }
        return $expected
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}
