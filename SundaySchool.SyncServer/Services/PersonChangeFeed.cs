using System.Data;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Npgsql;

namespace SundaySchool.SyncServer.Services;

public sealed record PersonChangesRequest(string? Cursor, int[]? KnownPersonIds, string? Domain);
public sealed record PersonChangesResponse(string Cursor, bool ResetRequired, int[] PersonIds);

/// <summary>Storage metadata only. Snapshot cursors also see transactions which
/// started before a previous poll but committed afterwards.</summary>
public sealed class PersonChangeFeed(PostgresSchemaInitializer schema)
{
    private static string Epoch = Guid.NewGuid().ToString("N");
    public static void Invalidate() => Epoch = Guid.NewGuid().ToString("N");
    private sealed record CursorData(string Epoch, long Issued, string Snapshot, string Scope);
    private long _nextCleanup;

    public async Task<PersonChangesResponse> ReadAsync(PersonChangesRequest request, DataVisibilityPolicy policy)
    {
        var epoch = Epoch;
        if ((request.KnownPersonIds?.Length ?? 0) > 100000 || (request.Cursor?.Length ?? 0) > 16384)
            throw new ArgumentException("Invalid change cursor size.");
        var scope = JsonSerializer.Serialize(policy.Selections.OrderBy(x => x.Key)
            .ToDictionary(x => x.Key, x => x.Value.Order().ToArray()));
        CursorData? previous = null;
        try
        {
            if (request.Cursor != null)
                previous = JsonSerializer.Deserialize<CursorData>(Convert.FromBase64String(request.Cursor));
        }
        catch (Exception e) when (e is FormatException or JsonException) { }
        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var reset = previous == null || previous.Epoch != epoch || previous.Scope != scope
            || previous.Issued < now - 86400 || previous.Issued > now
            || !Regex.IsMatch(previous.Snapshot, @"^\d+:\d+:(\d+(,\d+)*)?$");
        await using var connection = new NpgsqlConnection(schema.ConnectionString);
        await connection.OpenAsync();
        // Keep two days; cursors expire after one day. A separate committed
        // cleanup cannot remove any changes needed by an accepted cursor.
        var nextCleanup = Interlocked.Read(ref _nextCleanup);
        if (now > nextCleanup && Interlocked.CompareExchange(ref _nextCleanup, now + 3600, nextCleanup) == nextCleanup)
        {
            await using var cleanup = new NpgsqlCommand("""
                WITH removed AS (DELETE FROM client_change_journal WHERE changed_at < clock_timestamp() - interval '2 days' RETURNING transaction_id)
                UPDATE client_change_state SET floor = GREATEST(floor, COALESCE((SELECT max(transaction_id::text::numeric)::text::xid8 FROM removed), '0'::xid8))
                """, connection);
            await cleanup.ExecuteNonQueryAsync();
        }
        await using var transaction = await connection.BeginTransactionAsync(IsolationLevel.RepeatableRead);
        await using var snapshotCommand = new NpgsqlCommand("SELECT pg_current_snapshot()::text", connection, transaction);
        var snapshot = (string)(await snapshotCommand.ExecuteScalarAsync())!;
        var ids = new HashSet<int>();
        if (!reset)
        {
            await using var retained = new NpgsqlCommand("SELECT pg_snapshot_xmin(@snapshot::pg_snapshot) <= floor FROM client_change_state", connection, transaction);
            retained.Parameters.AddWithValue("snapshot", previous!.Snapshot);
            reset = (bool)(await retained.ExecuteScalarAsync())!;
        }
        if (!reset)
        {
            await using var changes = new NpgsqlCommand("""
                SELECT DISTINCT person_id FROM client_change_journal
                WHERE transaction_id >= pg_snapshot_xmin(@snapshot::pg_snapshot)
                  AND NOT pg_visible_in_snapshot(transaction_id, @snapshot::pg_snapshot)
                  AND (person_id = 0 OR @domain <> 'people' OR table_name IN ('persons','person_services','person_custom_field_values'))
                LIMIT 2001
                """, connection, transaction);
            changes.Parameters.AddWithValue("snapshot", previous!.Snapshot);
            changes.Parameters.AddWithValue("domain", request.Domain ?? "attendance");
            await using (var reader = await changes.ExecuteReaderAsync())
                while (await reader.ReadAsync())
                {
                    if (reader.GetInt32(0) == 0) reset = true;
                    else ids.Add(reader.GetInt32(0));
                }
            if (ids.Count > 2000) reset = true;
            if (!reset && ids.Count > 0)
            {
                // Newly visible people are scoped by the same read policy as
                // normal queries. Already known IDs may be removed after delete
                // or a move out of scope, without leaking unknown hidden IDs.
                var visible = new HashSet<int>((request.KnownPersonIds ?? []).Intersect(ids));
                await using var allowed = new NpgsqlCommand(policy.ReadSql("SELECT person_id FROM persons WHERE person_id = ANY(@ids)"), connection, transaction);
                allowed.Parameters.AddWithValue("ids", ids.ToArray());
                await using var reader = await allowed.ExecuteReaderAsync();
                while (await reader.ReadAsync()) visible.Add(reader.GetInt32(0));
                ids = visible;
            }
        }
        var cursor = Convert.ToBase64String(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(new CursorData(epoch, now, snapshot, scope))));
        await transaction.CommitAsync();
        return new(cursor, reset, reset ? [] : ids.Order().ToArray());
    }
}
