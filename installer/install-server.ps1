[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallRoot,
    [string]$DataRoot,
    [int]$ApiPort = 5050,
    [int]$DatabasePort = 5434,
    [string]$InstallerVersion = '1.0.0',
    [switch]$PrepareDatabaseOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$InstallRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $InstallRoot 'SundaySchool_ServerData'
}
$DataRoot = [IO.Path]::GetFullPath($DataRoot).TrimEnd('\', '/')

$ServerRoot = Join-Path $InstallRoot 'Server'
$PostgresBin = Join-Path $ServerRoot 'postgresql\bin'
$PgCtl = Join-Path $PostgresBin 'pg_ctl.exe'
$InitDb = Join-Path $PostgresBin 'initdb.exe'
$Psql = Join-Path $PostgresBin 'psql.exe'
$CreateDb = Join-Path $PostgresBin 'createdb.exe'
$PgIsReady = Join-Path $PostgresBin 'pg_isready.exe'

$PostgresData = Join-Path $DataRoot 'postgres-data'
$LogsRoot = Join-Path $DataRoot 'logs'
$InfoFile = Join-Path $InstallRoot 'SERVER_INFO.txt'
$ProgramDataInfoDir = Join-Path $env:ProgramData 'SundaySchool'
$ProgramDataInfoFile = Join-Path $ProgramDataInfoDir 'SERVER_INFO.txt'

New-Item -ItemType Directory -Force -Path $DataRoot, $LogsRoot | Out-Null
if (-not $PrepareDatabaseOnly) { New-Item -ItemType Directory -Force -Path $ProgramDataInfoDir | Out-Null }
Start-Transcript -Path (Join-Path $LogsRoot 'install-server.log') -Append | Out-Null
try {
& (Join-Path $PSScriptRoot 'validate-server-payload.ps1') `
    -BackendRoot (Join-Path $ServerRoot 'backend') `
    -ManagerRoot (Join-Path $InstallRoot 'ServerManager') `
    -PostgresRoot (Join-Path $ServerRoot 'postgresql')

# 1. Initialize portable PostgreSQL cluster if present and not yet initialized
if (Test-Path -LiteralPath $InitDb -PathType Leaf) {
    if (-not (Test-Path -LiteralPath (Join-Path $PostgresData 'PG_VERSION') -PathType Leaf)) {
        New-Item -ItemType Directory -Force -Path $PostgresData | Out-Null
        & $InitDb -D $PostgresData -U postgres -E UTF8 --locale=C --auth=trust | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "initdb failed with exit code $LASTEXITCODE"
        }
        Add-Content -LiteralPath (Join-Path $PostgresData 'postgresql.conf') -Encoding UTF8 -Value @"

# Sunday School managed settings
listen_addresses = '127.0.0.1'
port = $DatabasePort
"@
    }

    # Start PostgreSQL briefly to ensure sunday_school database exists
    $bootstrapLog = Join-Path $LogsRoot 'postgres-bootstrap.log'
    $status = Start-Process -FilePath $PgCtl -ArgumentList "status -D `"$PostgresData`"" -WindowStyle Hidden -Wait -PassThru
    $startedForPreparation = $status.ExitCode -ne 0
    try {
        if ($startedForPreparation) {
            $proc = Start-Process -FilePath $PgCtl -ArgumentList "start -D `"$PostgresData`" -o `"-h 127.0.0.1 -p $DatabasePort`" -l `"$bootstrapLog`" -w -t 180" -WindowStyle Hidden -PassThru
            $proc.WaitForExit()
            if ($proc.ExitCode -ne 0) { throw "PostgreSQL startup failed (exit $($proc.ExitCode)). See $bootstrapLog" }
        }
        for ($i = 0; $i -lt 180; $i++) {
            & $PgIsReady -h 127.0.0.1 -p $DatabasePort -U postgres -d postgres -q
            if ($LASTEXITCODE -eq 0) { break }
            Start-Sleep -Seconds 1
        }
        if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL did not become ready.' }
        $actualData = & $Psql -h 127.0.0.1 -p $DatabasePort -U postgres -d postgres -tAc 'SHOW data_directory'
        if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath(($actualData | Out-String).Trim()).TrimEnd('\', '/') -ne $PostgresData) {
            throw 'The database port belongs to another PostgreSQL data directory. Check port configuration.'
        }

        $dbExists = & $Psql -h 127.0.0.1 -p $DatabasePort -U postgres -d postgres -v ON_ERROR_STOP=1 -tAc "SELECT 1 FROM pg_database WHERE datname='sunday_school'"
        if ($LASTEXITCODE -ne 0) { throw 'Could not check the Sunday School database.' }
        if ([string]::IsNullOrWhiteSpace($dbExists)) {
            & $CreateDb -h 127.0.0.1 -p $DatabasePort -U postgres sunday_school | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Could not create the Sunday School database.' }
        }
    } finally {
        if ($startedForPreparation) {
            & $PgCtl stop -D $PostgresData -m fast -w -t 180 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Could not stop PostgreSQL after installation preparation.' }
        }
    }
}

# 2. Configure Windows Firewall rule for port 5050 (API + SignalR)
if ($PrepareDatabaseOnly) { return }
& (Join-Path $PSScriptRoot 'register-server-startup.ps1') -InstallRoot $InstallRoot
& netsh.exe advfirewall firewall delete rule name='Sunday School Sync Server' 2>&1 | Out-Null
& netsh.exe advfirewall firewall add rule name='Sunday School Sync Server' dir=in action=allow protocol=TCP localport=$ApiPort profile=domain,private,public 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not configure the Sunday School firewall rule.' }

# 3. Discover LAN IPv4 and write SERVER_INFO.txt
$lanIp = ([Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } |
    Sort-Object @{Expression={ if ($_.GetIPProperties().GatewayAddresses | Where-Object {
        $_.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and
        -not $_.Address.Equals([Net.IPAddress]::Any) }) { 0 } else { 1 } }} |
    ForEach-Object { $_.GetIPProperties().UnicastAddresses.Address } |
    Where-Object { $_.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and -not [Net.IPAddress]::IsLoopback($_) } |
    Where-Object { -not $_.ToString().StartsWith('169.254.') } |
    ForEach-Object { $_.ToString() } |
    Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($lanIp)) { $lanIp = '127.0.0.1' }

$infoLines = @(
    "LOCAL_URL=http://127.0.0.1:$ApiPort"
    "LAN_URL=http://$($lanIp):$ApiPort"
    "SIGNALR_HUB=http://$($lanIp):$ApiPort/hubs/sync"
    "POSTGRES_PORT=$DatabasePort"
    "UPDATED_AT=$(Get-Date -Format o)"
)
[IO.File]::WriteAllLines($InfoFile, $infoLines, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines($ProgramDataInfoFile, $infoLines, [Text.UTF8Encoding]::new($false))

Write-Host 'Sunday School Sync Server prepared successfully.'
} finally {
    Stop-Transcript | Out-Null
}
