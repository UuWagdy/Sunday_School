using Npgsql;
using SundaySchool.SyncServer.Services;

var cases = new (string Input, string Expected)[]
{
    ("DELETE FROM \"Person_Services\" WHERE \"Person_ID\" = ? AND 1;",
        "DELETE FROM \"person_services\" WHERE \"person_id\" = @p0 AND TRUE"),
    ("SELECT 1 WHERE 0 OR (1) AND NOT (0)", "SELECT 1 WHERE FALSE OR (TRUE) AND NOT (FALSE)"),
    ("SELECT 1 WHERE x = 1 AND 0 ORDER BY x LIMIT 1", "SELECT 1 WHERE x = 1 AND FALSE ORDER BY x LIMIT 1"),
    ("SELECT 1 WHERE x BETWEEN 0 AND 1 AND 1", "SELECT 1 WHERE x BETWEEN 0 AND 1 AND TRUE"),
    ("SELECT 1 WHERE x NOT BETWEEN (0) AND (1) OR 0", "SELECT 1 WHERE x NOT BETWEEN (0) AND (1) OR FALSE"),
    ("SELECT 'AND 1', 'WHERE 0', 'it''s OR 0' WHERE 1", "SELECT 'AND 1', 'WHERE 0', 'it''s OR 0' WHERE TRUE"),
    ("SELECT \"AND 1\" FROM \"Persons\" WHERE 1", "SELECT \"and 1\" FROM \"persons\" WHERE TRUE"),
    ("SELECT 1 WHERE x = 1 AND 1 = y", "SELECT 1 WHERE x = 1 AND 1 = y"),
    ("SELECT 1 WHERE x = 1 AND 1.5 > y", "SELECT 1 WHERE x = 1 AND 1.5 > y"),
    ("SELECT 1 WHERE (1) = y", "SELECT 1 WHERE (1) = y"),
    ("INSERT INTO t (x, y) VALUES (0, 1)", "INSERT INTO t (x, y) VALUES (0, 1)"),
    ("SELECT 1 WHERE 1 /* AND 0 */", "SELECT 1 WHERE TRUE /* AND 0 */"),
    ("SELECT 1 WHERE 1 -- OR 0\n", "SELECT 1 WHERE TRUE -- OR 0"),
    ("SELECT CASE WHEN 1 THEN 1 ELSE 0 END", "SELECT CASE WHEN TRUE THEN 1 ELSE 0 END"),
    ("SELECT 1 WHERE x IS ? AND 1", "SELECT 1 WHERE x IS NOT DISTINCT FROM @p0 AND TRUE"),
};
foreach (var (input, expected) in cases)
{
    var actual = SqlDialectTranslator.Translate(input).Sql;
    if (actual != expected) throw new Exception($"Input: {input}\nExpected: {expected}\nActual: {actual}");
}
Console.WriteLine($"PASS: {cases.Length} SQL translation cases (predicate constants, ranges, values, strings, comments).");

if (args.Length == 0) return;
await using var connection = new NpgsqlConnection(args[0]);
await connection.OpenAsync();
await using var tx = await connection.BeginTransactionAsync();
await using (var setup = new NpgsqlCommand("""
    CREATE TEMP TABLE person_services (person_id integer, service_id integer);
    INSERT INTO person_services VALUES (1, 1), (1, 2), (2, 1);
    """, connection, tx)) await setup.ExecuteNonQueryAsync();
async Task<int> Delete(string sql, int personId)
{
    await using var command = new NpgsqlCommand(SqlDialectTranslator.Translate(sql).Sql, connection, tx);
    command.Parameters.AddWithValue("p0", personId);
    return await command.ExecuteNonQueryAsync();
}
if (await Delete("DELETE FROM \"Person_Services\" WHERE \"Person_ID\" = ? AND 0", 1) != 0)
    throw new Exception("False predicate deleted rows.");
if (await Delete("DELETE FROM \"Person_Services\" WHERE \"Person_ID\" = ? AND 1", 1) != 2)
    throw new Exception("Empty NOT IN predicate did not clear the target person's links.");
await using (var count = new NpgsqlCommand("SELECT count(*) FROM person_services WHERE person_id = 2", connection, tx))
    if ((long)(await count.ExecuteScalarAsync())! != 1) throw new Exception("Another person's links changed.");
await tx.RollbackAsync();
Console.WriteLine("PASS: PostgreSQL executes the reported DELETE, clears only the requested person's services, and preserves false predicates (temporary table, rolled back).");
