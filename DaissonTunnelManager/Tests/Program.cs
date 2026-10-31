using System.Net;
using System.Net.Sockets;
using System.Text.Json;
using System.Text.Json.Nodes;
using DaissonTunnelManager;

internal static class Tests
{
    private const string Account = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private const string Zone = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    private const string Tunnel = "cccccccc-cccc-cccc-cccc-cccccccccccc";
    private static int count;
    private static void Check(bool condition, string name) { if (!condition) throw new Exception("FAILED: " + name); count++; Console.WriteLine("PASS " + name); }
    private static async Task Reject(Func<Task> action, string name)
    {
        try { await action(); } catch (InvalidOperationException) { Check(true, name); return; }
        throw new Exception("Expected rejection: " + name);
    }
    private static Task Reject(Action action, string name) => Reject(() => { action(); return Task.CompletedTask; }, name);
    private static CustomerProfile Profile() => new() { Name = "Customer", Domain = "example.com", ApiToken = "secret-api-token", AccountId = Account, ZoneId = Zone, TunnelId = Tunnel,
        Routes = [new LocalRoute { Publish = true, Protected = true, Name = "App", Subdomain = "app", Origin = "http://127.0.0.1:5050" }] };
    [STAThread]
    public static int Main(string[] args)
    {
        if (args.FirstOrDefault() == "--local-diagnostics")
        {
            foreach (var route in Discovery.Scan()) Console.WriteLine(JsonSerializer.Serialize(new { route.Name, route.Origin, route.ManagerPath, HttpReachable = Discovery.Reachable(route.Origin).GetAwaiter().GetResult() }));
            Console.WriteLine("Existing Cloudflared: " + ServiceHost.Describe("Cloudflared"));
            Console.WriteLine("Daisson connector: " + ServiceHost.Describe(ConnectorService.Name));
            return 0;
        }
        if (args.FirstOrDefault() == "tunnel")
        {
            if (Environment.GetEnvironmentVariable("TUNNEL_TOKEN") != "test-connector-token") return 3;
            var marker = Environment.GetEnvironmentVariable("DAISSON_TEST_CHILD_MARKER")!;
            File.AppendAllText(marker, Environment.ProcessId + "\r\n");
            Thread.Sleep(Timeout.Infinite); return 0;
        }
        var root = Path.Combine(Path.GetTempPath(), "Daisson-tests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root); ProfileStore.Root = root;
        try
        {
            Run().GetAwaiter().GetResult();
            Application.SetHighDpiMode(HighDpiMode.PerMonitorV2); Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
            using (var form = new MainForm(false))
            {
                form.Show(); Application.DoEvents();
                Check(form.IsHandleCreated && form.Controls.Count > 0, "WinForms lifecycle and handle creation");
                if (args.Length == 1)
                {
                    var tabs = form.Controls.OfType<Panel>().SelectMany(p => p.Controls.OfType<TabControl>()).Single();
                    for (var i = 0; i < tabs.TabCount; i++)
                    {
                        tabs.SelectedIndex = i; Application.DoEvents();
                        using var bitmap = new Bitmap(form.Width, form.Height);
                        form.DrawToBitmap(bitmap, new Rectangle(0, 0, form.Width, form.Height));
                        bitmap.Save(Path.Combine(Path.GetDirectoryName(args[0])!, $"ui-preview-{i}.png"));
                    }
                }
                form.Close();
            }
            Console.WriteLine($"ALL {count} CHECKS PASSED"); return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
        finally { Directory.Delete(root, true); }
    }
    private static async Task Run()
    {
        Check(Validation.Domain(" DAISSON.tech ") == "daisson.tech", "domain normalization");
        Check(Validation.Domain("مثال.مصر").StartsWith("xn--"), "international customer domain");
        Check(Validation.Host("customer.org", "branch.app") == "branch.app.customer.org", "arbitrary customer subdomain");
        foreach (var bad in new[] { "https://example.com", "example.com/path", "*.example.com", "127.0.0.1", "single", "a..com", "a-.com" })
            await Reject(() => Validation.Domain(bad), "reject domain " + bad);
        foreach (var bad in new[] { "https://evil.example", "http://127.0.0.1:5434", "http://localhost:80/data", "http://user:pass@localhost", "http://localhost/?secret=x", "file:///c:/foo" })
            await Reject(() => Validation.Origin(bad), "reject origin " + bad);
        Check(Validation.Origin("http://[::1]:5050/") == "http://[::1]:5050", "IPv6 loopback");
        var unprotected = Profile(); unprotected.Routes[0].Protected = false;
        await Reject(() => Validation.Routes(unprotected), "unprotected API cannot be published");
        var p = Profile(); var identity = CloudflareClient.Identity(p);
        p.ChangeDomain("customer.org");
        Check(p.TunnelId == "" && p.AccountId == "" && p.ZoneId == "" && p.TunnelToken == "" && p.Domain == "customer.org", "changing domain clears account and tunnel binding");
        Check(CloudflareClient.Identity(p) != identity, "review tied to customer domain");
        p = Profile(); p.TunnelToken = "secret-tunnel-token"; p.Routes[0].ManagerPath = "C:/Untrusted.exe";
        var export = ProfileStore.Export(p);
        Check(!export.Contains("secret-") && !export.Contains(Account) && !export.Contains(Tunnel) && !export.Contains("Untrusted.exe"), "export omits credentials and machine bindings");
        var imported = ProfileStore.Import(export);
        Check(imported.Domain == "example.com" && imported.Id != p.Id && imported.ApiToken == "" && !imported.Routes[0].Protected && !imported.Routes[0].Publish, "import resets permissions and assigns independent customer");
        var injected = JsonNode.Parse(export)!.AsObject(); injected["ApiToken"] = "injected"; injected["Routes"]![0]!["ManagerPath"] = "C:/bad.exe";
        Check(ProfileStore.Import(injected.ToJsonString()).ApiToken == "" && ProfileStore.Import(injected.ToJsonString()).Routes[0].ManagerPath == "", "import ignores injected secrets and executable paths");
        ProfileStore.Save([p, new CustomerProfile { Name = "Other", Domain = "other.com", ApiToken = "other-token" }]);
        var stored = File.ReadAllBytes(Path.Combine(ProfileStore.Root, "profiles.bin"));
        Check(!System.Text.Encoding.UTF8.GetString(stored).Contains("secret-api-token"), "profile credentials encrypted on disk");
        Check(ProfileStore.Load().Count == 2 && ProfileStore.Load()[1].ApiToken == "other-token", "independent encrypted customer roundtrip");
        var original = JsonNodeHelper.Parse("""{"originRequest":{"connectTimeout":15},"warp-routing":{"enabled":false},"ingress":[{"hostname":"old.example.com","service":"http://localhost:81","originRequest":{"httpHostHeader":"internal"}},{"hostname":"*.example.com","service":"http://localhost:82"},{"service":"http_status:404"}]}""");
        var merged = CloudflareClient.Merge(original, [("app.example.com", "http://127.0.0.1:5050")]);
        Check(merged["ingress"]![0]!["hostname"]!.GetValue<string>() == "app.example.com", "explicit routes inserted before wildcard");
        Check(JsonNode.DeepEquals(original["originRequest"], merged["originRequest"]) && JsonNode.DeepEquals(original["ingress"]![0], merged["ingress"]![1]), "preserve origin options and existing rules");
        Check(original["ingress"]!.AsArray().Count == 3, "merge does not mutate original snapshot");
        Check(JsonNode.DeepEquals(merged, CloudflareClient.Merge(merged, [("app.example.com", "http://127.0.0.1:5050")])), "idempotent same route");
        await Reject(() => CloudflareClient.Merge(merged, [("old.example.com", "http://localhost:99")]), "refuse conflicting existing route");
        var emptyMerge = CloudflareClient.Merge(new JsonObject(), [("app.example.com", "http://localhost:80")]);
        Check(emptyMerge["ingress"]!.AsArray().Last()!["service"]!.GetValue<string>() == "http_status:404", "new configuration receives final catchall");
        using (var fake = new FakeCloudflare(original))
        using (var client = new CloudflareClient(p.ApiToken, fake))
        {
            var plan = await client.Review(p); Check(fake.Writes == 0, "review performs no remote writes");
            await client.Apply(p, plan);
            Check(fake.Records.ContainsKey("app.example.com") && fake.Writes == 2, "apply creates ingress and proxied DNS");
            Check(JsonNode.DeepEquals(fake.Config["originRequest"], original["originRequest"]), "apply preserves unrelated configuration");
            var again = await client.Review(p); Check(again.Dns.All(d => !d.Create), "matching proxied DNS treated as no-op");
        }
        using (var fake = new FakeCloudflare(original))
        using (var client = new CloudflareClient(p.ApiToken, fake))
        {
            fake.Records["app.example.com"] = new JsonObject { ["type"] = "A", ["name"] = "app.example.com", ["content"] = "192.0.2.1", ["id"] = "old" };
            await Reject(() => client.Review(p), "existing DNS conflict rejected"); Check(fake.Writes == 0, "DNS conflict causes no writes");
        }
        using (var fake = new FakeCloudflare(original))
        using (var client = new CloudflareClient(p.ApiToken, fake))
        {
            var plan = await client.Review(p); fake.Config["changedElsewhere"] = true;
            await Reject(() => client.Apply(p, plan), "stale remote configuration rejected"); Check(fake.Writes == 0, "stale plan causes no writes");
        }
        using (var fake = new FakeCloudflare(original))
        using (var client = new CloudflareClient(p.ApiToken, fake))
        {
            var plan = await client.Review(p); p.Id = Guid.NewGuid();
            await Reject(() => client.Apply(p, plan), "cross-customer plan rejected"); Check(fake.Writes == 0, "cross-customer plan causes no writes");
        }
        p = Profile(); p.Routes.Add(new LocalRoute { Publish = true, Protected = true, Subdomain = "second", Origin = "http://127.0.0.1:5060" });
        using (var fake = new FakeCloudflare(original) { FailDnsNumber = 2 })
        using (var client = new CloudflareClient(p.ApiToken, fake))
        {
            var plan = await client.Review(p);
            await Reject(() => client.Apply(p, plan), "partial DNS failure reported");
            Check(fake.Records.Count == 0 && JsonNode.DeepEquals(fake.Config, original), "rollback restores ingress and removes only created DNS");
        }
        using (var fake = new FakeCloudflare(original) { Status = "pending" })
        using (var client = new CloudflareClient(p.ApiToken, fake))
        { await Reject(() => client.Review(p), "pending nameserver activation blocks publishing"); Check(fake.Writes == 0, "pending zone causes no writes"); }
        var priorTokenFile = Environment.GetEnvironmentVariable("TUNNEL_TOKEN_FILE");
        Environment.SetEnvironmentVariable("TUNNEL_TOKEN_FILE", "other-customer-token-file");
        var start = ConnectorService.ChildStart("C:/protected/cloudflared.exe", "secret-tunnel-token");
        Environment.SetEnvironmentVariable("TUNNEL_TOKEN_FILE", priorTokenFile);
        Check(!string.Join(' ', start.ArgumentList).Contains("secret-tunnel-token") && start.Environment["TUNNEL_TOKEN"] == "secret-tunnel-token", "connector secret passed by environment, never command line");
        Check(!start.Environment.ContainsKey("TUNNEL_TOKEN_FILE") && start.ArgumentList.Contains("--config"), "connector ignores inherited customer credentials and default config");
        var marker = Path.Combine(ProfileStore.Root, "child-marker.txt");
        Environment.SetEnvironmentVariable("DAISSON_TEST_CHILD_MARKER", marker);
        using (var cancelWorker = new CancellationTokenSource())
        {
            var worker = ConnectorService.RunEntries(Environment.ProcessPath!, [new ConnectorEntry(Guid.NewGuid(), Tunnel, "test-connector-token")], cancelWorker.Token, _ => { });
            for (var attempt = 0; attempt < 100 && !File.Exists(marker); attempt++) await Task.Delay(100);
            Check(File.Exists(marker), "supervisor starts isolated connector process with token");
            var childPid = int.Parse(File.ReadAllText(marker).Trim());
            using var child = System.Diagnostics.Process.GetProcessById(childPid);
            child.Kill(); await child.WaitForExitAsync();
            for (var attempt = 0; attempt < 100 && File.ReadAllLines(marker).Length < 2; attempt++) await Task.Delay(100);
            Check(File.ReadAllLines(marker).Length == 2, "supervisor restarts failed child");
            using var restarted = System.Diagnostics.Process.GetProcessById(int.Parse(File.ReadAllLines(marker)[1]));
            cancelWorker.Cancel(); await worker.WaitAsync(TimeSpan.FromSeconds(10));
            Check(child.HasExited && restarted.HasExited, "stopping supervisor terminates its connector child");
        }
        using (var job = new ChildJob())
        using (var child = System.Diagnostics.Process.Start(ConnectorService.ChildStart(Environment.ProcessPath!, "test-connector-token"))!)
        {
            job.Assign(child); job.Dispose();
            Check(child.WaitForExit(5000), "job closure terminates child after wrapper exit");
        }
        Environment.SetEnvironmentVariable("DAISSON_TEST_CHILD_MARKER", null);
        var folder = Path.Combine(ProfileStore.Root, "fake-install"); Directory.CreateDirectory(folder);
        File.WriteAllText(Path.Combine(folder, "SERVER_INFO.txt"), "LOCAL_URL=http://127.0.0.1:5099\r\nPOSTGRES_PORT=5434");
        Check(Discovery.Scan(folder).Any(r => r.Origin == "http://127.0.0.1:5099" && !r.Publish), "bounded metadata discovery does not auto-publish");
        var listener = new TcpListener(IPAddress.Loopback, 0); listener.Start();
        var port = ((IPEndPoint)listener.LocalEndpoint).Port;
        var responder = Task.Run(async () => { using var tcp = await listener.AcceptTcpClientAsync(); await using var s = tcp.GetStream(); var b = new byte[8192]; await s.ReadAsync(b); await s.WriteAsync(System.Text.Encoding.ASCII.GetBytes("HTTP/1.1 401 Unauthorized\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")); });
        Check(await Discovery.Reachable($"http://127.0.0.1:{port}"), "authenticated HTTP response counts as reachable"); await responder; listener.Stop();
        Check(!await Discovery.Reachable($"http://127.0.0.1:{port}"), "closed server reports unavailable");
    }
    private sealed class FakeCloudflare(JsonObject initial) : HttpMessageHandler
    {
        public JsonObject Config = initial.DeepClone().AsObject();
        public readonly Dictionary<string, JsonObject> Records = [];
        public int Writes, FailDnsNumber, posts;
        public string Status = "active";
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (request.Headers.Authorization?.Scheme != "Bearer") throw new Exception("Missing auth");
            var path = request.RequestUri!.AbsolutePath;
            var query = System.Web.HttpUtility.ParseQueryString(request.RequestUri.Query);
            JsonNode result;
            if (request.Method == HttpMethod.Get && path.EndsWith("/zones"))
                result = new JsonArray(new JsonObject { ["id"] = Zone, ["name"] = "example.com", ["status"] = Status, ["account"] = new JsonObject { ["id"] = Account }, ["name_servers"] = new JsonArray("one.ns.cloudflare.com", "two.ns.cloudflare.com") });
            else if (request.Method == HttpMethod.Get && path.EndsWith("/cfd_tunnel"))
                result = new JsonArray(new JsonObject { ["id"] = Tunnel, ["name"] = "Test", ["status"] = "healthy", ["config_src"] = "cloudflare" });
            else if (path.EndsWith("/configurations"))
            {
                if (request.Method == HttpMethod.Put) { Writes++; Config = JsonNode.Parse(await request.Content!.ReadAsStringAsync(cancellationToken))!["config"]!.DeepClone().AsObject(); }
                result = new JsonObject { ["config"] = Config.DeepClone() };
            }
            else if (path.Contains("/dns_records"))
            {
                if (request.Method == HttpMethod.Get)
                    result = Records.TryGetValue(query["name"]!, out var record) ? new JsonArray(record.DeepClone()) : new JsonArray();
                else if (request.Method == HttpMethod.Post)
                {
                    Writes++; posts++;
                    if (posts == FailDnsNumber) return Reply(new JsonObject { ["success"] = false, ["errors"] = new JsonArray(new JsonObject { ["code"] = 1000, ["message"] = "secret-api-token must not leak" }) }, HttpStatusCode.BadRequest);
                    var row = JsonNode.Parse(await request.Content!.ReadAsStringAsync(cancellationToken))!.AsObject(); row["id"] = "record" + posts;
                    Records.Add(row["name"]!.GetValue<string>(), row); result = row.DeepClone();
                }
                else if (request.Method == HttpMethod.Delete)
                {
                    Writes++; var id = path.Split('/').Last(); var key = Records.Single(r => r.Value["id"]!.GetValue<string>() == id).Key; Records.Remove(key); result = new JsonObject { ["id"] = id };
                }
                else throw new Exception("Unexpected DNS operation");
            }
            else throw new Exception("Unexpected endpoint " + path);
            return Reply(new JsonObject { ["success"] = true, ["result"] = result, ["result_info"] = new JsonObject { ["total_pages"] = 1 } });
        }
        private static HttpResponseMessage Reply(JsonObject body, HttpStatusCode status = HttpStatusCode.OK) => new(status) { Content = new StringContent(body.ToJsonString(), System.Text.Encoding.UTF8, "application/json") };
    }
}
