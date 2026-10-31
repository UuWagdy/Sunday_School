using System.Text.Json;
using System.Text.RegularExpressions;
using SundaySchool.SyncServer.Models;

namespace SundaySchool.SyncServer.Services;

/// <summary>Request-time row scope. The JWT identifies the user; permissions are
/// read afresh from storage so changing a scope does not require a new token.</summary>
public sealed class DataVisibilityPolicy
{
    public required int UserId { get; init; }
    public bool CanManageUsers { get; init; }
    public bool CanMaintain { get; init; }
    public Dictionary<string, List<string>> Selections { get; init; } = new();
    public bool Restricted => Selections.Count > 0;
    public static readonly string[] Dimensions = ["service", "gender", "stage", "khoros", "area", "rohot", "leader"];
    private static string Literal(string value) => "'" + value.Replace("'", "''") + "'";

    public static Dictionary<string,List<string>> Decode(string? json)
    {
        if (json is null || json.Length==0) return new();
        try
        {
            var value = JsonSerializer.Deserialize<Dictionary<string,List<string>>>(json);
            if(value is null) return new() { ["stage"] = new() };
            if(value.Keys.Any(k=>!Dimensions.Contains(k))) return new() { ["stage"] = new() };
            return value.Where(x => Dimensions.Contains(x.Key)).ToDictionary(x => x.Key, x => x.Value ?? new());
        }
        catch (JsonException) { return new() { ["stage"] = new() }; }
    }

    public string ReadSql(string sql)
    {
        var metadata=Regex.Replace(sql,@"[\s"";]","").ToLowerInvariant();
        if(metadata=="selectcoalesce(max(person_id),0)+1asnext_idfrompersons" || metadata=="selectcount(*)asid_existsfrompersonswhereperson_id=@p0") return sql;
        var clauses = new List<string>();
        string Values(string key) => string.Join(",", Selections[key].Select(Literal));
        foreach (var (key, values) in Selections)
        {
            if (values.Count == 0) { clauses.Add("FALSE"); continue; }
            var column = key switch { "gender" => "jender_name", "stage" => "stage_id", "khoros" => "khoros_id", "rohot" => "rohot", "leader" => "leader", _ => null };
            if (column != null) clauses.Add($"p.{column}::text IN ({Values(key)})");
            if (key == "area") clauses.Add("p.area_id IN (SELECT area_id FROM __scope_areas)");
            if (key == "service") clauses.Add($"""
                (EXISTS (SELECT 1 FROM public.person_services ps WHERE ps.person_id=p.person_id AND ps.service_id::text IN ({Values(key)}))
                 OR EXISTS (SELECT 1 FROM public.stage_services ss WHERE ss.stage_id=p.stage_id AND ss.service_id::text IN ({Values(key)}))
                 OR EXISTS (SELECT 1 FROM public.khoros_services ks WHERE ks.khoros_id=p.khoros_id AND ks.service_id::text IN ({Values(key)}))
                 OR EXISTS (SELECT 1 FROM public.stages s WHERE s.stage_id=p.stage_id AND s.service_id::text IN ({Values(key)}))
                 OR EXISTS (SELECT 1 FROM public.khoroses k WHERE k.khoros_id=p.khoros_id AND k.service_id::text IN ({Values(key)})))
                """);
        }
        var ctes = new List<string>();
        if (Selections.TryGetValue("area", out var areas) && areas.Count > 0)
            ctes.Add($"__scope_areas AS (SELECT area_id FROM public.areas WHERE area_id::text IN ({Values("area")}) UNION SELECT a.area_id FROM public.areas a JOIN __scope_areas b ON a.parent_id=b.area_id)");
        if (Restricted)
        {
            ctes.Add($"__visible_persons AS (SELECT p.* FROM public.persons p WHERE {string.Join(" AND ", clauses)})");
            ctes.Add("persons AS (SELECT * FROM __visible_persons)");
            foreach (var table in new[] { "coming", "visitations", "absent_persons", "absent_print", "credit", "person_services", "person_tayo_points", "person_custom_field_values", "person_documents", "bus_assignments" })
            {
                var service = (table is "coming" or "visitations" or "person_services") && Selections.ContainsKey("service")
                    ? $" AND service_id::text IN ({(Selections["service"].Count == 0 ? "NULL" : Values("service"))})" : "";
                ctes.Add($"{table} AS (SELECT * FROM public.{table} WHERE person_id IN (SELECT person_id FROM __visible_persons){service})");
            }
            ctes.Add("family_relationships AS (SELECT * FROM public.family_relationships WHERE person_id IN (SELECT person_id FROM __visible_persons) AND related_person_id IN (SELECT person_id FROM __visible_persons))");
            foreach (var (key, table, id) in new[] { ("stage", "stages", "stage_id"), ("khoros", "khoroses", "khoros_id") })
                ctes.Add($"{table} AS (SELECT * FROM public.{table} WHERE {id} IN (SELECT {id} FROM __visible_persons){(Selections.ContainsKey(key) && Selections[key].Count>0 ? $" OR {id}::text IN ({Values(key)})" : "")})");
            ctes.Add("fathers AS (SELECT * FROM public.fathers WHERE father_id IN (SELECT father_id FROM __visible_persons))");
            foreach(var (link,id,parent) in new[]{("stage_services","stage_id","stages"),("khoros_services","khoros_id","khoroses")})
                ctes.Add($"{link} AS (SELECT * FROM public.{link} WHERE {id} IN (SELECT {id} FROM {parent}){(Selections.ContainsKey("service") ? $" AND service_id::text IN ({(Selections["service"].Count==0 ? "NULL" : Values("service"))})" : "")})");
            ctes.Add("bus_drivers AS (SELECT * FROM public.bus_drivers WHERE id IN (SELECT driver_id FROM bus_assignments))");
            ctes.Add("__visible_area_tree AS (SELECT area_id,parent_id FROM public.areas WHERE area_id IN (SELECT area_id FROM __visible_persons) UNION SELECT a.area_id,a.parent_id FROM public.areas a JOIN __visible_area_tree c ON a.area_id=c.parent_id)");
            ctes.Add("areas AS (SELECT * FROM public.areas WHERE area_id IN (SELECT area_id FROM __visible_area_tree))");
            var serviceIds=Selections.ContainsKey("service") ? (Selections["service"].Count==0 ? "NULL" : Values("service")) : "SELECT service_id::text FROM person_services UNION SELECT service_id::text FROM public.stage_services WHERE stage_id IN (SELECT stage_id FROM __visible_persons) UNION SELECT service_id::text FROM public.khoros_services WHERE khoros_id IN (SELECT khoros_id FROM __visible_persons)";
            ctes.Add($"services AS (SELECT * FROM public.services WHERE service_id::text IN ({serviceIds}))");
        }
        if (!CanManageUsers)
        {
            ctes.Add($"pass AS (SELECT * FROM public.pass WHERE pass_id={UserId})");
            ctes.Add($"user_permissions_ext AS (SELECT * FROM public.user_permissions_ext WHERE user_id={UserId})");
            ctes.Add($"user_visibility_filters AS (SELECT * FROM public.user_visibility_filters WHERE user_id={UserId})");
        }
        if (Restricted)
        {
            ctes.Add($$"""
                settings AS (SELECT s.setting_key, CASE
                  WHEN s.setting_key='monthly_fund_payments_json' THEN
                    (SELECT COALESCE(jsonb_object_agg(e.key,e.value),'{}'::jsonb)::text FROM jsonb_each(COALESCE(NULLIF(s.setting_value,''),'{}')::jsonb) e WHERE e.key IN (SELECT person_id::text FROM __visible_persons))
                  WHEN s.setting_key='rohot_groups_json' THEN
                    (SELECT COALESCE(jsonb_agg(jsonb_set(jsonb_set(g,'{arifId}',CASE WHEN g->>'arifId' IN (SELECT person_id::text FROM __visible_persons) THEN g->'arifId' ELSE 'null'::jsonb END),'{members}', (SELECT COALESCE(jsonb_agg(m),'[]'::jsonb) FROM jsonb_array_elements(g->'members') m WHERE m->>'id' IN (SELECT person_id::text FROM __visible_persons)))),'[]'::jsonb)::text
                     FROM jsonb_array_elements(COALESCE(NULLIF(s.setting_value,''),'[]')::jsonb) g WHERE EXISTS (SELECT 1 FROM jsonb_array_elements(g->'members') m WHERE m->>'id' IN (SELECT person_id::text FROM __visible_persons)))
                  ELSE s.setting_value END AS setting_value FROM public.settings s
                  WHERE {{(CanManageUsers ? "TRUE" : $"s.setting_key NOT LIKE 'user_data_scope_%' OR s.setting_key='user_data_scope_{UserId}'")}})
                """);
        }
        else if (!CanManageUsers) ctes.Add($"settings AS (SELECT * FROM public.settings WHERE setting_key NOT LIKE 'user_data_scope_%' OR setting_key='user_data_scope_{UserId}')");
        if (ctes.Count == 0) return sql;
        var prefix = string.Join(", ", ctes);
        return Regex.IsMatch(sql, @"^\s*WITH\b", RegexOptions.IgnoreCase)
            ? Regex.Replace(sql, @"^\s*WITH\s+(?:RECURSIVE\s+)?", $"WITH RECURSIVE {prefix}, ", RegexOptions.IgnoreCase)
            : $"WITH RECURSIVE {prefix} {sql}";
    }

    public void ValidateRead(string sql)
    {
        // This endpoint accepts generated SELECTs, not arbitrary database commands.
        var clean = Regex.Replace(sql, "'(?:''|[^'])*'", "''");
        clean = Regex.Replace(clean, @"--[^\r\n]*|/\*[\s\S]*?\*/", " ");
        if (!Regex.IsMatch(clean, @"^\s*(SELECT|WITH|PRAGMA)\b", RegexOptions.IgnoreCase)
            || clean.Trim().TrimEnd(';').Contains(';')
            || Regex.IsMatch(clean, @"\b(public|main|pg_catalog|information_schema)\s*[""\s]*\.", RegexOptions.IgnoreCase)
            || Regex.IsMatch(clean, @"\b(INSERT|UPDATE|DELETE|COPY|ALTER|DROP|GRANT|REVOKE|CALL|DO|SET|RESET|INTO|ATTACH)\b", RegexOptions.IgnoreCase))
            throw new UnauthorizedAccessException("الاستعلام غير مسموح.");
        ValidateExpressions(clean);
    }

    private static void ValidateExpressions(string clean)
    {
        var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "count","sum","min","max","avg","coalesce","ifnull","nullif","replace","lower","upper","trim","ltrim","rtrim","substr","substring","length","cast","round","abs","strftime","date","datetime","julianday","group_concat","printf","exists","in","not","as","over","filter","partition","select","values","where","and","or","on","having","when","then","else","from","join","union","all","by","recursive", "table_info", "conflict", "update" };
        foreach (Match match in Regex.Matches(clean, @"\b([a-z_][a-z_0-9]*)""?\s*\(", RegexOptions.IgnoreCase))
            if (!allowed.Contains(match.Groups[1].Value)) throw new UnauthorizedAccessException("دالة الاستعلام غير مسموحة.");
        var tables = new HashSet<string>(PostgresSchemaInitializer.OrderedTables, StringComparer.OrdinalIgnoreCase) { "sqlite_master" };
        foreach (Match cte in Regex.Matches(clean,@"(?:WITH|,)\s*""?([a-z_][a-z_0-9]*)""?\s+AS\s*\(",RegexOptions.IgnoreCase)) tables.Add(cte.Groups[1].Value);
        foreach (Match table in Regex.Matches(clean,@"\b(?:FROM|JOIN)\s+""?([a-z_][a-z_0-9]*)""?",RegexOptions.IgnoreCase))
            if (!tables.Contains(SqlDialectTranslator.ToCanonicalTableName(table.Groups[1].Value))) throw new UnauthorizedAccessException("جدول الاستعلام غير مسموح.");
    }

    public string MutationSql(SqlRequest request, string translatedSql)
    {
        var clean = Regex.Replace(request.Sql, "'(?:''|[^'])*'", "''").Trim().TrimEnd(';');
        if (clean.Contains(';') || Regex.IsMatch(clean,@"--|/\*|\b(public|main|pg_catalog|information_schema)\s*[""\s]*\.",RegexOptions.IgnoreCase)) throw new UnauthorizedAccessException();
        var target = Regex.Match(clean,@"^\s*(?:INSERT\s+(?:OR\s+(?:IGNORE|REPLACE)\s+)?INTO|UPDATE|DELETE\s+FROM)\s+""?([a-z_][a-z_0-9]*)""?",RegexOptions.IgnoreCase);
        if (!target.Success) throw new UnauthorizedAccessException("نوع العملية غير مسموح.");
        var table = target.Groups[1].Value.ToLowerInvariant();
        if (!PostgresSchemaInitializer.OrderedTables.Contains(table,StringComparer.OrdinalIgnoreCase)) throw new UnauthorizedAccessException();
        // Writes from Drift contain scalar VALUES/SET bindings. A subquery in a
        // write would otherwise bypass the scoped read endpoint.
        if (Regex.IsMatch(clean, @"\b(SELECT|WITH|COPY|CALL|GRANT|ALTER|DROP)\b", RegexOptions.IgnoreCase)) throw new UnauthorizedAccessException();
        // Exclude the target/column list; validate functions in expressions.
        var expression = Regex.Replace(clean, @"^\s*INSERT\s+(?:OR\s+(?:IGNORE|REPLACE)\s+)?INTO\s+""?[a-z_][a-z_0-9]*""?\s*\([^)]*\)", "", RegexOptions.IgnoreCase);
        ValidateExpressions(expression);
        if (table is "pass" or "user_permissions_ext" or "user_visibility_filters")
            if (!CanManageUsers) throw new UnauthorizedAccessException("إدارة الصلاحيات غير مسموحة.");
        if (table == "settings" && !CanManageUsers)
        {
            if (CanMaintain && !Restricted && request.Params.Count==1 && request.Params[0].Value?.ToString()=="user_data_scope_%"
                && Regex.IsMatch(clean,@"^DELETE\s+FROM\s+""?Settings""?\s+WHERE\s+NOT\s*\(?\s*""?Setting_Key""?\s+LIKE\s+\?\s*\)?$",RegexOptions.IgnoreCase))
                return translatedSql;
            // Application settings use keyed upserts/deletes. Reject arbitrary
            // UPDATEs and broad deletes that could edit another user's scope.
            if (Regex.IsMatch(clean,@"^UPDATE\b",RegexOptions.IgnoreCase) || request.Params.Count == 0) throw new UnauthorizedAccessException();
            int keyIndex;
            if (Regex.IsMatch(clean,@"^DELETE\b",RegexOptions.IgnoreCase))
            {
                if (!Regex.IsMatch(clean,@"^DELETE\s+FROM\s+""?Settings""?\s+WHERE\s+""?Setting_Key""?\s*=\s*\?\s*$",RegexOptions.IgnoreCase)) throw new UnauthorizedAccessException();
                keyIndex=0;
            }
            else
            {
                var columns=Regex.Match(clean,@"INTO\s+""?Settings""?\s*\(([^)]+)\)",RegexOptions.IgnoreCase).Groups[1].Value.Split(',').Select(c=>c.Trim().Trim('"').ToLowerInvariant()).ToList();
                keyIndex=columns.IndexOf("setting_key");
                if(keyIndex<0 || request.Params.Count<columns.Count) throw new UnauthorizedAccessException();
            }
            var key = request.Params[keyIndex].Value?.ToString() ?? "";
            if (key.StartsWith("user_data_scope_",StringComparison.OrdinalIgnoreCase) || request.Params.Any(p=>(p.Value?.ToString() ?? "").StartsWith("user_data_scope_",StringComparison.OrdinalIgnoreCase))) throw new UnauthorizedAccessException();
            if(Restricted && Regex.IsMatch(clean,@"^DELETE\b",RegexOptions.IgnoreCase) && key is "monthly_fund_payments_json" or "rohot_groups_json") throw new UnauthorizedAccessException();
        }
        if (!Restricted || Regex.IsMatch(clean,@"^INSERT\b",RegexOptions.IgnoreCase)) return translatedSql;
        var personTable = table is "persons" or "coming" or "visitations" or "person_services" or "person_tayo_points" or "person_custom_field_values" or "person_documents" or "bus_assignments" or "family_relationships" or "credit" or "absent_persons" or "absent_print";
        var lookupId = table switch { "stages" or "stage_services" => "stage_id", "khoroses" or "khoros_services" => "khoros_id", "areas" => "area_id", "services" => "service_id", "fathers" => "father_id", "bus_drivers" => "id", _ => null };
        if (personTable || lookupId != null)
        {
            var returning=Regex.Match(translatedSql,@"\bRETURNING\b",RegexOptions.IgnoreCase);
            var tail=returning.Success ? translatedSql[returning.Index..] : "";
            var body=returning.Success ? translatedSql[..returning.Index] : translatedSql;
            var scope = personTable ? "person_id IN (SELECT person_id FROM __visible_persons)" : $"{lookupId} IN (SELECT {lookupId} FROM {table switch { "stage_services"=>"stages", "khoros_services"=>"khoroses", _=>table }})";
            if(table=="family_relationships") scope += " AND related_person_id IN (SELECT person_id FROM __visible_persons)";
            if(table is "coming" or "visitations" or "person_services" && Selections.TryGetValue("service",out var svc)) scope += $" AND service_id::text IN ({(svc.Count==0 ? "NULL" : string.Join(",",svc.Select(Literal)))})";
            var where=Regex.Match(body,@"\bWHERE\b",RegexOptions.IgnoreCase);
            body=body.TrimEnd().TrimEnd(';');
            return ReadSql(where.Success ? body[..where.Index]+" WHERE ("+body[(where.Index+where.Length)..]+") AND "+scope+" "+tail : body+" WHERE "+scope+" "+tail);
        }
        return translatedSql;
    }
}
