using System.Reflection;
using System.Runtime.CompilerServices;

internal static class Program
{
    [STAThread]
    private static void Main(string[] assemblies)
    {
        ApplicationConfiguration.Initialize();
        foreach (var path in assemblies)
        {
            var assembly = Assembly.LoadFrom(Path.GetFullPath(path));
            var ns = assembly.GetName().Name!;
            var supervisorType = assembly.GetType(ns + ".ServerSupervisor")!;
            var tunnelType = assembly.GetType(ns + ".TunnelSupervisor")!;
            var formType = assembly.GetType(ns + ".TunnelManagerForm")!;
            // No supervisor constructor: no watchdog, PID files, or installed
            // database processes are touched by this UI lifecycle test.
            var supervisor = RuntimeHelpers.GetUninitializedObject(supervisorType);
            var root = Path.Combine(Path.GetTempPath(), "manager-lifecycle-" + Guid.NewGuid().ToString("N"));
            using var tunnel = (IDisposable)Activator.CreateInstance(tunnelType, root)!;
            void Raise(string name, object value) =>
                ((MulticastDelegate?)tunnelType.GetField(name, BindingFlags.NonPublic | BindingFlags.Instance)!
                    .GetValue(tunnel))?.DynamicInvoke(tunnel, value);

            for (var i = 0; i < 3; i++)
            {
                var form = (Form)Activator.CreateInstance(formType, tunnel, supervisor)!;
                Raise("LogReceived", "test before ShowDialog");
                var background = Task.Run(() =>
                {
                    Raise("StatusChanged", false);
                    Raise("UrlDetected", "https://example.invalid");
                });
                background.GetAwaiter().GetResult();
                form.Dispose();
                // Pending callbacks and later broadcasts must tolerate disposal.
                Application.DoEvents();
                Raise("LogReceived", "test after disposal");
                foreach (var name in new[] { "UrlDetected", "StatusChanged", "LogReceived" })
                    if (tunnelType.GetField(name, BindingFlags.NonPublic | BindingFlags.Instance)!.GetValue(tunnel) != null)
                        throw new Exception("Disposed form still subscribes to " + name);
            }
            Console.WriteLine(ns + ": PASS (before show, background callbacks, disposal, reopen x3)");
        }
    }
}
