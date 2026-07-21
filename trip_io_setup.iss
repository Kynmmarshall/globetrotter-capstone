; Inno Setup script for the trip_io Windows desktop build.
; Build the app first (from the project root):
;   flutter build windows --dart-define=API_BASE_URL=https://trip-io.duckdns.org
; Then compile this script with Inno Setup (ISCC.exe trip_io_setup.iss, or open in the IDE).
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "trip_io"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "trip_io"
#define MyAppURL "https://trip-io.duckdns.org"
#define MyAppExeName "trip_io.exe"
#define MyAppBuildDir "build\windows\x64\runner\Release"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{354F8A05-A547-475C-B6F9-8A423D53C33F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
; "ArchitecturesAllowed=x64compatible" specifies that Setup cannot run
; on anything but x64 and Windows 11 on Arm.
ArchitecturesAllowed=x64compatible
; "ArchitecturesInstallIn64BitMode=x64compatible" requests that the
; install be done in "64-bit mode" on x64 or Windows 11 on Arm,
; meaning it should use the native 64-bit Program Files directory and
; the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
; Uncomment these if you add a release-notes / license text file next to this script.
;InfoBeforeFile={#SourcePath}\TRIP_IO_INFO.txt
;InfoAfterFile={#SourcePath}\TRIP_IO_INFO.txt
; Uncomment the following line to run in non administrative install mode (install for current user only).
;PrivilegesRequired=lowest
OutputBaseFilename=trip_io Setup
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourcePath}\{#MyAppBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\{#MyAppBuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\{#MyAppBuildDir}\file_selector_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\{#MyAppBuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
