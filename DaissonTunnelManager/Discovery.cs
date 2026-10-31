using System.Diagnostics;
using System.Net.NetworkInformation;
using System.Text.RegularExpressions;
using Microsoft.Win32;

namespace DaissonTunnelManager;

public static class Discovery
{
    public static List<LocalRoute> Scan(string? extraFolder = null)
    {
        var roots = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var drive in DriveInfo.GetDrives().Where(d => d.IsReady && d.DriveType == DriveType.Fixed))
            foreach (var folder in new[] { "Sunday School", "AbonaFlemoon" })
                roots.Add(Path.Combine(drive.RootDirectory.FullName, folder));
        foreach (var view in new[] { RegistryView.Registry64, RegistryView.Registry32 })
        {
            using var registry = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, view);
            using var uninstall = registry.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall");
            foreach (var key in uninstall?.GetSubKeyNames() ?? [])
            {
                using var entry = uninstall!.OpenSubKey(key);
                if (entry?.GetValue("InstallLocation") is string location && location.Length > 0) roots.Add(location);
            }
        }
        foreach (var process in Process.GetProcesses())
        {
            using (process)
                try
                {
                    if (process.ProcessName.Contains("ServerManager", StringComparison.OrdinalIgnoreCase) && process.MainModule?.FileName is string path)
                        roots.Add(Path.GetDirectoryName(Path.GetDirectoryName(path)!)!);
                }
                catch (Exception ex) when (ex is System.ComponentModel.Win32Exception or InvalidOperationException or NotSupportedException) { }
        }
        if (extraFolder is not null) roots.Add(Path.GetFullPath(extraFolder));
        List<LocalRoute> found = [];
        var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var root in roots)
            foreach (var dir in Walk(root, 2, visited))
            {
                var file = Path.Combine(dir, "SERVER_INFO.txt");
                if (!File.Exists(file)) continue;
                try
                {
                    if (new FileInfo(file).Length > 65536) continue;
                    var text = File.ReadAllText(file);
                    var match = Regex.Match(text, @"(?im)^\s*Local_?URL\s*[:=]\s*(https?://[^\s]+)");
                    if (!match.Success) continue;
                    var origin = Validation.Origin(match.Groups[1].Value);
                    if (found.Any(r => r.Origin == origin)) continue;
                    var managerDir = Path.Combine(dir, "ServerManager");
                    var manager = Directory.Exists(managerDir) ? Directory.GetFiles(managerDir, "*ServerManager.exe").FirstOrDefault() ?? "" : "";
                    var port = new Uri(origin).Port;
                    found.Add(new LocalRoute { Name = port == 5050 ? "مدارس الأحد" : port == 5060 ? "العضوية الكنسية" : new DirectoryInfo(dir).Name,
                        Subdomain = port == 5050 ? "sunday" : port == 5060 ? "membership" : "app" + port,
                        Origin = origin, ManagerPath = manager,
                        Note = port == 5060 ? "API العضوية الحالية بلا مصادقة؛ أضف الحماية قبل النشر" : port == 5050 ? "اضبط Jwt:Secret الخاص بالسيرفر قبل النشر" : "تحقق من مصادقة وصلاحيات API قبل النشر" });
                }
                catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or InvalidOperationException) { }
            }
        return found;
    }
    private static IEnumerable<string> Walk(string root, int depth, HashSet<string> visited)
    {
        if (visited.Count >= 1500 || !Directory.Exists(root) || !visited.Add(root)) yield break;
        string[] children;
        try
        {
            if ((File.GetAttributes(root) & FileAttributes.ReparsePoint) != 0) yield break;
            children = depth > 0 ? Directory.GetDirectories(root).Take(150).ToArray() : [];
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { yield break; }
        yield return root;
        foreach (var child in children)
            foreach (var dir in Walk(child, depth - 1, visited)) yield return dir;
    }
    public static string Listeners() => string.Join(", ", IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners()
        .Select(e => e.Port).Distinct().OrderBy(p => p));
    public static async Task<bool> Reachable(string origin, CancellationToken ct = default)
    {
        using var handler = new HttpClientHandler { AllowAutoRedirect = false, UseProxy = false };
        using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(3) };
        try
        {
            using var response = await client.GetAsync(Validation.Origin(origin) + "/health", HttpCompletionOption.ResponseHeadersRead, ct);
            return true; // Any HTTP status proves the local HTTP server is reachable; it does not prove authentication.
        }
        catch (HttpRequestException) { return false; }
        catch (TaskCanceledException) when (!ct.IsCancellationRequested) { return false; }
    }
}
