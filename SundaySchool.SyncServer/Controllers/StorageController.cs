using Microsoft.AspNetCore.Mvc;
using SundaySchool.SyncServer.Models;
using SundaySchool.SyncServer.Services;
using Microsoft.AspNetCore.Authorization;

namespace SundaySchool.SyncServer.Controllers;

[ApiController]
[Authorize]
[Route("api/storage")]
[RequestSizeLimit(100 * 1024 * 1024)]
public sealed class StorageController : ControllerBase
{
    private readonly StorageService _storage;
    private readonly PostgresSchemaInitializer _schema;
    private readonly ILogger<StorageController> _logger;

    public StorageController(
        StorageService storage,
        PostgresSchemaInitializer schema,
        ILogger<StorageController> logger)
    {
        _storage = storage;
        _schema = schema;
        _logger = logger;
    }

    [HttpPost("query")]
    public async Task<ActionResult<SqlQueryResponse>> Query([FromBody] SqlRequest request)
    {
        try
        {
            var policy = await CurrentPolicy(request.TransactionId);
            var res = await _storage.QueryAsync(request, policy);
            return Ok(res);
        }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Query failed: {Sql}", request.Sql);
            return BadRequest(new { error = ex.Message, sql = request.Sql });
        }
    }

    [HttpPost("person-changes")]
    public async Task<ActionResult<PersonChangesResponse>> PersonChanges(
        [FromBody] PersonChangesRequest request, [FromServices] PersonChangeFeed feed)
    {
        try { return Ok(await feed.ReadAsync(request, await CurrentPolicy())); }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (ArgumentException) { return BadRequest(new { error = "Invalid change cursor." }); }
    }

    [HttpPost("insert")]
    public async Task<ActionResult<SqlExecuteResponse>> Insert([FromBody] SqlRequest request)
    {
        try
        {
            var res = await _storage.ExecuteInsertAsync(request, await CurrentPolicy(request.TransactionId));
            return Ok(res);
        }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Insert failed: {Sql}", request.Sql);
            return BadRequest(new { error = ex.Message, sql = request.Sql });
        }
    }

    [HttpPost("execute")]
    public async Task<ActionResult<SqlExecuteResponse>> Execute([FromBody] SqlRequest request)
    {
        try
        {
            var res = await _storage.ExecuteNonQueryAsync(request, await CurrentPolicy(request.TransactionId));
            return Ok(res);
        }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Execute failed: {Sql}", request.Sql);
            return BadRequest(new { error = ex.Message, sql = request.Sql });
        }
    }

    [HttpPost("batch")]
    public async Task<ActionResult<SqlExecuteResponse>> Batch([FromBody] SqlBatchRequest request)
    {
        try
        {
            var res = await _storage.ExecuteBatchAsync(request, await CurrentPolicy(request.TransactionId));
            return Ok(res);
        }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Batch failed.");
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("tx/begin")]
    public async Task<ActionResult<BeginTransactionResponse>> BeginTransaction()
    {
        var id = await _storage.BeginTransactionAsync((await CurrentPolicy()).UserId);
        return Ok(new BeginTransactionResponse { TransactionId = id });
    }

    [HttpPost("tx/commit")]
    public async Task<IActionResult> CommitTransaction([FromBody] TransactionControlRequest request)
    {
        try {
            await _storage.CommitTransactionAsync(request.TransactionId, request.DeviceId, request.ConnectionId, await CurrentPolicy(request.TransactionId));
            return Ok(new { status = "committed" });
        } catch (UnauthorizedAccessException) { return Forbid(); }
    }

    [HttpPost("tx/rollback")]
    public async Task<IActionResult> RollbackTransaction([FromBody] TransactionControlRequest request)
    {
        try {
            await CurrentPolicy(request.TransactionId);
            await _storage.RollbackTransactionAsync(request.TransactionId);
            return Ok(new { status = "rolled_back" });
        } catch (UnauthorizedAccessException) { return Forbid(); }
    }

    [HttpPost("import-sqlite")]
    public async Task<IActionResult> ImportSqlite([FromQuery] bool overwrite = true, [FromQuery] string? deviceId = null)
    {
        var policy = await CurrentPolicy();
        if (!policy.CanMaintain || policy.Restricted) return Forbid();
        var tempFile = Path.Combine(Path.GetTempPath(), $"SundaySchool_Upload_{Guid.NewGuid():N}.db");
        try
        {
            if (Request.HasFormContentType && Request.Form.Files.Count > 0)
            {
                await using var fs = System.IO.File.Create(tempFile);
                await Request.Form.Files[0].CopyToAsync(fs);
            }
            else
            {
                await using var fs = System.IO.File.Create(tempFile);
                await Request.Body.CopyToAsync(fs);
            }

            await _schema.ImportFromSqliteFileAsync(tempFile, overwrite);
            PersonChangeFeed.Invalidate();
            await _storage.BroadcastChangesAsync(
                PostgresSchemaInitializer.OrderedTables.ToList(),
                "IMPORT_SQLITE",
                deviceId,
                null);

            return Ok(new { status = "ok", message = "تم رفع واستيراد قاعدة البيانات إلى PostgreSQL بنجاح!" });
        }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to import uploaded SQLite database.");
            return BadRequest(new { error = ex.Message });
        }
        finally
        {
            if (System.IO.File.Exists(tempFile))
            {
                try { System.IO.File.Delete(tempFile); } catch { }
            }
        }
    }

    [HttpGet("export-sqlite")]
    public async Task<IActionResult> ExportSqlite()
    {
        var policy = await CurrentPolicy();
        if (!policy.CanMaintain || policy.Restricted) return Forbid();
        try
        {
            var bytes = await _storage.ExportToSqliteBytesAsync();
            return File(bytes, "application/octet-stream", $"Betros_Bols_PostgreSQL_Backup_{DateTime.Now:yyyyMMdd_HHmmss}.db");
        }
        catch (UnauthorizedAccessException) { return Forbid(); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to export PostgreSQL to SQLite backup.");
            return BadRequest(new { error = ex.Message });
        }
    }

    private async Task<DataVisibilityPolicy> CurrentPolicy(string? transactionId = null)
    {
        var raw = User.FindFirst("sub")?.Value ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(raw,out var userId)) throw new UnauthorizedAccessException();
        _storage.AssertTransactionOwner(transactionId,userId);
        return await _storage.GetVisibilityPolicyAsync(userId);
    }
}
