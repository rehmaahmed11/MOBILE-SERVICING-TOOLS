unit DaLoader;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ DaLoader
  Locates the supplied portable data layout (Data/DA and Data/FDL1/FDL2),
  and keeps the real vendor agent payloads byte-for-byte. It also retains
  support for optional ZIP/.da archives containing da.bin and auth.bin.

  The shipped .da/.crp/.bin files are opaque vendor payloads; their format,
  signature and exact handset compatibility are not inferred here. Finding a
  file only catalogs it. No device communication is performed by this unit.
}

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, IniFiles, zipper;
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.IniFiles,
  System.Zip;
{$ENDIF}

type
  TDaLoadResult = record
    Found: Boolean;
    DaFile: string;           { Path to the source payload / archive }
    AgentFile: string;        { Direct raw payload or extracted da.bin }
    ExtractedDaBin: string;   { Path to extracted da.bin (archives only) }
    ExtractedAuthBin: string; { Path to extracted auth.bin (empty when absent) }
    HasAuth: Boolean;
    IsOpaque: Boolean;       { True for supplied vendor payloads kept byte-for-byte }
    FileSizeBytes: Int64;
    Message: string;
  end;

function GetDataFolder: string;
function GetDaFolder: string;
function GetFdl1Path: string;
function GetFdl2Path: string;
function GetBundledDataAssetCount: Integer;
function GetBundledDataAssetBytes: Int64;

{ Resolve a real payload for the given Brand and Model. Opaque supplied files
  are returned unchanged; only ZIP/7z archives are extracted. }
function ResolveAndExtractDa(const ABrand, AModelCode, AModelName: string): TDaLoadResult;

{ Direct archive extraction of a ZIP/7z container to output directory }
function ExtractDaArchive(const ADaPath, ATargetDir: string;
  out ADaBinPath, AAuthBinPath: string; out AError: string): Boolean;

implementation

uses
  AppInfo;

function IsDataRoot(const AFolder: string): Boolean;
var
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(AFolder);
  Result := DirectoryExists(Root + 'DA') or DirectoryExists(Root + 'da') or
    FileExists(Root + 'FDL1') or FileExists(Root + 'FDL2') or
    FileExists(Root + 'fdl1.bin') or FileExists(Root + 'fdl2.bin');
end;

function ParentDirectory(const ADirectory: string): string;
var
  Current: string;
begin
  Current := ExcludeTrailingPathDelimiter(ADirectory);
  Result := ExtractFileDir(Current);
  if SameText(Result, Current) then
    Result := '';
end;

function FindDataRootFrom(const AStartDirectory: string): string;
var
  Current, Candidate: string;
  I: Integer;
begin
  Result := '';
  if AStartDirectory = '' then
    Exit;
  Current := ExpandFileName(AStartDirectory);
  for I := 0 to 12 do
  begin
    Candidate := IncludeTrailingPathDelimiter(Current) + 'Data' + PathDelim;
    if IsDataRoot(Candidate) then
    begin
      Result := IncludeTrailingPathDelimiter(Candidate);
      Exit;
    end;
    Candidate := IncludeTrailingPathDelimiter(Current) + 'data' + PathDelim;
    if IsDataRoot(Candidate) then
    begin
      Result := IncludeTrailingPathDelimiter(Candidate);
      Exit;
    end;

    { Development checkout: keep the user-supplied support tree under the
      repository's data folder instead of copying 130+ MiB into the source. }
    Candidate := IncludeTrailingPathDelimiter(Current) + 'data' + PathDelim +
      'support' + PathDelim + 'MOBILO TOOLZ' + PathDelim + 'Data' + PathDelim;
    if IsDataRoot(Candidate) then
    begin
      Result := IncludeTrailingPathDelimiter(Candidate);
      Exit;
    end;

    Current := ParentDirectory(Current);
    if Current = '' then
      Break;
  end;
end;

function FindFileInsensitive(const ADirectory, AFileName: string): string;
var
  SR: TSearchRec;
  Dir: string;
begin
  Result := '';
  Dir := IncludeTrailingPathDelimiter(ADirectory);
  if FileExists(Dir + AFileName) then
  begin
    Result := Dir + AFileName;
    Exit;
  end;
  if FindFirst(Dir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if ((SR.Attr and faDirectory) = 0) and SameText(SR.Name, AFileName) then
      begin
        Result := Dir + SR.Name;
        Break;
      end;
    until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
end;

function GetDataFolder: string;
var
  Candidate: string;
begin
  { Installed bundle: Data/DA and Data/FDL1/FDL2 sit beside the EXE. }
  Candidate := FindDataRootFrom(ExeDir);
  if Candidate = '' then
    Candidate := FindDataRootFrom(GetCurrentDir);

  { User-managed data may be placed beside settings, including the APPDATA
    fallback used when the application folder is read-only. }
  if (Candidate = '') and IsDataRoot(DataDir + 'Data') then
    Candidate := DataDir + 'Data' + PathDelim;
  if (Candidate = '') and IsDataRoot(DataDir + 'data') then
    Candidate := DataDir + 'data' + PathDelim;

  if Candidate <> '' then
    Result := IncludeTrailingPathDelimiter(Candidate)
  else
    Result := ExeDir + 'Data' + PathDelim;
end;

function GetDaFolder: string;
var
  Root: string;
begin
  Root := GetDataFolder;
  if DirectoryExists(Root + 'DA') then
    Result := Root + 'DA' + PathDelim
  else if DirectoryExists(Root + 'da') then
    Result := Root + 'da' + PathDelim
  else
    Result := Root + 'DA' + PathDelim;
end;

function GetFdl1Path: string;
var
  Root: string;
begin
  Root := GetDataFolder;
  Result := FindFileInsensitive(Root, 'FDL1');
  if Result = '' then
    Result := FindFileInsensitive(Root, 'fdl1.bin');
end;

function GetFdl2Path: string;
var
  Root: string;
begin
  Root := GetDataFolder;
  Result := FindFileInsensitive(Root, 'FDL2');
  if Result = '' then
    Result := FindFileInsensitive(Root, 'fdl2.bin');
end;

function FileSizeByPath(const AFileName: string): Int64;
var
  SR: TSearchRec;
begin
  Result := -1;
  if (AFileName <> '') and (FindFirst(AFileName, faAnyFile, SR) = 0) then
  begin
    Result := SR.Size;
    SysUtils.FindClose(SR);
  end;
end;

function IsPayloadExtension(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.da') or (Ext = '.bin') or (Ext = '.crp');
end;

function GetBundledDataAssetCount: Integer;
var
  SR: TSearchRec;
  Dir: string;
begin
  Result := 0;
  Dir := GetDaFolder;
  if FindFirst(Dir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if ((SR.Attr and faDirectory) = 0) and IsPayloadExtension(SR.Name) then
        Inc(Result);
    until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
  if GetFdl1Path <> '' then
    Inc(Result);
  if GetFdl2Path <> '' then
    Inc(Result);
end;

function GetBundledDataAssetBytes: Int64;
var
  SR: TSearchRec;
  Dir, FdlPath: string;
  FdlSize: Int64;
begin
  Result := 0;
  Dir := GetDaFolder;
  if FindFirst(Dir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if ((SR.Attr and faDirectory) = 0) and IsPayloadExtension(SR.Name) then
        Inc(Result, SR.Size);
    until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
  FdlPath := GetFdl1Path;
  if FdlPath <> '' then
  begin
    FdlSize := FileSizeByPath(FdlPath);
    if FdlSize >= 0 then
      Inc(Result, FdlSize);
  end;
  FdlPath := GetFdl2Path;
  if FdlPath <> '' then
  begin
    FdlSize := FileSizeByPath(FdlPath);
    if FdlSize >= 0 then
      Inc(Result, FdlSize);
  end;
end;

function CleanFileName(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    if CharInSet(S[I], ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then
      Result := Result + '_'
    else
      Result := Result + S[I];
  end;
  Result := Trim(Result);
end;

function Check7zMagic(const AFilePath: string): Boolean;
var
  F: TFileStream;
  Magic: array[0..5] of Byte;
begin
  Result := False;
  if not FileExists(AFilePath) then
    Exit;
  try
    F := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      if F.Size >= 6 then
      begin
        F.ReadBuffer(Magic, 6);
        { 7z magic signature: 37 7A BC AF 27 1C }
        Result := (Magic[0] = $37) and (Magic[1] = $7A) and
                  (Magic[2] = $BC) and (Magic[3] = $AF) and
                  (Magic[4] = $27) and (Magic[5] = $1C);
      end;
    finally
      F.Free;
    end;
  except
    Result := False;
  end;
end;

function CheckZipMagic(const AFilePath: string): Boolean;
var
  F: TFileStream;
  Magic: array[0..3] of Byte;
begin
  Result := False;
  if not FileExists(AFilePath) then
    Exit;
  try
    F := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      if F.Size >= SizeOf(Magic) then
      begin
        F.ReadBuffer(Magic, SizeOf(Magic));
        Result := (Magic[0] = $50) and (Magic[1] = $4B) and
          (((Magic[2] = $03) and (Magic[3] = $04)) or
           ((Magic[2] = $05) and (Magic[3] = $06)) or
           ((Magic[2] = $07) and (Magic[3] = $08)));
      end;
    finally
      F.Free;
    end;
  except
    Result := False;
  end;
end;

function ExtractZipArchive(const AZipPath, ATargetDir: string;
  out ADaBinPath, AAuthBinPath: string; out AError: string): Boolean;
{$IFDEF FPC}
var
  UnZipper: TUnZipper;
  I: Integer;
  EntryName: string;
{$ELSE}
var
  Zip: TZipFile;
  I: Integer;
  EntryName: string;
{$ENDIF}
begin
  Result := False;
  ADaBinPath := '';
  AAuthBinPath := '';
  AError := '';
  ForceDirectories(ATargetDir);

{$IFDEF FPC}
  UnZipper := TUnZipper.Create;
  try
    try
      UnZipper.FileName := AZipPath;
      UnZipper.OutputPath := ATargetDir;
      UnZipper.Examine;
      UnZipper.UnZipAllFiles;

      for I := 0 to UnZipper.Entries.Count - 1 do
      begin
        EntryName := ExtractFileName(UnZipper.Entries[I].ArchiveFileName);
        if SameText(EntryName, 'da.bin') or SameText(ExtractFileExt(EntryName), '.bin') and
           (Pos('da', LowerCase(EntryName)) > 0) then
        begin
          if ADaBinPath = '' then
            ADaBinPath := IncludeTrailingPathDelimiter(ATargetDir) + UnZipper.Entries[I].ArchiveFileName;
        end;
        if SameText(EntryName, 'auth.bin') or (Pos('auth', LowerCase(EntryName)) > 0) then
        begin
          if AAuthBinPath = '' then
            AAuthBinPath := IncludeTrailingPathDelimiter(ATargetDir) + UnZipper.Entries[I].ArchiveFileName;
        end;
      end;
      Result := True;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    UnZipper.Free;
  end;
{$ELSE}
  Zip := TZipFile.Create;
  try
    try
      Zip.Open(AZipPath, zmRead);
      Zip.ExtractAll(ATargetDir);
      for I := 0 to Zip.FileCount - 1 do
      begin
        EntryName := ExtractFileName(Zip.FileNames[I]);
        if SameText(EntryName, 'da.bin') or (Pos('da', LowerCase(EntryName)) > 0) then
        begin
          if ADaBinPath = '' then
            ADaBinPath := IncludeTrailingPathDelimiter(ATargetDir) + Zip.FileNames[I];
        end;
        if SameText(EntryName, 'auth.bin') or (Pos('auth', LowerCase(EntryName)) > 0) then
        begin
          if AAuthBinPath = '' then
            AAuthBinPath := IncludeTrailingPathDelimiter(ATargetDir) + Zip.FileNames[I];
        end;
      end;
      Zip.Close;
      Result := True;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    Zip.Free;
  end;
{$ENDIF}
end;

function RunProcessHidden(const ACommandLine: string): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Cmd: string;
begin
  Result := False;
  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;

  Cmd := ACommandLine;
  UniqueString(Cmd);
  if CreateProcess(nil, PChar(Cmd), nil, nil, False, 0, nil, nil,
                   StartupInfo, ProcessInfo) then
  begin
    WaitForSingleObject(ProcessInfo.hProcess, 60000);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
    Result := True;
  end;
end;

function Extract7zViaCli(const AArchiveFile, ATargetDir: string): Boolean;
var
  ToolCmd: string;
  SysRoot: string;
begin
  Result := False;
  SysRoot := GetEnvironmentVariable('SystemRoot');
  if SysRoot = '' then
    SysRoot := 'C:\Windows';

  { Check for 7za.exe / 7z.exe in tools or system }
  if FileExists(ExeDir + 'tools\7za.exe') then
    ToolCmd := '"' + ExeDir + 'tools\7za.exe" x "' + AArchiveFile + '" -o"' + ATargetDir + '" -y -aoa'
  else if FileExists(ExeDir + '7za.exe') then
    ToolCmd := '"' + ExeDir + '7za.exe" x "' + AArchiveFile + '" -o"' + ATargetDir + '" -y -aoa'
  else if FileExists('C:\Program Files\7-Zip\7z.exe') then
    ToolCmd := '"C:\Program Files\7-Zip\7z.exe" x "' + AArchiveFile + '" -o"' + ATargetDir + '" -y -aoa'
  else if FileExists(SysRoot + '\System32\tar.exe') then
    ToolCmd := '"' + SysRoot + '\System32\tar.exe" -xf "' + AArchiveFile + '" -C "' + ATargetDir + '"'
  else
    Exit;

  Result := RunProcessHidden(ToolCmd);
end;

function ScanExtractedFolder(const ATargetDir: string;
  out ADaBinPath, AAuthBinPath: string): Boolean;
var
  SR: TSearchRec;
begin
  ADaBinPath := '';
  AAuthBinPath := '';
  if FindFirst(IncludeTrailingPathDelimiter(ATargetDir) + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
      begin
        if SameText(SR.Name, 'da.bin') then
          ADaBinPath := IncludeTrailingPathDelimiter(ATargetDir) + SR.Name
        else if SameText(SR.Name, 'auth.bin') then
          AAuthBinPath := IncludeTrailingPathDelimiter(ATargetDir) + SR.Name
        else if (ADaBinPath = '') and (Pos('da', LowerCase(SR.Name)) > 0) and
                SameText(ExtractFileExt(SR.Name), '.bin') then
          ADaBinPath := IncludeTrailingPathDelimiter(ATargetDir) + SR.Name
        else if (AAuthBinPath = '') and (Pos('auth', LowerCase(SR.Name)) > 0) and
                SameText(ExtractFileExt(SR.Name), '.bin') then
          AAuthBinPath := IncludeTrailingPathDelimiter(ATargetDir) + SR.Name;
      end;
    until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
  Result := (ADaBinPath <> '');
end;

function ExtractDaArchive(const ADaPath, ATargetDir: string;
  out ADaBinPath, AAuthBinPath: string; out AError: string): Boolean;
begin
  Result := False;
  AError := '';
  ADaBinPath := '';
  AAuthBinPath := '';
  ForceDirectories(ATargetDir);

  if Check7zMagic(ADaPath) then
  begin
    { Extracted via 7-Zip CLI or Windows tar.exe }
    if Extract7zViaCli(ADaPath, ATargetDir) and ScanExtractedFolder(ATargetDir, ADaBinPath, AAuthBinPath) then
    begin
      Result := True;
      Exit;
    end;
  end;

  { Try standard zip extraction }
  if ExtractZipArchive(ADaPath, ATargetDir, ADaBinPath, AAuthBinPath, AError) then
  begin
    if ADaBinPath = '' then
      ScanExtractedFolder(ATargetDir, ADaBinPath, AAuthBinPath);
    Result := (ADaBinPath <> '');
    if Result then
      Exit;
  end;

  { Final check in target folder }
  Result := ScanExtractedFolder(ATargetDir, ADaBinPath, AAuthBinPath);
  if not Result and (AError = '') then
    AError := 'da.bin was not found inside ' + ExtractFileName(ADaPath);
end;

function SafeRelativePath(const APath: string): Boolean;
begin
  Result := False;
  if APath = '' then
    Exit;
  Result := (ExtractFileDrive(APath) = '') and
    (APath[1] <> '\') and (APath[1] <> '/') and
    (Pos(':', APath) = 0) and (Pos('..', APath) = 0);
end;

function MappedPayloadPath(const ADirectory, ARelativePath: string): string;
var
  RelativePath: string;
  I: Integer;
begin
  Result := '';
  if not SafeRelativePath(ARelativePath) then
    Exit;
  RelativePath := ARelativePath;
  for I := 1 to Length(RelativePath) do
    if RelativePath[I] = '/' then
      RelativePath[I] := PathDelim;
  Result := IncludeTrailingPathDelimiter(ADirectory) + RelativePath;
  if not FileExists(Result) then
    Result := '';
end;

function FindPayloadByStem(const ADirectory, AStem: string): string;
const
  CExtensions: array[0..2] of string = ('.da', '.bin', '.crp');
var
  I: Integer;
begin
  Result := '';
  if AStem = '' then
    Exit;
  for I := Low(CExtensions) to High(CExtensions) do
  begin
    Result := FindFileInsensitive(ADirectory, AStem + CExtensions[I]);
    if Result <> '' then
      Exit;
  end;
end;

function FindDaFile(const ABrand, AModelCode, AModelName: string): string;
var
  DaDir, BrandDir, Candidate, MapFile: string;
  Ini: TIniFile;
  Mapped: string;
  SR: TSearchRec;
  CleanBrand, CleanCode, CleanModel: string;
begin
  Result := '';
  DaDir := GetDaFolder;
  if not DirectoryExists(DaDir) then
    Exit;

  CleanBrand := CleanFileName(ABrand);
  CleanCode := CleanFileName(AModelCode);
  CleanModel := CleanFileName(AModelName);
  BrandDir := IncludeTrailingPathDelimiter(DaDir + CleanBrand);

  { The checked-in brand map points to the actual supplied payload files. }
  MapFile := FindFileInsensitive(DaDir, 'models_map.ini');
  if MapFile <> '' then
  begin
    Ini := TIniFile.Create(MapFile);
    try
      Mapped := Ini.ReadString('Models', CleanCode, '');
      if Mapped = '' then
        Mapped := Ini.ReadString('Models', CleanModel, '');
      if Mapped = '' then
        Mapped := Ini.ReadString(CleanBrand, CleanCode, '');
      if Mapped = '' then
        Mapped := Ini.ReadString(CleanBrand, CleanModel, '');
      if Mapped = '' then
        Mapped := Ini.ReadString('Brands', CleanBrand, '');
      if Mapped = '' then
        Mapped := Ini.ReadString(CleanBrand, 'default', '');

      Candidate := MappedPayloadPath(DaDir, Mapped);
      if Candidate = '' then
        Candidate := MappedPayloadPath(BrandDir, Mapped);
      if Candidate <> '' then
      begin
        Result := Candidate;
        Exit;
      end;
    finally
      Ini.Free;
    end;
  end;

  { Exact model payloads take precedence over a brand-level package. }
  Candidate := FindPayloadByStem(BrandDir, CleanCode);
  if Candidate = '' then
    Candidate := FindPayloadByStem(BrandDir, CleanModel);
  if Candidate = '' then
    Candidate := FindPayloadByStem(DaDir, CleanCode);
  if Candidate = '' then
    Candidate := FindPayloadByStem(DaDir, CleanModel);
  if Candidate <> '' then
  begin
    Result := Candidate;
    Exit;
  end;

  { Also accept flat <Brand>_<Model>.da files and multi-model filenames. }
  if CleanCode <> '' then
  begin
    Candidate := FindFileInsensitive(DaDir, CleanBrand + '_' + CleanCode + '.da');
    if Candidate <> '' then
    begin
      Result := Candidate;
      Exit;
    end;
    if FindFirst(DaDir + '*' + CleanCode + '*.da', faAnyFile, SR) = 0 then
    begin
      if (SR.Attr and faDirectory) = 0 then
        Result := DaDir + SR.Name;
      SysUtils.FindClose(SR);
      if Result <> '' then
        Exit;
    end;
  end;

  { Finally accept a literal brand-named payload. No unrelated generic DA is
    selected when a brand/model has no matching file. }
  Candidate := FindPayloadByStem(DaDir, CleanBrand);
  if Candidate <> '' then
  begin
    Result := Candidate;
    Exit;
  end;
  if DirectoryExists(BrandDir) then
  begin
    Candidate := FindPayloadByStem(BrandDir, 'default');
    if Candidate <> '' then
      Result := Candidate;
  end;
end;

function ResolveAndExtractDa(const ABrand, AModelCode, AModelName: string): TDaLoadResult;
var
  DaFile, TargetDir: string;
  DaBin, AuthBin, Err: string;
  SafeName: string;
begin
  Result.Found := False;
  Result.DaFile := '';
  Result.AgentFile := '';
  Result.ExtractedDaBin := '';
  Result.ExtractedAuthBin := '';
  Result.HasAuth := False;
  Result.IsOpaque := False;
  Result.FileSizeBytes := 0;
  Result.Message := '';

  DaFile := FindDaFile(ABrand, AModelCode, AModelName);
  if DaFile = '' then
  begin
    Result.Message := 'No bundled agent payload found for ' + ABrand + ' ' + AModelCode;
    Exit;
  end;

  Result.DaFile := DaFile;
  if Check7zMagic(DaFile) or CheckZipMagic(DaFile) then
  begin
    { Archive support is retained for explicit ZIP/.da containers. Extracted
      files are written to the writable app-data area, not the installed bundle. }
    SafeName := CleanFileName(ChangeFileExt(ExtractFileName(DaFile), ''));
    TargetDir := DataDir + 'extracted' + PathDelim + SafeName + PathDelim;
    if ExtractDaArchive(DaFile, TargetDir, DaBin, AuthBin, Err) then
    begin
      Result.Found := True;
      Result.AgentFile := DaBin;
      Result.ExtractedDaBin := DaBin;
      Result.ExtractedAuthBin := AuthBin;
      Result.HasAuth := (AuthBin <> '') and FileExists(AuthBin);
      Result.FileSizeBytes := FileSizeByPath(DaBin);
      if Result.HasAuth then
        Result.Message := 'Archive contains da.bin and auth.bin; exact device compatibility is not verified.'
      else
        Result.Message := 'Archive contains da.bin; no auth.bin was supplied.';
    end
    else
      Result.Message := 'Could not extract ' + ExtractFileName(DaFile) + ': ' + Err;
    Exit;
  end;

  { Supplied vendor .da/.bin/.crp resources are opaque binary payloads, not
    ZIP/7z archives. Keep the original file intact; do not fabricate da.bin. }
  Result.Found := True;
  Result.AgentFile := DaFile;
  Result.IsOpaque := True;
  Result.FileSizeBytes := FileSizeByPath(DaFile);
  Result.Message := 'Vendor payload found for brand ' + ABrand +
    '; exact model compatibility and authenticity are not verified.';
end;

end.
