using System.Threading;

namespace SundaySchoolServerManager;

internal static class Program
{
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
        var apiPort = ReadPort(args, "--api-port", ServerSupervisor.ApiPort);
        var databasePort = ReadPort(args, "--database-port", ServerSupervisor.DatabasePort);

        using var activation = new EventWaitHandle(false, EventResetMode.AutoReset, $"SundaySchool_ServerManager_Activate_{apiPort}_v1");
        using var mutex = new Mutex(true, $"SundaySchool_ServerManager_{apiPort}_v1", out var isFirstInstance);
        if (!isFirstInstance)
        {
            if (!background)
            {
                activation.Set();
            }
            return;
        }

        ApplicationConfiguration.Initialize();
        var installRoot = ResolveInstallRoot(args);
        using var supervisor = new ServerSupervisor(installRoot, apiPort, databasePort);
        using var window = new MainForm(supervisor, background);
        var registration = ThreadPool.RegisterWaitForSingleObject(activation, (_, _) =>
        {
            try
            {
                if (!window.IsDisposed)
                    window.BeginInvoke(new Action(window.ShowWindow));
            }
            catch (InvalidOperationException) { /* Window is closing. */ }
        }, null, Timeout.Infinite, false);
        try { Application.Run(window); }
        finally { registration.Unregister(null); }
    }

    private static int ReadPort(string[] args, string option, int fallback)
    {
        var index = Array.FindIndex(args, value => value.Equals(option, StringComparison.OrdinalIgnoreCase));
        if (index < 0) return fallback;
        if (index + 1 < args.Length && int.TryParse(args[index + 1], out var port) && port is > 0 and <= 65535)
            return port;
        throw new ArgumentException($"Invalid port for {option}.");
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
