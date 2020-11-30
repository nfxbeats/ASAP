[Files]
Source: "D:\Dropbox\DelphiCode\ASAP\ASAP\Win32\Debug\ASAP.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\Dropbox\DelphiCode\ASAP\ASAP\Win32\Debug\bass.dll"; DestDir: "{app}"; Flags: ignoreversion

[Setup]
AppName=Audio Search And Preview
AppVersion=1.0
AppId={{FDB74CA7-28D3-4C3F-B59D-A4874D6F1CCC}
UninstallDisplayName=Audio Search And Preview - ASAP
DefaultDirName={commonpf}\nfx\ASAP
ShowLanguageDialog=no
VersionInfoVersion=1.0
SolidCompression=True
SourceDir=D:\Dropbox\DelphiCode\ASAP\ASAP\Win32\Debug
OutputBaseFilename=ASAP_Install.exe 

[Run]
Filename: "{app}\ASAP.exe"; WorkingDir: "{app}"
