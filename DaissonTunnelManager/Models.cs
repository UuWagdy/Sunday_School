using System.Globalization;
using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;

namespace DaissonTunnelManager;

public sealed class CustomerProfile
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "عميل جديد";
    public string Domain { get; set; } = "";
    public string ApiToken { get; set; } = "";
    public string AccountId { get; set; } = "";
    public string ZoneId { get; set; } = "";
    public string TunnelId { get; set; } = "";
    public string TunnelToken { get; set; } = "";
    public List<LocalRoute> Routes { get; set; } = [];
    public override string ToString() => $"{Name} — {Domain}";
    public void ChangeDomain(string domain)
    {
        domain = Validation.Domain(domain);
        if (domain == Domain) return;
        Domain = domain;
        AccountId = ZoneId = TunnelId = TunnelToken = "";
    }
}

public sealed class LocalRoute
{
    public bool Publish { get; set; }
    public string Name { get; set; } = "برنامج";
    public string Subdomain { get; set; } = "app";
    public string Origin { get; set; } = "http://127.0.0.1:8080";
    public bool Protected { get; set; }
    public string ManagerPath { get; set; } = "";
    public string Note { get; set; } = "تحقق من تسجيل الدخول والصلاحيات قبل النشر";
    [JsonIgnore] public string Status { get; set; } = "لم يُختبر";
}

public static class Validation
{
    public static string Domain(string input)
    {
        var raw = input.Trim().TrimEnd('.');
        string value;
        try { value = new IdnMapping().GetAscii(raw).ToLowerInvariant(); }
        catch { throw new InvalidOperationException("اسم الدومين غير صحيح."); }
        if (value.Length > 253 || !value.Contains('.') || IPAddress.TryParse(value, out _) ||
            value.Split('.').Any(l => !Regex.IsMatch(l, @"^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$")))
            throw new InvalidOperationException("اكتب الدومين فقط، مثل example.com، بدون https أو مسار.");
        return value;
    }
    public static string Host(string domain, string subdomain)
    {
        domain = Domain(domain);
        var sub = subdomain.Trim().ToLowerInvariant();
        if (sub.Length == 0 || sub.Split('.').Any(l => !Regex.IsMatch(l, @"^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$")))
            throw new InvalidOperationException("اكتب سب دومين مثل sunday أو branch.app، بدون نجمة أو رابط كامل.");
        var host = $"{sub}.{domain}";
        if (host.Length > 253) throw new InvalidOperationException("اسم السب دومين طويل جدًا.");
        return host;
    }
    public static string Origin(string input)
    {
        if (!Uri.TryCreate(input.Trim(), UriKind.Absolute, out var uri) ||
            (uri.Scheme != "http" && uri.Scheme != "https") ||
            !(uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase) ||
              (IPAddress.TryParse(uri.DnsSafeHost.Trim('[', ']'), out var ip) && IPAddress.IsLoopback(ip))) ||
            uri.UserInfo.Length != 0 || uri.Query.Length != 0 || uri.Fragment.Length != 0 || uri.AbsolutePath != "/" || uri.Port < 1)
            throw new InvalidOperationException("الخدمة المحلية يجب أن تكون مثل http://127.0.0.1:5050 على نفس الجهاز.");
        if (new[] { 5432, 5433, 5434, 5438, 3306, 6379, 1433, 27017 }.Contains(uri.Port))
            throw new InvalidOperationException("هذا منفذ قاعدة بيانات، اختر منفذ API الخاص بالبرنامج.");
        return uri.GetLeftPart(UriPartial.Authority);
    }
    public static void Id(string value)
    {
        if (!Regex.IsMatch(value, @"^[a-zA-Z0-9-]{16,64}$")) throw new InvalidOperationException("معرّف Cloudflare غير صحيح.");
    }
    public static List<(string Host, string Origin)> Routes(CustomerProfile profile)
    {
        var rows = profile.Routes.Where(r => r.Publish).ToList();
        if (rows.Count == 0) throw new InvalidOperationException("اختر برنامجًا واحدًا على الأقل للنشر.");
        if (rows.Any(r => !r.Protected))
            throw new InvalidOperationException("الخدمات المختارة تحتاج مصادقة وصلاحيات فعلية. أكّد خانة «API محمي» بعد ضبط الحماية. العضوية الحالية تحتاج حماية API، ومدارس الأحد تحتاج Jwt:Secret خاصًا.");
        var routes = rows.Select(r => (Host(profile.Domain, r.Subdomain), Origin(r.Origin))).ToList();
        if (routes.Select(r => r.Item1).Distinct().Count() != routes.Count)
            throw new InvalidOperationException("يوجد سب دومين مكرر.");
        return routes;
    }
}

public static class ProfileStore
{
    public static readonly JsonSerializerOptions Json = new() { WriteIndented = true, PropertyNameCaseInsensitive = true };
    public static string Root { get; internal set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DaissonTunnelManager");
    public static List<CustomerProfile> Load()
    {
        var file = Path.Combine(Root, "profiles.bin");
        return File.Exists(file) ? JsonSerializer.Deserialize<List<CustomerProfile>>(SecretFile.Read(file), Json) ?? [] :
            [new CustomerProfile()];
    }
    public static void Save(List<CustomerProfile> profiles) => SecretFile.Write(Path.Combine(Root, "profiles.bin"), JsonSerializer.Serialize(profiles, Json));
    public static string Export(CustomerProfile profile) => JsonSerializer.Serialize(new
    {
        Version = 1, profile.Name, profile.Domain,
        Routes = profile.Routes.Select(r => new { r.Name, r.Subdomain, r.Origin, r.Note })
    }, Json);
    public static CustomerProfile Import(string json)
    {
        if (json.Length > 1024 * 1024) throw new InvalidOperationException("ملف الإعدادات كبير جدًا.");
        // Import only the portable fields, even if the input contains credentials or local executable paths.
        var doc = JsonNodeHelper.Parse(json);
        var p = new CustomerProfile { Name = doc["Name"]?.GetValue<string>() ?? "عميل", Domain = Validation.Domain(doc["Domain"]?.GetValue<string>() ?? "") };
        if (doc["Routes"] is System.Text.Json.Nodes.JsonArray rows)
            foreach (var r in rows.Take(100))
                p.Routes.Add(new LocalRoute { Name = r?["Name"]?.GetValue<string>() ?? "برنامج", Subdomain = r?["Subdomain"]?.GetValue<string>() ?? "app", Origin = Validation.Origin(r?["Origin"]?.GetValue<string>() ?? ""), Note = r?["Note"]?.GetValue<string>() ?? "" });
        return p;
    }
}

internal static class JsonNodeHelper
{
    public static System.Text.Json.Nodes.JsonObject Parse(string s) => System.Text.Json.Nodes.JsonNode.Parse(s)?.AsObject() ?? throw new InvalidOperationException("بيانات غير صحيحة.");
}
