#define MyAppName "Reconix VAT 3-Way Reconciliation Platform"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Reconix Kenya Tax Compliance Ltd"
#define MyAppURL "https://reconix.co.ke"
#define MyAppExeName "reconix.exe"

[Setup]
AppId={{D8392190-3841-477A-9A2C-5F292B284192}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\Reconix
DefaultGroupName=Reconix
AllowNoIcons=yes
OutputDir=build\installer
OutputBaseFilename=Reconix_Setup_v1.0.0
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "c:\flutter_projects\reconix\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent







