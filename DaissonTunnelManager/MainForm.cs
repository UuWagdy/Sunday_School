using System.ComponentModel;
using System.Diagnostics;

namespace DaissonTunnelManager;

public sealed class MainForm : Form
{
    private readonly List<CustomerProfile> profiles;
    private CustomerProfile current;
    private readonly ComboBox customers = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 320 };
    private readonly TextBox customerName = new() { Width = 230 };
    private readonly TextBox domain = new() { Width = 270, RightToLeft = RightToLeft.No };
    private readonly TextBox apiToken = new() { Width = 480, UseSystemPasswordChar = true, RightToLeft = RightToLeft.No };
    private readonly TextBox tunnelName = new() { Width = 250, Text = "church-server" };
    private readonly ComboBox tunnels = new() { Width = 650, DropDownStyle = ComboBoxStyle.DropDownList, RightToLeft = RightToLeft.No };
    private readonly TextBox zoneDetails = ReadOnlyText();
    private readonly TextBox preview = ReadOnlyText();
    private readonly TextBox serviceDetails = ReadOnlyText();
    private readonly TextBox log = ReadOnlyText();
    private readonly DataGridView grid = new() { Dock = DockStyle.Fill, AutoGenerateColumns = false, AllowUserToAddRows = false, AllowUserToDeleteRows = false, MultiSelect = false, SelectionMode = DataGridViewSelectionMode.FullRowSelect, RowHeadersVisible = false, BackgroundColor = Color.White, AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.AllCells };
    private readonly Panel content = new() { Dock = DockStyle.Fill };
    private readonly Label status = new() { Dock = DockStyle.Fill, Text = "جاهز", TextAlign = ContentAlignment.MiddleRight, AutoEllipsis = true };
    private readonly Button cancel = new() { Text = "إلغاء العملية", AutoSize = true, Enabled = false, Dock = DockStyle.Left };
    private readonly Button apply = new() { Text = "تنفيذ المراجعة المعروضة", AutoSize = true, Enabled = false };
    private readonly CancellationTokenSource lifetime = new();
    private CancellationTokenSource? operation;
    private BindingList<LocalRoute> rows = [];
    private PublishPlan? plan;
    private bool loading;
    private bool running;
    private bool resourcesDisposed;

    public MainForm(bool discoverOnShow = true)
    {
        profiles = ProfileStore.Load();
        if (profiles.Count == 0) profiles.Add(new CustomerProfile());
        current = profiles[0];
        Text = "Daisson • مدير الدومينات والأنفاق";
        Width = 1250; Height = 850; MinimumSize = new Size(1000, 680);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("Segoe UI", 10);
        RightToLeft = RightToLeft.Yes; RightToLeftLayout = true;
        var footer = new Panel { Height = 42, Dock = DockStyle.Bottom, Padding = new Padding(10, 3, 10, 3) };
        footer.Controls.Add(status); footer.Controls.Add(cancel);
        Controls.Add(content); Controls.Add(footer);
        var header = new Label { Text = "إدارة دومينات العملاء وCloudflare Tunnel", Dock = DockStyle.Top, Height = 64, Font = new Font("Segoe UI", 18, FontStyle.Bold), BackColor = Color.FromArgb(26, 35, 126), ForeColor = Color.White, TextAlign = ContentAlignment.MiddleCenter };
        var profilePanel = new Panel { Dock = DockStyle.Top, Height = 112 };
        var customerRow = Flow(54);
        customerRow.Controls.AddRange([Label("العميل"), customers, Button("عميل جديد", NewCustomer), Button("تصدير بدون أسرار", Export), Button("استيراد عميل", Import)]);
        var domainRow = Flow(54); domainRow.Dock = DockStyle.Bottom;
        domainRow.Controls.AddRange([Label("اسم العميل"), customerName, Label("الدومين"), domain, Button("حفظ", SaveAction)]);
        profilePanel.Controls.Add(domainRow); profilePanel.Controls.Add(customerRow);
        var tabs = new TabControl { Dock = DockStyle.Fill };
        tabs.TabPages.Add(ServerTab()); tabs.TabPages.Add(CloudTab()); tabs.TabPages.Add(ReviewTab()); tabs.TabPages.Add(ServiceTab()); tabs.TabPages.Add(HelpTab());
        content.Controls.Add(tabs); content.Controls.Add(profilePanel); content.Controls.Add(header);
        cancel.Click += (_, _) => operation?.Cancel();
        customers.SelectedIndexChanged += (_, _) =>
        {
            if (loading || customers.SelectedItem is not CustomerProfile next || next == current) return;
            try { SaveCurrent(false); current = next; LoadCurrent(); }
            catch (Exception ex) { ShowError(ex); loading = true; customers.SelectedItem = current; loading = false; }
        };
        domain.TextChanged += (_, _) => InvalidatePlan();
        apiToken.TextChanged += (_, _) => InvalidatePlan();
        tunnels.SelectedIndexChanged += (_, _) =>
        {
            if (loading) return;
            if (tunnels.SelectedItem is TunnelInfo info && current.TunnelId != info.Id)
            { current.TunnelId = info.Id; current.TunnelToken = ""; InvalidatePlan(); }
        };
        grid.CellValueChanged += (_, _) => InvalidatePlan();
        grid.CurrentCellDirtyStateChanged += (_, _) => { if (grid.IsCurrentCellDirty) grid.CommitEdit(DataGridViewDataErrorContexts.Commit); };
        grid.DataError += (_, e) => { e.ThrowException = false; status.Text = "قيمة الحقل غير صحيحة."; };
        apply.Click += async (_, _) => await Busy(Apply);
        FormClosing += (_, e) =>
        {
            if (running) { operation?.Cancel(); e.Cancel = true; status.Text = "جارٍ إيقاف العملية بأمان. أغلق النافذة بعد انتهائها."; return; }
            try { SaveCurrent(false); } catch (Exception ex) { e.Cancel = true; ShowError(ex); }
        };
        _ = Handle; // Establish the handle before asynchronous callbacks can update the UI.
        RefreshCustomers(); LoadCurrent();
        Shown += async (_, _) => { if (discoverOnShow && rows.Count == 0) await Busy(Scan); };
    }
    private static TextBox ReadOnlyText() => new() { Multiline = true, ReadOnly = true, TabStop = false, Dock = DockStyle.Fill, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = Color.White, RightToLeft = RightToLeft.No };
    private static Label Label(string text) => new() { Text = text, AutoSize = true, Margin = new Padding(10, 9, 3, 3) };
    private static FlowLayoutPanel Flow(int height) => new() { Dock = DockStyle.Top, Height = height, AutoScroll = true, Padding = new Padding(6), FlowDirection = FlowDirection.LeftToRight, WrapContents = true };
    private Button Button(string text, Func<Task> action)
    {
        var b = new Button { Text = text, AutoSize = true, MinimumSize = new Size(90, 32), Margin = new Padding(4) };
        b.Click += async (_, _) => await Busy(action);
        return b;
    }
    private static TabPage Page(string name) => new(name) { Padding = new Padding(8), BackColor = Color.FromArgb(247, 248, 252) };
    private TabPage ServerTab()
    {
        var page = Page("١ • البرامج المحلية");
        foreach (var c in new[] { ("Publish", "نشر", 55), ("Name", "البرنامج", 140), ("Subdomain", "السب دومين", 140), ("Origin", "الخدمة المحلية", 230), ("Protected", "API محمي", 85), ("Status", "الاتصال", 85), ("Note", "ملاحظات الحماية", 310) })
        {
            DataGridViewColumn column = c.Item1 is "Publish" or "Protected" ? new DataGridViewCheckBoxColumn() : new DataGridViewTextBoxColumn();
            column.DataPropertyName = c.Item1; column.HeaderText = c.Item2; column.Width = c.Item3;
            column.FillWeight = c.Item3;
            column.DefaultCellStyle.WrapMode = DataGridViewTriState.True;
            column.ReadOnly = c.Item1 == "Status";
            grid.Columns.Add(column);
        }
        grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        var buttons = Flow(52);
        buttons.Controls.AddRange([Button("اكتشاف البرامج", Scan), Button("فحص مجلد آخر", ScanFolder), Button("إضافة خدمة", () => { rows.Add(new LocalRoute()); InvalidatePlan(); return Task.CompletedTask; }), Button("حذف السطر", () => { if (Selected() is { } row) rows.Remove(row); InvalidatePlan(); return Task.CompletedTask; }), Button("اختبار الاتصال", Health), Button("فتح مدير السيرفر", OpenManager), Button("نسخ الرابط الخارجي", CopyUrl)]);
        var note = new Label { Dock = DockStyle.Top, Height = 56, Text = "كل برنامج له سب دومين ومنفذ مستقل. اختر «نشر» بعد ضبطه. خانة «API محمي» تأكيد منك أن السيرفر يفرض تسجيل الدخول والصلاحيات؛ نجاح الاتصال وحده لا يثبت الحماية.", Padding = new Padding(6) };
        page.Controls.Add(grid); page.Controls.Add(note); page.Controls.Add(buttons);
        return page;
    }
    private TabPage CloudTab()
    {
        var page = Page("٢ • حساب Cloudflare");
        var tokenBar = Flow(60);
        tokenBar.Controls.AddRange([Label("API Token لهذا العميل"), apiToken, Button("اتصال وحفظ", Connect), Button("إنشاء API Token", () => OpenUrl("https://dash.cloudflare.com/profile/api-tokens"))]);
        var tunnelBar = new Panel { Dock = DockStyle.Top, Height = 120 };
        var selectTunnelRow = Flow(56);
        selectTunnelRow.Controls.AddRange([Label("نفق العميل (الأنفاق المدارة من Cloudflare)"), tunnels]);
        var newTunnelRow = Flow(56); newTunnelRow.Dock = DockStyle.Bottom;
        newTunnelRow.Controls.AddRange([Label("اسم نفق جديد"), tunnelName, Button("إنشاء نفق جديد", CreateTunnel)]);
        tunnelBar.Controls.Add(newTunnelRow); tunnelBar.Controls.Add(selectTunnelRow);
        var instructions = new Label { Dock = DockStyle.Bottom, Height = 90, Text = "صلاحيات API Token: Zone / Zone / Read، وZone / DNS / Edit للدومين المحدد، وAccount / Cloudflare Tunnel / Edit لحساب العميل.\r\nقد يظهر الاسم الجديد للصلاحية: Cloudflare One Connector: cloudflared / Write. لا تستخدم Global API Key أو Tunnel Token في هذا الحقل.", Padding = new Padding(8) };
        page.Controls.Add(zoneDetails); page.Controls.Add(instructions); page.Controls.Add(tunnelBar); page.Controls.Add(tokenBar);
        return page;
    }
    private TabPage ReviewTab()
    {
        var page = Page("٣ • مراجعة ونشر");
        var buttons = Flow(56);
        buttons.Controls.Add(Button("مراجعة DNS والمسارات", Review)); buttons.Controls.Add(apply);
        var split = new SplitContainer { Dock = DockStyle.Fill, Orientation = Orientation.Horizontal, SplitterDistance = 270 };
        split.SizeChanged += (_, _) =>
        {
            if (split.ClientSize.Height > 240)
            {
                split.Panel1MinSize = 90; split.Panel2MinSize = 90;
                split.SplitterDistance = (int)(split.ClientSize.Height * 0.62);
            }
        };
        split.Panel1.Controls.Add(preview); split.Panel2.Controls.Add(log);
        page.Controls.Add(split); page.Controls.Add(buttons);
        return page;
    }
    private TabPage ServiceTab()
    {
        var page = Page("٤ • موصل ويندوز");
        var buttons = Flow(104);
        buttons.Controls.AddRange([Button("تحديث الحالة", ServiceStatus), Button("تنزيل وتثبيت موصل العميل كخدمة", InstallConnector), Button("إزالة موصل العميل من خدمة Daisson", RemoveConnector), Button("تشغيل خدمة Daisson", async () => { await ConnectorService.ControlElevated("start"); await ServiceStatus(); }), Button("إيقاف خدمة Daisson (كل عملائها)", async () => { await ConnectorService.ControlElevated("stop"); await ServiceStatus(); })]);
        var note = new Label { Dock = DockStyle.Bottom, Height = 100, Padding = new Padding(8), Text = "التثبيت ينزل cloudflared من الإصدار الرسمي ويتحقق من SHA256، ثم يطلب صلاحية Administrator. الخدمة تشغّل موصلًا مستقلًا لكل نفق عميل، وتبدأ مع ويندوز.\r\nخدمة Cloudflared القديمة لا يتم إيقافها أو استبدالها. إذا كان النفق يعمل عليها بالفعل، يكفي نشر المسارات ولا يلزم تثبيت موصل ثانٍ له. تشغيل الموصل لا يشغّل برنامجك أو قاعدة بياناته." };
        page.Controls.Add(serviceDetails); page.Controls.Add(note); page.Controls.Add(buttons);
        return page;
    }
    private TabPage HelpTab()
    {
        var page = Page("ابدأ من هنا");
        var help = ReadOnlyText(); help.RightToLeft = RightToLeft.Yes; help.WordWrap = true;
        help.Text = "١. أضف دومين العميل إلى حسابه في Cloudflare واختر الخطة المناسبة. تسجيل الدومين يظل عند Hostinger.\r\n\r\n٢. راجع سجلات DNS المستوردة قبل نقل Nameservers، خصوصًا A وMX وTXT للموقع والبريد. من Hostinger > Domains > الدومين > Nameservers أدخل القيم التي يعطيها Cloudflare لهذا الدومين. لا تستخدم Nameservers عميل آخر. انتظر الحالة Active.\r\n\r\n٣. أنشئ API Token بالصلاحيات الموضحة في تبويب Cloudflare وأدخله هنا فقط. اختر العميل واكتب دومينه، ثم «اتصال وحفظ». يعرض البرنامج Nameservers والحالة وأنفاق الحساب.\r\n\r\n٤. اختر نفقًا موجودًا أو أنشئ نفقًا جديدًا من الزر. اسم النفق للتعريف فقط. نفق واحد يمكنه تشغيل sunday.example.com على 5050 وmembership.example.com على 5060 وأي خدمات HTTP أخرى على نفس الجهاز.\r\n\r\n٥. اكتشف البرامج أو أضفها يدويًا، اكتب السب دومين والخدمة المحلية. اضبط مصادقة السيرفر أولًا. اختر البرامج ثم راجع المسارات وDNS قبل التنفيذ. لا يفتح البرنامج منافذ قاعدة البيانات.\r\n\r\n٦. إن لم يكن للنفق موصل يعمل بالفعل، ثبّت موصل العميل من تبويب ويندوز. كل جهاز زبون يحتاج البرامج المحلية وموصله. اجعل مديري السيرفرات يبدأون مع ويندوز واترك الجهاز متصلًا بالإنترنت.\r\n\r\n٧. استخدم https://اسم-البرنامج.دومين-العميل داخل التطبيق. اختبر من اتصال مختلف، مثل بيانات الموبايل، بعد أن يصبح النفق Healthy. تشغيل خدمة ويندوز وحده لا يثبت أن النفق متصل.\r\n\r\nإعدادات كل عميل مشفرة بحساب ويندوز الحالي. التصدير يشمل الدومين والمسارات فقط؛ لا ينقل التوكنات أو صلاحية النشر أو مسارات تشغيل البرامج. أعد إدخال بيانات العميل على جهازه. إضافة ملف عميل أو استيراده لا ينشر شيئًا.\r\n\r\nتغيير الدومين يفصل اختيار الحساب والنفق السابق. تغيير توكن API يتطلب إعادة الاتصال. حذف سطر من الجدول لا يحذف DNS أو مسارًا منشورًا سابقًا؛ إدارة الإزالة تتم من لوحة Cloudflare.\r\n\r\nملاحظات التثبيت الحالي: API العضوية على 5060 بلا مصادقة فعلية، ومدارس الأحد على 5050 تحتاج Jwt:Secret خاصًا. يجب إصلاح ذلك قبل إتاحتهما للعامة. إعداد Tunnel لا يعالج حماية السيرفر.\r\n\r\nالمراجع: developers.cloudflare.com/tunnel/get-started/\r\nhostinger.com/support/4741545-how-to-use-cloudflare-in-hostinger/";
        var buttons = Flow(52);
        buttons.Controls.AddRange([Button("لوحة Cloudflare", () => OpenUrl("https://dash.cloudflare.com/")), Button("لوحة Hostinger", () => OpenUrl("https://hpanel.hostinger.com/")), Button("دليل Cloudflare", () => OpenUrl("https://developers.cloudflare.com/tunnel/get-started/"))]);
        page.Controls.Add(help); page.Controls.Add(buttons);
        return page;
    }
    private void RefreshCustomers()
    {
        loading = true;
        customers.DataSource = null; customers.DataSource = profiles.ToList(); customers.SelectedItem = current;
        loading = false;
    }
    private void LoadCurrent()
    {
        loading = true;
        customerName.Text = current.Name; domain.Text = current.Domain; apiToken.Text = current.ApiToken;
        rows = new BindingList<LocalRoute>(current.Routes); grid.DataSource = rows;
        tunnels.DataSource = current.TunnelId.Length > 0 ? new List<TunnelInfo> { new(current.TunnelId, "النفق المحفوظ — اتصل لتحديث حالته", "غير مفحوص") } : null;
        zoneDetails.Text = "اتصل بحساب العميل لعرض حالة الدومين وNameservers والأنفاق.";
        loading = false; InvalidatePlan(); _ = ServiceStatus();
    }
    private void InvalidatePlan()
    {
        plan = null; apply.Enabled = false;
        preview.Text = "اضبط البرامج والدومين والحساب ثم اضغط «مراجعة DNS والمسارات».";
    }
    private void SaveCurrent(bool validateDomain = true)
    {
        grid.EndEdit();
        current.Name = customerName.Text.Trim().Length == 0 ? "عميل" : customerName.Text.Trim();
        var oldDomain = current.Domain;
        if (domain.Text.Trim().Length > 0 || validateDomain) current.ChangeDomain(domain.Text);
        else if (current.Domain.Length > 0) throw new InvalidOperationException("اكتب الدومين أو أعد القيمة السابقة قبل حفظ العميل.");
        var token = apiToken.Text.Trim();
        if (current.ApiToken != token || current.Domain != oldDomain)
        {
            current.ApiToken = token;
            current.AccountId = current.ZoneId = current.TunnelId = current.TunnelToken = "";
            tunnels.DataSource = null;
        }
        current.Routes = rows.ToList(); ProfileStore.Save(profiles);
    }
    private Task SaveAction() { SaveCurrent(false); RefreshCustomers(); status.Text = "حُفظ ملف العميل مشفرًا على الجهاز."; return Task.CompletedTask; }
    private Task NewCustomer()
    {
        SaveCurrent(false); current = new CustomerProfile(); profiles.Add(current); ProfileStore.Save(profiles); RefreshCustomers(); LoadCurrent(); return Task.CompletedTask;
    }
    private Task Export()
    {
        SaveCurrent();
        using var dialog = new SaveFileDialog { Filter = "Customer settings (*.json)|*.json", FileName = current.Domain + ".json" };
        if (dialog.ShowDialog(this) == DialogResult.OK) File.WriteAllText(dialog.FileName, ProfileStore.Export(current));
        return Task.CompletedTask;
    }
    private Task Import()
    {
        using var dialog = new OpenFileDialog { Filter = "Customer settings (*.json)|*.json" };
        if (dialog.ShowDialog(this) != DialogResult.OK) return Task.CompletedTask;
        SaveCurrent(false); var imported = ProfileStore.Import(File.ReadAllText(dialog.FileName));
        profiles.Add(imported); current = imported; ProfileStore.Save(profiles); RefreshCustomers(); LoadCurrent(); return Task.CompletedTask;
    }
    private LocalRoute? Selected() => grid.CurrentRow?.DataBoundItem as LocalRoute;
    private async Task Scan()
    {
        var found = await Task.Run(() => Discovery.Scan(), operation?.Token ?? lifetime.Token);
        AddFound(found);
    }
    private async Task ScanFolder()
    {
        using var picker = new FolderBrowserDialog { Description = "اختر مجلد تثبيت البرامج. الفحص محدود بمستويين داخله." };
        if (picker.ShowDialog(this) != DialogResult.OK) return;
        var found = await Task.Run(() => Discovery.Scan(picker.SelectedPath), operation!.Token);
        AddFound(found);
    }
    private void AddFound(List<LocalRoute> found)
    {
        var count = 0;
        foreach (var route in found) if (rows.All(r => r.Origin != route.Origin)) { rows.Add(route); count++; }
        InvalidatePlan(); SaveCurrent(false);
        status.Text = $"أُضيف {count} برنامج. المنافذ المحلية المستمعة: {Discovery.Listeners()}";
    }
    private async Task Health()
    {
        grid.EndEdit();
        await Task.WhenAll(rows.Select(async row => { row.Status = await Discovery.Reachable(row.Origin, operation!.Token) ? "متاح" : "لا يستجيب"; }));
        grid.Refresh(); status.Text = "اكتمل اختبار HTTP المحلي. راجع حالة كل برنامج.";
    }
    private Task OpenManager()
    {
        var selected = Selected() ?? throw new InvalidOperationException("اختر البرنامج.");
        if (!File.Exists(selected.ManagerPath)) throw new InvalidOperationException("لم يُكتشف مدير سيرفر لهذا السطر. افتحه من اختصار البرنامج.");
        Process.Start(new ProcessStartInfo(selected.ManagerPath) { UseShellExecute = true }); return Task.CompletedTask;
    }
    private Task CopyUrl()
    {
        var selected = Selected() ?? throw new InvalidOperationException("اختر البرنامج.");
        Clipboard.SetText("https://" + Validation.Host(domain.Text, selected.Subdomain)); status.Text = "نُسخ الرابط. يصبح صالحًا بعد نشر المسار واتصال النفق."; return Task.CompletedTask;
    }
    private static Task OpenUrl(string url) { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); return Task.CompletedTask; }
    private CloudflareClient Client() => new(current.ApiToken);
    private async Task Connect()
    {
        SaveCurrent(); InvalidatePlan();
        using var client = Client();
        var zone = await client.FindZone(current.Domain, operation!.Token);
        var available = await client.Tunnels(zone.AccountId, operation.Token);
        current.ZoneId = zone.Id; current.AccountId = zone.AccountId;
        if (available.All(t => t.Id != current.TunnelId)) current.TunnelId = current.TunnelToken = "";
        loading = true; tunnels.DataSource = available; tunnels.SelectedItem = available.FirstOrDefault(t => t.Id == current.TunnelId); loading = false;
        zoneDetails.Text = $"Domain: {current.Domain}\r\nStatus: {zone.Status}\r\nAccount: {zone.AccountId}\r\nZone: {zone.Id}\r\n\r\nNameservers المطلوب وضعها في Hostinger:\r\n{string.Join("\r\n", zone.NameServers)}\r\n\r\n{(zone.Status == "active" ? "الدومين مفعل. اختر النفق أو أنشئ نفقًا." : "انقل Nameservers بعد مراجعة سجلات الموقع والبريد، ثم أعد الاتصال حتى تصبح الحالة Active.")}";
        ProfileStore.Save(profiles); RefreshCustomers(); status.Text = "تم الاتصال بحساب العميل وقراءة إعداداته.";
    }
    private async Task CreateTunnel()
    {
        SaveCurrent(); Validation.Id(current.AccountId);
        // This explicit button is the user's remote create action; it never overwrites an existing tunnel.
        using var client = Client();
        var created = await client.CreateTunnel(current.AccountId, tunnelName.Text, operation!.Token);
        current.TunnelId = created.Id; current.TunnelToken = "";
        ProfileStore.Save(profiles); // Persist immediately: a later list refresh must not lose a successfully created tunnel.
        await Connect();
        status.Text = "أُنشئ النفق. راجع المسارات ثم ثبّت موصله عند الحاجة.";
    }
    private async Task Review()
    {
        SaveCurrent(); InvalidatePlan(); await CheckSelectedOrigins();
        using var client = Client();
        var reviewed = await client.Review(current, operation!.Token);
        plan = reviewed; preview.Text = reviewed.Describe(); apply.Enabled = true;
        status.Text = "المراجعة جاهزة؛ زر التنفيذ هو الذي يغيّر إعدادات Cloudflare.";
    }
    private async Task CheckSelectedOrigins()
    {
        var selected = Validation.Routes(current);
        foreach (var route in selected)
            if (!await Discovery.Reachable(route.Origin, operation!.Token)) throw new InvalidOperationException($"الخدمة {route.Origin} لا تستجيب. شغّل مدير السيرفر أولًا.");
    }
    private async Task Apply()
    {
        var reviewed = plan ?? throw new InvalidOperationException("راجع المسارات أولًا.");
        SaveCurrent(); await CheckSelectedOrigins();
        using var client = Client(); await client.Apply(current, reviewed, operation!.Token);
        Log("اكتمل نشر المسارات وDNS للعميل " + current.Name + " — " + current.Domain);
        InvalidatePlan(); status.Text = "نُشرت المسارات. يلزم موصل Healthy، ثم اختبر الروابط من خارج الشبكة.";
    }
    private Task ServiceStatus()
    {
        if (IsDisposed) return Task.CompletedTask;
        serviceDetails.Text = $"خدمة Daisson متعددة الأنفاق: {ServiceHost.Describe(ConnectorService.Name)}\r\nخدمة Cloudflared الموجودة: {ServiceHost.Describe("Cloudflared")}\r\n\r\nالعميل الحالي: {current.Name}\r\nDomain: {current.Domain}\r\nTunnel ID: {current.TunnelId}\r\n\r\nكل الأنفاق المثبتة في خدمة Daisson تبدأ معًا. اختيار عميل آخر في الواجهة لا يوقف الأنفاق.\r\nهذه حالة خدمة ويندوز فقط؛ حالة اتصال النفق تظهر عند الاتصال بحساب Cloudflare.\r\nملف سجل الخدمة (للمسؤول): {Path.Combine(ConnectorService.DataRoot, "service.log")}";
        return Task.CompletedTask;
    }
    private async Task InstallConnector()
    {
        SaveCurrent(); Validation.Id(current.TunnelId); Validation.Id(current.AccountId);
        using var client = Client();
        // Fetch the token for exactly the selected account/tunnel, never reuse another profile's token.
        current.TunnelToken = await client.TunnelToken(current.AccountId, current.TunnelId, operation!.Token); ProfileStore.Save(profiles);
        status.Text = "تنزيل cloudflared الرسمي والتحقق من بصمته...";
        var binary = await ConnectorService.Download(operation.Token);
        operation.Token.ThrowIfCancellationRequested();
        status.Text = "وافق على طلب ويندوز لتثبيت خدمة موصل العميل.";
        await ConnectorService.Elevate(new InstallRequest(new ConnectorEntry(current.Id, current.TunnelId, current.TunnelToken), binary.Path, binary.ReleaseTag));
        await ServiceStatus(); status.Text = "ثُبّت موصل العميل. أعد الاتصال بـCloudflare للتحقق من حالة النفق.";
    }
    private async Task RemoveConnector()
    {
        SaveCurrent(false);
        await ConnectorService.Elevate(new InstallRequest(new ConnectorEntry(current.Id, "", ""), "", "", true));
        await ServiceStatus(); status.Text = "أُزيل موصل العميل من خدمة Daisson. لم يُحذف النفق أو DNS من Cloudflare.";
    }
    private async Task Busy(Func<Task> action)
    {
        if (running || IsDisposed) return;
        running = true; content.Enabled = false; cancel.Enabled = true;
        operation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token);
        try { await action(); }
        catch (OperationCanceledException) { status.Text = "أُلغيت العملية."; }
        catch (Exception ex) { ShowError(ex); }
        finally
        {
            operation.Dispose(); operation = null; running = false;
            if (!IsDisposed) { content.Enabled = true; cancel.Enabled = false; apply.Enabled = plan is not null; }
        }
    }
    private void ShowError(Exception ex)
    {
        var message = ex is Win32Exception w && w.NativeErrorCode == 1223 ? "أُلغي طلب صلاحية المسؤول." : ex.Message;
        foreach (var secret in profiles.SelectMany(p => new[] { p.ApiToken, p.TunnelToken }).Where(t => t.Length > 4)) message = message.Replace(secret, "[محجوب]", StringComparison.Ordinal);
        status.Text = message; Log(message);
        if (!IsDisposed) MessageBox.Show(this, message, "تعذر إتمام العملية", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }
    private void Log(string message) { if (!IsDisposed) log.AppendText($"{DateTime.Now:HH:mm:ss} {message}\r\n"); }
    protected override void Dispose(bool disposing)
    {
        if (disposing && !resourcesDisposed) { resourcesDisposed = true; lifetime.Cancel(); lifetime.Dispose(); }
        base.Dispose(disposing);
    }
}
