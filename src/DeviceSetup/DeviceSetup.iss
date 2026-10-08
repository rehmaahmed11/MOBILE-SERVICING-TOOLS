#define AppName "Mobile Servicing Tools"

#ifndef AppVersion
  #define AppVersion "1.1.0"
#endif

; AppPlatform64 is defined only for a Win64 package. Presence-based selection
; avoids treating a command-line value of 0 as a truthy string.
#ifdef AppPlatform64
  #define InstallerPlatform "Win64"
#else
  #define InstallerPlatform "Win32"
#endif

[Setup]
AppId={{45C79399-BC6E-4BA2-99BC-F5231463EB76}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} ({#InstallerPlatform})
AppPublisher=Mobile Servicing Tools
DefaultDirName={localappdata}\Programs\Mobile Servicing Tools
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
#ifdef AppPlatform64
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
#endif
OutputDir=..\..\artifacts
OutputBaseFilename=DeviceSetup-Setup-{#InstallerPlatform}
SetupIconFile=DeviceSetup.ico
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\DeviceSetup.exe
Uninstallable=yes
CloseApplications=yes
RestartApplications=no
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Install the verified bundle as-is at {app}: EXE and DLLs at the root,
; support payloads in Data, and the supplied architecture-specific libusb tree.
Source: "..\..\artifacts\package\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\DeviceSetup.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\DeviceSetup.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\DeviceSetup.exe"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
