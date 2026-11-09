using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using SundaySchoolServerManager;

// The child stands in for the API; PostgreSQL startup/shutdown use real binaries
// and a new temporary cluster. No installed database or ports are touched.
if (Process.GetCurrentProcess().ProcessName == "SundaySchool.SyncServer")
{
    var listener = new TcpListener(IPAddress.Loopback, int.Parse(Environment.GetEnvironmentVariable("PORT")!));
    listener.Start();
    while (true)
    {
        using var client = await listener.AcceptTcpClientAsync();
        using var stream = client.GetStream();
        var buffer = new byte[4096];
        await stream.ReadAsync(buffer);
        const string body = "{\"status\":\"ok\"}";
        await stream.WriteAsync(Encoding.ASCII.GetBytes(
            $"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {body.Length}\r\nConnection: close\r\n\r\n{body}"));
    }
}

if (args.Length != 1) throw new ArgumentException("Pass the PostgreSQL distribution directory (containing bin).");
var root = Path.Combine(Path.GetTempPath(), "SundaySchool supervisor test " + Guid.NewGuid().ToString("N"));
var pgRoot = Path.Combine(root, "Server", "postgresql");
var backendRoot = Path.Combine(root, "Server", "backend");
Directory.CreateDirectory(backendRoot);
// Junctions do not require the developer-mode privilege needed by symlinks.
var junction = new ProcessStartInfo("cmd.exe") { UseShellExecute = false, CreateNoWindow = true };
foreach (var arg in new[] { "/c", "mklink", "/J", pgRoot, Path.GetFullPath(args[0]) }) junction.ArgumentList.Add(arg);
using (var process = Process.Start(junction)!)
{
    await process.WaitForExitAsync();
    if (process.ExitCode != 0) throw new Exception("Could not create test PostgreSQL junction.");
}
foreach (var source in Directory.GetFiles(AppContext.BaseDirectory))
    File.Copy(source, Path.Combine(backendRoot, Path.GetFileName(source)));
File.Copy(Environment.ProcessPath!, Path.Combine(backendRoot, "SundaySchool.SyncServer.exe"));

int FreePort()
{
    var listener = new TcpListener(IPAddress.Loopback, 0);
    listener.Start();
    var port = ((IPEndPoint)listener.LocalEndpoint).Port;
    listener.Stop();
    return port;
}
var apiPort = FreePort();
var databasePort = FreePort();
while (apiPort == databasePort) databasePort = FreePort();
var data = Path.Combine(root, "SundaySchool_ServerData", "postgres-data");
async Task PgCtl(params string[] arguments)
{
    var start = new ProcessStartInfo(Path.Combine(pgRoot, "bin", "pg_ctl.exe"))
        { UseShellExecute = false, CreateNoWindow = true };
    foreach (var arg in arguments) start.ArgumentList.Add(arg);
    using var process = Process.Start(start)!;
    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(70));
    await process.WaitForExitAsync(timeout.Token);
    if (process.ExitCode != 0) throw new Exception($"pg_ctl failed: {process.ExitCode}");
}
void Assert(bool condition, string message)
{
    if (!condition) throw new Exception(message + "; logs: " + root);
    Console.WriteLine("PASS: " + message);
}

using var supervisor = new ServerSupervisor(root, apiPort, databasePort);
ServerState lastState = ServerState.Stopped;
supervisor.StatusChanged += (_, status) => lastState = status.State;
try
{
    await supervisor.StartAsync();
    Assert(lastState == ServerState.Running && await supervisor.IsHealthyAsync(), "fresh cluster starts before API");

    var pidFile = Path.Combine(data, "postmaster.pid");
    var originalPid = File.ReadLines(pidFile).First();
    using (var observer = new ServerSupervisor(root, apiPort, databasePort)) { }
    Assert(File.Exists(pidFile) && File.ReadLines(pidFile).First() == originalPid,
        "closing a tunnels-only observer leaves PostgreSQL running");
    await PgCtl("status", "-D", data);

    for (var i = 0; i < 3; i++)
    {
        await supervisor.RestartAsync();
        Assert(lastState == ServerState.Running && await supervisor.IsHealthyAsync(), $"clean restart {i + 1}");
    }
    await supervisor.StopAsync();
    Assert(lastState == ServerState.Stopped && !File.Exists(pidFile), "stop waits for PostgreSQL lock removal");

    // A power loss can leave the lock file behind, including a PID reused by
    // an unrelated process after Windows restarts.
    await File.WriteAllTextAsync(pidFile, $"{Environment.ProcessId}\n{data}\n0\n{databasePort}\n");
    await supervisor.StartAsync();
    Assert(lastState == ServerState.Running && await supervisor.IsHealthyAsync(),
        "startup recovers a stale postmaster PID reused by a different executable");
    await supervisor.StopAsync();

    // Reproduce a database that dies after readiness but before API readiness.
    EventHandler<ServerStatusEventArgs> stopDuringStartup = (_, status) =>
    {
        if (status.State == ServerState.Starting && status.Message.Contains(".NET"))
            PgCtl("stop", "-D", data, "-m", "fast", "-w", "-t", "60").GetAwaiter().GetResult();
    };
    supervisor.StatusChanged += stopDuringStartup;
    var elapsed = Stopwatch.StartNew();
    await supervisor.StartAsync();
    supervisor.StatusChanged -= stopDuringStartup;
    await supervisor.StopAsync(); // Disarm automatic recovery before assertions.
    Assert(elapsed.Elapsed < TimeSpan.FromSeconds(30) && !await supervisor.IsHealthyAsync(),
        "database loss during startup fails promptly and stops the API");
    var log = await File.ReadAllTextAsync(supervisor.ManagerLogPath);
    Assert(log.Contains("Failed:") && log.Contains("توقف PostgreSQL"), "failure reports the PostgreSQL cause");
    Assert(!log.Contains("lock file \"postmaster.pid\" already exists"), "restarts never race a previous postmaster");
}
finally
{
    await supervisor.StopAsync();
    // Leave the small temporary cluster and logs available for diagnosis.
    Console.WriteLine("Test artifacts: " + root);
}
