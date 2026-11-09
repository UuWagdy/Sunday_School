using System.Diagnostics;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;

namespace SundaySchoolServerManager;

internal enum ServerState
{
    Stopped,
    Starting,
    Running,
    Stopping,
    Recovering,
    Failed,
}

internal sealed class ServerStatusEventArgs(ServerState state, string message) : EventArgs
{
    public ServerState State { get; } = state;
    public string Message { get; } = message;
}

internal sealed class ServerSupervisor : IDisposable
{
    public const int ApiPort = 5050;
    public const int DatabasePort = 5434;
    private const long MaxManagerLogBytes = 5 * 1024 * 1024;
    private const int ManagerLogArchives = 3;
    private readonly SemaphoreSlim _operationLock = new(1, 1);
    private readonly HttpClient _http;
    private readonly System.Threading.Timer _watchdog;
    private readonly object _logLock = new();
    private readonly int _apiPort;
    private readonly int _databasePort;
    private Process? _postgres;
    private Process? _backend;
    private bool _desiredRunning;
    private bool _ownsServerProcesses;
    private bool _disposed;

    public ServerSupervisor(string installRoot, int apiPort = ApiPort, int databasePort = DatabasePort, string? dataRoot = null)
    {
        _apiPort = apiPort;
        _databasePort = databasePort;
        InstallRoot = Path.GetFullPath(installRoot).TrimEnd(Path.DirectorySeparatorChar);
        ServerRoot = Path.Combine(InstallRoot, "Server");
        ServerData = Path.GetFullPath(dataRoot ?? Path.Combine(InstallRoot, "SundaySchool_ServerData"));
        LogsRoot = Path.Combine(ServerData, "logs");
        Directory.CreateDirectory(LogsRoot);
        ManagerLogPath = Path.Combine(LogsRoot, "server-manager.log");

        var handler = new HttpClientHandler
        {
            UseProxy = false,
            ServerCertificateCustomValidationCallback = (_, _, _, _) => true,
        };
        _http = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(2) };
        _watchdog = new System.Threading.Timer(
            WatchdogTick,
            null,
            TimeSpan.FromSeconds(8),
            TimeSpan.FromSeconds(8));
    }

    public event EventHandler<ServerStatusEventArgs>? StatusChanged;
    public event EventHandler<string>? LogReceived;

    public string InstallRoot { get; }
    public string ServerRoot { get; }
    public string ServerData { get; }
    public string LogsRoot { get; }
    public string ManagerLogPath { get; }
    public string LocalUrl => $"http://127.0.0.1:{_apiPort}";

    public IReadOnlyList<string> NetworkUrls => GetLanAddresses()
        .Select(address => $"http://{address}:{_apiPort}")
        .ToList();

    private string BackendPidPath => Path.Combine(ServerData, "backend-manager.pid");

    public async Task StartAsync(bool recovering = false)
    {
        _desiredRunning = true;
        await _operationLock.WaitAsync();
        try
        {
            // Start explicitly adopts an already-running installation as well.
            _ownsServerProcesses = true;
            if (await IsHealthyAsync())
            {
                WriteServerInfoFile();
                Publish(ServerState.Running, "السيرفر يعمل وقاعدة البيانات PostgreSQL متصلة (SignalR نشط)");
                return;
            }

            Publish(
                recovering ? ServerState.Recovering : ServerState.Starting,
                recovering
                    ? "جاري استعادة تشغيل السيرفر تلقائيًا..."
                    : "جاري تشغيل قاعدة البيانات PostgreSQL...");

            var (postgresBinDir, backendExePath) = ResolveBinaries();
            RemoveStalePostmasterPid();
            await StopOwnedProcessesAsync(postgresBinDir);

            var postgresData = Path.Combine(ServerData, "postgres-data");
            await EnsurePostgresClusterInitializedAsync(postgresBinDir, postgresData);

            // Check if port 5434 is already open (e.g., external Postgres on 5434)
            if (!await IsPortOpenAsync(_databasePort))
            {
                var postgresExe = Path.Combine(postgresBinDir, "postgres.exe");
                _postgres = StartProcess(
                    postgresExe,
                    postgresBinDir,
                    "postgres",
                    null,
                    "-D", postgresData,
                    "-h", "127.0.0.1",
                    "-p", _databasePort.ToString());
            }

            // An open TCP socket precedes PostgreSQL recovery completion on slow disks.
            await WaitForPostgresAsync(postgresBinDir, TimeSpan.FromMinutes(3));

            Publish(ServerState.Starting, "قاعدة البيانات تعمل — جاري تشغيل سيرفر .NET 8 + SignalR...");
            var backendWorkDir = Path.GetDirectoryName(backendExePath)!;
            var envVars = new Dictionary<string, string>
            {
                ["PORT"] = _apiPort.ToString(),
                ["POSTGRES_BIN"] = postgresBinDir,
                ["BACKUP_SETTINGS_ROOT"] = ServerData,
                ["BACKUP_DEFAULT_DIRECTORY"] = Path.Combine(InstallRoot, "SundaySchool_ServerBackups"),
                ["DATABASE_URL"] = $"Host=127.0.0.1;Port={_databasePort};Database=sunday_school;Username=postgres;Pooling=true;Maximum Pool Size=50;",
            };

            _backend = StartProcess(
                backendExePath,
                backendWorkDir,
                "dotnet-server",
                envVars);
            File.WriteAllText(BackendPidPath, _backend.Id.ToString(), new UTF8Encoding(false));

            if (!await WaitForHealthAsync(_backend, TimeSpan.FromMinutes(5)))
            {
                throw new InvalidOperationException(
                    _backend.HasExited
                        ? $"توقف سيرفر .NET أثناء التشغيل (ExitCode={_backend.ExitCode}). راجع سجل مدير السيرفر."
                        : "لم يجهز سيرفر .NET خلال خمس دقائق. راجع سجل مدير السيرفر ثم أعد المحاولة.");
            }

            WriteServerInfoFile();
            Publish(ServerState.Running, "السيرفر يعمل وقاعدة البيانات PostgreSQL متصلة (SignalR نشط)");
        }
        catch (Exception exception)
        {
            // Do not leave the API serving requests against a failed database.
            await StopProcessAsync(_backend);
            _backend = null;
            WriteLog("manager", exception.ToString());
            Publish(ServerState.Failed, exception.Message);
        }
        finally
        {
            _operationLock.Release();
        }
    }

    public async Task StopAsync()
    {
        _desiredRunning = false;
        await _operationLock.WaitAsync();
        try
        {
            Publish(ServerState.Stopping, "جاري إيقاف السيرفر بأمان...");
            var (postgresBinDir, _) = TryResolveBinaries();
            await StopOwnedProcessesAsync(postgresBinDir);
            Publish(ServerState.Stopped, "السيرفر متوقف");
        }
        catch (Exception exception)
        {
            WriteLog("manager", exception.ToString());
            Publish(ServerState.Failed, exception.Message);
        }
        finally
        {
            _operationLock.Release();
        }
    }

    public async Task RestartAsync()
    {
        await StopAsync();
        await StartAsync();
    }

    public async Task<bool> IsHealthyAsync()
    {
        try
        {
            using var response = await _http.GetAsync($"{LocalUrl}/health");
            if (!response.IsSuccessStatusCode) return false;
            await using var stream = await response.Content.ReadAsStreamAsync();
            using var json = await JsonDocument.ParseAsync(stream);
            return json.RootElement.TryGetProperty("status", out var status)
                && status.GetString()?.Equals("ok", StringComparison.OrdinalIgnoreCase) == true;
        }
        catch
        {
            return false;
        }
    }

    private (string? PostgresBinDir, string? BackendExePath) TryResolveBinaries()
    {
        var pgCandidates = new[]
        {
            Path.Combine(ServerRoot, "postgresql", "bin"),
            Path.Combine(InstallRoot, "postgresql", "bin"),
        };
        var pgBin = pgCandidates.FirstOrDefault(dir => File.Exists(Path.Combine(dir, "postgres.exe")));

        var backendCandidates = new[]
        {
            Path.Combine(ServerRoot, "backend", "SundaySchool.SyncServer.exe"),
            Path.Combine(InstallRoot, "SundaySchool.SyncServer", "bin", "Release", "net8.0", "SundaySchool.SyncServer.exe"),
            Path.Combine(InstallRoot, "SundaySchool.SyncServer", "bin", "Debug", "net8.0", "SundaySchool.SyncServer.exe"),
            Path.Combine(AppContext.BaseDirectory, "SundaySchool.SyncServer.exe"),
        };
        var backendExe = backendCandidates.FirstOrDefault(File.Exists);

        return (pgBin, backendExe);
    }

    private (string PostgresBinDir, string BackendExePath) ResolveBinaries()
    {
        var (pgBin, backendExe) = TryResolveBinaries();
        if (string.IsNullOrWhiteSpace(pgBin))
        {
            throw new FileNotFoundException(
                "لم يتم العثور على محرك قاعدة البيانات PostgreSQL (postgres.exe) داخل مجلد Server\\postgresql\\bin.");
        }
        if (string.IsNullOrWhiteSpace(backendExe))
        {
            throw new FileNotFoundException(
                "لم يتم العثور على ملف سيرفر المزامنة SundaySchool.SyncServer.exe.");
        }
        return (pgBin, backendExe);
    }

    private async Task EnsurePostgresClusterInitializedAsync(string postgresBinDir, string postgresData)
    {
        var pgVersionFile = Path.Combine(postgresData, "PG_VERSION");
        if (File.Exists(pgVersionFile)) return;

        Directory.CreateDirectory(postgresData);
        var initDbExe = Path.Combine(postgresBinDir, "initdb.exe");
        if (!File.Exists(initDbExe))
        {
            throw new FileNotFoundException("ملف initdb.exe غير موجود لتهيئة قاعدة البيانات.", initDbExe);
        }

        WriteLog("manager", "جاري تهيئة عنقود بيانات PostgreSQL لأول مرة (initdb)...");
        var start = new ProcessStartInfo
        {
            FileName = initDbExe,
            WorkingDirectory = postgresBinDir,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        foreach (var arg in new[] { "-D", postgresData, "-U", "postgres", "-E", "UTF8", "--locale=C", "--auth=trust" })
        {
            start.ArgumentList.Add(arg);
        }

        using var proc = Process.Start(start)
            ?? throw new InvalidOperationException("تعذر تشغيل initdb.exe");
        var stdOut = await proc.StandardOutput.ReadToEndAsync();
        var stdErr = await proc.StandardError.ReadToEndAsync();
        await proc.WaitForExitAsync();

        if (!string.IsNullOrWhiteSpace(stdOut)) WriteLog("initdb", stdOut.Trim());
        if (!string.IsNullOrWhiteSpace(stdErr)) WriteLog("initdb", stdErr.Trim());

        if (proc.ExitCode != 0 || !File.Exists(pgVersionFile))
        {
            throw new InvalidOperationException($"فشل تهيئة قاعدة البيانات PostgreSQL (ExitCode={proc.ExitCode}).");
        }
        WriteLog("manager", "تم تهيئة عنقود بيانات PostgreSQL بنجاح.");
    }

    private void WriteServerInfoFile()
    {
        try
        {
            var lanUrls = NetworkUrls;
            var recommendedLan = lanUrls.FirstOrDefault() ?? LocalUrl;
            var lines = new List<string>
            {
                $"LOCAL_URL={LocalUrl}",
                $"LAN_URL={recommendedLan}",
                $"SIGNALR_HUB={recommendedLan}/hubs/sync",
                $"POSTGRES_PORT={_databasePort}",
                $"UPDATED_AT={DateTime.Now:O}",
                "",
                "Sunday School Sync Server is installed and running.",
                $"This computer: {LocalUrl}",
                $"Recommended LAN address: {recommendedLan}",
                $"SignalR Hub: {recommendedLan}/hubs/sync",
                $"PostgreSQL Port: {_databasePort}",
            };
            lines.AddRange(lanUrls);

            var infoPath = Path.Combine(InstallRoot, "SERVER_INFO.txt");
            File.WriteAllLines(infoPath, lines, new UTF8Encoding(false));
        }
        catch (Exception ex)
        {
            WriteLog("manager", $"Could not write SERVER_INFO.txt: {ex.Message}");
        }
    }

    private Process StartProcess(
        string executable,
        string workingDirectory,
        string logPrefix,
        IDictionary<string, string>? environmentVariables,
        params string[] arguments)
    {
        var start = new ProcessStartInfo
        {
            FileName = executable,
            WorkingDirectory = workingDirectory,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        if (environmentVariables is not null)
        {
            foreach (var (k, v) in environmentVariables)
            {
                start.EnvironmentVariables[k] = v;
            }
        }
        foreach (var argument in arguments) start.ArgumentList.Add(argument);

        var process = new Process { StartInfo = start, EnableRaisingEvents = true };
        process.OutputDataReceived += (_, eventArgs) =>
        {
            if (!string.IsNullOrWhiteSpace(eventArgs.Data)) WriteLog(logPrefix, eventArgs.Data);
        };
        process.ErrorDataReceived += (_, eventArgs) =>
        {
            if (!string.IsNullOrWhiteSpace(eventArgs.Data)) WriteLog(logPrefix, eventArgs.Data);
        };
        if (!process.Start())
        {
            throw new InvalidOperationException($"تعذر تشغيل {Path.GetFileName(executable)}");
        }
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
        WriteLog("manager", $"Started {Path.GetFileName(executable)} (PID {process.Id})");
        return process;
    }

    private async Task StopOwnedProcessesAsync(string? postgresBinDir)
    {
        await StopProcessAsync(_backend);
        _backend = null;
        await StopPersistedBackendAsync();

        if (!string.IsNullOrWhiteSpace(postgresBinDir))
        {
            var pgCtl = Path.Combine(postgresBinDir, "pg_ctl.exe");
            var postgresData = Path.Combine(ServerData, "postgres-data");
            if (File.Exists(pgCtl) && File.Exists(Path.Combine(postgresData, "postmaster.pid")))
            {
                var start = new ProcessStartInfo
                {
                    FileName = pgCtl,
                    WorkingDirectory = postgresBinDir,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                };
                foreach (var value in new[] { "stop", "-D", postgresData, "-m", "fast", "-w", "-t", "60" })
                {
                    start.ArgumentList.Add(value);
                }
                using var stopper = Process.Start(start);
                if (stopper is not null)
                {
                    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(65));
                    try { await stopper.WaitForExitAsync(timeout.Token); }
                    catch (OperationCanceledException)
                    {
                        stopper.Kill(entireProcessTree: true);
                        await stopper.WaitForExitAsync();
                        throw new InvalidOperationException("لم يكتمل إيقاف PostgreSQL بأمان. لن يتم تشغيل نسخة أخرى حتى ينتهي الإيقاف.");
                    }
                    if (File.Exists(Path.Combine(postgresData, "postmaster.pid")))
                    {
                        throw new InvalidOperationException($"لم يكتمل إيقاف PostgreSQL (ExitCode={stopper.ExitCode}). أعد المحاولة بعد انتهاء الإيقاف.");
                    }
                }
                else throw new InvalidOperationException("تعذر تشغيل أداة إيقاف PostgreSQL.");
            }
        }

        // pg_ctl has completed a clean shutdown; never force-kill a cluster that
        // is still shutting down and then race it with a second postmaster.
        _postgres?.Dispose();
        _postgres = null;
    }

    private async Task StopPersistedBackendAsync()
    {
        if (!File.Exists(BackendPidPath)) return;
        try
        {
            var raw = await File.ReadAllTextAsync(BackendPidPath);
            if (!int.TryParse(raw.Trim(), out var pid)) return;
            using var process = Process.GetProcessById(pid);
            if (!process.ProcessName.Contains("SundaySchool.SyncServer", StringComparison.OrdinalIgnoreCase)) return;
            process.Kill(entireProcessTree: true);
            await process.WaitForExitAsync();
        }
        catch (ArgumentException) { }
        catch (InvalidOperationException) { }
        finally
        {
            try { File.Delete(BackendPidPath); } catch { }
        }
    }

    private static async Task StopProcessAsync(Process? process)
    {
        if (process is null || process.HasExited) return;
        process.Kill(entireProcessTree: true);
        await process.WaitForExitAsync();
    }

    private async Task<bool> WaitForHealthAsync(Process process, TimeSpan timeout)
    {
        var deadline = DateTime.UtcNow + timeout;
        while (DateTime.UtcNow < deadline)
        {
            ThrowIfPostgresExited();
            if (process.HasExited) return false;
            if (await IsHealthyAsync()) return true;
            await Task.Delay(500);
        }
        return false;
    }

    private static async Task<bool> IsPortOpenAsync(int port)
    {
        try
        {
            using var client = new TcpClient();
            using var attempt = new CancellationTokenSource(TimeSpan.FromMilliseconds(400));
            await client.ConnectAsync(IPAddress.Loopback, port, attempt.Token);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private async Task WaitForPostgresAsync(string postgresBinDir, TimeSpan timeout)
    {
        var deadline = DateTime.UtcNow + timeout;
        while (DateTime.UtcNow < deadline)
        {
            ThrowIfPostgresExited();
            var start = new ProcessStartInfo(Path.Combine(postgresBinDir, "pg_isready.exe"))
            {
                UseShellExecute = false, CreateNoWindow = true,
                RedirectStandardOutput = true, RedirectStandardError = true,
            };
            foreach (var arg in new[] { "-h", "127.0.0.1", "-p", _databasePort.ToString(), "-U", "postgres", "-t", "2", "-q" })
                start.ArgumentList.Add(arg);
            using var probe = Process.Start(start)
                ?? throw new InvalidOperationException("تعذر فحص جاهزية PostgreSQL.");
            await probe.WaitForExitAsync();
            ThrowIfPostgresExited();
            if (probe.ExitCode == 0) return;
            await Task.Delay(1000);
        }
        throw new InvalidOperationException("لم تجهز قاعدة البيانات PostgreSQL خلال ثلاث دقائق. راجع سجل مدير السيرفر.");
    }

    private void ThrowIfPostgresExited()
    {
        if (_postgres?.HasExited == true)
            throw new InvalidOperationException($"توقف PostgreSQL (ExitCode={_postgres.ExitCode}). راجع سجل مدير السيرفر.");
    }

    private void RemoveStalePostmasterPid()
    {
        var pidFile = Path.Combine(ServerData, "postgres-data", "postmaster.pid");
        if (!File.Exists(pidFile)) return;
        try
        {
            var lines = File.ReadAllLines(pidFile);
            if (int.TryParse(lines.FirstOrDefault(), out var pid))
            {
                try
                {
                    using var process = Process.GetProcessById(pid);
                    // Windows may reuse the recorded PID after a reboot. An
                    // unrelated process must not block recovery (or be stopped).
                    if (!process.HasExited && process.ProcessName.Equals("postgres", StringComparison.OrdinalIgnoreCase))
                    {
                        if (lines.Length < 3 || !long.TryParse(lines[2], out var startedAt)) return;
                        var actualStart = new DateTimeOffset(process.StartTime.ToUniversalTime()).ToUnixTimeSeconds();
                        if (Math.Abs(actualStart - startedAt) <= 2) return;
                    }
                }
                catch (ArgumentException) { }
            }
            File.Delete(pidFile);
            WriteLog("manager", "Removed stale postmaster.pid");
        }
        catch (Exception exception)
        {
            WriteLog("manager", $"Could not inspect postmaster.pid: {exception.Message}");
        }
    }

    private async void WatchdogTick(object? _)
    {
        if (!_desiredRunning || _disposed || _operationLock.CurrentCount == 0) return;
        if (await IsHealthyAsync()) return;
        await StartAsync(recovering: true);
    }

    private void Publish(ServerState state, string message)
    {
        WriteLog("manager", $"{state}: {message}");
        StatusChanged?.Invoke(this, new ServerStatusEventArgs(state, message));
    }

    private void WriteLog(string source, string message)
    {
        var line = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [{source}] {message}";
        lock (_logLock)
        {
            var output = line + Environment.NewLine;
            if (output.Length > MaxManagerLogBytes / 4)
            {
                output = output[^((int)MaxManagerLogBytes / 4)..];
            }
            if (File.Exists(ManagerLogPath) &&
                new FileInfo(ManagerLogPath).Length + Encoding.UTF8.GetByteCount(output) > MaxManagerLogBytes)
            {
                var oldest = $"{ManagerLogPath}.{ManagerLogArchives}";
                if (File.Exists(oldest)) File.Delete(oldest);
                for (var number = ManagerLogArchives - 1; number >= 1; number--)
                {
                    var sourceArchive = $"{ManagerLogPath}.{number}";
                    if (File.Exists(sourceArchive))
                    {
                        File.Move(sourceArchive, $"{ManagerLogPath}.{number + 1}");
                    }
                }
                if (new FileInfo(ManagerLogPath).Length > MaxManagerLogBytes)
                {
                    using var stream = new FileStream(ManagerLogPath, FileMode.Open, FileAccess.Write, FileShare.Read);
                    stream.SetLength(0);
                }
                else
                {
                    File.Move(ManagerLogPath, $"{ManagerLogPath}.1");
                }
            }
            File.AppendAllText(ManagerLogPath, output, new UTF8Encoding(false));
        }
        LogReceived?.Invoke(this, line);
    }

    private static IEnumerable<string> GetLanAddresses()
    {
        // Prefer a physical LAN interface with a gateway over VPN/host-only adapters.
        return NetworkInterface.GetAllNetworkInterfaces()
            .Where(item => item.OperationalStatus == OperationalStatus.Up
                && item.NetworkInterfaceType != NetworkInterfaceType.Loopback)
            .OrderBy(item => item.GetIPProperties().GatewayAddresses.Any(g =>
                g.Address.AddressFamily == AddressFamily.InterNetwork &&
                !g.Address.Equals(IPAddress.Any)) ? 0 : 1)
            .ThenBy(item => item.NetworkInterfaceType is NetworkInterfaceType.Ethernet
                or NetworkInterfaceType.Wireless80211 ? 0 : 1)
            .SelectMany(item => item.GetIPProperties().UnicastAddresses)
            .Where(item => item.Address.AddressFamily == AddressFamily.InterNetwork
                && !IPAddress.IsLoopback(item.Address)
                && !item.Address.ToString().StartsWith("169.254.", StringComparison.Ordinal))
            .Select(item => item.Address.ToString())
            .Distinct();
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        _desiredRunning = false;
        _watchdog.Dispose();
        var (pgBin, _) = TryResolveBinaries();
        // A supervisor used only by the standalone tunnels window is an
        // observer. Closing it must not stop the main manager's database.
        if (_ownsServerProcesses)
        {
            try { StopOwnedProcessesAsync(pgBin).GetAwaiter().GetResult(); } catch { }
        }
        _http.Dispose();
        _operationLock.Dispose();
        _postgres?.Dispose();
        _backend?.Dispose();
    }
}
