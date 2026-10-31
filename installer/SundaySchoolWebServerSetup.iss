#define MyAppName "Sunday School Web Server"
#define MyAppArabicName "خادم ويب مدارس الأحد"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.5"
#endif
#define MyAppPublisher "Sunday School"
#define MyAppExeName "SundaySchoolServerManager.exe"
#ifndef SyncServerSource
  #define SyncServerSource "payload\server\backend"
#endif
#ifndef ServerManagerSource
  #define ServerManagerSource "payload\server-manager"
#endif
#ifndef PostgresSource
  #define PostgresSource "payload\server\postgresql"
#endif
#ifndef WebSource
  #define WebSource "..\build\web"
#endif

#if !FileExists(SyncServerSource + "\coreclr.dll") || !FileExists(SyncServerSource + "\Microsoft.AspNetCore.dll")
  #error Publish the sync server with --self-contained true before compiling the installer.
#endif
#if !FileExists(ServerManagerSource + "\coreclr.dll") || !FileExists(ServerManagerSource + "\System.Windows.Forms.dll")
  #error Publish Server Manager with --self-contained true before compiling the installer.
#endif
#if !FileExists(PostgresSource + "\bin\pg_isready.exe") || !FileExists(PostgresSource + "\share\postgres.bki")
  #error Stage the complete portable PostgreSQL payload before compiling the installer.
#endif
#if !FileExists(WebSource + "\index.html") || !FileExists(WebSource + "\main.dart.js")
  #error Build the Flutter Web app before compiling the web server installer.
#endif

[Setup]
AppId={{D81729A1-7B14-4A3C-9E28-8C62A4F1D773}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Sunday School Web Server
DefaultGroupName={#MyAppName}
UsePreviousAppDir=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\ServerManager\{#MyAppExeName}
OutputDir=output
OutputBaseFilename=SundaySchool_WebServer_Setup
Compression=lzma2/fast
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
ChangesAssociations=no
ChangesEnvironment=no
VersionInfoVersion={#MyAppVersion}.0
VersionInfoProductName={#MyAppName}
VersionInfoDescription=Sunday School Web Server (.NET 8 + PostgreSQL + Web App)
VersionInfoCompany={#MyAppPublisher}

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "إنشاء اختصار على سطح المكتب (Desktop Shortcut)"; GroupDescription: "اختصارات إضافية:"; Flags: checkedonce

[Dirs]
Name: "{app}\SundaySchool_ServerData"; Permissions: users-modify authusers-modify; Flags: uninsneveruninstall
Name: "{app}\SundaySchool_ServerBackups"; Permissions: users-modify authusers-modify; Flags: uninsneveruninstall
Name: "{app}\Server\backend\wwwroot"; Permissions: users-modify authusers-modify

[Files]
Source: "BACKUP_GUIDE.txt"; DestDir: "{app}"; Flags: ignoreversion

; 1. .NET 8 Sync Server + SignalR Hub Payload
Source: "{#SyncServerSource}\*"; DestDir: "{app}\Server\backend"; Flags: ignoreversion recursesubdirs createallsubdirs

; 2. Flutter Web App Payload into wwwroot
Source: "{#WebSource}\*"; DestDir: "{app}\Server\backend\wwwroot"; Flags: ignoreversion recursesubdirs createallsubdirs

; 3. SundaySchoolServerManager
Source: "{#ServerManagerSource}\*"; DestDir: "{app}\ServerManager"; Flags: ignoreversion recursesubdirs createallsubdirs

; 4. Portable PostgreSQL
Source: "{#PostgresSource}\*"; DestDir: "{app}\Server\postgresql"; Flags: ignoreversion recursesubdirs createallsubdirs

; 5. Server PowerShell Helpers
Source: "install-server.ps1"; DestDir: "{app}\Server\installer"; Flags: ignoreversion
Source: "validate-server-payload.ps1"; DestDir: "{app}\Server\installer"; Flags: ignoreversion
Source: "register-server-startup.ps1"; DestDir: "{app}\Server\installer"; Flags: ignoreversion
Source: "repair-server.ps1"; DestDir: "{app}\Server\installer"; Flags: ignoreversion
Source: "uninstall-server.ps1"; DestDir: "{app}\Server\installer"; Flags: ignoreversion

; 6. Microsoft Visual C++ Redistributables
Source: "downloads\VC_redist.x64.exe"; Flags: dontcopy
Source: "downloads\VC_redist.x86.exe"; Flags: dontcopy

[Icons]
Name: "{autoprograms}\خادم ويب مدارس الأحد"; Filename: "{app}\ServerManager\SundaySchoolServerManager.exe"; Parameters: "--install-root ""{app}"""; WorkingDir: "{app}\ServerManager"
Name: "{autodesktop}\خادم ويب مدارس الأحد"; Filename: "{app}\ServerManager\SundaySchoolServerManager.exe"; Parameters: "--install-root ""{app}"""; WorkingDir: "{app}\ServerManager"; Tasks: desktopicon
Name: "{autoprograms}\فتح تطبيق مدارس الأحد (Web)"; Filename: "http://localhost:5050/"; WorkingDir: "{app}"
Name: "{autodesktop}\فتح تطبيق مدارس الأحد (Web)"; Filename: "http://localhost:5050/"; Tasks: desktopicon
Name: "{autoprograms}\معلومات سيرفر مدارس الأحد"; Filename: "{sys}\notepad.exe"; Parameters: """{app}\SERVER_INFO.txt"""
Name: "{autoprograms}\إصلاح سيرفر مدارس الأحد"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Server\installer\repair-server.ps1"" -InstallRoot ""{app}"""

[Run]
Filename: "{app}\ServerManager\SundaySchoolServerManager.exe"; Parameters: "--background --install-root ""{app}"""; Description: "تشغيل مدير سيرفر مدارس الأحد (PostgreSQL + SignalR)"; Flags: nowait runasoriginaluser
Filename: "http://localhost:5050/"; Description: "فتح تطبيق مدارس الأحد في المتصفح الآن"; Flags: shellexec nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Server\installer\uninstall-server.ps1"" -InstallRoot ""{app}"" -PreserveData"; Flags: waituntilterminated runhidden; RunOnceId: "StopSundaySchoolServerOnUninstall"

[Code]
var
  PrerequisiteRestart: Boolean;

function VCRuntimeInstalled(const Arch: String; const RootKey: Integer): Boolean;
var
  Key: String;
  Installed, Major, Minor, Build: Cardinal;
begin
  Key := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\' + Arch;
  Result := RegQueryDWordValue(RootKey, Key, 'Installed', Installed) and (Installed = 1) and
    RegQueryDWordValue(RootKey, Key, 'Major', Major) and
    RegQueryDWordValue(RootKey, Key, 'Minor', Minor) and
    RegQueryDWordValue(RootKey, Key, 'Bld', Build);
  if Result then
    Result := (Major > 14) or ((Major = 14) and ((Minor > 44) or ((Minor = 44) and (Build >= 35211))));
end;

function InstallVCRuntime(const Arch: String; const RootKey: Integer): String;
var
  Name, Parameters: String;
  ExitCode, Attempt: Integer;
begin
  Result := '';
  if VCRuntimeInstalled(Arch, RootKey) then exit;
  Name := 'VC_redist.' + Arch + '.exe';
  ExtractTemporaryFile(Name);
  Parameters := '/install /quiet /norestart /log "' + ExpandConstant('{tmp}\SundaySchool-VC-') + Arch + '.log"';
  WizardForm.PreparingLabel.Caption := 'جاري تجهيز متطلبات التشغيل Visual C++ (' + Arch + ')...';
  for Attempt := 1 to 30 do begin
    if not Exec(ExpandConstant('{tmp}\') + Name, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ExitCode) then begin
      Result := 'تعذر تشغيل مثبت متطلبات Visual C++ (' + Arch + ').';
      exit;
    end;
    Log(Format('VC++ %s attempt %d exit code: %d', [Arch, Attempt, ExitCode]));
    if (ExitCode <> 1618) and (ExitCode <> -2147023278) then break;
    WizardForm.PreparingLabel.Caption := 'يوجد تثبيت آخر قيد التشغيل. جاري الانتظار ثم إعادة المحاولة تلقائيًا...';
    Sleep(10000);
  end;
  if (ExitCode = 3010) or (ExitCode = 1641) then PrerequisiteRestart := True
  else if (ExitCode <> 0) and (ExitCode <> 1638) and (ExitCode <> -2147023258) then begin
    Result := Format('فشل تثبيت متطلبات Visual C++ (%s)، كود %d. أغلق أي تثبيت آخر ثم أعد المحاولة. السجل: ', [Arch, ExitCode]) + ExpandConstant('{tmp}\SundaySchool-VC-') + Arch + '.log';
    exit;
  end;
  if not PrerequisiteRestart and not VCRuntimeInstalled(Arch, RootKey) then
    Result := 'لم يكتمل تجهيز متطلبات Visual C++ (' + Arch + '). أعد تشغيل Windows ثم أعد تشغيل المثبت.';
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := InstallVCRuntime('x64', HKLM64);
  if Result = '' then Result := InstallVCRuntime('x86', HKLM32);
  NeedsRestart := PrerequisiteRestart;
  if NeedsRestart and (Result = '') then
    Result := 'تم تثبيت متطلبات التشغيل. أعد تشغيل Windows ثم شغّل المثبت مرة أخرى لإكمال تثبيت البرنامج.';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Parameters: String;
  ExitCode: Integer;
begin
  if (CurStep = ssPostInstall) then begin
    WizardForm.StatusLabel.Caption := 'جاري تجهيز PostgreSQL وسيرفر المزامنة...';
    Parameters := '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\Server\installer\install-server.ps1') +
      '" -InstallRoot "' + ExpandConstant('{app}') + '" -InstallerVersion "{#MyAppVersion}"';
    if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Parameters, '', SW_HIDE, ewWaitUntilTerminated, ExitCode) then
      RaiseException('تعذر تشغيل تجهيز السيرفر. أعد تشغيل المثبت.');
    if ExitCode <> 0 then
      RaiseException('فشل تجهيز السيرفر. أعد تشغيل المثبت بعد مراجعة السجل: ' + ExpandConstant('{app}\SundaySchool_ServerData\logs\install-server.log'));
  end;
end;
