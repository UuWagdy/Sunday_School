# Validation — 2026-10-18

`dotnet run --project Tests/DaissonTunnelManager.Tests.csproj -c Release` completed with **55 passing checks**.

Coverage includes domain/IDN and local origin validation; multi-customer identity separation; credential-free import/export; DPAPI encrypted persistence; preserving existing ingress, wildcard order, origin settings and DNS; rejecting conflicting DNS and stale or cross-customer plans; rolling back a partial DNS failure; blocking inactive zones and unprotected services; connector environment-only credentials; child restart, cancellation cleanup and job-based process cleanup; bounded metadata discovery; HTTP connectivity; and WinForms construction/rendering/close/dispose.

Five tab previews were rendered and visually inspected during development. The UI supports an editable domain on every customer profile; it does not ship a customer's account, credentials, domain binding or publish selections.

Read-only diagnostics on the installed applications found:

| Program | Origin | Manager | HTTP reachable |
|---|---|---|---|
| Sunday School | http://127.0.0.1:5050 | E:\Sunday School\ServerManager\SundaySchoolServerManager.exe | Yes |
| Church membership | http://127.0.0.1:5060 | E:\AbonaFlemoon\ServerManager\AbonaFlemoonServerManager.exe | Yes |

The existing Cloudflared service remained running. No replacement or restart of it was performed. No Daisson service was installed during this session. Process supervisor tests used disposable test processes, not customer tunnels.

Cloudflare API tests used an in-memory HTTP handler. No actual Cloudflare account, DNS, tunnel configuration, Hostinger nameservers or application authentication settings were changed. Real Windows service installation, connector health and public HTTPS connectivity remain to be verified with the user's account, UAC and protected application servers. Local HTTP connectivity does not establish phone LAN connectivity or public access.
