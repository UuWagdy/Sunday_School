using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;

namespace DaissonTunnelManager;

public sealed record ZoneInfo(string Id, string AccountId, string Status, string[] NameServers);
public sealed record TunnelInfo(string Id, string Name, string Status)
{
    public override string ToString() => $"{Name} ({Status}) — {Id}";
}
public sealed record DnsChange(string Host, JsonArray Before, bool Create);
public sealed record PublishPlan(string Identity, string ConfigPath, JsonObject Before, JsonObject After, List<DnsChange> Dns, string ZoneId, string Target, List<(string Host, string Origin)> Routes)
{
    public string Describe() => string.Join(Environment.NewLine,
        Routes.Select(r => $"https://{r.Host}  →  {r.Origin}")) + Environment.NewLine + Environment.NewLine +
        $"DNS: إنشاء {Dns.Count(d => d.Create)} سجل CNAME، والحفاظ على {Dns.Count(d => !d.Create)} سجل مطابق." + Environment.NewLine +
        "سيتم الحفاظ على المسارات الأخرى وإعدادات النفق. النسخة السابقة تُحفظ مشفرة محليًا قبل التنفيذ.";
}

public sealed class CloudflareClient : IDisposable
{
    private readonly HttpClient http;
    public CloudflareClient(string token, HttpMessageHandler? handler = null)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Any(char.IsWhiteSpace)) throw new InvalidOperationException("أدخل API Token صالحًا في البرنامج.");
        http = new HttpClient(handler ?? new HttpClientHandler { AllowAutoRedirect = false }) { BaseAddress = new Uri("https://api.cloudflare.com/client/v4/"), Timeout = TimeSpan.FromSeconds(35) };
        http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }
    public void Dispose() => http.Dispose();
    private async Task<JsonNode> Call(HttpMethod method, string path, JsonNode? data, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(method, path);
        if (data is not null) request.Content = new StringContent(data.ToJsonString(), Encoding.UTF8, "application/json");
        using var response = await http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);
        await using var stream = await response.Content.ReadAsStreamAsync(ct);
        using var buffer = new MemoryStream();
        var bytes = new byte[8192];
        int count;
        while ((count = await stream.ReadAsync(bytes, ct)) > 0)
        {
            if (buffer.Length + count > 4 * 1024 * 1024) throw new InvalidOperationException("استجابة Cloudflare أكبر من الحد المسموح.");
            buffer.Write(bytes, 0, count);
        }
        JsonObject? body = null;
        try { body = JsonNode.Parse(buffer.ToArray())?.AsObject(); } catch (System.Text.Json.JsonException) { }
        if (!response.IsSuccessStatusCode || body?["success"]?.GetValue<bool>() != true)
        {
            var code = body?["errors"]?.AsArray().FirstOrDefault()?["code"]?.ToString();
            // Cloudflare error messages may echo user input or credentials. Never display raw response bodies.
            throw new InvalidOperationException($"Cloudflare HTTP {(int)response.StatusCode}" + (int.TryParse(code, out var number) ? $" — code {number}" : "") + ". راجع صلاحيات التوكن والحساب والدومين.");
        }
        return body!;
    }
    private async Task<JsonArray> List(string path, CancellationToken ct)
    {
        var output = new JsonArray();
        for (var page = 1; page <= 100; page++)
        {
            var body = await Call(HttpMethod.Get, path + (path.Contains('?') ? "&" : "?") + $"per_page=100&page={page}", null, ct);
            var rows = body["result"]?.AsArray() ?? [];
            foreach (var row in rows) output.Add(row?.DeepClone());
            var pages = body["result_info"]?["total_pages"]?.GetValue<int>();
            if ((pages.HasValue && page >= pages.Value) || (!pages.HasValue && rows.Count < 100)) return output;
        }
        throw new InvalidOperationException("عدد نتائج Cloudflare كبير جدًا. ضيّق صلاحيات الحساب.");
    }
    public async Task<ZoneInfo> FindZone(string domain, CancellationToken ct = default)
    {
        domain = Validation.Domain(domain);
        var rows = await List("zones?name=" + Uri.EscapeDataString(domain), ct);
        var zone = rows.SingleOrDefault(z => z?["name"]?.GetValue<string>() == domain) ??
            throw new InvalidOperationException("أضف هذا الدومين إلى حساب Cloudflare أولًا، ثم امنح التوكن صلاحية Zone Read وDNS Edit عليه.");
        return new ZoneInfo(zone["id"]!.GetValue<string>(), zone["account"]!["id"]!.GetValue<string>(), zone["status"]!.GetValue<string>(), zone["name_servers"]?.AsArray().Select(n => n!.GetValue<string>()).ToArray() ?? []);
    }
    public async Task<List<TunnelInfo>> Tunnels(string account, CancellationToken ct = default)
    {
        Validation.Id(account);
        var rows = await List($"accounts/{account}/cfd_tunnel?is_deleted=false", ct);
        return rows.Where(t => t?["config_src"]?.GetValue<string>() == "cloudflare").Select(t => new TunnelInfo(t!["id"]!.GetValue<string>(), t["name"]!.GetValue<string>(), t["status"]?.GetValue<string>() ?? "unknown")).ToList();
    }
    public async Task<TunnelInfo> CreateTunnel(string account, string name, CancellationToken ct = default)
    {
        Validation.Id(account);
        if (string.IsNullOrWhiteSpace(name) || name.Length > 100) throw new InvalidOperationException("اسم النفق مطلوب وأقصاه 100 حرف.");
        var body = await Call(HttpMethod.Post, $"accounts/{account}/cfd_tunnel", new JsonObject { ["name"] = name.Trim(), ["config_src"] = "cloudflare" }, ct);
        var r = body["result"]!;
        return new TunnelInfo(r["id"]!.GetValue<string>(), r["name"]!.GetValue<string>(), "inactive");
    }
    public async Task<string> TunnelToken(string account, string tunnel, CancellationToken ct = default)
    {
        Validation.Id(account); Validation.Id(tunnel);
        var body = await Call(HttpMethod.Get, $"accounts/{account}/cfd_tunnel/{tunnel}/token", null, ct);
        return body["result"]!.GetValue<string>();
    }
    private async Task<JsonObject> Config(string path, CancellationToken ct)
    {
        var body = await Call(HttpMethod.Get, path, null, ct);
        return body["result"]?["config"]?.DeepClone().AsObject() ?? new JsonObject { ["ingress"] = new JsonArray(new JsonObject { ["service"] = "http_status:404" }) };
    }
    public static JsonObject Merge(JsonObject before, List<(string Host, string Origin)> routes)
    {
        var result = before.DeepClone().AsObject();
        var ingress = result["ingress"]?.AsArray() ?? new JsonArray();
        if (ingress.Count > 0 && (ingress.Last()?["hostname"] is not null || ingress.Last()?["path"] is not null))
            throw new InvalidOperationException("إعداد النفق الحالي لا يحتوي مسارًا افتراضيًا أخيرًا. أصلحه من Cloudflare قبل الدمج.");
        if (ingress.Take(Math.Max(0, ingress.Count - 1)).Any(r => r?["hostname"] is null && r?["path"] is null))
            throw new InvalidOperationException("هناك مسار عام يسبق مسارات النفق. المراجعة اليدوية مطلوبة.");
        foreach (var route in routes)
        {
            var matches = ingress.Where(r => string.Equals(r?["hostname"]?.GetValue<string>(), route.Host, StringComparison.OrdinalIgnoreCase)).ToList();
            if (matches.Count > 0)
            {
                if (matches.Count == 1 && matches[0]?["service"]?.GetValue<string>() == route.Origin && matches[0]?["path"] is null) continue;
                throw new InvalidOperationException($"المسار {route.Host} موجود بإعدادات مختلفة. لم يتم تغييره.");
            }
            // Explicit hostnames must precede wildcard and general path rules.
            ingress.Insert(0, new JsonObject { ["hostname"] = route.Host, ["service"] = route.Origin });
        }
        if (ingress.Count == routes.Count && before["ingress"]?.AsArray().Count is null or 0)
            ingress.Add(new JsonObject { ["service"] = "http_status:404" });
        result["ingress"] = ingress;
        return result;
    }
    public static string Identity(CustomerProfile p) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(
        string.Join('|', p.Id, p.Domain, p.AccountId, p.ZoneId, p.TunnelId, p.ApiToken,
            string.Join(';', p.Routes.Where(r => r.Publish).Select(r => $"{r.Subdomain}:{r.Origin}:{r.Protected}"))))));
    private Task<JsonArray> Dns(string zone, string host, CancellationToken ct) => List($"zones/{zone}/dns_records?name={Uri.EscapeDataString(host)}", ct);
    private static bool Matches(JsonArray records, string target) => records.Count == 1 &&
        records[0]?["type"]?.GetValue<string>() == "CNAME" &&
        string.Equals(records[0]?["content"]?.GetValue<string>()?.TrimEnd('.'), target, StringComparison.OrdinalIgnoreCase) && records[0]?["proxied"]?.GetValue<bool>() == true;
    public async Task<PublishPlan> Review(CustomerProfile p, CancellationToken ct = default)
    {
        var routes = Validation.Routes(p);
        Validation.Id(p.AccountId); Validation.Id(p.ZoneId); Validation.Id(p.TunnelId);
        var zone = await FindZone(p.Domain, ct);
        if (zone.Id != p.ZoneId || zone.AccountId != p.AccountId) throw new InvalidOperationException("الدومين لا يطابق الحساب الحالي. أعد الاتصال.");
        if (zone.Status != "active") throw new InvalidOperationException("الدومين لم يصبح Active بعد. انقل Nameservers إلى القيم التي يعرضها Cloudflare ثم انتظر التفعيل.");
        var tunnels = await Tunnels(p.AccountId, ct);
        if (tunnels.All(t => t.Id != p.TunnelId)) throw new InvalidOperationException("النفق غير موجود ضمن أنفاق الحساب المدارة من Cloudflare.");
        var path = $"accounts/{p.AccountId}/cfd_tunnel/{p.TunnelId}/configurations";
        var before = await Config(path, ct);
        var after = Merge(before, routes);
        var target = p.TunnelId + ".cfargotunnel.com";
        List<DnsChange> dns = [];
        foreach (var r in routes)
        {
            var records = await Dns(p.ZoneId, r.Host, ct);
            if (records.Count > 0 && !Matches(records, target))
                throw new InvalidOperationException($"DNS للاسم {r.Host} مستخدم بالفعل أو غير Proxied. لم يتم تغييره؛ اختر سب دومين آخر أو راجعه من لوحة Cloudflare.");
            dns.Add(new DnsChange(r.Host, records, records.Count == 0));
        }
        return new PublishPlan(Identity(p), path, before, after, dns, p.ZoneId, target, routes);
    }
    public async Task Apply(CustomerProfile p, PublishPlan plan, CancellationToken ct = default)
    {
        if (Identity(p) != plan.Identity) throw new InvalidOperationException("تغيّرت الإعدادات بعد المراجعة. أعد المراجعة أولًا.");
        var fresh = await Review(p, ct);
        if (!JsonNode.DeepEquals(fresh.Before, plan.Before) || fresh.Dns.Where((d, i) => !JsonNode.DeepEquals(d.Before, plan.Dns[i].Before)).Any())
            throw new InvalidOperationException("تغيّرت إعدادات Cloudflare منذ المراجعة. أعد المراجعة قبل التنفيذ.");
        SecretFile.Write(Path.Combine(ProfileStore.Root, "backups", $"{DateTime.UtcNow:yyyyMMdd-HHmmss}-{Guid.NewGuid():N}.bin"),
            new JsonObject { ["configPath"] = plan.ConfigPath, ["config"] = plan.Before.DeepClone(), ["dns"] = new JsonArray(plan.Dns.Select(d => (JsonNode?)new JsonObject { ["host"] = d.Host, ["before"] = d.Before.DeepClone() }).ToArray()) }.ToJsonString());
        List<(string Id, string Host)> created = [];
        var configAttempted = false;
        try
        {
            configAttempted = true;
            await Call(HttpMethod.Put, plan.ConfigPath, new JsonObject { ["config"] = plan.After.DeepClone() }, ct);
            foreach (var d in plan.Dns.Where(d => d.Create))
            {
                // Recheck immediately before each DNS write; never replace an existing record.
                if ((await Dns(plan.ZoneId, d.Host, ct)).Count != 0) throw new InvalidOperationException("تم إنشاء DNS بالتزامن. أوقف التنفيذ لحماية السجلات.");
                var response = await Call(HttpMethod.Post, $"zones/{plan.ZoneId}/dns_records", new JsonObject { ["type"] = "CNAME", ["name"] = d.Host, ["content"] = plan.Target, ["proxied"] = true, ["ttl"] = 1 }, ct);
                created.Add((response["result"]!["id"]!.GetValue<string>(), d.Host));
            }
        }
        catch
        {
            var rollbackOk = true;
            using var recovery = new CancellationTokenSource(TimeSpan.FromSeconds(60));
            foreach (var record in created.AsEnumerable().Reverse())
            {
                try
                {
                    var current = await Dns(plan.ZoneId, record.Host, recovery.Token);
                    if (Matches(current, plan.Target) && current[0]?["id"]?.GetValue<string>() == record.Id)
                        await Call(HttpMethod.Delete, $"zones/{plan.ZoneId}/dns_records/{record.Id}", null, recovery.Token);
                    else rollbackOk = false;
                }
                catch { rollbackOk = false; }
            }
            if (configAttempted)
            {
                try
                {
                    var current = await Config(plan.ConfigPath, recovery.Token);
                    if (JsonNode.DeepEquals(current, plan.After))
                        await Call(HttpMethod.Put, plan.ConfigPath, new JsonObject { ["config"] = plan.Before.DeepClone() }, recovery.Token);
                    else if (!JsonNode.DeepEquals(current, plan.Before)) rollbackOk = false;
                }
                catch { rollbackOk = false; }
            }
            throw new InvalidOperationException(rollbackOk ?
                "تعذر إتمام النشر. تم التراجع عن التغييرات المؤكدة؛ إن انقطع الاتصال أثناء إنشاء DNS، راجع السجلات من اللوحة قبل المحاولة مجددًا." :
                "تعذر إتمام النشر والتراجع الكامل. راجع Cloudflare والنسخة المشفرة في مجلد backups قبل إعادة المحاولة.");
        }
    }
}
