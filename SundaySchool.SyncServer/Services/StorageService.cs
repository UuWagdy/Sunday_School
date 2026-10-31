using System.Collections.Concurrent;
using System.Text.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Data.Sqlite;
using Npgsql;
using NpgsqlTypes;
using SundaySchool.SyncServer.Hubs;
using SundaySchool.SyncServer.Models;

namespace SundaySchool.SyncServer.Services;

public sealed class StorageService : IDisposable
{
    private sealed class TransactionSession : IAsyncDisposable
    {
        public required string Id { get; init; }
        public int UserId { get; init; }
        public HashSet<int> CreatedPersonIds { get; } = new();
        public required NpgsqlConnection Connection { get; init; }
        public required NpgsqlTransaction Transaction { get; init; }
        public SemaphoreSlim Lock { get; } = new(1, 1);
        public HashSet<string> AffectedTables { get; } = new(StringComparer.OrdinalIgnoreCase);
        public DateTime LastActivityUtc { get; set; } = DateTime.UtcNow;

        public async ValueTask DisposeAsync()
        {
            Lock.Dispose();
            await Transaction.DisposeAsync();
            await Connection.DisposeAsync();
        }
    }

    private readonly PostgresSchemaInitializer _schema;
    private readonly IHubContext<SyncHub> _hubContext;
    private readonly ILogger<StorageService> _logger;
    private readonly ConcurrentDictionary<string, TransactionSession> _transactions = new();
    private readonly Timer _cleanupTimer;
    private long _sequenceCounter = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
    private readonly string _readCacheEpoch = Guid.NewGuid().ToString("N");

    public StorageService(
        PostgresSchemaInitializer schema,
        IHubContext<SyncHub> hubContext,
        ILogger<StorageService> logger)
    {
        _schema = schema;
        _hubContext = hubContext;
        _logger = logger;
        _cleanupTimer = new Timer(CleanupStaleTransactions, null, TimeSpan.FromMinutes(1), TimeSpan.FromMinutes(1));
    }

    public long CurrentSequenceId => Interlocked.Read(ref _sequenceCounter);

    public async Task<bool> UserExistsAsync(int userId)
    {
        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("SELECT EXISTS(SELECT 1 FROM pass WHERE pass_id=@id)", conn);
        cmd.Parameters.AddWithValue("id", userId);
        return (bool)(await cmd.ExecuteScalarAsync())!;
    }

    public async Task<DataVisibilityPolicy> GetVisibilityPolicyAsync(int userId)
    {
        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        bool canUsers, canMaintenance;
        await using (var cmd = new NpgsqlCommand("SELECT can_users, can_maintenance FROM pass WHERE pass_id=@id", conn))
        {
            cmd.Parameters.AddWithValue("id",userId);
            await using var reader = await cmd.ExecuteReaderAsync();
            if (!await reader.ReadAsync()) throw new UnauthorizedAccessException("انتهت صلاحية المستخدم.");
            canUsers = ReadBoolInt(reader,0); canMaintenance = ReadBoolInt(reader,1);
        }
        await using var scopeCommand = new NpgsqlCommand("SELECT setting_value FROM settings WHERE setting_key=@key",conn);
        scopeCommand.Parameters.AddWithValue("key",$"user_data_scope_{userId}");
        var raw = await scopeCommand.ExecuteScalarAsync() as string;
        var selections=DataVisibilityPolicy.Decode(raw);
        if(raw==null)
        {
            var legacy=await FetchAllVisibilityFiltersAsync(conn,userId);
            if(legacy.TryGetValue(userId,out var filters))
                foreach(var (key,ids) in filters.Where(x=>new[]{"service","gender","stage","khoros","area"}.Contains(x.Key)))
                    selections[key]=ids.Select(id=>key=="gender" ? (id==1 ? "ذكر" : id==2 ? "أنثى" : "") : id.ToString()).Where(x=>x.Length>0).ToList();
        }
        return new DataVisibilityPolicy { UserId=userId, CanManageUsers=canUsers, CanMaintain=canMaintenance, Selections=selections };
    }

    public async Task<bool> CheckHealthAsync()
    {
        try
        {
            await using var conn = new NpgsqlConnection(_schema.ConnectionString);
            await conn.OpenAsync();
            await using var cmd = new NpgsqlCommand("SELECT 1;", conn);
            await cmd.ExecuteScalarAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PostgreSQL health check failed.");
            return false;
        }
    }

    public async Task<List<UserDto>> GetAllUsersAsync()
    {
        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();

        var permissionsByUser = await FetchAllGranularPermissionsAsync(conn);
        var filtersByUser = await FetchAllVisibilityFiltersAsync(conn);

        var users = new List<UserDto>();
        await using var cmd = new NpgsqlCommand("""
            SELECT
                pass_id, person_name,
                can_persons, can_stages, can_areas, can_fathers,
                can_reports, can_users, can_absence, can_maintenance,
                can_id_card, can_tayo, can_transfer, can_services,
                can_khoros, can_behavior, is_advanced
            FROM pass
            ORDER BY pass_id ASC;
            """, conn);

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var id = reader.GetInt32(0);
            var filters = filtersByUser.TryGetValue(id, out var f) ? f : new Dictionary<string, List<int>>();
            users.Add(new UserDto
            {
                Id = id,
                Username = reader.IsDBNull(1) ? string.Empty : reader.GetString(1),
                CanPersons = ReadBoolInt(reader, 2),
                CanStages = ReadBoolInt(reader, 3),
                CanAreas = ReadBoolInt(reader, 4),
                CanFathers = ReadBoolInt(reader, 5),
                CanReports = ReadBoolInt(reader, 6),
                CanUsers = ReadBoolInt(reader, 7),
                CanAbsence = ReadBoolInt(reader, 8),
                CanMaintenance = ReadBoolInt(reader, 9),
                CanIdCard = ReadBoolInt(reader, 10),
                CanTayo = ReadBoolInt(reader, 11),
                CanTransfer = ReadBoolInt(reader, 12),
                CanServices = ReadBoolInt(reader, 13),
                CanKhoros = ReadBoolInt(reader, 14),
                CanBehavior = ReadBoolInt(reader, 15),
                IsAdvanced = ReadBoolInt(reader, 16),
                GranularPermissions = permissionsByUser.TryGetValue(id, out var perms) ? perms : new(),
                VisibilityFilters = filters,
                VisibleUserIds = filters.TryGetValue("user", out var uIds) ? uIds : new(),
            });
        }

        return users;
    }

    public async Task<UserDto?> AuthenticateUserAsync(string username, string password)
    {
        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand("""
            SELECT
                pass_id, person_name, pass_word,
                can_persons, can_stages, can_areas, can_fathers,
                can_reports, can_users, can_absence, can_maintenance,
                can_id_card, can_tayo, can_transfer, can_services,
                can_khoros, can_behavior, is_advanced
            FROM pass
            WHERE person_name = @u
            LIMIT 1;
            """, conn);
        cmd.Parameters.AddWithValue("u", username);

        int userId;
        string storedUsername;
        string? storedPassword;
        UserDto user;

        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            if (!await reader.ReadAsync()) return null;
            userId = reader.GetInt32(0);
            storedUsername = reader.IsDBNull(1) ? string.Empty : reader.GetString(1);
            storedPassword = reader.IsDBNull(2) ? null : reader.GetString(2);

            if (storedPassword != password) return null;

            user = new UserDto
            {
                Id = userId,
                Username = storedUsername,
                CanPersons = ReadBoolInt(reader, 3),
                CanStages = ReadBoolInt(reader, 4),
                CanAreas = ReadBoolInt(reader, 5),
                CanFathers = ReadBoolInt(reader, 6),
                CanReports = ReadBoolInt(reader, 7),
                CanUsers = ReadBoolInt(reader, 8),
                CanAbsence = ReadBoolInt(reader, 9),
                CanMaintenance = ReadBoolInt(reader, 10),
                CanIdCard = ReadBoolInt(reader, 11),
                CanTayo = ReadBoolInt(reader, 12),
                CanTransfer = ReadBoolInt(reader, 13),
                CanServices = ReadBoolInt(reader, 14),
                CanKhoros = ReadBoolInt(reader, 15),
                CanBehavior = ReadBoolInt(reader, 16),
                IsAdvanced = ReadBoolInt(reader, 17),
            };
        }

        var perms = await FetchAllGranularPermissionsAsync(conn, userId);
        var filters = await FetchAllVisibilityFiltersAsync(conn, userId);

        user.GranularPermissions = perms.TryGetValue(userId, out var p) ? p : new();
        user.VisibilityFilters = filters.TryGetValue(userId, out var f) ? f : new();
        user.VisibleUserIds = user.VisibilityFilters.TryGetValue("user", out var uIds) ? uIds : new();
        user.DataVisibilityScope = (await GetVisibilityPolicyAsync(userId)).Selections;

        return user;
    }

    private static bool ReadBoolInt(NpgsqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal)) return false;
        var val = reader.GetValue(ordinal);
        if (val is bool b) return b;
        return Convert.ToInt64(val) != 0;
    }

    private static async Task<Dictionary<int, Dictionary<string, Dictionary<string, bool>>>> FetchAllGranularPermissionsAsync(
        NpgsqlConnection conn, int? filterUserId = null)
    {
        var result = new Dictionary<int, Dictionary<string, Dictionary<string, bool>>>();
        var sql = filterUserId.HasValue
            ? "SELECT user_id, feature_key, can_add, can_edit, can_delete FROM user_permissions_ext WHERE user_id = @uid;"
            : "SELECT user_id, feature_key, can_add, can_edit, can_delete FROM user_permissions_ext;";

        await using var cmd = new NpgsqlCommand(sql, conn);
        if (filterUserId.HasValue) cmd.Parameters.AddWithValue("uid", filterUserId.Value);

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var uid = reader.GetInt32(0);
            var rawKey = reader.GetString(1);
            var featureKey = rawKey == "absence" ? "attendance" : rawKey;
            var canAdd = ReadBoolInt(reader, 2);
            var canEdit = ReadBoolInt(reader, 3);
            var canDelete = ReadBoolInt(reader, 4);

            if (!result.TryGetValue(uid, out var userMap))
            {
                userMap = new Dictionary<string, Dictionary<string, bool>>();
                result[uid] = userMap;
            }

            if (!userMap.TryGetValue(featureKey, out var flags))
            {
                flags = new Dictionary<string, bool> { ["add"] = false, ["edit"] = false, ["delete"] = false };
                userMap[featureKey] = flags;
            }

            flags["add"] = flags["add"] || canAdd;
            flags["edit"] = flags["edit"] || canEdit;
            flags["delete"] = flags["delete"] || canDelete;
        }
        return result;
    }

    private static async Task<Dictionary<int, Dictionary<string, List<int>>>> FetchAllVisibilityFiltersAsync(
        NpgsqlConnection conn, int? filterUserId = null)
    {
        var result = new Dictionary<int, Dictionary<string, List<int>>>();
        var sql = filterUserId.HasValue
            ? "SELECT user_id, filter_type, value_id FROM user_visibility_filters WHERE user_id = @uid;"
            : "SELECT user_id, filter_type, value_id FROM user_visibility_filters;";

        await using var cmd = new NpgsqlCommand(sql, conn);
        if (filterUserId.HasValue) cmd.Parameters.AddWithValue("uid", filterUserId.Value);

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var uid = reader.GetInt32(0);
            var filterType = reader.GetString(1);
            var valueId = reader.GetInt32(2);

            if (!result.TryGetValue(uid, out var userMap))
            {
                userMap = new Dictionary<string, List<int>>();
                result[uid] = userMap;
            }

            if (!userMap.TryGetValue(filterType, out var list))
            {
                list = new List<int>();
                userMap[filterType] = list;
            }
            list.Add(valueId);
        }
        return result;
    }

    public void AssertTransactionOwner(string? transactionId,int userId)
    {
        if(string.IsNullOrWhiteSpace(transactionId)) return;
        if(!_transactions.TryGetValue(transactionId,out var session) || session.UserId!=userId)
            throw new UnauthorizedAccessException("المعاملة لا تخص هذا المستخدم.");
    }

    public async Task<string> BeginTransactionAsync(int userId = 0)
    {
        var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        var tx = await conn.BeginTransactionAsync();
        var id = Guid.NewGuid().ToString("N");
        var session = new TransactionSession
        {
            Id = id,
            UserId = userId,
            Connection = conn,
            Transaction = tx,
            LastActivityUtc = DateTime.UtcNow,
        };
        _transactions[id] = session;
        return id;
    }

    public async Task CommitTransactionAsync(string transactionId, string? deviceId, string? connectionId, DataVisibilityPolicy? policy = null)
    {
        if (!_transactions.TryRemove(transactionId, out var session))
        {
            return;
        }

        await session.Lock.WaitAsync();
        try
        {
            if(policy?.Restricted == true && session.CreatedPersonIds.Count>0)
            {
                var ids=string.Join(",",session.CreatedPersonIds);
                var visible=await ExecuteReaderInternalAsync(session.Connection,session.Transaction,policy.ReadSql($"SELECT person_id FROM persons WHERE person_id IN ({ids})"),new());
                if(visible.Rows.Count!=session.CreatedPersonIds.Count) throw new UnauthorizedAccessException("بيانات الشخص الجديد لا تطابق نطاق المستخدم.");
            }
            await session.Transaction.CommitAsync();

            if (session.AffectedTables.Count > 0)
            {
                var tables = session.AffectedTables.Select(SqlDialectTranslator.ToCanonicalTableName).ToList();
                await BroadcastChangesAsync(tables, "TRANSACTION_COMMIT", deviceId, connectionId);
            }
        }
        finally
        {
            session.Lock.Release();
            await session.DisposeAsync();
        }
    }

    public async Task RollbackTransactionAsync(string transactionId)
    {
        if (!_transactions.TryRemove(transactionId, out var session))
        {
            return;
        }

        await session.Lock.WaitAsync();
        try
        {
            await session.Transaction.RollbackAsync();
        }
        catch
        {
            // ignore rollback errors on closed connection
        }
        finally
        {
            session.Lock.Release();
            await session.DisposeAsync();
        }
    }

    public async Task<SqlQueryResponse> QueryAsync(SqlRequest request, DataVisibilityPolicy? policy = null)
    {
        policy?.ValidateRead(request.Sql);
        var translated = SqlDialectTranslator.Translate(request.Sql, isInsertRequest: false);
        if (translated.IsPragma)
        {
            if (translated.PragmaTableInfoTarget is not null)
            {
                return await ExecutePragmaTableInfoAsync(translated.PragmaTableInfoTarget, request.TransactionId);
            }
            return new SqlQueryResponse();
        }

        if (!string.IsNullOrWhiteSpace(request.TransactionId) &&
            _transactions.TryGetValue(request.TransactionId, out var session))
        {
            await session.Lock.WaitAsync();
            try
            {
                session.LastActivityUtc = DateTime.UtcNow;
                return await ExecuteReaderInternalAsync(session.Connection, session.Transaction, policy?.ReadSql(translated.Sql) ?? translated.Sql, request.Params);
            }
            finally
            {
                session.Lock.Release();
            }
        }

        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        string? cacheTag = null;
        // Validate the client's snapshot against PostgreSQL on every read.
        // This observes external writes and out-of-order commits as well as API
        // writes. No cached results are used within explicit transactions.
        if (request.AcceptCache && !Regex.IsMatch(request.Sql,
            @"\b(now|current_timestamp|current_date|current_time|datetime|strftime|random)\b", RegexOptions.IgnoreCase))
        {
            await using var snapshotCommand = new NpgsqlCommand("SELECT pg_current_snapshot()::text", conn);
            var snapshot = (string)(await snapshotCommand.ExecuteScalarAsync())!;
            var identity = JsonSerializer.Serialize(new {
                epoch = _readCacheEpoch, snapshot, request.Sql, request.Params,
                user = policy?.UserId, users = policy?.CanManageUsers,
                scope = policy?.Selections.OrderBy(x => x.Key).ToDictionary(x => x.Key, x => x.Value.Order().ToArray())
            });
            cacheTag = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(identity)));
            if (cacheTag == request.CacheTag)
                return new SqlQueryResponse { CacheTag = cacheTag, NotModified = true };
        }
        var result = await ExecuteReaderInternalAsync(conn, null, policy?.ReadSql(translated.Sql) ?? translated.Sql, request.Params);
        result.CacheTag = cacheTag;
        return result;
    }

    public async Task<SqlExecuteResponse> ExecuteInsertAsync(SqlRequest request, DataVisibilityPolicy? policy = null)
    {
        var translated = SqlDialectTranslator.Translate(request.Sql, isInsertRequest: true);
        if (policy != null) translated = translated with { Sql = policy.MutationSql(request, translated.Sql) };
        if (translated.IsPragma || string.IsNullOrWhiteSpace(translated.Sql))
        {
            return new SqlExecuteResponse();
        }

        if (!string.IsNullOrWhiteSpace(request.TransactionId) &&
            _transactions.TryGetValue(request.TransactionId, out var session))
        {
            await session.Lock.WaitAsync();
            try
            {
                session.LastActivityUtc = DateTime.UtcNow;
                var (lastId, rows) = await RunInsertInternalAsync(
                    session.Connection, session.Transaction, translated, request.Params, policy, session.CreatedPersonIds);
                if(translated.AffectedTable=="persons" && lastId>0) session.CreatedPersonIds.Add((int)lastId);
                if (translated.AffectedTable is not null)
                {
                    session.AffectedTables.Add(translated.AffectedTable);
                }
                return new SqlExecuteResponse
                {
                    LastInsertId = lastId,
                    RowsAffected = rows,
                    AffectedTables = translated.AffectedTable is not null
                        ? [SqlDialectTranslator.ToCanonicalTableName(translated.AffectedTable)]
                        : [],
                    SequenceId = CurrentSequenceId,
                };
            }
            finally
            {
                session.Lock.Release();
            }
        }

        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        var (insertedId, rowsAffected) = await RunInsertInternalAsync(conn, null, translated, request.Params, policy);

        var affectedList = new List<string>();
        long seqId = CurrentSequenceId;
        if (translated.AffectedTable is not null)
        {
            var canonical = SqlDialectTranslator.ToCanonicalTableName(translated.AffectedTable);
            affectedList.Add(canonical);
            seqId = await BroadcastChangesAsync(affectedList, "INSERT", request.DeviceId, request.ConnectionId);
        }

        return new SqlExecuteResponse
        {
            LastInsertId = insertedId,
            RowsAffected = rowsAffected,
            AffectedTables = affectedList,
            SequenceId = seqId,
        };
    }

    public async Task<SqlExecuteResponse> ExecuteNonQueryAsync(SqlRequest request, DataVisibilityPolicy? policy = null)
    {
        if (System.Text.RegularExpressions.Regex.IsMatch(request.Sql, @"^\s*INSERT\b", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
            return await ExecuteInsertAsync(request, policy);
        var translated = SqlDialectTranslator.Translate(request.Sql, isInsertRequest: false);
        if (policy != null) translated = translated with { Sql = policy.MutationSql(request, translated.Sql) };
        if (translated.IsPragma || string.IsNullOrWhiteSpace(translated.Sql))
        {
            return new SqlExecuteResponse();
        }

        if (!string.IsNullOrWhiteSpace(request.TransactionId) &&
            _transactions.TryGetValue(request.TransactionId, out var session))
        {
            await session.Lock.WaitAsync();
            try
            {
                session.LastActivityUtc = DateTime.UtcNow;
                await using var cmd = CreateCommand(session.Connection, session.Transaction, translated.Sql, request.Params);
                var rows = await cmd.ExecuteNonQueryAsync();
                if (translated.AffectedTable is not null)
                {
                    session.AffectedTables.Add(translated.AffectedTable);
                }
                return new SqlExecuteResponse
                {
                    RowsAffected = Math.Max(rows, 0),
                    AffectedTables = translated.AffectedTable is not null
                        ? [SqlDialectTranslator.ToCanonicalTableName(translated.AffectedTable)]
                        : [],
                    SequenceId = CurrentSequenceId,
                };
            }
            finally
            {
                session.Lock.Release();
            }
        }

        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        await using var command = CreateCommand(conn, null, translated.Sql, request.Params);
        var affectedRows = await command.ExecuteNonQueryAsync();

        var affectedList = new List<string>();
        long seqId = CurrentSequenceId;
        if (translated.AffectedTable is not null)
        {
            var canonical = SqlDialectTranslator.ToCanonicalTableName(translated.AffectedTable);
            affectedList.Add(canonical);
            seqId = await BroadcastChangesAsync(affectedList, "EXECUTE", request.DeviceId, request.ConnectionId);
        }

        return new SqlExecuteResponse
        {
            RowsAffected = Math.Max(affectedRows, 0),
            AffectedTables = affectedList,
            SequenceId = seqId,
        };
    }

    public async Task<SqlExecuteResponse> ExecuteBatchAsync(SqlBatchRequest request, DataVisibilityPolicy? policy = null)
    {
        if (!string.IsNullOrWhiteSpace(request.TransactionId) &&
            _transactions.TryGetValue(request.TransactionId, out var session))
        {
            await session.Lock.WaitAsync();
            try
            {
                session.LastActivityUtc = DateTime.UtcNow;
                var (totalRows, tables) = await RunBatchInternalAsync(session.Connection, session.Transaction, request.Statements, policy, session.CreatedPersonIds);
                foreach (var t in tables) session.AffectedTables.Add(t);
                return new SqlExecuteResponse
                {
                    RowsAffected = totalRows,
                    AffectedTables = tables.Select(SqlDialectTranslator.ToCanonicalTableName).ToList(),
                    SequenceId = CurrentSequenceId,
                };
            }
            finally
            {
                session.Lock.Release();
            }
        }

        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        await using var tx = await conn.BeginTransactionAsync();
        try
        {
            var (totalRows, tables) = await RunBatchInternalAsync(conn, tx, request.Statements, policy);
            await tx.CommitAsync();

            var canonicalTables = tables.Select(SqlDialectTranslator.ToCanonicalTableName).ToList();
            var seqId = canonicalTables.Count > 0
                ? await BroadcastChangesAsync(canonicalTables, "BATCH", request.DeviceId, request.ConnectionId)
                : CurrentSequenceId;

            return new SqlExecuteResponse
            {
                RowsAffected = totalRows,
                AffectedTables = canonicalTables,
                SequenceId = seqId,
            };
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    private static async Task<(int TotalRows, HashSet<string> Tables)> RunBatchInternalAsync(
        NpgsqlConnection conn,
        NpgsqlTransaction? tx,
        List<SqlBatchStatementDto> statements, DataVisibilityPolicy? policy = null, HashSet<int>? createdPeople = null)
    {
        int totalRows = 0;
        var tables = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var stmt in statements)
        {
            var isInsert = System.Text.RegularExpressions.Regex.IsMatch(stmt.Sql, @"^\s*INSERT\b", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            var translated = SqlDialectTranslator.Translate(stmt.Sql, isInsertRequest: isInsert);
            if (policy != null) {
                var sets = stmt.ArgSets.Count == 0 ? new List<List<SqlParamDto>> { new() } : stmt.ArgSets;
                foreach(var args in sets) policy.MutationSql(new SqlRequest { Sql=stmt.Sql, Params=args },translated.Sql);
                translated = translated with { Sql=policy.MutationSql(new SqlRequest { Sql=stmt.Sql, Params=sets[0] },translated.Sql) };
            }
            if (translated.IsPragma || string.IsNullOrWhiteSpace(translated.Sql)) continue;
            if (translated.AffectedTable is not null) tables.Add(translated.AffectedTable);

            if(isInsert)
            {
                var sets = stmt.ArgSets.Count == 0 ? new List<List<SqlParamDto>> { new() } : stmt.ArgSets;
                foreach(var args in sets)
                {
                    var (lastId, rows) = await RunInsertInternalAsync(conn,tx,translated,args,policy,createdPeople);
                    totalRows += rows;
                    if(translated.AffectedTable=="persons" && lastId>0) createdPeople?.Add((int)lastId);
                }
                continue;
            }

            if (stmt.ArgSets.Count == 0)
            {
                await using var cmd = CreateCommand(conn, tx, translated.Sql, []);
                var r = await cmd.ExecuteNonQueryAsync();
                if (r > 0) totalRows += r;
            }
            else
            {
                foreach (var argSet in stmt.ArgSets)
                {
                    await using var cmd = CreateCommand(conn, tx, translated.Sql, argSet);
                    var r = await cmd.ExecuteNonQueryAsync();
                    if (r > 0) totalRows += r;
                }
            }
        }

        return (totalRows, tables);
    }

    private static async Task ValidateScopedInsertAsync(NpgsqlConnection conn,NpgsqlTransaction? tx,SqlDialectTranslator.TranslatedSql translated,List<SqlParamDto> parameters,DataVisibilityPolicy policy,HashSet<int>? createdPeople)
    {
        var table=translated.AffectedTable;
        if(table is not ("coming" or "visitations" or "person_services" or "person_tayo_points" or "person_custom_field_values" or "person_documents" or "bus_assignments" or "family_relationships" or "credit")) return;
        var header=System.Text.RegularExpressions.Regex.Match(translated.Sql,@"INSERT\s+INTO\s+[^\s(]+\s*\(([^)]+)\)\s*VALUES\s*\(([^)]+)\)",System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if(!header.Success) throw new UnauthorizedAccessException();
        var columns=header.Groups[1].Value.Split(',').Select(c=>c.Trim().Trim('"').ToLowerInvariant()).ToList();
        var bindings=header.Groups[2].Value.Split(',').Select(v=>v.Trim()).ToList();
        foreach(var column in new[]{"person_id","related_person_id"})
        {
            var index=columns.IndexOf(column); if(index<0) { if(column=="person_id") throw new UnauthorizedAccessException(); continue; }
            if(index>=bindings.Count || !System.Text.RegularExpressions.Regex.IsMatch(bindings[index],@"^@p[0-9]+$")) throw new UnauthorizedAccessException();
            var binding=int.Parse(bindings[index][2..]);
            if(binding>=parameters.Count || !int.TryParse(parameters[binding].Value?.ToString(),out var personId)) throw new UnauthorizedAccessException();
            var visible=await ExecuteReaderInternalAsync(conn,tx,policy.ReadSql("SELECT person_id FROM persons WHERE person_id=@p0"),new(){new SqlParamDto{Type="int",Value=personId}});
            if(visible.Rows.Count>0) continue;
            if(table=="person_services" && createdPeople?.Contains(personId)==true) continue;
            throw new UnauthorizedAccessException("الشخص خارج نطاق رؤية المستخدم.");
        }
        if(table=="person_services" && policy.Selections.TryGetValue("service",out var services))
        {
            var index=columns.IndexOf("service_id");
            if(index<0 || !System.Text.RegularExpressions.Regex.IsMatch(bindings[index],@"^@p[0-9]+$")) throw new UnauthorizedAccessException();
            var binding=int.Parse(bindings[index][2..]);
            if(!services.Contains(parameters[binding].Value?.ToString() ?? "")) throw new UnauthorizedAccessException();
        }
    }

    private static async Task<(long LastId, int Rows)> RunInsertInternalAsync(
        NpgsqlConnection conn,
        NpgsqlTransaction? tx,
        SqlDialectTranslator.TranslatedSql translated,
        List<SqlParamDto> parameters, DataVisibilityPolicy? policy = null, HashSet<int>? createdPeople = null)
    {
        // Normal inserts use SERIAL directly. Only user-supplied IDs require
        // sequence repair. Never reset every sequence after an edit or delete:
        // that can reuse IDs already reserved by another device's transaction.
        var explicitId = HasExplicitSerialId(translated);
        if (explicitId && tx is null)
        {
            await using var ownTx = await conn.BeginTransactionAsync();
            var result = await RunInsertInternalAsync(conn, ownTx, translated, parameters, policy, createdPeople);
            await ownTx.CommitAsync();
            return result;
        }
        if (explicitId)
        {
            // Exclude concurrent writers while advancing this table's sequence.
            // The table name comes from our fixed schema allowlist.
            await using var guard = new NpgsqlCommand(
                $"LOCK TABLE {translated.AffectedTable} IN SHARE ROW EXCLUSIVE MODE", conn, tx);
            await guard.ExecuteNonQueryAsync();
        }
        if(policy?.Restricted==true) await ValidateScopedInsertAsync(conn,tx,translated,parameters,policy,createdPeople);
        if (policy?.Restricted == true && translated.AffectedTable == "settings" && parameters.Count >= 2)
        {
            var columns = System.Text.RegularExpressions.Regex.Match(translated.Sql, @"INSERT\s+INTO\s+""?settings""?\s*\(([^)]+)\)", System.Text.RegularExpressions.RegexOptions.IgnoreCase).Groups[1].Value.Split(',').Select(c=>c.Trim().Trim('"')).ToList();
            var keyIndex=columns.IndexOf("setting_key"); var valueIndex=columns.IndexOf("setting_value");
            var key=keyIndex>=0 ? parameters[keyIndex].Value?.ToString() : null;
            if(key is "monthly_fund_payments_json" or "rohot_groups_json")
            {
                if(tx == null)
                {
                    await using var ownTx=await conn.BeginTransactionAsync();
                    var result=await RunInsertInternalAsync(conn,ownTx,translated,parameters,policy);
                    await ownTx.CommitAsync();
                    return result;
                }
                await using(var sync=new NpgsqlCommand("SELECT pg_advisory_xact_lock(hashtext(@key))",conn,tx))
                { sync.Parameters.AddWithValue("key",key); await sync.ExecuteNonQueryAsync(); }
                string? previous;
                await using(var read=new NpgsqlCommand("SELECT setting_value FROM public.settings WHERE setting_key=@key FOR UPDATE",conn,tx))
                { read.Parameters.AddWithValue("key",key); previous=await read.ExecuteScalarAsync() as string; }
                var rows=await ExecuteReaderInternalAsync(conn,tx,policy.ReadSql("SELECT person_id FROM persons"),new());
                var visible=rows.Rows.Select(r=>r["person_id"]!.ToString()!).ToHashSet();
                var incoming=parameters[valueIndex].Value?.ToString() ?? "";
                var merged=ScopedSettingsMerge.Merge(key,previous,incoming,visible);
                parameters=parameters.Select(p=>p.Value?.ToString()==incoming ? new SqlParamDto { Type="string",Value=merged } : p).ToList();
            }
        }
        await using var cmd = CreateCommand(conn, tx, translated.Sql, parameters);
        if (translated.ReturningColumn is not null)
        {
            var scalar = await cmd.ExecuteScalarAsync();
            if (scalar is not null && scalar is not DBNull && long.TryParse(scalar.ToString(), out var id))
            {
                if (explicitId) await SyncTableSequenceIfNeededAsync(conn, tx, translated.AffectedTable!);
                return (id, 1);
            }
            return (0, 0);
        }
        else
        {
            var rows = await cmd.ExecuteNonQueryAsync();
            if (explicitId && rows > 0) await SyncTableSequenceIfNeededAsync(conn, tx, translated.AffectedTable!);
            return (Math.Max(rows, 0), Math.Max(rows, 0));
        }
    }

    private static bool HasExplicitSerialId(SqlDialectTranslator.TranslatedSql translated)
    {
        if (translated.AffectedTable is null ||
            !PostgresSchemaInitializer.SingleIdPrimaryKeys.TryGetValue(translated.AffectedTable, out var idColumn))
            return false;
        var header = System.Text.RegularExpressions.Regex.Match(translated.Sql,
            @"^\s*INSERT\s+INTO\s+[^\s(]+\s*\(([^)]+)\)",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        return header.Success && header.Groups[1].Value.Split(',')
            .Any(column => column.Trim().Trim('"').Equals(idColumn, StringComparison.OrdinalIgnoreCase));
    }

    private static async Task SyncTableSequenceIfNeededAsync(
        NpgsqlConnection conn, NpgsqlTransaction? tx, string tableLower)
    {
        if (!PostgresSchemaInitializer.SingleIdPrimaryKeys.TryGetValue(tableLower, out var idCol))
        {
            return;
        }
        var sql = $"""
            SELECT setval(
                pg_get_serial_sequence('{tableLower}', '{idCol}'),
                GREATEST((SELECT last_value FROM {tableLower}_{idCol}_seq),
                    COALESCE((SELECT MAX({idCol}) FROM {tableLower}), 1)),
                true
            );
            """;
        await using var cmd = new NpgsqlCommand(sql, conn, tx);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task<SqlQueryResponse> ExecutePragmaTableInfoAsync(string tableLower, string? transactionId)
    {
        const string sql = """
            SELECT
                ordinal_position - 1 AS cid,
                column_name AS name,
                UPPER(data_type) AS type,
                CASE WHEN is_nullable = 'NO' THEN 1 ELSE 0 END AS "notnull",
                column_default AS dflt_value,
                0 AS pk
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = @p0
            ORDER BY ordinal_position;
            """;

        var param = new List<SqlParamDto> { new() { Type = "string", Value = tableLower } };
        if (!string.IsNullOrWhiteSpace(transactionId) && _transactions.TryGetValue(transactionId, out var session))
        {
            await session.Lock.WaitAsync();
            try
            {
                return await ExecuteReaderInternalAsync(session.Connection, session.Transaction, sql, param);
            }
            finally
            {
                session.Lock.Release();
            }
        }

        await using var conn = new NpgsqlConnection(_schema.ConnectionString);
        await conn.OpenAsync();
        return await ExecuteReaderInternalAsync(conn, null, sql, param);
    }

    private static async Task<SqlQueryResponse> ExecuteReaderInternalAsync(
        NpgsqlConnection conn,
        NpgsqlTransaction? tx,
        string sql,
        List<SqlParamDto> parameters)
    {
        var response = new SqlQueryResponse();
        await using var cmd = CreateCommand(conn, tx, sql, parameters);
        await using var reader = await cmd.ExecuteReaderAsync();

        var colCount = reader.FieldCount;
        var rawColNames = new string[colCount];
        var canonicalColNames = new string[colCount];
        for (int i = 0; i < colCount; i++)
        {
            rawColNames[i] = reader.GetName(i);
            canonicalColNames[i] = SqlDialectTranslator.ToCanonicalColumnName(rawColNames[i]);
        }

        while (await reader.ReadAsync())
        {
            var row = new Dictionary<string, object?>(StringComparer.Ordinal);
            for (int i = 0; i < colCount; i++)
            {
                object? val;
                if (reader.IsDBNull(i))
                {
                    val = null;
                }
                else
                {
                    var raw = reader.GetValue(i);
                    if (raw is byte[] bytes)
                    {
                        val = new Dictionary<string, string>
                        {
                            ["__type"] = "bytes",
                            ["base64"] = Convert.ToBase64String(bytes),
                        };
                    }
                    else if (raw is DateTime dt)
                    {
                        val = new DateTimeOffset(dt.Kind == DateTimeKind.Unspecified
                            ? DateTime.SpecifyKind(dt, DateTimeKind.Utc)
                            : dt).ToUnixTimeSeconds();
                    }
                    else if (raw is bool b)
                    {
                        val = b ? 1 : 0;
                    }
                    else
                    {
                        val = raw;
                    }
                }

                row[canonicalColNames[i]] = val;
                if (!row.ContainsKey(rawColNames[i]))
                {
                    row[rawColNames[i]] = val;
                }
            }
            response.Rows.Add(row);
        }

        return response;
    }

    private static NpgsqlCommand CreateCommand(
        NpgsqlConnection conn,
        NpgsqlTransaction? tx,
        string sql,
        List<SqlParamDto> parameters)
    {
        var cmd = new NpgsqlCommand(sql, conn, tx);
        for (int i = 0; i < parameters.Count; i++)
        {
            var p = parameters[i];
            var paramName = $"p{i}";
            var type = (p.Type ?? "null").ToLowerInvariant();

            if (type == "null" || p.Value is null)
            {
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
                continue;
            }

            if (p.Value is JsonElement je)
            {
                BindJsonElement(cmd, paramName, type, je);
                continue;
            }

            cmd.Parameters.AddWithValue(paramName, p.Value);
        }
        return cmd;
    }

    private static void BindJsonElement(NpgsqlCommand cmd, string paramName, string type, JsonElement je)
    {
        if (je.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
        {
            cmd.Parameters.AddWithValue(paramName, DBNull.Value);
            return;
        }

        switch (type)
        {
            case "bytes":
                var b64 = je.GetString();
                var bytes = string.IsNullOrEmpty(b64) ? Array.Empty<byte>() : Convert.FromBase64String(b64);
                cmd.Parameters.Add(new NpgsqlParameter(paramName, NpgsqlDbType.Bytea) { Value = bytes });
                break;

            case "int":
                if (je.ValueKind == JsonValueKind.Number && je.TryGetInt64(out var lVal))
                    cmd.Parameters.AddWithValue(paramName, lVal);
                else if (long.TryParse(je.ToString(), out var parsedL))
                    cmd.Parameters.AddWithValue(paramName, parsedL);
                else
                    cmd.Parameters.AddWithValue(paramName, 0L);
                break;

            case "double":
                if (je.ValueKind == JsonValueKind.Number && je.TryGetDouble(out var dVal))
                    cmd.Parameters.AddWithValue(paramName, dVal);
                else if (double.TryParse(je.ToString(), out var parsedD))
                    cmd.Parameters.AddWithValue(paramName, parsedD);
                else
                    cmd.Parameters.AddWithValue(paramName, 0.0);
                break;

            case "bool":
                bool bVal = je.ValueKind == JsonValueKind.True ||
                            (je.ValueKind == JsonValueKind.Number && je.TryGetInt64(out var bi) && bi != 0) ||
                            je.ToString().Equals("true", StringComparison.OrdinalIgnoreCase) ||
                            je.ToString() == "1";
                cmd.Parameters.AddWithValue(paramName, bVal ? 1 : 0);
                break;

            default:
                cmd.Parameters.AddWithValue(paramName, je.GetString() ?? je.ToString());
                break;
        }
    }

    public async Task<long> BroadcastChangesAsync(
        List<string> affectedTables,
        string operation,
        string? sourceDeviceId,
        string? sourceConnectionId)
    {
        var seq = Interlocked.Increment(ref _sequenceCounter);
        var payload = new SyncEventPayload
        {
            SequenceId = seq,
            AffectedTables = affectedTables.Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            Operation = operation,
            SourceDeviceId = sourceDeviceId,
            SourceConnectionId = sourceConnectionId,
            TimestampUtc = DateTime.UtcNow,
        };

        await _hubContext.Clients.All.SendAsync("DatabaseChanged", payload);
        return seq;
    }

    public async Task<byte[]> ExportToSqliteBytesAsync()
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"SundaySchool_Export_{Guid.NewGuid():N}.db");
        try
        {
            var sqliteConnStr = new SqliteConnectionStringBuilder
            {
                DataSource = tempFile,
                Mode = SqliteOpenMode.ReadWriteCreate,
                Pooling = false,
            }.ToString();

            await using (var sqliteConn = new SqliteConnection(sqliteConnStr))
            {
                await sqliteConn.OpenAsync();
                await using var pgConn = new NpgsqlConnection(_schema.ConnectionString);
                await pgConn.OpenAsync();

                foreach (var table in PostgresSchemaInitializer.OrderedTables)
                {
                    var pgTable = table.ToLowerInvariant();
                    await ExportTableToSqliteAsync(pgConn, sqliteConn, table, pgTable);
                }
            }

            return await File.ReadAllBytesAsync(tempFile);
        }
        finally
        {
            if (File.Exists(tempFile))
            {
                try { File.Delete(tempFile); } catch { }
            }
        }
    }

    private static async Task ExportTableToSqliteAsync(
        NpgsqlConnection pgConn,
        SqliteConnection sqliteConn,
        string canonicalTable,
        string pgTable)
    {
        var cols = new List<(string PgCol, string CanonicalCol, string SqliteType)>();
        await using (var colCmd = new NpgsqlCommand("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = @t
            ORDER BY ordinal_position;
            """, pgConn))
        {
            colCmd.Parameters.AddWithValue("t", pgTable);
            await using var rdr = await colCmd.ExecuteReaderAsync();
            while (await rdr.ReadAsync())
            {
                var pgCol = rdr.GetString(0);
                var dataType = rdr.GetString(1).ToLowerInvariant();
                var canonicalCol = SqlDialectTranslator.ToCanonicalColumnName(pgCol);
                var sqliteType = dataType switch
                {
                    "bytea" => "BLOB",
                    "integer" or "bigint" or "smallint" => "INTEGER",
                    "double precision" or "numeric" or "real" => "REAL",
                    _ => "TEXT",
                };
                cols.Add((pgCol, canonicalCol, sqliteType));
            }
        }

        if (cols.Count == 0) return;

        var createCols = string.Join(", ", cols.Select(c => $"\"{c.CanonicalCol}\" {c.SqliteType}"));
        await using (var createCmd = new SqliteCommand($"CREATE TABLE IF NOT EXISTS \"{canonicalTable}\" ({createCols});", sqliteConn))
        {
            await createCmd.ExecuteNonQueryAsync();
        }

        var selectCols = string.Join(", ", cols.Select(c => $"\"{c.PgCol}\""));
        var insertCols = string.Join(", ", cols.Select(c => $"\"{c.CanonicalCol}\""));
        var paramPlaceholders = string.Join(", ", cols.Select((_, i) => $"$p{i}"));

        await using var tx = await sqliteConn.BeginTransactionAsync();
        await using var pgSelect = new NpgsqlCommand($"SELECT {selectCols} FROM {pgTable};", pgConn);
        await using var pgReader = await pgSelect.ExecuteReaderAsync();

        while (await pgReader.ReadAsync())
        {
            await using var insCmd = new SqliteCommand(
                $"INSERT INTO \"{canonicalTable}\" ({insertCols}) VALUES ({paramPlaceholders});",
                sqliteConn,
                (SqliteTransaction)tx);

            for (int i = 0; i < cols.Count; i++)
            {
                var val = pgReader.IsDBNull(i) ? DBNull.Value : pgReader.GetValue(i);
                insCmd.Parameters.AddWithValue($"$p{i}", val);
            }
            await insCmd.ExecuteNonQueryAsync();
        }

        await tx.CommitAsync();
    }

    private void CleanupStaleTransactions(object? _)
    {
        var cutoff = DateTime.UtcNow.AddMinutes(-2);
        foreach (var (id, session) in _transactions)
        {
            if (session.LastActivityUtc < cutoff && _transactions.TryRemove(id, out var removed))
            {
                _ = Task.Run(async () =>
                {
                    try { await removed.Transaction.RollbackAsync(); } catch { }
                    await removed.DisposeAsync();
                });
            }
        }
    }

    public void Dispose()
    {
        _cleanupTimer.Dispose();
        foreach (var (_, session) in _transactions)
        {
            session.DisposeAsync().AsTask().GetAwaiter().GetResult();
        }
        _transactions.Clear();
    }
}
