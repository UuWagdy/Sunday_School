using Microsoft.Data.Sqlite;
using Npgsql;
using NpgsqlTypes;

namespace SundaySchool.SyncServer.Services;

public sealed class PostgresSchemaInitializer
{
    private readonly string _connectionString;
    private readonly ILogger<PostgresSchemaInitializer> _logger;

    /// <summary>
    /// Maps lowercase table name to its single auto-increment/primary key column (if applicable) for RETURNING id.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, string> SingleIdPrimaryKeys =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["areas"] = "area_id",
            ["services"] = "service_id",
            ["stages"] = "stage_id",
            ["khoroses"] = "khoros_id",
            ["fathers"] = "father_id",
            ["persons"] = "person_id",
            ["coming"] = "id",
            ["visitations"] = "id",
            ["pass"] = "pass_id",
            ["tayo_cards"] = "card_id",
            ["person_tayo_points"] = "id",
            ["custom_field_definitions"] = "id",
            ["person_documents"] = "id",
            ["family_relationships"] = "id",
            ["bus_drivers"] = "id",
            ["bus_assignments"] = "id",
        };

    /// <summary>
    /// Maps lowercase table name to its conflict target columns for INSERT OR REPLACE / ON CONFLICT.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, string[]> ConflictTargetColumns =
        new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
        {
            ["areas"] = ["area_id"],
            ["services"] = ["service_id"],
            ["stages"] = ["stage_id"],
            ["khoroses"] = ["khoros_id"],
            ["fathers"] = ["father_id"],
            ["persons"] = ["person_id"],
            ["coming"] = ["id"],
            ["visitations"] = ["id"],
            ["pass"] = ["pass_id"],
            ["person_services"] = ["person_id", "service_id"],
            ["khoros_services"] = ["khoros_id", "service_id"],
            ["stage_services"] = ["stage_id", "service_id"],
            ["user_permissions_ext"] = ["user_id", "feature_key"],
            ["user_visibility_filters"] = ["user_id", "filter_type", "value_id"],
            ["settings"] = ["setting_key"],
            ["tayo_cards"] = ["card_id"],
            ["person_tayo_points"] = ["id"],
            ["custom_field_definitions"] = ["id"],
            ["person_custom_field_values"] = ["person_id", "field_id"],
            ["person_documents"] = ["id"],
            ["family_relationships"] = ["id"],
            ["bus_drivers"] = ["id"],
            ["bus_assignments"] = ["id"],
        };

    /// <summary>
    /// Ordered list of tables so parent tables are created/imported before child tables.
    /// </summary>
    public static readonly string[] OrderedTables =
    [
        "Services",
        "Stages",
        "Khoroses",
        "Areas",
        "Fathers",
        "Jender",
        "Pass",
        "Settings",
        "Tayo_Cards",
        "custom_field_definitions",
        "Bus_Drivers",
        "Persons",
        "Coming",
        "Visitations",
        "Person_Services",
        "Khoros_Services",
        "Stage_Services",
        "User_Permissions_Ext",
        "User_Visibility_Filters",
        "Person_Tayo_Points",
        "person_custom_field_values",
        "person_documents",
        "Family_Relationships",
        "Bus_Assignments",
        "Absent_Persons",
        "Absent_Print",
        "Adding",
        "Credit",
    ];

    /// <summary>
    /// Canonical casing for columns as expected by Drift in Flutter.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, string> CanonicalColumnNames =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["person_id"] = "Person_ID",
            ["person_name"] = "Person_Name",
            ["stage_id"] = "Stage_ID",
            ["stage_name"] = "Stage_Name",
            ["khoros_id"] = "Khoros_ID",
            ["khoros_name"] = "Khoros_Name",
            ["area_id"] = "Area_ID",
            ["area_name"] = "Area_Name",
            ["parent_id"] = "Parent_ID",
            ["level"] = "Level",
            ["area_path"] = "Area_Path",
            ["street_name"] = "Street_Name",
            ["street"] = "Street",
            ["phone"] = "Phone",
            ["mobile"] = "Mobile",
            ["date_from"] = "Date_From",
            ["date_to"] = "Date_To",
            ["date_id"] = "Date_ID",
            ["date"] = "Date",
            ["date_week"] = "date_Week",
            ["point"] = "Point",
            ["attendance_point"] = "Attendance_Point",
            ["checkout_point"] = "Checkout_Point",
            ["mont_1"] = "Mont_1",
            ["year_1"] = "Year_1",
            ["service_id"] = "Service_ID",
            ["service_name"] = "Service_Name",
            ["attend_time"] = "Attend_Time",
            ["checkout_time"] = "Checkout_Time",
            ["visited"] = "Visited",
            ["visit_notes"] = "Visit_Notes",
            ["behavior"] = "Behavior",
            ["attendance_notes"] = "Attendance_Notes",
            ["checkout_notes"] = "Checkout_Notes",
            ["checkout_type"] = "Checkout_Type",
            ["visit_date"] = "Visit_Date",
            ["is_visited"] = "Is_Visited",
            ["visit_type"] = "Visit_Type",
            ["notes"] = "Notes",
            ["created_at"] = "Created_At",
            ["updated_at"] = "Updated_At",
            ["day_of_week"] = "Day_Of_Week",
            ["hour"] = "Hour",
            ["minute"] = "Minute",
            ["end_hour"] = "End_Hour",
            ["end_minute"] = "End_Minute",
            ["logo"] = "Logo",
            ["check_color"] = "Check_Color",
            ["day"] = "Day",
            ["month"] = "Month",
            ["year"] = "Year",
            ["jender"] = "Jender",
            ["jender_id"] = "Jender_ID",
            ["jender_name"] = "Jender_Name",
            ["photo"] = "Photo",
            ["parcode"] = "Parcode",
            ["father_id"] = "Father_ID",
            ["father_name"] = "Father_Name",
            ["pass_id"] = "Pass_ID",
            ["pass_word"] = "Pass_Word",
            ["can_persons"] = "can_persons",
            ["can_stages"] = "can_stages",
            ["can_areas"] = "can_areas",
            ["can_fathers"] = "can_fathers",
            ["can_reports"] = "can_reports",
            ["can_users"] = "can_users",
            ["can_absence"] = "can_absence",
            ["can_maintenance"] = "can_maintenance",
            ["can_id_card"] = "can_id_card",
            ["can_tayo"] = "can_tayo",
            ["can_transfer"] = "can_transfer",
            ["can_services"] = "can_services",
            ["can_khoros"] = "can_khoros",
            ["can_behavior"] = "can_behavior",
            ["is_advanced"] = "is_advanced",
            ["user_id"] = "User_ID",
            ["feature_key"] = "Feature_Key",
            ["can_add"] = "can_add",
            ["can_edit"] = "can_edit",
            ["can_delete"] = "can_delete",
            ["filter_type"] = "Filter_Type",
            ["value_id"] = "Value_ID",
            ["rohot"] = "Rohot",
            ["leader"] = "Leader",
            ["next_stage_id"] = "Next_Stage_ID",
            ["setting_key"] = "Setting_Key",
            ["setting_value"] = "Setting_Value",
            ["card_id"] = "Card_ID",
            ["card_name"] = "Card_Name",
            ["card_points"] = "Card_Points",
            ["card_image"] = "Card_Image",
            ["points"] = "Points",
            ["award_date"] = "Award_Date",
            ["is_attendance"] = "Is_Attendance",
            ["field_key"] = "Field_Key",
            ["name"] = "Name",
            ["type"] = "Type",
            ["options"] = "Options",
            ["field_order"] = "Field_Order",
            ["is_visible"] = "Is_Visible",
            ["is_filter"] = "Is_Filter",
            ["is_phone"] = "Is_Phone",
            ["field_id"] = "Field_ID",
            ["value"] = "Value",
            ["file_name"] = "File_Name",
            ["file_content"] = "File_Content",
            ["related_person_id"] = "Related_Person_ID",
            ["category"] = "Category",
            ["relationship_code"] = "Relationship_Code",
            ["custom_label"] = "Custom_Label",
            ["bus_number"] = "Bus_Number",
            ["driver_id"] = "Driver_ID",
            ["stage"] = "Stage",
            ["month_1"] = "Month_1",
            ["first"] = "First",
            ["second"] = "second",
            ["third"] = "third",
            ["forth"] = "Forth",
            ["fife"] = "fife",
        };

    public PostgresSchemaInitializer(IConfiguration configuration, ILogger<PostgresSchemaInitializer> logger)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? Environment.GetEnvironmentVariable("DATABASE_URL")
            ?? "Host=127.0.0.1;Port=5434;Database=sunday_school;Username=postgres;Password=postgres;Pooling=true;Maximum Pool Size=50;";
        _logger = logger;
    }

    public string ConnectionString => _connectionString;

    public async Task InitializeAsync()
    {
        await EnsureDatabaseExistsAsync();

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        const string ddl = """
            CREATE TABLE IF NOT EXISTS sync_meta (
                key TEXT PRIMARY KEY,
                value TEXT
            );

            CREATE TABLE IF NOT EXISTS absent_persons (
                id INTEGER,
                person_id INTEGER,
                person_name TEXT,
                stage TEXT,
                month_1 TEXT,
                first TEXT,
                second TEXT,
                third TEXT,
                forth TEXT,
                fife TEXT
            );

            CREATE TABLE IF NOT EXISTS absent_print (
                id INTEGER,
                person_id INTEGER,
                person_name TEXT,
                stage_id INTEGER,
                stage_name TEXT,
                khoros_id INTEGER,
                khoros_name TEXT,
                area_id INTEGER,
                area_name TEXT,
                street_name TEXT,
                phone TEXT,
                mobile TEXT,
                date_from TEXT,
                date_to TEXT
            );

            CREATE TABLE IF NOT EXISTS adding (
                date_id INTEGER,
                date TEXT
            );

            CREATE TABLE IF NOT EXISTS areas (
                area_id SERIAL PRIMARY KEY,
                area_name TEXT,
                parent_id INTEGER,
                level INTEGER DEFAULT 0,
                area_path TEXT
            );

            CREATE TABLE IF NOT EXISTS services (
                service_id SERIAL PRIMARY KEY,
                service_name TEXT,
                day_of_week INTEGER,
                hour INTEGER,
                minute INTEGER,
                end_hour INTEGER,
                end_minute INTEGER,
                logo BYTEA,
                check_color TEXT
            );

            CREATE TABLE IF NOT EXISTS stages (
                stage_id SERIAL PRIMARY KEY,
                stage_name TEXT,
                service_id INTEGER REFERENCES services(service_id) ON DELETE SET NULL,
                next_stage_id INTEGER REFERENCES stages(stage_id) ON DELETE SET NULL
            );

            CREATE TABLE IF NOT EXISTS khoroses (
                khoros_id SERIAL PRIMARY KEY,
                khoros_name TEXT,
                logo BYTEA,
                service_id INTEGER REFERENCES services(service_id) ON DELETE SET NULL
            );

            CREATE TABLE IF NOT EXISTS fathers (
                father_id SERIAL PRIMARY KEY,
                father_name TEXT
            );

            CREATE TABLE IF NOT EXISTS jender (
                jender_id INTEGER,
                jender_name TEXT
            );

            CREATE TABLE IF NOT EXISTS pass (
                pass_id SERIAL PRIMARY KEY,
                pass_word TEXT,
                person_name TEXT,
                can_persons INTEGER DEFAULT 0,
                can_stages INTEGER DEFAULT 0,
                can_areas INTEGER DEFAULT 0,
                can_fathers INTEGER DEFAULT 0,
                can_reports INTEGER DEFAULT 0,
                can_users INTEGER DEFAULT 0,
                can_absence INTEGER DEFAULT 0,
                can_maintenance INTEGER DEFAULT 0,
                can_id_card INTEGER DEFAULT 0,
                can_tayo INTEGER DEFAULT 0,
                can_transfer INTEGER DEFAULT 0,
                can_services INTEGER DEFAULT 0,
                can_khoros INTEGER DEFAULT 0,
                can_behavior INTEGER DEFAULT 0,
                is_advanced INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS persons (
                person_id SERIAL PRIMARY KEY,
                person_name TEXT,
                stage_id INTEGER,
                khoros_id INTEGER,
                area_id INTEGER,
                street_name TEXT,
                phone TEXT,
                mobile TEXT,
                day INTEGER,
                month INTEGER,
                year INTEGER,
                jender_name TEXT,
                father_id INTEGER,
                photo BYTEA,
                rohot TEXT,
                leader TEXT
            );

            CREATE TABLE IF NOT EXISTS coming (
                id SERIAL PRIMARY KEY,
                person_id INTEGER,
                date_week TEXT,
                point INTEGER,
                attendance_point INTEGER,
                checkout_point INTEGER,
                mont_1 INTEGER,
                year_1 INTEGER,
                service_id INTEGER,
                attend_time TEXT,
                checkout_time TEXT,
                visited INTEGER,
                visit_notes TEXT,
                behavior INTEGER DEFAULT 5,
                attendance_notes TEXT,
                checkout_notes TEXT,
                checkout_type TEXT
            );

            CREATE TABLE IF NOT EXISTS visitations (
                id SERIAL PRIMARY KEY,
                person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
                service_id INTEGER REFERENCES services(service_id) ON DELETE SET NULL,
                visit_date TEXT NOT NULL,
                is_visited INTEGER NOT NULL DEFAULT 0,
                visit_type TEXT NOT NULL DEFAULT 'تليفون',
                notes TEXT,
                created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())::BIGINT),
                updated_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())::BIGINT)
            );

            CREATE TABLE IF NOT EXISTS credit (
                id INTEGER,
                person_id INTEGER,
                person_name TEXT,
                stage_name TEXT,
                area_name TEXT,
                street TEXT,
                phone TEXT,
                mobile TEXT,
                day INTEGER,
                month INTEGER,
                year INTEGER,
                jender TEXT,
                photo BYTEA,
                parcode BYTEA
            );

            CREATE TABLE IF NOT EXISTS person_services (
                person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
                service_id INTEGER NOT NULL REFERENCES services(service_id) ON DELETE CASCADE,
                PRIMARY KEY (person_id, service_id)
            );

            CREATE TABLE IF NOT EXISTS khoros_services (
                khoros_id INTEGER NOT NULL REFERENCES khoroses(khoros_id) ON DELETE CASCADE,
                service_id INTEGER NOT NULL REFERENCES services(service_id) ON DELETE CASCADE,
                PRIMARY KEY (khoros_id, service_id)
            );

            CREATE TABLE IF NOT EXISTS stage_services (
                stage_id INTEGER NOT NULL REFERENCES stages(stage_id) ON DELETE CASCADE,
                service_id INTEGER NOT NULL REFERENCES services(service_id) ON DELETE CASCADE,
                PRIMARY KEY (stage_id, service_id)
            );

            CREATE TABLE IF NOT EXISTS user_permissions_ext (
                user_id INTEGER NOT NULL REFERENCES pass(pass_id) ON DELETE CASCADE,
                feature_key TEXT NOT NULL,
                can_add INTEGER NOT NULL DEFAULT 0,
                can_edit INTEGER NOT NULL DEFAULT 0,
                can_delete INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (user_id, feature_key)
            );

            CREATE TABLE IF NOT EXISTS user_visibility_filters (
                user_id INTEGER NOT NULL REFERENCES pass(pass_id) ON DELETE CASCADE,
                filter_type TEXT NOT NULL,
                value_id INTEGER NOT NULL,
                PRIMARY KEY (user_id, filter_type, value_id)
            );

            CREATE TABLE IF NOT EXISTS settings (
                setting_key TEXT PRIMARY KEY,
                setting_value TEXT
            );

            CREATE TABLE IF NOT EXISTS tayo_cards (
                card_id SERIAL PRIMARY KEY,
                card_name TEXT,
                card_points INTEGER,
                card_image BYTEA
            );

            CREATE TABLE IF NOT EXISTS person_tayo_points (
                id SERIAL PRIMARY KEY,
                person_id INTEGER,
                card_id INTEGER,
                points INTEGER,
                award_date TEXT,
                is_attendance INTEGER,
                notes TEXT,
                service_id INTEGER
            );

            CREATE TABLE IF NOT EXISTS custom_field_definitions (
                id SERIAL PRIMARY KEY,
                field_key TEXT UNIQUE,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                options TEXT,
                field_order INTEGER NOT NULL,
                is_visible INTEGER NOT NULL DEFAULT 1,
                is_filter INTEGER NOT NULL DEFAULT 0,
                is_phone INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS person_custom_field_values (
                person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
                field_id INTEGER NOT NULL REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
                value TEXT,
                PRIMARY KEY (person_id, field_id)
            );

            CREATE TABLE IF NOT EXISTS person_documents (
                id SERIAL PRIMARY KEY,
                person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
                field_id INTEGER NOT NULL REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
                file_name TEXT NOT NULL,
                file_content BYTEA NOT NULL,
                created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())::BIGINT)
            );

            CREATE TABLE IF NOT EXISTS family_relationships (
                id SERIAL PRIMARY KEY,
                person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
                related_person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
                category TEXT NOT NULL,
                relationship_code TEXT NOT NULL,
                custom_label TEXT,
                created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())::BIGINT)
            );

            CREATE TABLE IF NOT EXISTS bus_drivers (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                phone TEXT,
                bus_number TEXT,
                notes TEXT,
                created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())::BIGINT)
            );

            CREATE TABLE IF NOT EXISTS bus_assignments (
                id SERIAL PRIMARY KEY,
                driver_id INTEGER NOT NULL REFERENCES bus_drivers(id) ON DELETE CASCADE,
                person_id INTEGER NOT NULL UNIQUE REFERENCES persons(person_id) ON DELETE CASCADE,
                notes TEXT,
                created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW())::BIGINT)
            );

            CREATE INDEX IF NOT EXISTS idx_coming_person_id ON coming(person_id);
            CREATE INDEX IF NOT EXISTS idx_coming_service_date ON coming(service_id, date_week);
            CREATE INDEX IF NOT EXISTS idx_coming_person_date_service ON coming(person_id, date_week, service_id);
            CREATE INDEX IF NOT EXISTS idx_coming_date_person ON coming(date_week, person_id);
            CREATE INDEX IF NOT EXISTS idx_visitations_date_person ON visitations(visit_date, person_id);
            CREATE INDEX IF NOT EXISTS idx_credit_person ON credit(person_id);
            CREATE INDEX IF NOT EXISTS idx_absent_persons_person ON absent_persons(person_id);
            CREATE INDEX IF NOT EXISTS idx_absent_print_person ON absent_print(person_id);
            CREATE INDEX IF NOT EXISTS idx_persons_stage ON persons(stage_id);
            CREATE INDEX IF NOT EXISTS idx_persons_khoros ON persons(khoros_id);
            CREATE INDEX IF NOT EXISTS idx_persons_area ON persons(area_id);

            CREATE TABLE IF NOT EXISTS client_change_journal (
                transaction_id xid8 NOT NULL DEFAULT pg_current_xact_id(),
                table_name text NOT NULL,
                person_id integer NOT NULL,
                changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
                PRIMARY KEY (transaction_id, table_name, person_id)
            );
            CREATE INDEX IF NOT EXISTS idx_client_changes_age ON client_change_journal(changed_at);
            CREATE TABLE IF NOT EXISTS client_change_state (id boolean PRIMARY KEY DEFAULT true CHECK(id), floor xid8 NOT NULL);
            INSERT INTO client_change_state VALUES (true, '0') ON CONFLICT DO NOTHING;
            CREATE OR REPLACE FUNCTION record_client_change() RETURNS trigger LANGUAGE plpgsql AS $$
            DECLARE old_id integer; new_id integer;
            BEGIN
                old_id := CASE WHEN TG_OP <> 'INSERT' THEN COALESCE((to_jsonb(OLD)->>'person_id')::integer,0) ELSE 0 END;
                new_id := CASE WHEN TG_OP <> 'DELETE' THEN COALESCE((to_jsonb(NEW)->>'person_id')::integer,0) ELSE 0 END;
                IF TG_OP <> 'INSERT' THEN
                    INSERT INTO client_change_journal(table_name,person_id) VALUES(TG_TABLE_NAME,old_id) ON CONFLICT DO NOTHING;
                END IF;
                IF TG_OP <> 'DELETE' THEN
                    INSERT INTO client_change_journal(table_name,person_id) VALUES(TG_TABLE_NAME,new_id) ON CONFLICT DO NOTHING;
                END IF;
                RETURN NULL;
            END $$;
            DO $$ DECLARE tracked text; BEGIN
                FOREACH tracked IN ARRAY ARRAY['persons','coming','person_services','person_custom_field_values','visitations','credit',
                    'absent_persons','absent_print','adding','stages','khoroses','areas','fathers','services','jender',
                    'stage_services','khoros_services','custom_field_definitions','settings','pass','user_visibility_filters'] LOOP
                    EXECUTE format('CREATE OR REPLACE TRIGGER client_change AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION record_client_change()',tracked);
                END LOOP;
            END $$;
            """;

        await using (var cmd = new NpgsqlCommand(ddl, conn))
        {
            await cmd.ExecuteNonQueryAsync();
        }

        // Check if initial import is needed
        var countCmd = new NpgsqlCommand("SELECT COUNT(*) FROM persons;", conn);
        var personCount = Convert.ToInt64(await countCmd.ExecuteScalarAsync());

        var passCountCmd = new NpgsqlCommand("SELECT COUNT(*) FROM pass;", conn);
        var passCount = Convert.ToInt64(await passCountCmd.ExecuteScalarAsync());

        if (personCount == 0 && passCount == 0)
        {
            var sqliteCandidate = FindCandidateSqliteDatabase();
            if (sqliteCandidate is not null)
            {
                _logger.LogInformation("PostgreSQL is empty. Importing initial data from SQLite: {Path}", sqliteCandidate);
                try { await ImportFromSqliteFileAsync(sqliteCandidate, overwrite: false); }
                catch (Exception ex) when (ex is SqliteException or PostgresException)
                {
                    // Import is transactional. Keep the source intact and allow
                    // a new host to start with defaults if its old client file
                    // is not a compatible standalone database.
                    _logger.LogWarning(ex, "Initial SQLite import failed; starting the empty server with defaults. Source file preserved.");
                }
            }
        }

        await EnsureDefaultsSeededAsync(conn);
        await SyncAllSequencesAsync(conn);
    }

    private async Task EnsureDatabaseExistsAsync()
    {
        try
        {
            var builder = new NpgsqlConnectionStringBuilder(_connectionString);
            var targetDb = builder.Database;
            if (string.IsNullOrWhiteSpace(targetDb)) return;

            builder.Database = "postgres";
            await using var adminConn = new NpgsqlConnection(builder.ConnectionString);
            await adminConn.OpenAsync();

            await using var checkCmd = new NpgsqlCommand(
                "SELECT 1 FROM pg_database WHERE datname = @db;", adminConn);
            checkCmd.Parameters.AddWithValue("db", targetDb);
            var exists = await checkCmd.ExecuteScalarAsync();

            if (exists is null)
            {
                _logger.LogInformation("Creating PostgreSQL database '{Database}'...", targetDb);
                await using var createCmd = new NpgsqlCommand($"CREATE DATABASE \"{targetDb}\";", adminConn);
                await createCmd.ExecuteNonQueryAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not check/create database via postgres maintenance db (may already exist).");
        }
    }

    private static string? FindCandidateSqliteDatabase()
    {
        var baseDir = AppContext.BaseDirectory;
        var candidates = new List<string>
        {
            Path.Combine(baseDir, "Betros_Bols.db"),
            Path.Combine(baseDir, "database", "Betros_Bols.db"),
            Path.Combine(baseDir, "..", "database", "Betros_Bols.db"),
            Path.Combine(baseDir, "..", "assets", "database", "Betros_Bols.db"),
            Path.Combine(baseDir, "..", "data", "flutter_assets", "assets", "database", "Betros_Bols.db"),
            Path.Combine(Directory.GetCurrentDirectory(), "assets", "database", "Betros_Bols.db"),
            Path.Combine(Directory.GetCurrentDirectory(), "database", "Betros_Bols.db"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "assets", "database", "Betros_Bols.db"),
        };

        foreach (var path in candidates)
        {
            try
            {
                var full = Path.GetFullPath(path);
                if (File.Exists(full) && new FileInfo(full).Length > 0)
                {
                    return full;
                }
            }
            catch
            {
                // ignore invalid path
            }
        }

        return null;
    }

    public async Task ImportFromSqliteFileAsync(string sqliteFilePath, bool overwrite)
    {
        await using var pgConn = new NpgsqlConnection(_connectionString);
        await pgConn.OpenAsync();
        await using var tx = await pgConn.BeginTransactionAsync();

        try
        {
            // Temporarily relax foreign key checks during bulk import
            await using (var replicaCmd = new NpgsqlCommand("SET session_replication_role = 'replica';", pgConn, tx))
            {
                await replicaCmd.ExecuteNonQueryAsync();
            }

            if (overwrite)
            {
                foreach (var table in OrderedTables.Reverse())
                {
                    await using var truncCmd = new NpgsqlCommand(
                        $"TRUNCATE TABLE {table.ToLowerInvariant()} RESTART IDENTITY CASCADE;", pgConn, tx);
                    await truncCmd.ExecuteNonQueryAsync();
                }
            }

            var sqliteConnStr = new SqliteConnectionStringBuilder
            {
                DataSource = sqliteFilePath,
                Mode = SqliteOpenMode.ReadOnly,
            }.ToString();

            await using var sqliteConn = new SqliteConnection(sqliteConnStr);
            await sqliteConn.OpenAsync();

            foreach (var table in OrderedTables)
            {
                var pgTable = table.ToLowerInvariant();
                if (!await SqliteTableExistsAsync(sqliteConn, table)) continue;

                var pgColumns = await GetPgTableColumnsAsync(pgConn, tx, pgTable);
                var sqliteColumns = await GetSqliteTableColumnsAsync(sqliteConn, table);

                var commonColumns = sqliteColumns
                    .Where(sc => pgColumns.ContainsKey(sc.ToLowerInvariant()))
                    .ToList();

                if (commonColumns.Count == 0) continue;

                var selectCols = string.Join(", ", commonColumns.Select(c => $"\"{c}\""));
                var insertCols = string.Join(", ", commonColumns.Select(c => c.ToLowerInvariant()));
                var paramNames = string.Join(", ", commonColumns.Select((_, idx) => $"@p{idx}"));

                var conflictClause = ConflictTargetColumns.TryGetValue(pgTable, out var pkCols)
                    ? $"ON CONFLICT ({string.Join(", ", pkCols)}) DO NOTHING"
                    : "";

                var insertSql = $"INSERT INTO {pgTable} ({insertCols}) VALUES ({paramNames}) {conflictClause};";

                await using var readCmd = new SqliteCommand($"SELECT {selectCols} FROM \"{table}\";", sqliteConn);
                await using var reader = await readCmd.ExecuteReaderAsync();

                int importedCount = 0;
                while (await reader.ReadAsync())
                {
                    await using var writeCmd = new NpgsqlCommand(insertSql, pgConn, tx);
                    for (int i = 0; i < commonColumns.Count; i++)
                    {
                        var colLower = commonColumns[i].ToLowerInvariant();
                        var pgType = pgColumns[colLower];
                        var rawVal = reader.GetValue(i);

                        if (rawVal is DBNull || rawVal is null)
                        {
                            writeCmd.Parameters.AddWithValue($"p{i}", DBNull.Value);
                        }
                        else if (pgType == "bytea")
                        {
                            if (rawVal is byte[] bytes)
                                writeCmd.Parameters.Add(new NpgsqlParameter($"p{i}", NpgsqlDbType.Bytea) { Value = bytes });
                            else
                                writeCmd.Parameters.AddWithValue($"p{i}", DBNull.Value);
                        }
                        else if (pgType is "integer" or "bigint" or "smallint")
                        {
                            if (rawVal is bool b)
                                writeCmd.Parameters.AddWithValue($"p{i}", b ? 1 : 0);
                            else if (long.TryParse(rawVal.ToString(), out var lVal))
                                writeCmd.Parameters.AddWithValue($"p{i}", lVal);
                            else if (DateTimeOffset.TryParse(rawVal.ToString(), out var dto))
                                writeCmd.Parameters.AddWithValue($"p{i}", dto.ToUnixTimeSeconds());
                            else
                                writeCmd.Parameters.AddWithValue($"p{i}", DBNull.Value);
                        }
                        else
                        {
                            writeCmd.Parameters.AddWithValue($"p{i}", rawVal.ToString() ?? string.Empty);
                        }
                    }

                    await writeCmd.ExecuteNonQueryAsync();
                    importedCount++;
                }

                _logger.LogInformation("Imported {Count} rows into '{Table}'.", importedCount, pgTable);
            }

            await using (var defaultRoleCmd = new NpgsqlCommand("SET session_replication_role = 'origin';", pgConn, tx))
            {
                await defaultRoleCmd.ExecuteNonQueryAsync();
            }

            await tx.CommitAsync();
            await EnsureDefaultsSeededAsync(pgConn);
            await SyncAllSequencesAsync(pgConn);
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync();
            _logger.LogError(ex, "Error importing SQLite database into PostgreSQL.");
            throw;
        }
    }

    private static async Task<bool> SqliteTableExistsAsync(SqliteConnection conn, string tableName)
    {
        await using var cmd = new SqliteCommand(
            "SELECT name FROM sqlite_master WHERE type='table' AND LOWER(name) = LOWER(@name);", conn);
        cmd.Parameters.AddWithValue("@name", tableName);
        var res = await cmd.ExecuteScalarAsync();
        return res is not null;
    }

    private static async Task<List<string>> GetSqliteTableColumnsAsync(SqliteConnection conn, string tableName)
    {
        var cols = new List<string>();
        await using var cmd = new SqliteCommand($"PRAGMA table_info(\"{tableName}\");", conn);
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var name = reader["name"]?.ToString();
            if (!string.IsNullOrWhiteSpace(name))
                cols.Add(name);
        }
        return cols;
    }

    private static async Task<Dictionary<string, string>> GetPgTableColumnsAsync(
        NpgsqlConnection conn, NpgsqlTransaction tx, string pgTable)
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        await using var cmd = new NpgsqlCommand("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = @t;
            """, conn, tx);
        cmd.Parameters.AddWithValue("t", pgTable);
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            map[reader.GetString(0)] = reader.GetString(1).ToLowerInvariant();
        }
        return map;
    }

    private static async Task EnsureDefaultsSeededAsync(NpgsqlConnection conn)
    {
        // 1. Seed default admin user if pass table is empty
        await using (var checkPass = new NpgsqlCommand("SELECT COUNT(*) FROM pass;", conn))
        {
            var count = Convert.ToInt64(await checkPass.ExecuteScalarAsync());
            if (count == 0)
            {
                const string insertAdmin = """
                    INSERT INTO pass (
                        person_name, pass_word,
                        can_persons, can_stages, can_areas, can_fathers,
                        can_reports, can_users, can_absence, can_maintenance,
                        can_id_card, can_tayo, can_transfer, can_services,
                        can_khoros, can_behavior, is_advanced
                    ) VALUES (
                        'admin', '1234',
                        1, 1, 1, 1,
                        1, 1, 1, 1,
                        1, 1, 1, 1,
                        1, 1, 0
                    );
                    """;
                await using var cmd = new NpgsqlCommand(insertAdmin, conn);
                await cmd.ExecuteNonQueryAsync();
            }
        }

        // 2. Ensure admin has visitation permission
        await using (var visPermCmd = new NpgsqlCommand("""
            INSERT INTO user_permissions_ext (user_id, feature_key, can_add, can_edit, can_delete)
            SELECT pass_id, 'visitation', 1, 1, 1
            FROM pass
            WHERE person_name = 'admin'
            ON CONFLICT (user_id, feature_key) DO UPDATE SET
                can_add = 1, can_edit = 1, can_delete = 1;
            """, conn))
        {
            await visPermCmd.ExecuteNonQueryAsync();
        }

        // 3. Seed native custom field definitions
        var nativeFields = new (string Key, string Name, int Order, int Filter, int Visible, int IsPhone)[]
        {
            ("name", "الاسم رباعي", 0, 0, 1, 0),
            ("gender", "النوع", 1, 1, 1, 0),
            ("stage", "المرحلة", 2, 1, 1, 0),
            ("mobile", "الموبايل", 3, 0, 1, 1),
            ("phone", "التليفون الأرضي", 4, 0, 1, 1),
            ("area", "المنطقة", 5, 1, 1, 0),
            ("street", "العنوان/الشارع", 6, 0, 1, 0),
            ("father", "أب الاعتراف", 7, 1, 1, 0),
            ("khoros", "الخورس", 8, 1, 1, 0),
            ("services", "الخدمات", 9, 1, 1, 0),
            ("birthday", "تاريخ الميلاد", 10, 1, 1, 0),
            ("rohot", "الرهط", 11, 1, 0, 0),
            ("leader", "القائد", 12, 1, 0, 0),
        };

        foreach (var f in nativeFields)
        {
            await using var cmd = new NpgsqlCommand("""
                INSERT INTO custom_field_definitions (field_key, name, type, field_order, is_visible, is_filter, is_phone)
                VALUES (@k, @n, 'native', @o, @v, @f, @p)
                ON CONFLICT (field_key) DO NOTHING;
                """, conn);
            cmd.Parameters.AddWithValue("k", f.Key);
            cmd.Parameters.AddWithValue("n", f.Name);
            cmd.Parameters.AddWithValue("o", f.Order);
            cmd.Parameters.AddWithValue("v", f.Visible);
            cmd.Parameters.AddWithValue("f", f.Filter);
            cmd.Parameters.AddWithValue("p", f.IsPhone);
            await cmd.ExecuteNonQueryAsync();
        }

        // 4. Seed legacy service links into Khoros_Services and Stage_Services
        await using (var seedLinksCmd = new NpgsqlCommand("""
            INSERT INTO khoros_services (khoros_id, service_id)
            SELECT khoros_id, service_id FROM khoroses
            WHERE khoros_id IS NOT NULL AND service_id IS NOT NULL
            ON CONFLICT DO NOTHING;

            INSERT INTO stage_services (stage_id, service_id)
            SELECT stage_id, service_id FROM stages
            WHERE stage_id IS NOT NULL AND service_id IS NOT NULL
            ON CONFLICT DO NOTHING;
            """, conn))
        {
            await seedLinksCmd.ExecuteNonQueryAsync();
        }
    }

    public static async Task SyncAllSequencesAsync(NpgsqlConnection conn, NpgsqlTransaction? tx = null)
    {
        foreach (var (table, idCol) in SingleIdPrimaryKeys)
        {
            var sql = $"""
                SELECT setval(
                    pg_get_serial_sequence('{table}', '{idCol}'),
                    COALESCE((SELECT MAX({idCol}) FROM {table}), 0) + 1,
                    false
                );
                """;
            await using var cmd = new NpgsqlCommand(sql, conn, tx);
            await cmd.ExecuteNonQueryAsync();
        }
    }
}
