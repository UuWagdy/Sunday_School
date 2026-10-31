using Microsoft.AspNetCore.SignalR;
using SundaySchool.SyncServer.Models;

namespace SundaySchool.SyncServer.Hubs;

[Microsoft.AspNetCore.Authorization.Authorize]
public sealed class SyncHub : Hub
{
    private readonly ILogger<SyncHub> _logger;

    public SyncHub(ILogger<SyncHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var deviceId = Context.GetHttpContext()?.Request.Query["deviceId"].ToString();
        _logger.LogInformation("SignalR client connected: ConnectionId={ConnectionId}, DeviceId={DeviceId}",
            Context.ConnectionId, deviceId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("SignalR client disconnected: ConnectionId={ConnectionId}", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    public Task<string> Ping()
    {
        return Task.FromResult("pong");
    }

    public async Task NotifyTablesChanged(List<string> tables, string? sourceDeviceId = null)
    {
        var payload = new SyncEventPayload
        {
            SequenceId = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
            AffectedTables = tables,
            Operation = "MANUAL_REFRESH",
            SourceDeviceId = sourceDeviceId,
            SourceConnectionId = Context.ConnectionId,
            TimestampUtc = DateTime.UtcNow,
        };
        await Clients.All.SendAsync("DatabaseChanged", payload);
    }
}
