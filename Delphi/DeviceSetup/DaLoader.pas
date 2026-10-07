unit DaLoader;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ DaLoader
  Handles discovering and loading Download Agent (.da) containers, FDL files,
  and standalone DA files from the data directory:
    data/
      fdl1.bin
      fdl2.bin
      da/
        <Brand>/<Model>.da
        <Model>.da
        multi_model.da
        models_map.ini (optional mapping of model codes / aliases to DA files)

  Each .da file is an archive container (7z created with ZArchiver / 7-Zip,
  or standard ZIP format) containing:
    - da.bin   (mandatory MTK download agent binary)
    - auth.bin (optional brand/model authorization key binary)
  If auth.bin is absent, it safely falls back to using only da.bin.
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
    DaFile: string;         { Path to the .da container file }
    ExtractedDaBin: string; { Path to extracted da.bin }
    ExtractedAuthBin: string; { Path to extracted auth.bin (empty if not present) }
    HasAuth: Boolean;
    Message: string;
  end;

function GetDataFolder: string;
function GetDaFolder: string;
function GetFdl1Path: string;
function GetFdl2Path: string;

{ Attempts to find and parse the DA container for the given Brand and Model.
  Supports multi-model matching, brand subfolders, flat da folders,
  and models_map.ini if present. }
function ResolveAndExtractDa(const ABrand, AModelCode, AModelName: string): TDaLoadResult;

{ Direct archive extraction of .da (7z or ZIP) to output directory }
function ExtractDaArchive(const ADaPath, ATargetDir: string;
  out ADaBinPath, AAuthBinPath: string; out AError: string): Boolean;

implementation

uses
  AppInfo;

function GetDataFolder: string;
var
  Candidate: string;
begin
  { Check directory next to exe or working directory }
  Candidate := ExeDir + 'data' + PathDelim;
  if DirectoryExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Candidate := DataDir + 'data' + PathDelim;
  if DirectoryExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  { Default fallback to ExeDir\data }
  Result := ExeDir + 'data' + PathDelim;
end;

function GetDaFolder: string;
begin
  Result := GetDataFolder + 'da' + PathDelim;
end;

function GetFdl1Path: string;
var
  P: string;
begin
  P := GetDataFolder + 'fdl1.bin';
  if FileExists(P) then
    Result := P
  else
    Result := '';
end;

function GetFdl2Path: string;
var
  P: string;
begin
  P := GetDataFolder + 'fdl2.bin';
  if FileExists(P) then
    Result := P
  else
    Result := '';
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

function FindDaFile(const ABrand, AModelCode, AModelName: string): string;
var
  DaDir: string;
  Candidate: string;
  MapFile: string;
  Ini: TIniFile;
  Mapped: string;
  SR: TSearchRec;
  CleanCode, CleanModel: string;
begin
  Result := '';
  DaDir := GetDaFolder;
  if not DirectoryExists(DaDir) then
    Exit;

  CleanCode := CleanFileName(AModelCode);
  CleanModel := CleanFileName(AModelName);

  { 1. Check models_map.ini if present for alias / multi-model mapping }
  MapFile := DaDir + 'models_map.ini';
  if FileExists(MapFile) then
  begin
    Ini := TIniFile.Create(MapFile);
    try
      Mapped := Ini.ReadString('Models', CleanCode, '');
      if Mapped = '' then
        Mapped := Ini.ReadString('Models', CleanModel, '');
      if Mapped = '' then
        Mapped := Ini.ReadString(ABrand, CleanCode, '');
      if Mapped = '' then
        Mapped := Ini.ReadString(ABrand, CleanModel, '');

      if Mapped <> '' then
      begin
        if FileExists(DaDir + Mapped) then
        begin
          Result := DaDir + Mapped;
          Exit;
        end
        else if FileExists(DaDir + IncludeTrailingPathDelimiter(ABrand) + Mapped) then
        begin
          Result := DaDir + IncludeTrailingPathDelimiter(ABrand) + Mapped;
          Exit;
        end;
      end;
    finally
      Ini.Free;
    end;
  end;

  { 2. Brand subfolder: data/da/<Brand>/<ModelCode>.da or <ModelName>.da }
  if (CleanCode <> '') and FileExists(DaDir + IncludeTrailingPathDelimiter(ABrand) + CleanCode + '.da') then
  begin
    Result := DaDir + IncludeTrailingPathDelimiter(ABrand) + CleanCode + '.da';
    Exit;
  end;
  if (CleanModel <> '') and FileExists(DaDir + IncludeTrailingPathDelimiter(ABrand) + CleanModel + '.da') then
  begin
    Result := DaDir + IncludeTrailingPathDelimiter(ABrand) + CleanModel + '.da';
    Exit;
  end;

  { 3. Flat folder: data/da/<Brand>_<ModelCode>.da or <ModelCode>.da }
  if (CleanCode <> '') and FileExists(DaDir + CleanCode + '.da') then
  begin
    Result := DaDir + CleanCode + '.da';
    Exit;
  end;
  if (CleanModel <> '') and FileExists(DaDir + CleanModel + '.da') then
  begin
    Result := DaDir + CleanModel + '.da';
    Exit;
  end;
  if (CleanCode <> '') and FileExists(DaDir + ABrand + '_' + CleanCode + '.da') then
  begin
    Result := DaDir + ABrand + '_' + CleanCode + '.da';
    Exit;
  end;

  { 4. Multi-model search: Look for DA file where model code or name is part of the filename }
  if CleanCode <> '' then
  begin
    if FindFirst(DaDir + '*' + CleanCode + '*.da', faAnyFile, SR) = 0 then
    begin
      Result := DaDir + SR.Name;
      SysUtils.FindClose(SR);
      Exit;
    end;
    if FindFirst(DaDir + IncludeTrailingPathDelimiter(ABrand) + '*' + CleanCode + '*.da', faAnyFile, SR) = 0 then
    begin
      Result := DaDir + IncludeTrailingPathDelimiter(ABrand) + SR.Name;
      SysUtils.FindClose(SR);
      Exit;
    end;
  end;

  { 5. Fallback: Brand-level generic DA e.g. Oppo_Multi.da, MTK_AllInOne.da, default.da }
  Candidate := DaDir + IncludeTrailingPathDelimiter(ABrand) + 'default.da';
  if FileExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;
  Candidate := DaDir + ABrand + '.da';
  if FileExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;
  Candidate := DaDir + 'default.da';
  if FileExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;
end;

function ResolveAndExtractDa(const ABrand, AModelCode, AModelName: string): TDaLoadResult;
var
  DaFile: string;
  TargetDir: string;
  DaBin, AuthBin, Err: string;
  SafeName: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Found := False;

  DaFile := FindDaFile(ABrand, AModelCode, AModelName);
  if DaFile = '' then
  begin
    Result.Message := 'No specific .da file found for ' + ABrand + ' ' + AModelCode;
    Exit;
  end;

  Result.DaFile := DaFile;
  SafeName := ChangeFileExt(ExtractFileName(DaFile), '');
  TargetDir := GetDataFolder + 'extracted' + PathDelim + SafeName;

  if ExtractDaArchive(DaFile, TargetDir, DaBin, AuthBin, Err) then
  begin
    Result.Found := True;
    Result.ExtractedDaBin := DaBin;
    Result.ExtractedAuthBin := AuthBin;
    Result.HasAuth := (AuthBin <> '') and FileExists(AuthBin);
    if Result.HasAuth then
      Result.Message := 'Loaded DA and Auth from ' + ExtractFileName(DaFile)
    else
      Result.Message := 'Loaded DA from ' + ExtractFileName(DaFile) + ' (Auth not present, safe fallback)';
  end
  else
  begin
    Result.Message := 'Failed to unpack ' + ExtractFileName(DaFile) + ': ' + Err;
  end;
end;

end.
