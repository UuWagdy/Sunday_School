using System.Text;
using System.Text.RegularExpressions;

namespace SundaySchool.SyncServer.Services;

public sealed partial class SqlDialectTranslator
{
    public static readonly IReadOnlyDictionary<string, string> CanonicalTableNames =
        PostgresSchemaInitializer.OrderedTables.ToDictionary(
            t => t.ToLowerInvariant(),
            t => t,
            StringComparer.OrdinalIgnoreCase);

    public sealed record TranslatedSql(
        string Sql,
        bool IsPragma,
        string? PragmaTableInfoTarget,
        string? AffectedTable,
        string? ReturningColumn);

    public static TranslatedSql Translate(string rawSql, bool isInsertRequest = false)
    {
        var trimmed = rawSql.Trim().TrimEnd(';').Trim();
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return new TranslatedSql(string.Empty, true, null, null, null);
        }

        // 1. Handle PRAGMA statements
        if (trimmed.StartsWith("PRAGMA", StringComparison.OrdinalIgnoreCase))
        {
            var match = PragmaTableInfoRegex().Match(trimmed);
            if (match.Success)
            {
                var table = match.Groups[1].Value.Trim('"', '\'', ' ');
                return new TranslatedSql(string.Empty, true, table.ToLowerInvariant(), null, null);
            }
            return new TranslatedSql(string.Empty, true, null, null, null);
        }

        var sql = trimmed;

        // 2. Replace sqlite_master table lookup
        if (sql.Contains("sqlite_master", StringComparison.OrdinalIgnoreCase))
        {
            sql = SqliteMasterRegex().Replace(
                sql,
                "(SELECT table_name AS name, 'table' AS type FROM information_schema.tables WHERE table_schema = 'public')");
        }

        // 3. Replace strftime('%s', 'now')
        sql = StrftimeNowRegex().Replace(sql, "(EXTRACT(EPOCH FROM NOW())::BIGINT)");

        // 4. Replace rowid with id
        sql = RowIdRegex().Replace(sql, "id");

        // 5. Replace INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT -> SERIAL PRIMARY KEY
        sql = AutoIncrementRegex().Replace(sql, "SERIAL PRIMARY KEY");

        // 6. Detect INSERT OR IGNORE / INSERT OR REPLACE
        bool isInsertOrIgnore = false;
        bool isInsertOrReplace = false;

        if (InsertOrIgnoreRegex().IsMatch(sql))
        {
            isInsertOrIgnore = true;
            sql = InsertOrIgnoreRegex().Replace(sql, "INSERT INTO ");
        }
        else if (InsertOrReplaceRegex().IsMatch(sql))
        {
            isInsertOrReplace = true;
            sql = InsertOrReplaceRegex().Replace(sql, "INSERT INTO ");
        }

        // 7. Lowercase all quoted identifiers except column aliases after AS "..."
        //    and convert ? / ?N placeholders to @p0, @p1, ...
        sql = NormalizeIdentifiersAndPlaceholders(sql);
        sql = NormalizeBooleanConstants(sql);
        // Drift emits SQLite's null-safe IS / IS NOT for bound values. PostgreSQL
        // accepts IS only with NULL/TRUE/FALSE, so preserve the null-safe semantics.
        sql = Regex.Replace(sql, @"'(?:''|[^'])*'|\bIS\s+(NOT\s+)?(@p\d+)\b", m =>
            m.Value.StartsWith('\'') ? m.Value : $"IS {(m.Groups[1].Success ? "" : "NOT ")}DISTINCT FROM {m.Groups[2].Value}", RegexOptions.IgnoreCase);

        // 8. Detect affected table for write operations
        var affectedTable = DetectAffectedTable(sql);

        // 9. Append ON CONFLICT for INSERT OR IGNORE / INSERT OR REPLACE
        if (isInsertOrIgnore && !sql.Contains("ON CONFLICT", StringComparison.OrdinalIgnoreCase))
        {
            sql += " ON CONFLICT DO NOTHING";
        }
        else if (isInsertOrReplace && affectedTable is not null && !sql.Contains("ON CONFLICT", StringComparison.OrdinalIgnoreCase))
        {
            sql = AppendUpsertOnConflict(sql, affectedTable);
        }

        // 10. Determine RETURNING column for runInsert if applicable
        string? returningCol = null;
        if (isInsertRequest && affectedTable is not null &&
            PostgresSchemaInitializer.SingleIdPrimaryKeys.TryGetValue(affectedTable, out var pkCol) &&
            !sql.Contains("RETURNING ", StringComparison.OrdinalIgnoreCase))
        {
            sql += $" RETURNING {pkCol}";
            returningCol = pkCol;
        }

        return new TranslatedSql(sql, false, null, affectedTable, returningCol);
    }

    private static string NormalizeIdentifiersAndPlaceholders(string sql)
    {
        var sb = new StringBuilder(sql.Length + 32);
        int i = 0;
        int n = sql.Length;
        int positionalParamIndex = 0;
        string lastWord = string.Empty;

        while (i < n)
        {
            char c = sql[i];

            // Single-quoted string literal '...'
            if (c == '\'')
            {
                sb.Append(c);
                i++;
                while (i < n)
                {
                    sb.Append(sql[i]);
                    if (sql[i] == '\'')
                    {
                        if (i + 1 < n && sql[i + 1] == '\'')
                        {
                            sb.Append(sql[i + 1]);
                            i += 2;
                            continue;
                        }
                        i++;
                        break;
                    }
                    i++;
                }
                lastWord = string.Empty;
                continue;
            }

            // Double-quoted identifier "..."
            if (c == '"')
            {
                int start = i + 1;
                i++;
                while (i < n && sql[i] != '"')
                {
                    i++;
                }
                var ident = sql[start..i];
                if (i < n && sql[i] == '"') i++;

                // If preceded by AS, keep exact alias casing so Drift row mapping sees the exact alias
                if (lastWord.Equals("AS", StringComparison.OrdinalIgnoreCase))
                {
                    sb.Append('"').Append(ident).Append('"');
                }
                else
                {
                    sb.Append('"').Append(ident.ToLowerInvariant()).Append('"');
                }
                lastWord = ident;
                continue;
            }

            // Parameter placeholder ? or ?123
            if (c == '?')
            {
                i++;
                int numStart = i;
                while (i < n && char.IsDigit(sql[i]))
                {
                    i++;
                }
                if (i > numStart && int.TryParse(sql[numStart..i], out int explicitIdx) && explicitIdx >= 1)
                {
                    sb.Append($"@p{explicitIdx - 1}");
                }
                else
                {
                    sb.Append($"@p{positionalParamIndex++}");
                }
                lastWord = string.Empty;
                continue;
            }

            // Track words to detect "AS"
            if (char.IsLetterOrDigit(c) || c == '_')
            {
                int wordStart = i;
                while (i < n && (char.IsLetterOrDigit(sql[i]) || sql[i] == '_'))
                {
                    i++;
                }
                var word = sql[wordStart..i];
                sb.Append(word);
                lastWord = word;
                continue;
            }

            sb.Append(c);
            i++;
        }

        return sb.ToString();
    }

    private static string NormalizeBooleanConstants(string sql)
    {
        // Drift reduces empty IN/NOT IN lists to SQLite's integer predicates.
        // PostgreSQL requires actual booleans. Only rewrite standalone predicate
        // operands, preserving numbers in comparisons, ranges, values and text.
        var tokens = SqlTokenRegex().Matches(sql).Cast<Match>()
            .Where(m => !m.Value.StartsWith("--") && !m.Value.StartsWith("/*"))
            .ToArray();
        var rangeAnds = new HashSet<int>();
        var pendingBetween = new Dictionary<int, int>();
        var depth = 0;
        for (var i = 0; i < tokens.Length; i++)
        {
            var token = tokens[i].Value;
            if (token == "(") depth++;
            else if (token == ")")
            {
                pendingBetween.Remove(depth);
                depth--;
            }
            else if (token.Equals("BETWEEN", StringComparison.OrdinalIgnoreCase))
                pendingBetween[depth] = pendingBetween.GetValueOrDefault(depth) + 1;
            else if (token.Equals("AND", StringComparison.OrdinalIgnoreCase)
                && pendingBetween.GetValueOrDefault(depth) > 0)
            {
                pendingBetween[depth]--;
                rangeAnds.Add(i);
            }
        }

        var result = new StringBuilder(sql.Length);
        var copied = 0;
        for (var i = 0; i < tokens.Length; i++)
        {
            if (tokens[i].Value is not ("0" or "1")) continue;
            var left = i - 1;
            while (left >= 0 && (tokens[left].Value == "("
                || tokens[left].Value.Equals("NOT", StringComparison.OrdinalIgnoreCase))) left--;
            if (left < 0 || rangeAnds.Contains(left)) continue;
            var before = tokens[left].Value.ToUpperInvariant();
            if (before is not ("WHERE" or "HAVING" or "ON" or "AND" or "OR" or "WHEN")) continue;
            var right = i + 1;
            while (right < tokens.Length && tokens[right].Value == ")") right++;
            var after = right < tokens.Length ? tokens[right].Value.ToUpperInvariant() : "";
            if (after is not ("" or ";" or "AND" or "OR" or "THEN" or "GROUP" or "ORDER"
                or "HAVING" or "LIMIT" or "OFFSET" or "RETURNING" or "UNION" or "EXCEPT"
                or "INTERSECT" or "JOIN" or "LEFT" or "RIGHT" or "INNER" or "FULL" or "WHERE")) continue;
            result.Append(sql, copied, tokens[i].Index - copied);
            result.Append(tokens[i].Value == "1" ? "TRUE" : "FALSE");
            copied = tokens[i].Index + tokens[i].Length;
        }
        return result.Append(sql, copied, sql.Length - copied).ToString();
    }

    [GeneratedRegex(@"'(?:''|[^'])*'|""(?:""""|[^""])*""|--[^\r\n]*|/\*[\s\S]*?\*/|@\w+|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|\w+|[^\s]")]
    private static partial Regex SqlTokenRegex();

    private static string? DetectAffectedTable(string sql)
    {
        var match = WriteTableRegex().Match(sql);
        if (!match.Success) return null;
        var rawTable = match.Groups[2].Value.Trim('"', ' ').ToLowerInvariant();
        return string.IsNullOrWhiteSpace(rawTable) ? null : rawTable;
    }

    private static string AppendUpsertOnConflict(string sql, string tableLower)
    {
        if (!PostgresSchemaInitializer.ConflictTargetColumns.TryGetValue(tableLower, out var pkCols) || pkCols.Length == 0)
        {
            return sql + " ON CONFLICT DO NOTHING";
        }

        var colListMatch = InsertColumnsListRegex().Match(sql);
        if (!colListMatch.Success)
        {
            return sql + $" ON CONFLICT ({string.Join(", ", pkCols)}) DO NOTHING";
        }

        var colsRaw = colListMatch.Groups[1].Value;
        var cols = colsRaw
            .Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(c => c.Trim().Trim('"').ToLowerInvariant())
            .Where(c => !string.IsNullOrWhiteSpace(c))
            .ToList();

        var updateCols = cols.Where(c => !pkCols.Contains(c, StringComparer.OrdinalIgnoreCase)).ToList();
        if (updateCols.Count == 0)
        {
            return sql + $" ON CONFLICT ({string.Join(", ", pkCols)}) DO NOTHING";
        }

        var setClauses = string.Join(", ", updateCols.Select(c => $"\"{c}\" = EXCLUDED.\"{c}\""));
        return $"{sql} ON CONFLICT ({string.Join(", ", pkCols)}) DO UPDATE SET {setClauses}";
    }

    public static string ToCanonicalTableName(string tableLower)
    {
        return CanonicalTableNames.TryGetValue(tableLower, out var canonical) ? canonical : tableLower;
    }

    public static string ToCanonicalColumnName(string colName)
    {
        // If it's a table-prefixed alias like "persons.person_id", preserve prefix and canonicalize column part
        var dotIdx = colName.IndexOf('.');
        if (dotIdx > 0 && dotIdx < colName.Length - 1)
        {
            var prefix = colName[..dotIdx];
            var colPart = colName[(dotIdx + 1)..];
            var canonicalCol = PostgresSchemaInitializer.CanonicalColumnNames.TryGetValue(colPart, out var c)
                ? c
                : colPart;
            return $"{prefix}.{canonicalCol}";
        }

        return PostgresSchemaInitializer.CanonicalColumnNames.TryGetValue(colName, out var mapped)
            ? mapped
            : colName;
    }

    [GeneratedRegex(@"PRAGMA\s+table_info\s*\(\s*([^)]+)\s*\)", RegexOptions.IgnoreCase)]
    private static partial Regex PragmaTableInfoRegex();

    [GeneratedRegex(@"\bsqlite_master\b", RegexOptions.IgnoreCase)]
    private static partial Regex SqliteMasterRegex();

    [GeneratedRegex(@"\(\s*strftime\s*\(\s*'%s'\s*,\s*'now'\s*\)\s*\)", RegexOptions.IgnoreCase)]
    private static partial Regex StrftimeNowRegex();

    [GeneratedRegex(@"\browid\b", RegexOptions.IgnoreCase)]
    private static partial Regex RowIdRegex();

    [GeneratedRegex(@"INTEGER\s+NOT\s+NULL\s+PRIMARY\s+KEY\s+AUTOINCREMENT", RegexOptions.IgnoreCase)]
    private static partial Regex AutoIncrementRegex();

    [GeneratedRegex(@"^\s*INSERT\s+OR\s+IGNORE\s+INTO\s+", RegexOptions.IgnoreCase)]
    private static partial Regex InsertOrIgnoreRegex();

    [GeneratedRegex(@"^\s*INSERT\s+OR\s+REPLACE\s+INTO\s+", RegexOptions.IgnoreCase)]
    private static partial Regex InsertOrReplaceRegex();

    [GeneratedRegex(@"^\s*(INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(""[^""]+""|[a-zA-Z0-9_]+)", RegexOptions.IgnoreCase)]
    private static partial Regex WriteTableRegex();

    [GeneratedRegex(@"^\s*INSERT\s+INTO\s+(?:""[^""]+""|[a-zA-Z0-9_]+)\s*\(([^)]+)\)", RegexOptions.IgnoreCase)]
    private static partial Regex InsertColumnsListRegex();
}
