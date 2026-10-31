[Setup]
AppId={{CF8C4527-5027-443E-9C08-328052491189}
AppName=Daisson Tunnel Manager
AppVersion=1.0.0
AppPublisher=Daisson
DefaultDirName={localappdata}\Programs\DaissonTunnelManager
DefaultGroupName=Daisson Tunnel Manager
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist\tunnel-manager
OutputBaseFilename=DaissonTunnelManager-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\DaissonTunnelManager.exe
CloseApplications=yes

[Files]
Source: "publish\DaissonTunnelManager.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "README-ar.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Daisson Tunnel Manager"; Filename: "{app}\DaissonTunnelManager.exe"
Name: "{userdesktop}\Daisson Tunnel Manager"; Filename: "{app}\DaissonTunnelManager.exe"

[Run]
Filename: "{app}\DaissonTunnelManager.exe"; Description: "Open Daisson Tunnel Manager"; Flags: nowait postinstall skipifsilent
