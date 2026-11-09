using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text.Json;

// Only accepts a newly staged build directory, never an installed database.
var root = Path.GetFullPath(args[0]);
var repository = Path.GetFullPath(args[1]);
if (!root.StartsWith(Path.Combine(repository, "build", "restart-verification") + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
    throw new ArgumentException("Use an isolated directory under build/restart-verification.");
int FreePort()
{
    var listener = new TcpListener(IPAddress.Loopback, 0);
    listener.Start();
    var port = ((IPEndPoint)listener.LocalEndpoint).Port;
    listener.Stop();
    return port;
}
var apiPort = FreePort();
var dbPort = FreePort();
while (apiPort == dbPort) dbPort = FreePort();
var managerExe = Path.Combine(root, "ServerManager", "SundaySchoolServerManager.exe");
var data = Path.Combine(root, "SundaySchool_ServerData");
var control = Path.Combine(root, "restart.request");
File.Delete(control);
Environment.SetEnvironmentVariable("DOTNET_ROOT", Path.Combine(root, "no-system-runtime"));
Environment.SetEnvironmentVariable("DOTNET_ROOT_X64", Path.Combine(root, "no-system-runtime"));
Environment.SetEnvironmentVariable("DOTNET_MULTILEVEL_LOOKUP", "0");
Environment.SetEnvironmentVariable("HTTP_PROXY", "http://127.0.0.1:1");
Environment.SetEnvironmentVariable("ALL_PROXY", "http://127.0.0.1:1");
Environment.SetEnvironmentVariable("NO_PROXY", "127.0.0.1,localhost");
Environment.SetEnvironmentVariable("BindLocalOnly", "true");
Process StartManager(bool background)
{
    var start = new ProcessStartInfo(managerExe) { WorkingDirectory = root, UseShellExecute = false, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
    foreach (var arg in new[] { "--install-root", root, "--api-port", apiPort.ToString(), "--database-port", dbPort.ToString() }) start.ArgumentList.Add(arg);
    if (background) start.ArgumentList.Add("--background");
    return Process.Start(start)!;
}
using var http = new HttpClient(new HttpClientHandler { UseProxy = false }) { Timeout = TimeSpan.FromSeconds(2) };
async Task WaitHealthy(Process process)
{
    var deadline = DateTime.UtcNow.AddMinutes(5);
    while (DateTime.UtcNow < deadline)
    {
        if (process.HasExited) throw new Exception("Manager exited: " + process.ExitCode);
        try
        {
            var response = await http.GetStringAsync($"http://127.0.0.1:{apiPort}/health");
            if (response.Contains("\"status\":\"ok\"") && response.Contains("SundaySchool.SyncServer")) return;
        }
        catch (HttpRequestException) { }
        catch (TaskCanceledException) { }
        await Task.Delay(500);
    }
    throw new Exception("Manager health timeout; logs: " + data);
}
void KillOwned(int pid)
{
    try
    {
        using var process = Process.GetProcessById(pid);
        var executable = process.MainModule!.FileName;
        if (!executable.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            throw new Exception("Refusing to stop a process outside the test root.");
        process.Kill(entireProcessTree: true);
        process.WaitForExit(15000);
    }
    catch (ArgumentException) { }
}
Process? manager = null;
Process? flutter = null;
try
{
    manager = StartManager(true);
    await WaitHealthy(manager);
    Console.WriteLine("PASS: actual self-contained Manager EXE starts PostgreSQL and backend in a path with spaces.");
    using (var second = StartManager(false))
        await second.WaitForExitAsync().WaitAsync(TimeSpan.FromSeconds(10));
    for (var i = 0; i < 30 && manager.MainWindowHandle == IntPtr.Zero; i++) { manager.Refresh(); await Task.Delay(200); }
    if (manager.MainWindowHandle == IntPtr.Zero || !Native.IsWindowVisible(manager.MainWindowHandle)) throw new Exception("Second launch did not show the running manager.");
    Native.PostMessage(manager.MainWindowHandle, 0x0010, IntPtr.Zero, IntPtr.Zero);
    await Task.Delay(500);
    if (manager.HasExited) throw new Exception("Closing the window stopped the manager.");
    Console.WriteLine("PASS: second launch shows existing manager; closing returns it to tray and keeps the server running.");
    using var packages = JsonDocument.Parse(File.ReadAllText(Path.Combine(repository, ".dart_tool", "package_config.json")));
    var flutterPackage = packages.RootElement.GetProperty("packages").EnumerateArray().Single(p => p.GetProperty("name").GetString() == "flutter");
    var flutterRoot = Directory.GetParent(new Uri(flutterPackage.GetProperty("rootUri").GetString()!).LocalPath.TrimEnd('/', '\\'))!.Parent!.FullName;
    var start = new ProcessStartInfo(Path.Combine(flutterRoot, "bin", "cache", "dart-sdk", "bin", "dart.exe")) { WorkingDirectory = repository, UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
    start.Environment["FLUTTER_ROOT"] = flutterRoot;
    foreach (var arg in new[] { Path.Combine(flutterRoot, "bin", "cache", "flutter_tools.snapshot"), "test", "--no-pub", "test/release_restart_remote_test.dart", "--reporter", "expanded", $"--dart-define=SYNC_TEST_URL=http://127.0.0.1:{apiPort}", $"--dart-define=SYNC_RESTART_CONTROL={control}" }) start.ArgumentList.Add(arg);
    flutter = Process.Start(start)!;
    flutter.OutputDataReceived += (_, e) => { if (e.Data != null) Console.WriteLine(e.Data); };
    flutter.ErrorDataReceived += (_, e) => { if (e.Data != null) Console.Error.WriteLine(e.Data); };
    flutter.BeginOutputReadLine(); flutter.BeginErrorReadLine();
    var deadline = DateTime.UtcNow.AddMinutes(8);
    var restarted = false;
    while (!flutter.HasExited && DateTime.UtcNow < deadline)
    {
        if (!restarted && File.Exists(control))
        {
            var backendPid = int.Parse(File.ReadAllText(Path.Combine(data, "backend-manager.pid")));
            var pgPid = int.Parse(File.ReadLines(Path.Combine(data, "postgres-data", "postmaster.pid")).First());
            KillOwned(manager.Id);
            KillOwned(backendPid);
            KillOwned(pgPid);
            manager.Dispose();
            manager = StartManager(true);
            await WaitHealthy(manager);
            restarted = true;
            Console.WriteLine("PASS: abrupt stop of all test processes and recovery through the actual Manager EXE.");
        }
        await Task.Delay(250);
    }
    if (!flutter.HasExited) { flutter.Kill(true); throw new Exception("Flutter integration test timeout."); }
    if (flutter.ExitCode != 0 || !restarted) throw new Exception("Restart/client integration test failed.");
    Console.WriteLine("PASS: packaged manager, persisted cards and attendance, two clients, reconnect and post-restart writes.");
}
catch (Exception exception)
{
    Console.Error.WriteLine(exception);
    Environment.ExitCode = 1;
}
finally
{
    if (flutter is { HasExited: false }) flutter.Kill(true);
    if (manager is { HasExited: false }) KillOwned(manager.Id);
    var backendPidPath = Path.Combine(data, "backend-manager.pid");
    if (File.Exists(backendPidPath)) KillOwned(int.Parse(File.ReadAllText(backendPidPath)));
    var pgCtl = new ProcessStartInfo(Path.Combine(root, "Server", "postgresql", "bin", "pg_ctl.exe")) { UseShellExecute = false, CreateNoWindow = true };
    foreach (var arg in new[] { "stop", "-D", Path.Combine(data, "postgres-data"), "-m", "fast", "-w", "-t", "60" }) pgCtl.ArgumentList.Add(arg);
    using var stop = Process.Start(pgCtl)!;
    await stop.WaitForExitAsync();
    manager?.Dispose(); flutter?.Dispose();
    Console.WriteLine("Isolated test artifacts: " + root);
}
internal static class Native
{
    [DllImport("user32.dll")] internal static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] internal static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
}
