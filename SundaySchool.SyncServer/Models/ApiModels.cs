using System.Text.Json.Serialization;

namespace SundaySchool.SyncServer.Models;

public sealed class LoginRequest
{
    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;

    [JsonPropertyName("password")]
    public string Password { get; set; } = string.Empty;

    [JsonPropertyName("deviceId")]
    public string? DeviceId { get; set; }
}

public sealed class LoginResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("ok")]
    public bool Ok => Success;

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("token")]
    public string? Token { get; set; }

    [JsonPropertyName("user")]
    public UserDto? User { get; set; }
}

public sealed class UserDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;

    [JsonPropertyName("canPersons")]
    public bool CanPersons { get; set; }

    [JsonPropertyName("canStages")]
    public bool CanStages { get; set; }

    [JsonPropertyName("canAreas")]
    public bool CanAreas { get; set; }

    [JsonPropertyName("canFathers")]
    public bool CanFathers { get; set; }

    [JsonPropertyName("canReports")]
    public bool CanReports { get; set; }

    [JsonPropertyName("canUsers")]
    public bool CanUsers { get; set; }

    [JsonPropertyName("canAbsence")]
    public bool CanAbsence { get; set; }

    [JsonPropertyName("canMaintenance")]
    public bool CanMaintenance { get; set; }

    [JsonPropertyName("canIdCard")]
    public bool CanIdCard { get; set; }

    [JsonPropertyName("canTayo")]
    public bool CanTayo { get; set; }

    [JsonPropertyName("canTransfer")]
    public bool CanTransfer { get; set; }

    [JsonPropertyName("canServices")]
    public bool CanServices { get; set; }

    [JsonPropertyName("canKhoros")]
    public bool CanKhoros { get; set; }

    [JsonPropertyName("canBehavior")]
    public bool CanBehavior { get; set; }

    [JsonPropertyName("isAdvanced")]
    public bool IsAdvanced { get; set; }

    [JsonPropertyName("granularPermissions")]
    public Dictionary<string, Dictionary<string, bool>> GranularPermissions { get; set; } = new();

    [JsonPropertyName("visibilityFilters")]
    public Dictionary<string, List<int>> VisibilityFilters { get; set; } = new();
    [JsonPropertyName("dataVisibilityScope")]
    public Dictionary<string, List<string>> DataVisibilityScope { get; set; } = new();

    [JsonPropertyName("visibleUserIds")]
    public List<int> VisibleUserIds { get; set; } = new();
}

public sealed class SqlParamDto
{
    /// <summary>
    /// "null" | "int" | "double" | "string" | "bool" | "bytes"
    /// </summary>
    [JsonPropertyName("type")]
    public string Type { get; set; } = "null";

    [JsonPropertyName("value")]
    public object? Value { get; set; }
}

public sealed class SqlRequest
{
    [JsonPropertyName("acceptCache")]
    public bool AcceptCache { get; set; }

    [JsonPropertyName("cacheTag")]
    public string? CacheTag { get; set; }
    [JsonPropertyName("sql")]
    public string Sql { get; set; } = string.Empty;

    [JsonPropertyName("params")]
    public List<SqlParamDto> Params { get; set; } = new();

    [JsonPropertyName("transactionId")]
    public string? TransactionId { get; set; }

    [JsonPropertyName("deviceId")]
    public string? DeviceId { get; set; }

    [JsonPropertyName("connectionId")]
    public string? ConnectionId { get; set; }
}

public sealed class SqlQueryResponse
{
    [JsonPropertyName("cacheTag")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? CacheTag { get; set; }

    [JsonPropertyName("notModified")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public bool NotModified { get; set; }
    [JsonPropertyName("rows")]
    public List<Dictionary<string, object?>> Rows { get; set; } = new();
}

public sealed class SqlExecuteResponse
{
    [JsonPropertyName("rowsAffected")]
    public int RowsAffected { get; set; }

    [JsonPropertyName("lastInsertId")]
    public long LastInsertId { get; set; }

    [JsonPropertyName("affectedTables")]
    public List<string> AffectedTables { get; set; } = new();

    [JsonPropertyName("sequenceId")]
    public long SequenceId { get; set; }
}

public sealed class SqlBatchStatementDto
{
    [JsonPropertyName("sql")]
    public string Sql { get; set; } = string.Empty;

    [JsonPropertyName("argSets")]
    public List<List<SqlParamDto>> ArgSets { get; set; } = new();
}

public sealed class SqlBatchRequest
{
    [JsonPropertyName("statements")]
    public List<SqlBatchStatementDto> Statements { get; set; } = new();

    [JsonPropertyName("transactionId")]
    public string? TransactionId { get; set; }

    [JsonPropertyName("deviceId")]
    public string? DeviceId { get; set; }

    [JsonPropertyName("connectionId")]
    public string? ConnectionId { get; set; }
}

public sealed class BeginTransactionResponse
{
    [JsonPropertyName("transactionId")]
    public string TransactionId { get; set; } = string.Empty;
}

public sealed class TransactionControlRequest
{
    [JsonPropertyName("transactionId")]
    public string TransactionId { get; set; } = string.Empty;

    [JsonPropertyName("deviceId")]
    public string? DeviceId { get; set; }

    [JsonPropertyName("connectionId")]
    public string? ConnectionId { get; set; }
}

public sealed class SyncEventPayload
{
    [JsonPropertyName("sequenceId")]
    public long SequenceId { get; set; }

    [JsonPropertyName("affectedTables")]
    public List<string> AffectedTables { get; set; } = new();

    [JsonPropertyName("operation")]
    public string Operation { get; set; } = "WRITE";

    [JsonPropertyName("sourceDeviceId")]
    public string? SourceDeviceId { get; set; }

    [JsonPropertyName("sourceConnectionId")]
    public string? SourceConnectionId { get; set; }

    [JsonPropertyName("timestampUtc")]
    public DateTime TimestampUtc { get; set; } = DateTime.UtcNow;
}
