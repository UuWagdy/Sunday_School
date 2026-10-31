#define MyAppName "Sunday School Client"
#define MyAppArabicName "عميل مدارس الأحد (الشبكة المحلية)"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.5"
#endif
#define MyAppPublisher "Sunday School"

[Setup]
AppId={{5E9B2834-8A01-4F29-9150-706F79F88C02}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Sunday School Client
DefaultGroupName=مدارس الأحد
UsePreviousAppDir=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\app_icon.ico
OutputDir=output
OutputBaseFilename=SundaySchool_Client_Setup
Compression=lzma2/ultra64
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
ChangesAssociations=no
ChangesEnvironment=no
VersionInfoVersion={#MyAppVersion}.0
VersionInfoProductName={#MyAppName}
VersionInfoDescription=Sunday School LAN Thin Client Installer (Windows 7/8/10/11 Compatible)
VersionInfoCompany={#MyAppPublisher}

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "إنشاء اختصار للبرنامج على سطح المكتب (Desktop Shortcut)"; GroupDescription: "اختصارات إضافية:"; Flags: checkedonce
Name: "changeservericon"; Description: "إنشاء اختصار 'تغيير عنوان السيرفر' على سطح المكتب"; GroupDescription: "اختصارات إضافية:"; Flags: checkedonce

[Files]
Source: "client\SundaySchoolLauncher.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "client\ChangeServerAddress.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "client\SundaySchoolLauncher.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "client\server_url.txt"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "..\windows\runner\resources\app_icon.ico"; DestDir: "{app}"; DestName: "app_icon.ico"; Flags: ignoreversion

[Icons]
; Desktop Shortcuts
Name: "{autodesktop}\مدارس الأحد"; Filename: "{sys}\wscript.exe"; Parameters: """//B"" ""//Nologo"" ""{app}\SundaySchoolLauncher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon
Name: "{autodesktop}\تغيير عنوان خادم مدارس الأحد"; Filename: "{sys}\wscript.exe"; Parameters: """//B"" ""//Nologo"" ""{app}\ChangeServerAddress.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"; Tasks: changeservericon

; Start Menu Shortcuts
Name: "{autoprograms}\مدارس الأحد\مدارس الأحد"; Filename: "{sys}\wscript.exe"; Parameters: """//B"" ""//Nologo"" ""{app}\SundaySchoolLauncher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{autoprograms}\مدارس الأحد\تغيير عنوان خادم مدارس الأحد"; Filename: "{sys}\wscript.exe"; Parameters: """//B"" ""//Nologo"" ""{app}\ChangeServerAddress.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{autoprograms}\مدارس الأحد\إلغاء التثبيت"; Filename: "{uninstallexe}"; WorkingDir: "{app}"

[Run]
Filename: "{sys}\wscript.exe"; Parameters: """//B"" ""//Nologo"" ""{app}\SundaySchoolLauncher.vbs"""; Description: "تشغيل مدارس الأحد الآن"; Flags: nowait postinstall skipifsilent

[Code]
var
  ServerPage: TInputQueryWizardPage;

procedure InitializeWizard;
begin
  ServerPage := CreateInputQueryPage(wpSelectDir,
    'عنوان خادم مدارس الأحد',
    'يرجى إدخال عنوان IP الخاص بجهاز السيرفر الرئيسي على الشبكة المحلية (LAN)',
    'مثال: 192.168.1.100:5050 أو http://192.168.1.100:5050' + #13#10 +
    'ملاحظة: يمكنك تعديل هذا العنوان في أي وقت لاحقاً عبر اختصار "تغيير عنوان خادم مدارس الأحد".');
  ServerPage.Add('عنوان السيرفر (IP أو اسم الجهاز مع المنفذ):', False);
  ServerPage.Values[0] := '192.168.1.100:5050';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Url: string;
begin
  if CurStep = ssPostInstall then
  begin
    Url := Trim(ServerPage.Values[0]);
    if Length(Url) > 0 then
    begin
      if (Pos('http://', Lowercase(Url)) = 0) and (Pos('https://', Lowercase(Url)) = 0) then
        Url := 'http://' + Url;
      SaveStringToFile(ExpandConstant('{app}\server_url.txt'), Url + #13#10, False);
    end;
  end;
end;
