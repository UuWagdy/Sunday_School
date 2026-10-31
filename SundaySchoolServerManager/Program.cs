using System.Threading;

namespace SundaySchoolServerManager;

internal static class Program
{
    private const string MutexName = "SundaySchool_ServerManager_5050_v1";

    [STAThread]
    private static void Main(string[] args)
    {
        var onlyTunnels = args.Any(value =>
            value.Equals("--tunnels", StringComparison.OrdinalIgnoreCase));
        if (onlyTunnels)
        {
            ApplicationConfiguration.Initialize();
            var root = ResolveInstallRoot(args);
            using var serverSup = new ServerSupervisor(root);
            using var tunnelSup = new TunnelSupervisor(root);
            using var form = new TunnelManagerForm(tunnelSup, serverSup);
            Application.Run(form);
            return;
        }

        var background = args.Any(value =>
            value.Equals("--background", StringComparison.OrdinalIgnoreCase));

        using var mutex = new Mutex(true, MutexName, out var isFirstInstance);
        if (!isFirstInstance)
        {
            if (!background)
            {
                MessageBox.Show(
                    "مدير سيرفر مدارس الأحد يعمل بالفعل بجانب الساعة.",
                    "مدير السيرفر",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            return;
        }

        ApplicationConfiguration.Initialize();
        var installRoot = ResolveInstallRoot(args);
        using var supervisor = new ServerSupervisor(installRoot);
        using var window = new MainForm(supervisor, background);
        Application.Run(window);
    }

    private static string ResolveInstallRoot(string[] args)
    {
        for (var index = 0; index < args.Length - 1; index++)
        {
            if (args[index].Equals("--install-root", StringComparison.OrdinalIgnoreCase))
            {
                return Path.GetFullPath(args[index + 1]);
            }
        }

        var executableDirectory = AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
        if (Directory.Exists(Path.Combine(executableDirectory, "Server")))
        {
            return executableDirectory;
        }

        var parent = Directory.GetParent(executableDirectory)?.FullName;
        if (parent is not null && Directory.Exists(Path.Combine(parent, "Server")))
        {
            return parent;
        }

        // Check dev workspace root (bin/Release/net8.0-windows -> ../../../..)
        var current = new DirectoryInfo(executableDirectory);
        for (int i = 0; i < 5 && current is not null; i++)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "SundaySchool.SyncServer")) ||
                File.Exists(Path.Combine(current.FullName, "pubspec.yaml")))
            {
                return current.FullName;
            }
            current = current.Parent;
        }

        return executableDirectory;
    }
}
