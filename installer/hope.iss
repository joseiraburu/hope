; Instalador de HOPE para Windows (Inno Setup 6).
; Se compila automáticamente en GitHub Actions; también a mano con:
;   iscc /DMyAppVersion=0.1.0 installer\hope.iss
; después de "flutter build windows --release".

#ifndef MyAppVersion
  #define MyAppVersion "0.1.0"
#endif

#define MyAppName "HOPE"
#define MyAppExe "hope.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{DA69590D-8DAE-4E45-9ED1-EE1302F4C04B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=Proyecto HOPE (software libre, GPL-3.0)
AppPublisherURL=https://github.com/joseiraburu/hope
AppSupportURL=https://github.com/joseiraburu/hope/issues
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Instalación para el usuario actual: no pide permisos de administrador.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\dist
OutputBaseFilename=HOPE-{#MyAppVersion}-windows-instalador
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExe}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
