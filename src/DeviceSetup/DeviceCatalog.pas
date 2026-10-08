unit DeviceCatalog;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Brand/model catalog used by MAIN 1.
  Each model entry is shown as "<model code> : <marketing name>".

  The catalog comes from one of two places:
    - models.csv next to the EXE (if present), one model per line:
          Brand,Model code,Name
      e.g.  Realme,RMX3511,Realme C35
      Lines starting with # are comments. ";" or a tab also work as the
      separator. The name may contain commas.
    - otherwise the built-in starter list below.
  MAIN 1 can export the current list to models.csv as a starting point. }

interface

type
  TDeviceCatalog = class
  public
    class function BrandCount: Integer; static;
    class function BrandName(const ABrandIndex: Integer): string; static;
    class function ModelCount(const ABrandIndex: Integer): Integer; static;
    class function ModelName(const ABrandIndex, AModelIndex: Integer): string; static;
    class function FindBrand(const AName: string): Integer; static;
    class function TotalModels: Integer; static;

    { '' when the built-in list is used, otherwise the file name. }
    class function Source: string; static;
    class procedure ResetToBuiltIn; static;
    { Replaces the catalog with the file contents. On failure (no valid
      lines, unreadable file) the catalog is left unchanged. ASkipped is the
      number of lines that could not be read. }
    class function LoadFromFile(const AFileName: string; out ASkipped: Integer;
      out AError: string): Boolean; static;
    class procedure ExportToFile(const AFileName: string); static;
  end;

implementation

uses
{$IFDEF FPC}
  Classes, SysUtils;
{$ELSE}
  System.Classes,
  System.SysUtils;
{$ENDIF}

type
  TModelList = array of string;
  TBrandEntry = record
    Name: string;
    Models: TModelList;
  end;
  TBrandList = array of TBrandEntry;

var
  GBrands: TBrandList;
  GSource: string;

procedure AddBrand(const AName: string; const AModels: array of string);
var
  Entry: TBrandEntry;
  I: Integer;
begin
  Entry.Name := AName;
  SetLength(Entry.Models, Length(AModels));
  for I := 0 to High(AModels) do
    Entry.Models[I] := AModels[I];
  SetLength(GBrands, Length(GBrands) + 1);
  GBrands[High(GBrands)] := Entry;
end;

procedure BuildBuiltIn;
begin
  { Brands are kept in case-insensitive alphabetical order (iGET, myPhone...). }
  AddBrand('Alcatel', [
    '5033D : Alcatel 1',
    '5024D : Alcatel 1S',
    '5029Y : Alcatel 3L',
    '6025H : Alcatel 1S 2021']);
  AddBrand('Alps', []);
  AddBrand('Amazon', []);
  AddBrand('ASUS', [
    'ASUS_X00TD : Zenfone Max Pro M1',
    'ASUS_X01BD : Zenfone Max Pro M2',
    'ASUS_I006D : Zenfone 8']);
  AddBrand('ATT', []);
  AddBrand('Black Fox', []);
  AddBrand('Blackview', []);
  AddBrand('BLU', []);
  AddBrand('Bluboo', []);
  AddBrand('Bmobile', []);
  AddBrand('Boost', []);
  AddBrand('BQ', [
    'BQ-5518G : Jeans',
    'BQ-5533G : Fresh',
    'BQ-6040L : Magic']);
  AddBrand('Coolpad', [
    'CP3705A : Legacy Go',
    'CP3322A : Legacy SR',
    '1851 : Cool 5']);
  AddBrand('CORN', []);
  AddBrand('Cricket', [
    'EC211001 : Cricket Icon 3',
    'U705AC : Cricket Ovation',
    'EC1002 : Cricket Innovate E']);
  AddBrand('Dexp', [
    'G155 : Dexp G155',
    'AL350 : Dexp AL350',
    'B355 : Dexp B355']);
  AddBrand('Digit', [
    'DIGIT 4G ELITE : Digit 4G Elite',
    'DIGIT E2 PRO : Digit E2 Pro']);
  AddBrand('Doogee', [
    'S88 Pro : Doogee S88 Pro',
    'S96 Pro : Doogee S96 Pro',
    'X96 Pro : Doogee X96 Pro',
    'N40 Pro : Doogee N40 Pro']);
  AddBrand('Highscreen', [
    'Power Five Max 2 : Highscreen Power Five Max 2',
    'Fest XL Pro : Highscreen Fest XL Pro']);
  AddBrand('Hisense', [
    'HLTE230E : Hisense Infinity H30',
    'HLTE226E : Hisense Infinity H50',
    'HLTE202N : Hisense E30 Lite']);
  AddBrand('HTC', [
    '2Q7A100 : HTC Desire 21 Pro 5G',
    '2Q9J100 : HTC Desire 20 Pro',
    '2Q4D100 : HTC U12+']);
  AddBrand('Huawei', [
    'MAR-LX1A : Huawei P30 Lite',
    'STK-LX1 : Huawei Y9 Prime 2019',
    'JNY-LX1 : Huawei P40 Lite',
    'DUB-LX1 : Huawei Y7 2019']);
  AddBrand('iGET', [
    'BLACKVIEW GBV9900 : iGET Blackview GBV9900',
    'BLACKVIEW GBV6300 : iGET Blackview GBV6300']);
  AddBrand('Infinix', [
    'X657B : Infinix Smart 5',
    'X6816 : Infinix Hot 12 Play',
    'X669 : Infinix Hot 30i',
    'X6831 : Infinix Hot 30',
    'X6833B : Infinix Note 30']);
  AddBrand('INOI', []);
  AddBrand('Itel', [
    'A507LS : Itel A23 Pro',
    'A665L : Itel A70',
    'S665L : Itel S23',
    'P661N : Itel P40']);
  AddBrand('Lava', [
    'LZG403 : Lava Blaze',
    'LXX504 : Lava Agni 5G',
    'LZX408 : Lava Yuva 2']);
  AddBrand('Lenovo', [
    'TB-X606F : Tab M10 Plus',
    'TB-J606F : Tab P11',
    'XT2093-4 : Lenovo K13 Note']);
  AddBrand('Lg', [
    'LM-K420 : LG K42',
    'LM-K520 : LG K52',
    'LM-Q630 : LG K61',
    'LM-G900 : LG Velvet']);
  AddBrand('Mediatek', [
    'MT6765 : Helio P35 Generic',
    'MT6768 : Helio G85 Generic',
    'MT6833 : Dimensity 700 Generic']);
  AddBrand('Meizu', [
    'M2010 : Meizu 18',
    'M1852 : Meizu X8',
    'M1822 : Meizu Note 8']);
  AddBrand('Micromax', [
    'E7533 : Micromax IN Note 1',
    'E6533 : Micromax IN 1b',
    'E7544 : Micromax IN 2b']);
  AddBrand('Mint', [
    'MINT M5 : Mint M5',
    'MINT M7 : Mint M7']);
  AddBrand('Motorola', [
    'XT2155-3 : Moto G Pure',
    'XT2235-2 : Moto G Power 2022',
    'XT2343-1 : Moto G84 5G',
    'XT2363-4 : Moto G24']);
  AddBrand('myPhone', [
    'myPhone Pocket 18x9 : myPhone Pocket',
    'myPhone Hammer Energy 2 : Hammer Energy 2']);
  AddBrand('Nokia', [
    'TA-1418 : Nokia G21',
    'TA-1503 : Nokia C21 Plus',
    'TA-1577 : Nokia G22',
    'TA-1534 : Nokia C32']);
  AddBrand('OnePlus', [
    'IN2013 : OnePlus 8',
    'AC2003 : OnePlus Nord',
    'CPH2581 : OnePlus 12']);
  { Visible entries from S1, followed by the existing starter models. }
  AddBrand('Oppo', [
    'A37m',
    'A59',
    'A59m : OPPO A59',
    'A59s',
    'A59st : OPPO A59s',
    'A59t : OPPO A59',
    'A8 Mini',
    'CPH1605 : OPPO A39',
    'CPH1609 : OPPO F3',
    'CPH1717 : OPPO A71',
    'CPH1723 : OPPO F5',
    'CPH1725 : OPPO F5 Youth / A73',
    'CPH1727 : OPPO F5',
    'CPH1729 : OPPO A83',
    'CPH1819 : OPPO F7',
    'CPH1821 : OPPO F7',
    'CPH1823 : OPPO F9',
    'CPH1825 : OPPO F9',
    'CPH1827 : OPPO A83',
    'CPH1835 : OPPO R15',
    'CPH1837 : OPPO A3',
    'CPH1859 : OPPO F7 Youth',
    'CPH1881 : OPPO F9',
    'CPH1909 : OPPO A5s',
    'CPH1911 : OPPO F11',
    'CPH2269 : Oppo A16',
    'CPH2387 : Oppo A57',
    'CPH2477 : Oppo A17',
    'CPH2565 : Oppo A78']);
  AddBrand('Realme', [
    'RMX2020 : Realme C3',
    'RMX2180 : Realme C15',
    'RMX2185 : Realme C11',
    'RMX2189 : Realme C12',
    'RMX3085 : Realme 8',
    'RMX3231 : Realme C11 2021',
    'RMX3241 : Realme 8 5G',
    'RMX3261 : Realme C21Y',
    'RMX3363 : Realme GT Master Edition',
    'RMX3382 : Realme 8s 5G',
    'RMX3388 : Realme 9 5G',
    'RMX3392 : Realme 9 Pro Plus',
    'RMX3393 : Realme 9 Pro Plus',
    'RMX3394 : Realme 9 Pro Plus',
    'RMX3395 : Realme Narzo 50 Pro',
    'RMX3396 : Realme Narzo 50 Pro',
    'RMX3397 : Realme 9 Pro Plus',
    'RMX3430 : Realme Narzo 50A',
    'RMX3501 : Realme C31',
    'RMX3503 : Realme C31',
    'RMX3506 : Realme Narzo 50i Prime',
    'RMX3511 : Realme C35',
    'RMX3513 : Realme C35',
    'RMX3516 : Realme Narzo 50A Prime',
    'RMX3516PU : Realme Narzo 50A Prime',
    'RMX3571 : Realme Narzo 50 5G',
    'RMX3572 : Realme Narzo 50 5G',
    'RMX3574 : Realme Q5i',
    'RMX3581 : Realme C30',
    'RMX3624 : Realme C33',
    'RMX3624BA : Realme C33',
    'RMX3627 : Realme C33',
    'RMX3710 : Realme C55',
    'RMX3760 : Realme C53',
    'RMX3830 : Realme C51']);
  AddBrand('Samsung', [
    'SM-A155F : Galaxy A15',
    'SM-A356B : Galaxy A35 5G',
    'SM-A556B : Galaxy A55 5G',
    'SM-S921B : Galaxy S24',
    'SM-S928B : Galaxy S24 Ultra',
    'SM-F741B : Galaxy Z Flip6']);
  AddBrand('Tecno', [
    'KG5 : Tecno Spark 8C',
    'KI5q : Tecno Spark 10',
    'CK6n : Tecno Camon 20',
    'CK7n : Tecno Camon 20 Pro']);
  AddBrand('Vivo', [
    'V2111 : Vivo Y21',
    'V2120 : Vivo Y33s',
    'V2204 : Vivo Y16']);
  AddBrand('Xiaomi', [
    '2201117TG : Redmi Note 11',
    '23021RAAEG : Redmi Note 12',
    '23053RN02Y : Redmi 12']);
  AddBrand('ZTE', [
    'ZTE 8030 : Blade A51',
    'ZTE 7060 : Blade A71',
    'ZTE A2022 : Axon 30 5G']);
end;

class function TDeviceCatalog.BrandCount: Integer;
begin
  Result := Length(GBrands);
end;

class function TDeviceCatalog.BrandName(const ABrandIndex: Integer): string;
begin
  Result := '';
  if (ABrandIndex >= 0) and (ABrandIndex < Length(GBrands)) then
    Result := GBrands[ABrandIndex].Name;
end;

class function TDeviceCatalog.ModelCount(const ABrandIndex: Integer): Integer;
begin
  Result := 0;
  if (ABrandIndex >= 0) and (ABrandIndex < Length(GBrands)) then
    Result := Length(GBrands[ABrandIndex].Models);
end;

class function TDeviceCatalog.ModelName(const ABrandIndex,
  AModelIndex: Integer): string;
begin
  Result := '';
  if (ABrandIndex < 0) or (ABrandIndex >= Length(GBrands)) then
    Exit;
  if (AModelIndex < 0) or (AModelIndex >= Length(GBrands[ABrandIndex].Models)) then
    Exit;
  Result := GBrands[ABrandIndex].Models[AModelIndex];
end;

class function TDeviceCatalog.FindBrand(const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(GBrands) do
    if SameText(GBrands[I].Name, AName) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

class function TDeviceCatalog.TotalModels: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(GBrands) do
    Inc(Result, Length(GBrands[I].Models));
end;

class function TDeviceCatalog.Source: string;
begin
  Result := GSource;
end;

class procedure TDeviceCatalog.ResetToBuiltIn;
begin
  SetLength(GBrands, 0);
  BuildBuiltIn;
  GSource := '';
end;

{ ---------------------------------------------------------------- file }

function Unquote(const S: string): string;
begin
  Result := Trim(S);
  if (Length(Result) >= 2) and (Result[1] = '"') and
     (Result[Length(Result)] = '"') then
    Result := Trim(Copy(Result, 2, Length(Result) - 2));
end;

function FindSeparator(const S: string): Char;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if CharInSet(S[I], [',', ';', #9]) then
    begin
      Result := S[I];
      Exit;
    end;
  Result := #0;
end;

{ Splits "Brand,Code,Name" (the name may contain the separator). }
function SplitLine(const S: string; out ABrand, ACode, AName: string): Boolean;
var
  Sep: Char;
  P: Integer;
  Rest: string;
begin
  Result := False;
  Sep := FindSeparator(S);
  if Sep = #0 then
    Exit;
  P := Pos(Sep, S);
  ABrand := Unquote(Copy(S, 1, P - 1));
  Rest := Copy(S, P + 1, MaxInt);
  P := Pos(Sep, Rest);
  if P = 0 then
    Exit;
  ACode := Unquote(Copy(Rest, 1, P - 1));
  AName := Unquote(Copy(Rest, P + 1, MaxInt));
  { Brand,, preserves an empty category from the reference brand list. }
  Result := ABrand <> '';
end;

function NewBrandIndex(var ABrands: TBrandList; const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(ABrands) do
    if SameText(ABrands[I].Name, AName) then
    begin
      Result := I;
      Exit;
    end;
  SetLength(ABrands, Length(ABrands) + 1);
  Result := High(ABrands);
  ABrands[Result].Name := AName;
  SetLength(ABrands[Result].Models, 0);
end;

procedure SortBrands(var ABrands: TBrandList);
var
  I, J: Integer;
  Tmp: TBrandEntry;
begin
  { insertion sort, case-insensitive (iGET, myPhone...) }
  for I := 1 to High(ABrands) do
  begin
    Tmp := ABrands[I];
    J := I - 1;
    while (J >= 0) and (CompareText(ABrands[J].Name, Tmp.Name) > 0) do
    begin
      ABrands[J + 1] := ABrands[J];
      Dec(J);
    end;
    ABrands[J + 1] := Tmp;
  end;
end;

procedure ReadLines(const AFileName: string; ALines: TStringList);
begin
  {$IFDEF FPC}
  ALines.LoadFromFile(AFileName);  { LCL strings are UTF-8 }
  { strip a UTF-8 byte order mark (compared byte by byte to avoid any
    code page conversion of the constant) }
  if (ALines.Count > 0) and (Length(ALines[0]) >= 3) and
     (Ord(ALines[0][1]) = $EF) and (Ord(ALines[0][2]) = $BB) and
     (Ord(ALines[0][3]) = $BF) then
    ALines[0] := Copy(ALines[0], 4, MaxInt);
  {$ELSE}
  try
    ALines.LoadFromFile(AFileName, TEncoding.UTF8);
  except
    on EEncodingError do
      ALines.LoadFromFile(AFileName);  { not UTF-8: read as ANSI }
  end;
  {$ENDIF}
end;

class function TDeviceCatalog.LoadFromFile(const AFileName: string;
  out ASkipped: Integer; out AError: string): Boolean;
var
  Lines: TStringList;
  NewList: TBrandList;
  I, B, Valid: Integer;
  Line, Brand, Code, Name, Entry: string;
begin
  Result := False;
  ASkipped := 0;
  AError := '';
  Valid := 0;
  SetLength(NewList, 0);
  Lines := TStringList.Create;
  try
    try
      ReadLines(AFileName, Lines);
    except
      on E: Exception do
      begin
        AError := E.Message;
        Exit;
      end;
    end;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if (Line = '') or (Line[1] = '#') then
        Continue;
      if not SplitLine(Line, Brand, Code, Name) then
      begin
        Inc(ASkipped);
        Continue;
      end;
      if SameText(Brand, 'Brand') then
        Continue;  { header line }
      B := NewBrandIndex(NewList, Brand);
      if (Code = '') and (Name = '') then
        Continue;  { a category only, not an invented device model }
      if Code = '' then
        Entry := Name
      else if Name = '' then
        Entry := Code
      else
        Entry := Code + ' : ' + Name;
      SetLength(NewList[B].Models, Length(NewList[B].Models) + 1);
      NewList[B].Models[High(NewList[B].Models)] := Entry;
      Inc(Valid);
    end;
  finally
    Lines.Free;
  end;

  if Valid = 0 then
  begin
    AError := 'No models found. Each line should look like: Brand,Model code,Name';
    Exit;
  end;
  SortBrands(NewList);
  GBrands := NewList;
  GSource := AFileName;
  Result := True;
end;

class procedure TDeviceCatalog.ExportToFile(const AFileName: string);
var
  Lines: TStringList;
  B, M, P: Integer;
  Entry, Code, Name: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('# Mobile Servicing Tools - model list');
    Lines.Add('# One model per line: Brand,Model code,Name');
    Lines.Add('# Put this file next to the EXE as models.csv, then restart the app');
    Lines.Add('# or use Menu > Reload models.');
    Lines.Add('Brand,Model code,Name');
    for B := 0 to High(GBrands) do
    begin
      if Length(GBrands[B].Models) = 0 then
        Lines.Add(GBrands[B].Name + ',,');
      for M := 0 to High(GBrands[B].Models) do
      begin
        Entry := GBrands[B].Models[M];
        P := Pos(' : ', Entry);
        if P > 0 then
        begin
          Code := Copy(Entry, 1, P - 1);
          Name := Copy(Entry, P + 3, MaxInt);
        end
        else
        begin
          Code := Entry;
          Name := '';
        end;
        Lines.Add(GBrands[B].Name + ',' + Code + ',' + Name);
      end;
    end;
    {$IFDEF FPC}
    Lines.SaveToFile(AFileName);
    {$ELSE}
    Lines.SaveToFile(AFileName, TEncoding.UTF8);
    {$ENDIF}
  finally
    Lines.Free;
  end;
end;

initialization
  BuildBuiltIn;

end.
