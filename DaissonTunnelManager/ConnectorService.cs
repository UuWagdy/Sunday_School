using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Win32;

namespace DaissonTunnelManager;

public sealed record ConnectorEntry(Guid ProfileId, string TunnelId, string Token);
public sealed class ConnectorConfig
{
    public string BinaryHash { get; set; } = "";
    public List<ConnectorEntry> Entries { get; set; } = [];
}
public sealed record InstallRequest(ConnectorEntry Entry, string BinaryPath, string ReleaseTag, bool Remove = false);
public sealed record BinaryDownload(string Path, string ReleaseTag);

public static class ConnectorService
{
    public const string Name = "DaissonTunnelConnector";
    public static string ServiceRoot => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Daisson Tunnel Manager", "Service");
    public static string DataRoot => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "DaissonTunnelManager");
    public static string ConfigPath => Path.Combine(DataRoot, "connectors.bin");
    private static string Sc => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "sc.exe");
    public static ProcessStartInfo ChildStart(string exe, string token)
    {
        var start = new ProcessStartInfo(exe) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardError = true, RedirectStandardOutput = true, WorkingDirectory = Path.GetDirectoryName(Path.GetFullPath(exe))! };
        foreach (var arg in new[] { "tunnel", "--config", Path.Combine(ServiceRoot, "connector.yml"), "--no-autoupdate", "--metrics", "127.0.0.1:0", "--loglevel", "error", "run" }) start.ArgumentList.Add(arg);
        foreach (var key in start.Environment.Keys.Where(k => k.StartsWith("TUNNEL_", StringComparison.OrdinalIgnoreCase)).ToArray()) start.Environment.Remove(key);
        start.Environment["TUNNEL_TOKEN"] = token;
        return start;
    }
    private static HttpClient DownloadClient()
    {
        var http = new HttpClient { Timeout = TimeSpan.FromMinutes(4) };
        http.DefaultRequestHeaders.UserAgent.ParseAdd("DaissonTunnelManager/1.0");
        return http;
    }
    private static async Task<(string Url, string Digest, string Tag)> Release(HttpClient http, string? tag, CancellationToken ct)
    {
        if (tag is not null && !System.Text.RegularExpressions.Regex.IsMatch(tag, @"^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,3}$")) throw new InvalidOperationException("إصدار cloudflared غير صحيح.");
        var url = "https://api.github.com/repos/cloudflare/cloudflared/releases/" + (tag is null ? "latest" : "tags/" + tag);
        var json = JsonNodeHelper.Parse(await http.GetStringAsync(url, ct));
        var asset = json["assets"]!.AsArray().Single(a => a?["name"]?.GetValue<string>() == "cloudflared-windows-amd64.exe")!;
        var download = asset["browser_download_url"]!.GetValue<string>();
        var digest = asset["digest"]?.GetValue<string>() ?? "";
        if (!download.StartsWith("https://github.com/cloudflare/cloudflared/releases/download/", StringComparison.Ordinal) || !System.Text.RegularExpressions.Regex.IsMatch(digest, "^sha256:[a-fA-F0-9]{64}$"))
            throw new InvalidOperationException("لم يتوفر بصمة رسمية للملف. تم إيقاف التنزيل.");
        return (download, digest[7..], json["tag_name"]!.GetValue<string>());
    }
    public static async Task<BinaryDownload> Download(CancellationToken ct)
    {
        using var http = DownloadClient();
        var release = await Release(http, null, ct);
        var dir = Path.Combine(ProfileStore.Root, "downloads", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var file = Path.Combine(dir, "cloudflared.exe");
        try
        {
            using var response = await http.GetAsync(release.Url, HttpCompletionOption.ResponseHeadersRead, ct);
            response.EnsureSuccessStatusCode();
            await using var stream = await response.Content.ReadAsStreamAsync(ct);
            await using (var target = File.Create(file))
            {
                var buffer = new byte[65536];
                int count;
                long size = 0;
                while ((count = await stream.ReadAsync(buffer, ct)) > 0)
                {
                    if ((size += count) > 160 * 1024 * 1024) throw new InvalidOperationException("حجم cloudflared غير متوقع.");
                    await target.WriteAsync(buffer.AsMemory(0, count), ct);
                }
            }
            if (!Hash(file).Equals(release.Digest, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("بصمة التنزيل لا تطابق الإصدار الرسمي.");
            return new BinaryDownload(file, release.Tag);
        }
        catch { if (File.Exists(file)) File.Delete(file); throw; }
    }
    public static string Hash(string file) { using var stream = File.OpenRead(file); return Convert.ToHexString(SHA256.HashData(stream)); }
    public static async Task Elevate(InstallRequest request)
    {
        Directory.CreateDirectory(ProfileStore.Root);
        var path = Path.Combine(ProfileStore.Root, "request-" + Guid.NewGuid().ToString("N") + ".bin");
        SecretFile.Write(path, JsonSerializer.Serialize(request));
        try
        {
            var start = new ProcessStartInfo(Environment.ProcessPath!) { UseShellExecute = true, Verb = "runas" };
            start.ArgumentList.Add("--install-connector"); start.ArgumentList.Add(path);
            using var process = Process.Start(start) ?? throw new InvalidOperationException("تعذر تشغيل مساعد التثبيت.");
            await process.WaitForExitAsync();
            if (process.ExitCode != 0) throw new InvalidOperationException("لم يكتمل تثبيت الموصل. يعرض مساعد المسؤول سبب الفشل. إذا استخدمت حساب مسؤول مختلفًا، شغّل البرنامج نفسه بهذا الحساب وأدخل بياناته من جديد.");
        }
        finally { if (File.Exists(path)) File.Delete(path); }
    }
    private static void SecureDirectory(string path)
    {
        // Reject junctions before writing an executable or machine-scoped secrets as SYSTEM.
        for (var directory = new DirectoryInfo(path); directory is not null; directory = directory.Parent)
            if (directory.Exists && (directory.Attributes & FileAttributes.ReparsePoint) != 0) throw new InvalidOperationException("مسار التثبيت يحتوي رابطًا بديلًا؛ أوقف التثبيت.");
        Directory.CreateDirectory(path);
        var security = new DirectorySecurity();
        security.SetAccessRuleProtection(true, false);
        security.SetOwner(new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null));
        foreach (var sid in new[] { WellKnownSidType.LocalSystemSid, WellKnownSidType.BuiltinAdministratorsSid })
            security.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(sid, null), FileSystemRights.FullControl, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
        new DirectoryInfo(path).SetAccessControl(security);
        foreach (var entry in Directory.GetFileSystemEntries(path))
        {
            if ((File.GetAttributes(entry) & FileAttributes.ReparsePoint) != 0 || Directory.Exists(entry))
                throw new InvalidOperationException("مجلد الخدمة يحتوي عنصرًا غير متوقع. راجعه قبل التثبيت.");
            var fileSecurity = new FileSecurity();
            fileSecurity.SetAccessRuleProtection(true, false);
            fileSecurity.SetOwner(new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null));
            foreach (var sid in new[] { WellKnownSidType.LocalSystemSid, WellKnownSidType.BuiltinAdministratorsSid })
                fileSecurity.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(sid, null), FileSystemRights.FullControl, AccessControlType.Allow));
            new FileInfo(entry).SetAccessControl(fileSecurity);
        }
    }
    private static async Task<int> Command(params string[] args)
    {
        using var process = new Process { StartInfo = new ProcessStartInfo(Sc) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true } };
        foreach (var arg in args) process.StartInfo.ArgumentList.Add(arg);
        process.Start();
        var stdout = process.StandardOutput.ReadToEndAsync(); var stderr = process.StandardError.ReadToEndAsync();
        await process.WaitForExitAsync(); await Task.WhenAll(stdout, stderr);
        return process.ExitCode;
    }
    private static void VerifyOwnedService()
    {
        using var key = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\" + Name);
        if (key is null) return;
        var expected = "\"" + Path.Combine(ServiceRoot, "DaissonTunnelManager.exe") + "\" --service";
        if (!string.Equals(key.GetValue("ImagePath") as string, expected, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("اسم خدمة Daisson مستخدم بواسطة مسار آخر. لم يتم تغييره.");
    }
    public static async Task Install(string requestFile)
    {
        using var identity = WindowsIdentity.GetCurrent();
        if (!new WindowsPrincipal(identity).IsInRole(WindowsBuiltInRole.Administrator)) throw new InvalidOperationException("يلزم تشغيل مساعد التثبيت كمسؤول.");
        VerifyOwnedService();
        SecureDirectory(ServiceRoot); SecureDirectory(DataRoot);
        // File sharing locks survive async thread switches; an OS mutex is thread-affine.
        using var installLock = new FileStream(Path.Combine(DataRoot, "install.lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
        {
            var request = JsonSerializer.Deserialize<InstallRequest>(SecretFile.Read(requestFile)) ?? throw new InvalidOperationException("طلب غير صحيح.");
            if (new FileInfo(Environment.ProcessPath!).Length < 10 * 1024 * 1024)
                throw new InvalidOperationException("تثبيت الخدمة يحتاج النسخة المنشورة المستقلة DaissonTunnelManager.exe، وليس ملف تشغيل البناء التجريبي.");
            var config = File.Exists(ConfigPath) ? JsonSerializer.Deserialize<ConnectorConfig>(SecretFile.Read(ConfigPath))! : new ConnectorConfig();
            var previous = JsonSerializer.Serialize(config);
            config.Entries.RemoveAll(e => e.ProfileId == request.Entry.ProfileId);
            if (!request.Remove)
            {
                Validation.Id(request.Entry.TunnelId);
                if (request.Entry.Token.Length < 40 || request.Entry.Token.Any(char.IsWhiteSpace)) throw new InvalidOperationException("توكن النفق غير صالح.");
                if (config.Entries.Any(e => e.TunnelId == request.Entry.TunnelId)) throw new InvalidOperationException("هذا النفق مضاف بالفعل لعميل آخر على نفس الجهاز.");
                // Reverify the cached download with the official release manifest inside the elevated helper.
                using var http = DownloadClient();
                var release = await Release(http, request.ReleaseTag, CancellationToken.None);
                if (!Hash(request.BinaryPath).Equals(release.Digest, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("بصمة ملف الموصل لا تطابق Cloudflare.");
                config.Entries.Add(request.Entry);
                config.BinaryHash = release.Digest;
            }
            var priorState = ServiceHost.State(Name);
            var existed = priorState != 0;
            var shouldStart = config.Entries.Count > 0 && (!request.Remove || priorState == 4);
            var files = new[] { Path.Combine(ServiceRoot, "DaissonTunnelManager.exe"), Path.Combine(ServiceRoot, "cloudflared.exe") };
            foreach (var file in files) if (File.Exists(file)) File.Copy(file, file + ".rollback", true);
            if (existed) await StopOwned();
            try
            {
                var executable = Path.Combine(ServiceRoot, "DaissonTunnelManager.exe");
                var current = Environment.ProcessPath!;
                if (!current.Equals(executable, StringComparison.OrdinalIgnoreCase)) File.Copy(current, executable, true);
                if (!request.Remove)
                {
                    var target = Path.Combine(ServiceRoot, "cloudflared.exe");
                    File.Copy(request.BinaryPath, target + ".new", true);
                    if (!Hash(target + ".new").Equals(config.BinaryHash, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("تغيّر الملف أثناء النسخ.");
                    File.Move(target + ".new", target, true);
                }
                SecretFile.Write(ConfigPath, JsonSerializer.Serialize(config), true);
                File.WriteAllText(Path.Combine(ServiceRoot, "connector.yml"), "{}\r\n");
                if (!existed && await Command("create", Name, "binPath=", $"\"{executable}\" --service", "start=", "delayed-auto", "DisplayName=", "Daisson Multi Tunnel Connector") != 0)
                    throw new InvalidOperationException("تعذر إنشاء خدمة الموصل.");
                if (await Command("failure", Name, "reset=", "86400", "actions=", "restart/5000/restart/15000/restart/60000") != 0)
                    throw new InvalidOperationException("تعذر ضبط إعادة تشغيل الخدمة.");
                if (await Command("failureflag", Name, "1") != 0) throw new InvalidOperationException("تعذر ضبط استعادة الخدمة بعد الفشل.");
                if (shouldStart && await Command("start", Name) != 0) throw new InvalidOperationException("تعذر تشغيل الخدمة.");
                if (shouldStart) await WaitState(4);
                foreach (var file in files) if (File.Exists(file + ".rollback")) File.Delete(file + ".rollback");
            }
            catch
            {
                // Configuration rollback retains previously registered customer connectors.
                if (ServiceHost.State(Name) is not (0 or 1)) await StopOwned();
                foreach (var file in files) if (File.Exists(file + ".rollback")) File.Move(file + ".rollback", file, true);
                SecretFile.Write(ConfigPath, previous, true);
                if (priorState == 4) await Command("start", Name);
                throw;
            }
        }
    }
    private static async Task WaitState(int desired)
    {
        for (var attempt = 0; attempt < 60; attempt++)
        {
            if (ServiceHost.State(Name) == desired) return;
            await Task.Delay(500);
        }
        throw new InvalidOperationException("انتهت مهلة انتظار خدمة الموصل.");
    }
    private static async Task StopOwned()
    {
        VerifyOwnedService();
        if (ServiceHost.State(Name) == 1) return;
        if (await Command("stop", Name) != 0 && ServiceHost.State(Name) != 3) throw new InvalidOperationException("تعذر إيقاف موصل Daisson للتحديث.");
        await WaitState(1);
    }
    public static async Task Control(string action)
    {
        if (action is not ("start" or "stop")) throw new InvalidOperationException("عملية غير صحيحة.");
        VerifyOwnedService();
        if (action == "stop") await StopOwned();
        else if (ServiceHost.State(Name) != 4)
        {
            if (await Command("start", Name) != 0) throw new InvalidOperationException("تعذر تشغيل خدمة Daisson.");
            await WaitState(4);
        }
    }
    public static async Task ControlElevated(string action)
    {
        var start = new ProcessStartInfo(Environment.ProcessPath!) { UseShellExecute = true, Verb = "runas" };
        start.ArgumentList.Add("--connector-control"); start.ArgumentList.Add(action);
        using var p = Process.Start(start)!; await p.WaitForExitAsync();
        if (p.ExitCode != 0) throw new InvalidOperationException("لم تكتمل عملية خدمة Daisson.");
    }
    private static void Log(string message)
    {
        try
        {
            var file = Path.Combine(DataRoot, "service.log");
            if (File.Exists(file) && new FileInfo(file).Length > 1024 * 1024) File.Move(file, file + ".previous", true);
            File.AppendAllText(file, $"{DateTime.UtcNow:O} {message}\r\n");
        }
        catch (IOException) { }
    }
    public static async Task Run(CancellationToken ct)
    {
        var config = JsonSerializer.Deserialize<ConnectorConfig>(SecretFile.Read(ConfigPath)) ?? throw new InvalidOperationException("Missing configuration");
        var exe = Path.Combine(ServiceRoot, "cloudflared.exe");
        if (config.Entries.Count == 0) { await Task.Delay(Timeout.Infinite, ct); return; }
        if (!Hash(exe).Equals(config.BinaryHash, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Connector hash mismatch");
        await RunEntries(exe, config.Entries, ct, Log);
    }
    internal static async Task RunEntries(string exe, List<ConnectorEntry> entries, CancellationToken ct, Action<string> log)
    {
        await Task.WhenAll(entries.Select(async entry =>
        {
            var delay = 2;
            while (!ct.IsCancellationRequested)
            {
                using var process = new Process { StartInfo = ChildStart(exe, entry.Token) };
                using var job = new ChildJob();
                try
                {
                    process.Start();
                    try { job.Assign(process); }
                    catch { if (!process.HasExited) process.Kill(true); throw; }
                    // Drain output without persisting potentially sensitive URLs, headers, or tokens.
                    var stdout = process.StandardOutput.BaseStream.CopyToAsync(Stream.Null);
                    var stderr = process.StandardError.BaseStream.CopyToAsync(Stream.Null);
                    log($"Started tunnel {entry.TunnelId}");
                    try { await process.WaitForExitAsync(ct); }
                    finally
                    {
                        if (!process.HasExited) { process.Kill(true); await process.WaitForExitAsync(); }
                        await Task.WhenAll(stdout, stderr);
                    }
                    log($"Tunnel {entry.TunnelId} exited: {process.ExitCode}");
                }
                catch (OperationCanceledException) when (ct.IsCancellationRequested) { break; }
                catch { log($"Tunnel {entry.TunnelId} process failure"); }
                try { await Task.Delay(TimeSpan.FromSeconds(delay), ct); } catch (OperationCanceledException) { break; }
                delay = Math.Min(delay * 2, 30);
            }
        }));
    }
}

internal sealed class ChildJob : IDisposable
{
    [StructLayout(LayoutKind.Sequential)] private struct BasicLimits { public long ProcessTime, JobTime; public uint Flags; public nuint MinWorking, MaxWorking; public uint ActiveProcesses; public nuint Affinity; public uint Priority, Scheduling; }
    [StructLayout(LayoutKind.Sequential)] private struct IoCounters { public ulong ReadOps, WriteOps, OtherOps, ReadBytes, WriteBytes, OtherBytes; }
    [StructLayout(LayoutKind.Sequential)] private struct Limits { public BasicLimits Basic; public IoCounters Io; public nuint ProcessMemory, JobMemory, PeakProcess, PeakJob; }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] private static extern IntPtr CreateJobObject(IntPtr security, string? name);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool SetInformationJobObject(IntPtr handle, int infoClass, ref Limits info, int length);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool AssignProcessToJobObject(IntPtr handle, IntPtr process);
    [DllImport("kernel32.dll")] private static extern bool CloseHandle(IntPtr handle);
    private IntPtr handle;
    public ChildJob()
    {
        handle = CreateJobObject(IntPtr.Zero, null);
        if (handle == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        var limits = new Limits { Basic = new BasicLimits { Flags = 0x2000 } }; // Kill children even if the wrapper crashes.
        if (!SetInformationJobObject(handle, 9, ref limits, Marshal.SizeOf<Limits>())) { Dispose(); throw new Win32Exception(Marshal.GetLastWin32Error()); }
    }
    public void Assign(Process process) { if (!AssignProcessToJobObject(handle, process.Handle)) throw new Win32Exception(Marshal.GetLastWin32Error()); }
    public void Dispose() { if (handle != IntPtr.Zero) { CloseHandle(handle); handle = IntPtr.Zero; } }
}

public static class ServiceHost
{
    [StructLayout(LayoutKind.Sequential)] private struct Status { public int Type, State, Accepted, ExitCode, Specific, Checkpoint, WaitHint; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] private struct Table { [MarshalAs(UnmanagedType.LPWStr)] public string? Name; public MainDelegate? Main; }
    [UnmanagedFunctionPointer(CallingConvention.Winapi)] private delegate void MainDelegate(int argc, IntPtr argv);
    [UnmanagedFunctionPointer(CallingConvention.Winapi)] private delegate void HandlerDelegate(int control);
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] private static extern bool StartServiceCtrlDispatcher([In] Table[] table);
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] private static extern IntPtr RegisterServiceCtrlHandler(string name, HandlerDelegate handler);
    [DllImport("advapi32.dll")] private static extern bool SetServiceStatus(IntPtr handle, ref Status status);
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode)] private static extern IntPtr OpenSCManager(string? machine, string? database, int access);
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode)] private static extern IntPtr OpenService(IntPtr manager, string name, int access);
    [DllImport("advapi32.dll")] private static extern bool QueryServiceStatus(IntPtr handle, out Status status);
    [DllImport("advapi32.dll")] private static extern bool CloseServiceHandle(IntPtr handle);
    public static int State(string name)
    {
        var manager = OpenSCManager(null, null, 1);
        if (manager == IntPtr.Zero) return 0;
        try
        {
            var handle = OpenService(manager, name, 4);
            if (handle == IntPtr.Zero) return 0;
            try { return QueryServiceStatus(handle, out var status) ? status.State : 0; }
            finally { CloseServiceHandle(handle); }
        }
        finally { CloseServiceHandle(manager); }
    }
    public static string Describe(string name) => State(name) switch { 0 => "غير مثبتة أو غير متاحة", 1 => "متوقفة", 2 => "تبدأ التشغيل", 3 => "تتوقف", 4 => "تعمل", _ => "انتقال" };
    private static readonly CancellationTokenSource Stop = new();
    private static IntPtr handle;
    private static readonly MainDelegate MainCallback = ServiceMain;
    private static readonly HandlerDelegate HandlerCallback = control => { if (control is 1 or 5) { Report(3); Stop.Cancel(); } };
    private static void Report(int state, int code = 0)
    {
        var status = new Status { Type = 0x10, State = state, Accepted = state == 4 ? 1 | 4 : 0, ExitCode = code, WaitHint = state is 2 or 3 ? 30000 : 0 };
        SetServiceStatus(handle, ref status);
    }
    private static void ServiceMain(int argc, IntPtr argv)
    {
        handle = RegisterServiceCtrlHandler(ConnectorService.Name, HandlerCallback);
        if (handle == IntPtr.Zero) return;
        Report(2);
        try { var task = ConnectorService.Run(Stop.Token); Report(4); task.GetAwaiter().GetResult(); Report(1); }
        catch (OperationCanceledException) when (Stop.IsCancellationRequested) { Report(1); }
        catch { Report(1, 1); }
    }
    public static void Dispatch()
    {
        if (!StartServiceCtrlDispatcher([new Table { Name = ConnectorService.Name, Main = MainCallback }, new Table()]))
            throw new Win32Exception(Marshal.GetLastWin32Error());
    }
}
