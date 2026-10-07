unit DeviceCatalog;

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
  TModelNames = array[0..5] of string;
  TBrandInfo = record
    Name: string;
    Models: TModelNames;
  end;

const
  { Starter data only. Replace or load this catalog from the backend in a later stage. }
  CBrands: array[0..4] of TBrandInfo = (
    (Name: 'Nokia'; Models: ('C32', 'G22', 'G42 5G', 'X30 5G', 'XR21', '')),
    (Name: 'Samsung'; Models: ('Galaxy A15', 'Galaxy A35 5G', 'Galaxy A55 5G',
      'Galaxy S24', 'Galaxy S24 Ultra', 'Galaxy Z Flip6')),
    (Name: 'Google Pixel'; Models: ('Pixel 8a', 'Pixel 8', 'Pixel 8 Pro',
      'Pixel 9', 'Pixel 9 Pro', 'Pixel 9 Pro XL')),
    (Name: 'Lenovo'; Models: ('K13 Note', 'K14 Plus', 'Legion Phone Duel 2',
      'Tab M11', 'Tab P12', '')),
    (Name: 'Motorola'; Models: ('Moto G Power (2024)', 'Moto G Stylus 5G (2024)',
      'Edge 50 Fusion', 'Edge 50 Pro', 'Razr 50', ''))
  );

class function TDeviceCatalog.BrandCount: Integer;
begin
  Result := Length(CBrands);
end;

class function TDeviceCatalog.BrandName(const ABrandIndex: Integer): string;
begin
  Result := '';
  if (ABrandIndex >= Low(CBrands)) and (ABrandIndex <= High(CBrands)) then
    Result := CBrands[ABrandIndex].Name;
end;

class function TDeviceCatalog.ModelCount(const ABrandIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  if (ABrandIndex < Low(CBrands)) or (ABrandIndex > High(CBrands)) then
    Exit;

  for I := Low(CBrands[ABrandIndex].Models) to High(CBrands[ABrandIndex].Models) do
  begin
    if CBrands[ABrandIndex].Models[I] = '' then
      Break;
    Inc(Result);
  end;
end;

class function TDeviceCatalog.ModelName(const ABrandIndex,
  AModelIndex: Integer): string;
begin
  Result := '';
  if (ABrandIndex < Low(CBrands)) or (ABrandIndex > High(CBrands)) then
    Exit;
  if (AModelIndex < Low(CBrands[ABrandIndex].Models)) or
     (AModelIndex > High(CBrands[ABrandIndex].Models)) then
    Exit;
  Result := CBrands[ABrandIndex].Models[AModelIndex];
end;

end.
