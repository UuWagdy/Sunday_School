namespace DaissonTunnelManager;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length == 1 && args[0] == "--service")
        {
            try { ServiceHost.Dispatch(); return 0; } catch { return 1; }
        }
        ApplicationConfiguration.Initialize();
        if (args.Length == 1 && args[0] == "--self-test")
        {
            try { using var form = new MainForm(false); form.CreateControl(); return form.IsHandleCreated ? 0 : 1; }
            catch { return 1; }
        }
        try
        {
            if (args.Length == 2 && args[0] == "--install-connector") { ConnectorService.Install(args[1]).GetAwaiter().GetResult(); return 0; }
            if (args.Length == 2 && args[0] == "--connector-control") { ConnectorService.Control(args[1]).GetAwaiter().GetResult(); return 0; }
            if (args.Length != 0) throw new InvalidOperationException("خيارات التشغيل غير صحيحة.");
            using var mutex = new Mutex(true, @"Local\DaissonTunnelManagerUI", out var first);
            if (!first) { MessageBox.Show("مدير الأنفاق مفتوح بالفعل. استخدم نافذته الحالية.", "Daisson"); return 0; }
            Application.Run(new MainForm());
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "Daisson Tunnel Manager", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
