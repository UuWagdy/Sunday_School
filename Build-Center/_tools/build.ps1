#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('sunday-installer', 'sunday-android', 'membership-installer', 'membership-android', 'sunday-all', 'membership-all', 'everything')]
    [string]$Target,
    [string]$ConfigPath,
    [switch]$PlanOnly,
    [switch]$NoOpenOutput
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Build.Core.ps1')
$center = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = Join-Path $center 'settings.json' }
$transcript = $false
$buildLock = $null
$staging = $null
$exitCode = 0

function Find-Tool([string]$Name, [string]$Override, [string[]]$Fallbacks = @()) {
    if ($Override) {
        if (-not (Test-Path -LiteralPath $Override -PathType Leaf)) { throw "Tool not found: $Override" }
        return [IO.Path]::GetFullPath($Override)
    }
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    foreach ($path in $Fallbacks) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    throw "Required tool '$Name' was not found. Set its path in $ConfigPath"
}

function Invoke-BuildCommand([string]$Executable, [string[]]$Arguments, [string]$Root) {
    Write-Host ("`n> " + $Executable + ' ' + ($Arguments -join ' ')) -ForegroundColor Cyan
    Push-Location -LiteralPath $Root
    try {
        # Windows PowerShell 5.1 can turn native stderr into terminating errors;
        # the native exit code determines whether a build actually failed.
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { & $Executable @Arguments; $nativeExitCode = $LASTEXITCODE }
        finally { $ErrorActionPreference = $previous }
        if ($nativeExitCode -ne 0) { throw "Build command failed (exit $nativeExitCode): $Executable" }
    } finally { Pop-Location }
}

function Ensure-VCRuntime([string]$Root) {
    foreach ($arch in @('x64', 'x86')) {
        $path = Join-Path $Root "installer\downloads\VC_redist.$arch.exe"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            $download = Join-Path (Split-Path -Parent $path) ("VC_redist.$arch." + [guid]::NewGuid().ToString('N') + '.exe')
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/vs/17/release/vc_redist.$arch.exe" -OutFile $download
                $signature = Get-AuthenticodeSignature -LiteralPath $download
                if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notlike '*Microsoft Corporation*') {
                    throw "Invalid Microsoft redistributable signature: $download"
                }
                [IO.File]::Move($download, $path)
            } finally { if ([IO.File]::Exists($download)) { [IO.File]::Delete($download) } }
        }
        if ((Get-Item -LiteralPath $path).Length -lt 1MB) { throw "Incomplete VC runtime: $path" }
        $cachedSignature = Get-AuthenticodeSignature -LiteralPath $path
        if ($cachedSignature.Status -ne 'Valid' -or $cachedSignature.SignerCertificate.Subject -notlike '*Microsoft Corporation*') {
            throw "Invalid Microsoft redistributable signature: $path"
        }
    }
}

try {
    $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    $output = if ([IO.Path]::IsPathRooted($config.OutputDirectory)) { [IO.Path]::GetFullPath($config.OutputDirectory) }
              else { [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($ConfigPath))) $config.OutputDirectory)) }
    $jobs = @(Get-TargetJobs $Target)
    if ($PlanOnly) {
        foreach ($job in $jobs) {
            $buildProfile = Get-BuildProfile $config $job
            $version = Get-ProjectVersion $buildProfile.Root
            $name = if ($job.EndsWith('-installer')) { $buildProfile.InstallerName } else { $buildProfile.AndroidName }
            Write-Output "$job | $($buildProfile.Root) | version $($version.Full) | $(Join-Path $output $name)"
        }
        exit 0
    }

    $logs = Join-Path $center 'Logs'
    [IO.Directory]::CreateDirectory($logs) | Out-Null
    try { $buildLock = [IO.File]::Open((Join-Path $logs '.build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { throw 'Another Build-Center job is running. Wait until it finishes, then try again.' }
    $runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    $logPath = Join-Path $logs "$runId-$Target.log"
    Start-Transcript -LiteralPath $logPath | Out-Null
    $transcript = $true
    $staging = Join-Path $logs ".staging\$runId"
    [IO.Directory]::CreateDirectory($staging) | Out-Null
    $flutter = Find-Tool 'flutter.bat' $config.FlutterPath @((Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'))
    $needsInstaller = @($jobs | Where-Object { $_.EndsWith('-installer') }).Count -gt 0
    if ($needsInstaller) {
        # Pin the module to this PowerShell runtime when launched from a Core host.
        Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Security\Microsoft.PowerShell.Security.psd1') -ErrorAction Stop
        $dotnet = Find-Tool 'dotnet.exe' $config.DotnetPath
        $iscc = Find-Tool 'ISCC.exe' $config.InnoSetupPath @(
            'C:\Program Files (x86)\Inno Setup 6\ISCC.exe', 'C:\Program Files\Inno Setup 6\ISCC.exe')
    }
    $prepared = @{}
    $pending = @()
    foreach ($job in $jobs) {
        $buildProfile = Get-BuildProfile $config $job
        $version = Get-ProjectVersion $buildProfile.Root
        Write-Host "`n=== $($buildProfile.DisplayName) / $job / $($version.Full) ===" -ForegroundColor Green
        if (-not $prepared.ContainsKey($buildProfile.Key)) {
            Invoke-BuildCommand $flutter @('pub', 'get') $buildProfile.Root
            $prepared[$buildProfile.Key] = $true
        }
        if ($job.EndsWith('-installer')) {
            foreach ($required in @($buildProfile.BackendProject, $buildProfile.ManagerProject, $buildProfile.InstallerScript, 'installer\validate-server-payload.ps1')) {
                if (-not (Test-Path -LiteralPath (Join-Path $buildProfile.Root $required) -PathType Leaf)) { throw "Missing project input: $required" }
            }
            Ensure-VCRuntime $buildProfile.Root
            $backend = Join-Path $staging "$($buildProfile.Key)-backend"
            $manager = Join-Path $staging "$($buildProfile.Key)-manager"
            Invoke-BuildCommand $dotnet @('publish', $buildProfile.BackendProject, '-c', 'Release', '-r', 'win-x64', '--self-contained', 'true', '-p:PublishSingleFile=false', '-o', $backend) $buildProfile.Root
            Invoke-BuildCommand $dotnet @('publish', $buildProfile.ManagerProject, '-c', 'Release', '-r', 'win-x64', '--self-contained', 'true', '-p:PublishSingleFile=false', '-o', $manager) $buildProfile.Root
            & (Join-Path $buildProfile.Root 'installer\validate-server-payload.ps1') -BackendRoot $backend -ManagerRoot $manager -PostgresRoot $buildProfile.Postgres
            Invoke-BuildCommand $flutter @('build', 'windows', '--release', '--no-pub', '--build-name', $version.Name, '--build-number', $version.Build) $buildProfile.Root
            $compilerArguments = @('/Qp', "/O$staging", "/F$([IO.Path]::GetFileNameWithoutExtension($buildProfile.InstallerName))",
                "/DMyAppVersion=$($version.Name)", "/DSyncServerSource=$backend", "/DServerManagerSource=$manager", "/DPostgresSource=$($buildProfile.Postgres)")
            if ($buildProfile.Tools) { $compilerArguments += "/DToolsSource=$($buildProfile.Tools)" }
            $compilerArguments += (Join-Path $buildProfile.Root $buildProfile.InstallerScript)
            Invoke-BuildCommand $iscc $compilerArguments $buildProfile.Root
            $source = Join-Path $staging $buildProfile.InstallerName
            Assert-BuildArtifact $source 'exe'
            $pending += [pscustomobject]@{ Source = $source; Name = $buildProfile.InstallerName; Version = $version.Full; Project = $buildProfile.DisplayName }
        } else {
            Invoke-BuildCommand $flutter @('build', 'apk', '--release', '--no-pub', '--target-platform', 'android-arm,android-arm64,android-x64', '--build-name', $version.Name, '--build-number', $version.Build) $buildProfile.Root
            $apk = Join-Path $buildProfile.Root 'build\app\outputs\flutter-apk\app-release.apk'
            Assert-BuildArtifact $apk 'apk'
            $source = Join-Path $staging $buildProfile.AndroidName
            [IO.File]::Copy($apk, $source, $false)
            $pending += [pscustomobject]@{ Source = $source; Name = $buildProfile.AndroidName; Version = $version.Full; Project = $buildProfile.DisplayName }
        }
    }

    # Nothing in Output is replaced until every selected build has succeeded.
    [IO.Directory]::CreateDirectory($output) | Out-Null
    $infoPath = Join-Path $output 'BUILD_INFO.json'
    $info = @{}
    if (Test-Path -LiteralPath $infoPath) {
        try {
            $existing = Get-Content -LiteralPath $infoPath -Raw | ConvertFrom-Json
            foreach ($property in $existing.PSObject.Properties) { $info[$property.Name] = $property.Value }
        } catch { Write-Warning 'Previous BUILD_INFO.json was unreadable; recreating metadata for this build.' }
    }
    foreach ($artifact in $pending) {
        $destination = Join-Path $output $artifact.Name
        $hash = Publish-BuildArtifact $artifact.Source $destination
        $info[$artifact.Name] = [ordered]@{ project = $artifact.Project; version = $artifact.Version;
            builtUtc = [DateTime]::UtcNow.ToString('o'); bytes = (Get-Item -LiteralPath $destination).Length; sha256 = $hash; log = $logPath }
        Write-Host "READY: $destination" -ForegroundColor Green
    }
    $temporaryInfo = Join-Path $staging 'BUILD_INFO.json'
    $info | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $temporaryInfo -Encoding UTF8
    Publish-BuildArtifact $temporaryInfo $infoPath | Out-Null
    $sums = foreach ($name in @('SundaySchool_Setup.exe', 'SundaySchool_Android.apk', 'ChurchMembership_Setup.exe', 'ChurchMembership_Android.apk')) {
        $path = Join-Path $output $name
        if (Test-Path -LiteralPath $path -PathType Leaf) { '{0}  {1}' -f (Get-BuildFileHash $path), $name }
    }
    $temporarySums = Join-Path $staging 'SHA256SUMS.txt'
    [IO.File]::WriteAllLines($temporarySums, [string[]]$sums)
    Publish-BuildArtifact $temporarySums (Join-Path $output 'SHA256SUMS.txt') | Out-Null
    Write-Host "`nSUCCESS. Output: $output`nLog: $logPath" -ForegroundColor Green
    if (-not $NoOpenOutput) { Start-Process -FilePath explorer.exe -ArgumentList @("`"$output`"") }
} catch {
    $exitCode = 1
    Write-Host "`nBUILD FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Existing completed output files were not deleted. Check the build log for details.'
} finally {
    if ($staging -and (Test-Path -LiteralPath $staging)) {
        # Only remove the unique scratch directory allocated by this run.
        $expectedRoot = [IO.Path]::GetFullPath((Join-Path $center 'Logs\.staging')) + [IO.Path]::DirectorySeparatorChar
        $resolved = [IO.Path]::GetFullPath($staging)
        if ($resolved.StartsWith($expectedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            try { Remove-Item -LiteralPath $resolved -Recurse -Force }
            catch { Write-Warning "Could not clean scratch files: $resolved" }
        }
    }
    if ($transcript) { Stop-Transcript | Out-Null }
    if ($buildLock) { $buildLock.Dispose() }
}
exit $exitCode
