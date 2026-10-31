$ErrorActionPreference = 'Stop'
Import-Module ScheduledTasks
$taskRoot = Join-Path ([IO.Path]::GetTempPath()) ('petros startup test ' + [Guid]::NewGuid().ToString('N'))
$managerRoot = Join-Path $taskRoot 'ServerManager'
New-Item -ItemType Directory -Path $managerRoot -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $managerRoot 'SundaySchoolServerManager.exe') | Out-Null

# Exercise real Task Scheduler CIM objects, replacing only the privileged
# registration and legacy-file removal. Never changes this PC's startup tasks.
$taskTestCapture = [pscustomobject]@{ Registration = $null }
function Register-ScheduledTask {
    param($TaskName, $Action, $Trigger, $Principal, $Settings, $Description, [switch]$Force)
    $taskTestCapture.Registration = @{ Name=$TaskName; Action=$Action; Trigger=$Trigger; Principal=$Principal; Settings=$Settings }
}
function Remove-Item { param($LiteralPath, [switch]$Force) }
function Assert($condition, $message) { if (-not $condition) { throw $message } }

& (Join-Path $PSScriptRoot '..\installer\register-server-startup.ps1') -InstallRoot $taskRoot
$r = $taskTestCapture.Registration
Assert ($r.Name -eq 'Sunday School Server Manager') 'Unexpected task name'
Assert ($r.Action.Execute -eq (Join-Path $managerRoot 'SundaySchoolServerManager.exe')) 'Wrong executable'
Assert ($r.Action.WorkingDirectory -eq $managerRoot) 'Missing working directory'
Assert ($r.Action.Arguments -eq "--background --install-root `"$taskRoot`"") 'Paths with spaces must be quoted'
Assert ($r.Trigger.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger') 'Must trigger on Windows sign-in'
Assert ([string]::IsNullOrEmpty($r.Trigger.UserId)) 'Must handle any signed-in user'
Assert ($r.Trigger.Delay -eq 'PT15S') 'Logon delay missing'
Assert ($r.Principal.GroupId -eq 'S-1-5-32-545' -or $r.Principal.GroupId -match 'Users$') 'Must run for standard users'
Assert ($r.Principal.RunLevel -eq 0) 'Should not require elevation at sign-in'
Assert (-not $r.Settings.DisallowStartIfOnBatteries) 'Must start on battery'
Assert (-not $r.Settings.StopIfGoingOnBatteries) 'Must stay running on battery'
Assert ($r.Settings.ExecutionTimeLimit -eq 'PT0S') 'Must not stop automatically after three days'
Assert ($r.Settings.StartWhenAvailable) 'Must handle a delayed logon'
Assert ($r.Settings.RestartCount -eq 3) 'Startup retry missing'
Write-Host 'PASS: logon, standard-user principal, spaced paths, tray arguments, battery, unlimited runtime, retries.'

# Only remove our validated temporary test directory, using the native cmdlet.
$resolved = [IO.Path]::GetFullPath($taskRoot)
$tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if ($resolved.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -like 'petros startup test *') {
    Microsoft.PowerShell.Management\Remove-Item -LiteralPath $resolved -Recurse -Force
}
