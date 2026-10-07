unit DeviceCatalog;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ In-memory brand/model catalog used by MAIN 1.
  Each model entry is shown exactly as "<model code> : <marketing name>".
  This is starter/demo data - replace it with a real data source later. }

interface

type
  TDeviceCatalog = class
  public
    class function BrandCount: Integer; static;
    class function BrandName(const ABrandIndex: Integer): string; static;
    class function ModelCount(const ABrandIndex: Integer): Integer; static;
    class function ModelName(const ABrandIndex, AModelIndex: Integer): string; static;
  end;

implementation

type
  TModelList = array of string;
  TBrandEntry = record
    Name: string;
    Models: TModelList;
  end;
  TBrandList = array of TBrandEntry;

var
  GBrands: TBrandList;

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

procedure BuildCatalog;
begin
  { Brands are kept in case-insensitive alphabetical order (iGET, myPhone...). }
  AddBrand('Alcatel', [
    '5033D : Alcatel 1',
    '5024D : Alcatel 1S',
    '5029Y : Alcatel 3L',
    '6025H : Alcatel 1S 2021']);
  AddBrand('Asus', [
    'ASUS_X00TD : Zenfone Max Pro M1',
    'ASUS_X01BD : Zenfone Max Pro M2',
    'ASUS_I006D : Zenfone 8']);
  AddBrand('BQ', [
    'BQ-5518G : Jeans',
    'BQ-5533G : Fresh',
    'BQ-6040L : Magic']);
  AddBrand('Coolpad', [
    'CP3705A : Legacy Go',
    'CP3322A : Legacy SR',
    '1851 : Cool 5']);
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
  AddBrand('Oppo', [
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

initialization
  BuildCatalog;

end.
