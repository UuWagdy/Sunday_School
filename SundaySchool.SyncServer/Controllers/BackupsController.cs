using DatabaseBackups;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SundaySchool.SyncServer.Services;

namespace SundaySchool.SyncServer.Controllers;

[ApiController, Authorize, Route("api/backups")]
public sealed class BackupsController(NativeBackupService backups, StorageService storage) : ControllerBase
{
    private async Task<bool> Allowed()
    {
        var raw = User.FindFirst("sub")?.Value ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(raw, out var id)) return false;
        var policy = await storage.GetVisibilityPolicyAsync(id);
        return policy.CanMaintain && !policy.Restricted;
    }
    [HttpGet("settings")]
    public async Task<IActionResult> Settings() => await Allowed() ? Ok(backups.Settings) : Forbid();
    [HttpPut("settings")]
    public async Task<IActionResult> Configure(BackupSettings settings)
    {
        if (!await Allowed()) return Forbid();
        try { return Ok(await backups.ConfigureAsync(settings)); }
        catch (Exception ex) { return BadRequest(new { error = ex.Message }); }
    }
    [HttpPost("run")]
    public async Task<IActionResult> Run(CancellationToken token)
    {
        if (!await Allowed()) return Forbid();
        try { await backups.CreateAsync(true, token: token); return Ok(backups.Settings); }
        catch (Exception ex) { return BadRequest(new { error = ex.Message }); }
    }
    [HttpGet("download")]
    public async Task<IActionResult> Download(CancellationToken token)
    {
        if (!await Allowed()) return Forbid();
        var path = await backups.CreateAsync(false, token: token);
        var stream = new FileStream(path!, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, FileOptions.DeleteOnClose);
        return File(stream, "application/octet-stream", Path.GetFileName(path));
    }
    [HttpPost("restore"), RequestSizeLimit(2L * 1024 * 1024 * 1024)]
    public async Task<IActionResult> Restore(CancellationToken token)
    {
        if (!await Allowed()) return Forbid();
        var path = Path.Combine(Path.GetTempPath(), $"restore-{Guid.NewGuid():N}.dump");
        try
        {
            await using (var file = System.IO.File.Create(path)) await Request.Body.CopyToAsync(file, token);
            await backups.RestoreAsync(path, token);
            PersonChangeFeed.Invalidate();
            await storage.BroadcastChangesAsync(PostgresSchemaInitializer.OrderedTables.ToList(), "RESTORE_POSTGRESQL", null, null);
            return Ok(new { status = "ok" });
        }
        catch (Exception ex) { return BadRequest(new { error = ex.Message }); }
        finally { if (System.IO.File.Exists(path)) System.IO.File.Delete(path); }
    }
}
