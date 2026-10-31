using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using SundaySchool.SyncServer.Models;
using SundaySchool.SyncServer.Services;

namespace SundaySchool.SyncServer.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly StorageService _storage;
    private readonly IConfiguration _configuration;

    public AuthController(StorageService storage, IConfiguration configuration)
    {
        _storage = storage;
        _configuration = configuration;
    }

    [HttpGet("users")]
    public async Task<ActionResult<List<UserDto>>> GetUsers()
    {
        var users = await _storage.GetAllUsersAsync();
        // Login needs display names only. Never publish permissions or scopes anonymously.
        return Ok(users.Select(u => new UserDto { Id=u.Id, Username=u.Username }).ToList());
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            return Ok(new LoginResponse
            {
                Success = false,
                Message = "يرجى إدخال اسم المستخدم وكلمة المرور.",
            });
        }

        var user = await _storage.AuthenticateUserAsync(request.Username, request.Password);
        if (user is null)
        {
            return Ok(new LoginResponse
            {
                Success = false,
                Message = "كلمة مرور أو مستخدم غير صحيح.",
            });
        }

        var token = GenerateJwtToken(user);
        return Ok(new LoginResponse
        {
            Success = true,
            Message = "تم تسجيل الدخول بنجاح!",
            Token = token,
            User = user,
        });
    }

    private string GenerateJwtToken(UserDto user)
    {
        var secret = GetJwtSecret(_configuration);

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
            new Claim("is_advanced", user.IsAdvanced ? "1" : "0"),
        };

        var token = new JwtSecurityToken(
            issuer: "SundaySchool.SyncServer",
            audience: "SundaySchool.FlutterClient",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    internal static string GetJwtSecret(IConfiguration configuration) => configuration["Jwt:Secret"]
            ?? Environment.GetEnvironmentVariable("JWT_SECRET")
            ?? "SundaySchool_Default_Super_Secret_Jwt_Key_2026_PostgreSQL_Sync!";

}
