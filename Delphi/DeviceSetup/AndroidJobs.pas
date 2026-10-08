unit AndroidJobs;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ The jobs that run against a booted Android phone through adb and fastboot.

  These are the operations that need no vendor secret at all: reading what the
  phone reports about itself, rebooting it into another mode, and the fastboot
  commands Google defined for every Android device (flashing unlock / lock,
  --set-active, getvar).

  Every step is logged with the exact command that ran and the exact output
  that came back, so nothing here can look like a success it was not. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes, AdbTool;

type
  { The job engine passes its own log and progress routines in, so this unit
    needs no VCL and no form. }
  TAndroidLog = procedure(const AText: string) of object;
  TAndroidProgress = procedure(APercent: Integer; const AText: string)
    of object;

{ Runs one job that needs a booted phone. Returns the outcome; every step is
  logged through ALog. }
function RunAndroidOperation(AKind: TJobKind; AAdb: TAdbTool;
  const AParams: TJobParams; ALog: TAndroidLog;
  AProgress: TAndroidProgress): TJobOutcome;

{ Jobs that need no phone at all but still belong to the Android family. }
function RunAndroidOffline(AKind: TJobKind; AAdb: TAdbTool;
  ALog: TAndroidLog): TJobOutcome;

{ 'adb shell getprop' summary, written through ALog. Returns how many
  properties were read. }
function CollectPhoneInfo(AAdb: TAdbTool; ALog: TAndroidLog): Integer;

{ Reads one IMEI through the radio service. Empty string when the phone
  refuses - Android 10 and later block it for non-privileged callers.
  AIndex is 1 for IMEI1 and 3 for IMEI2 on most builds. }
function ReadImeiViaAdb(AAdb: TAdbTool; AIndex: Integer): string;

{ Decodes the "Parcel(00000000 0000000f '35646019 0304879 ')" output of
  'adb shell service call' into plain text. }
function DecodeServiceCall(const AOutput: string): string;

{ How many digits a string holds, for IMEI validation. }
function CountDigits(const AText: string): Integer;

implementation

uses
{$IFDEF FPC}
  StrUtils;
{$ELSE}
  System.StrUtils;
{$ENDIF}

const
  { packages that push OTA updates on the common OEM builds }
  COtaPackages: array[0..5] of string = (
    'com.google.android.gms.update',
    'com.android.updater',
    'com.miui.updater',
    'com.oplus.ota',
    'com.sec.android.soagent',
    'com.huawei.android.hwouc');

function CountDigits(const AText: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(AText) do
    if AText[I] in ['0'..'9'] then
      Inc(Result);
end;

function DecodeServiceCall(const AOutput: string): string;
var
  Lines: TStringList;
  I, Q1, Q2, J, Value, Code: Integer;
  Line, Chunk: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AOutput;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      Q1 := Pos('''', Line);
      if Q1 = 0 then
        Continue;
      Q2 := Q1 + 1;
      while (Q2 <= Length(Line)) and (Line[Q2] <> '''') do
        Inc(Q2);
      if Q2 <= Q1 then
        Continue;
      Chunk := Copy(Line, Q1 + 1, Q2 - Q1 - 1);
      J := 1;
      while J + 1 <= Length(Chunk) do
      begin
        if (Chunk[J] in ['0'..'9', 'a'..'f', 'A'..'F']) and
           (Chunk[J + 1] in ['0'..'9', 'a'..'f', 'A'..'F']) then
        begin
          Val('$' + Copy(Chunk, J, 2), Value, Code);
          if (Code = 0) and (Value > 0) then
            Result := Result + Chr(Value);
          Inc(J, 2);
        end
        else
          Inc(J);
      end;
    end;
  finally
    Lines.Free;
  end;
  Result := Trim(Result);
end;

function ReadImeiViaAdb(AAdb: TAdbTool; AIndex: Integer): string;
var
  Res: TCmdResult;
  Candidate: string;
begin
  Result := '';
  if AAdb = nil then
    Exit;
  if not AAdb.Adb(Format('shell service call iphonesubinfo %d', [AIndex]),
    Res) then
    Exit;
  if not Res.Ok then
    Exit;
  Candidate := DecodeServiceCall(Res.Output);
  if CountDigits(Candidate) >= 14 then
    Result := Candidate;
end;

function CollectPhoneInfo(AAdb: TAdbTool; ALog: TAndroidLog): Integer;
const
  CProps: array[0..23] of string = (
    'ro.product.brand', 'ro.product.manufacturer', 'ro.product.model',
    'ro.product.name', 'ro.product.device', 'ro.product.board',
    'ro.build.version.release', 'ro.build.version.sdk',
    'ro.build.version.security_patch', 'ro.build.display.id',
    'ro.build.fingerprint', 'ro.build.type', 'ro.build.tags',
    'ro.build.date', 'ro.boot.hardware', 'ro.board.platform',
    'ro.hardware', 'ro.serialno', 'ro.boot.serialno',
    'ro.boot.verifiedbootstate', 'ro.boot.flash.locked',
    'gsm.version.baseband', 'ro.build.ab_update',
    'persist.sys.device_provisioned');
var
  I: Integer;
  Value: string;
  Res: TCmdResult;
  State: TAndroidState;
begin
  Result := 0;
  if AAdb = nil then
    Exit;
  State := AAdb.DeviceState;
  if State <> asDevice then
  begin
    if Assigned(ALog) then
      ALog('The phone is not reachable through adb: ' + StateName(State) +
        '. Switch it on, accept the USB debugging prompt, and try again.');
    Exit;
  end;
  if Assigned(ALog) then
    ALog('adb device: ' + AAdb.Serial);
  for I := 0 to High(CProps) do
  begin
    Value := AAdb.GetProp(CProps[I]);
    if Value <> '' then
    begin
      Inc(Result);
      if Assigned(ALog) then
        ALog(Format('%-34s %s', [CProps[I], Value]));
    end;
  end;
  { the current slot of an A/B device }
  if AAdb.Adb('shell getprop ro.boot.slot_suffix', Res) and Res.Ok then
  begin
    Value := Trim(FirstLineOf(Res.Output));
    if Value <> '' then
    begin
      Inc(Result);
      if Assigned(ALog) then
        ALog(Format('%-34s %s', ['ro.boot.slot_suffix', Value]));
    end;
  end;
end;

{ ---------------------------------------------------------------- the jobs }

function RunAndroidOperation(AKind: TJobKind; AAdb: TAdbTool;
  const AParams: TJobParams; ALog: TAndroidLog;
  AProgress: TAndroidProgress): TJobOutcome;
var
  Res: TCmdResult;
  State: TAndroidState;
  Value, Msg, Imei2: string;
  Count, I: Integer;

  procedure L(const AText: string);
  begin
    if Assigned(ALog) then
      ALog(AText);
  end;

  procedure P(APercent: Integer; const AText: string);
  begin
    if Assigned(AProgress) then
      AProgress(APercent, AText);
  end;

begin
  Result := OutcomeFail('NO_JOB', 'No handler for this job');
  if AAdb = nil then
  begin
    Result := OutcomeFail('NO_TOOLS', 'The platform tools are not available');
    Exit;
  end;

  State := AAdb.DeviceState;
  L('adb reports: ' + StateName(State));

  case AKind of
    jkReadPhoneInfo:
      begin
        Count := CollectPhoneInfo(AAdb, ALog);
        if Count = 0 then
        begin
          Result := OutcomeFail('NO_DEVICE',
            'The phone did not answer adb. Enable USB debugging and accept ' +
            'the RSA prompt, or read the information in download mode ' +
            'instead.');
          Exit;
        end;
        Result := OutcomeOk(IntToStr(Count) + ' properties read', Count);
      end;

    jkReadImei:
      begin
        Value := ReadImeiViaAdb(AAdb, 1);
        if Value <> '' then
          L('IMEI1 : ' + Value)
        else
          L('IMEI1 : not available');
        Imei2 := ReadImeiViaAdb(AAdb, 3);
        if Imei2 <> '' then
          L('IMEI2 : ' + Imei2);
        if (Value = '') and (Imei2 = '') then
        begin
          Result := OutcomeFail('IMEI_BLOCKED',
            'Android refused to hand out the IMEI. Since Android 10 the ' +
            'iphonesubinfo service only answers a caller holding ' +
            'READ_PRIVILEGED_PHONE_STATE, which adb shell does not have. ' +
            'Dial *#06# on the phone, or read it in download mode.');
          Exit;
        end;
        Result := OutcomeOk('IMEI read', Int64(CountDigits(Value)));
      end;

    jkRebootRecovery:
      begin
        if State <> asDevice then
        begin
          Result := OutcomeFail('NO_DEVICE',
            'The phone is not in Android (' + StateName(State) +
            '), so adb cannot reboot it.');
          Exit;
        end;
        P(50, 'Rebooting to recovery');
        if not AAdb.RebootTo('recovery', Res) then
        begin
          Result := OutcomeFail('NO_TOOLS', Res.Error);
          Exit;
        end;
        if not Res.Ok then
        begin
          Result := OutcomeFail('REBOOT', Trim(Res.Output));
          Exit;
        end;
        L('The phone is rebooting into recovery. adb drops the connection, ' +
          'which is expected.');
        Result := OutcomeOk('Rebooted to recovery');
      end;

    jkUnlockBootloader:
      begin
        L('Unlocking the bootloader erases all user data on most devices and ' +
          'may void the warranty. On Samsung it also trips Knox permanently.');
        if State = asDevice then
        begin
          L('Rebooting the phone into the bootloader ...');
          AAdb.RebootTo('bootloader', Res);
          AAdb.WaitForState(asBootloader, 40000);
        end;
        if not AAdb.FastbootDevice then
        begin
          Result := OutcomeFail('NO_FASTBOOT',
            'The phone did not appear in fastboot mode. Switch it off, hold ' +
            'Volume Down + Power (Volume Up on some boards) and plug in the ' +
            'USB cable.');
          Exit;
        end;
        P(30, 'fastboot flashing unlock');
        if not AAdb.Fastboot('flashing unlock', Res) then
        begin
          Result := OutcomeFail('NO_TOOLS', Res.Error);
          Exit;
        end;
        L(Trim(Res.Output));
        if not Res.Ok then
        begin
          L('Retrying with the older "oem unlock" command ...');
          if not AAdb.Fastboot('oem unlock', Res) then
          begin
            Result := OutcomeFail('NO_TOOLS', Res.Error);
            Exit;
          end;
          L(Trim(Res.Output));
        end;
        if not Res.Ok then
        begin
          Result := OutcomeFail('UNLOCK',
            'The bootloader refused to unlock. Many devices need "OEM ' +
            'unlocking" enabled in Developer options first, and some need an ' +
            'unlock code from the vendor.');
          Exit;
        end;
        Result := OutcomeOk('Bootloader unlock command accepted. The phone ' +
          'wipes its data on the next boot.');
      end;

    jkRelockBootloader:
      begin
        L('Relocking the bootloader on a device with a modified system ' +
          'usually makes it unbootable. Only relock a stock, unmodified ' +
          'phone.');
        if State = asDevice then
        begin
          L('Rebooting the phone into the bootloader ...');
          AAdb.RebootTo('bootloader', Res);
          AAdb.WaitForState(asBootloader, 40000);
        end;
        if not AAdb.FastbootDevice then
        begin
          Result := OutcomeFail('NO_FASTBOOT', 'No phone in fastboot mode.');
          Exit;
        end;
        P(30, 'fastboot flashing lock');
        if not AAdb.Fastboot('flashing lock', Res) then
        begin
          Result := OutcomeFail('NO_TOOLS', Res.Error);
          Exit;
        end;
        L(Trim(Res.Output));
        if not Res.Ok then
        begin
          AAdb.Fastboot('oem lock', Res);
          L(Trim(Res.Output));
        end;
        if not Res.Ok then
        begin
          Result := OutcomeFail('LOCK', Trim(Res.Output));
          Exit;
        end;
        Result := OutcomeOk('Bootloader lock command accepted');
      end;

    jkSwitchSlot:
      begin
        Msg := '';
        if State = asDevice then
        begin
          Value := AAdb.GetProp('ro.boot.slot_suffix');
          if Value = '' then
          begin
            Result := OutcomeFail('NO_AB',
              'This phone has no A/B slot (ro.boot.slot_suffix is empty), so ' +
              'there is nothing to switch.');
            Exit;
          end;
          L('Current slot: ' + Value);
          if Value = '_a' then
            Msg := 'b'
          else
            Msg := 'a';
          L('Rebooting into the bootloader to switch to slot ' + Msg);
          AAdb.RebootTo('bootloader', Res);
          AAdb.WaitForState(asBootloader, 40000);
        end
        else
        begin
          if not AAdb.Fastboot('getvar current-slot', Res) then
          begin
            Result := OutcomeFail('NO_TOOLS', Res.Error);
            Exit;
          end;
          L(Trim(Res.Output));
          if Pos(': a', Res.Output) > 0 then
            Msg := 'b'
          else if Pos(': b', Res.Output) > 0 then
            Msg := 'a'
          else
          begin
            Result := OutcomeFail('NO_AB',
              'fastboot did not report a current slot, so this device is ' +
              'probably not an A/B device.');
            Exit;
          end;
        end;
        if not AAdb.FastbootDevice then
        begin
          Result := OutcomeFail('NO_FASTBOOT',
            'The phone did not reach fastboot mode.');
          Exit;
        end;
        P(50, 'fastboot --set-active=' + Msg);
        if not AAdb.Fastboot('--set-active=' + Msg, Res) then
        begin
          Result := OutcomeFail('NO_TOOLS', Res.Error);
          Exit;
        end;
        L(Trim(Res.Output));
        if not Res.Ok then
        begin
          Result := OutcomeFail('SLOT', Trim(Res.Output));
          Exit;
        end;
        Result := OutcomeOk('Active slot set to ' + Msg);
      end;

    jkDisableOta:
      begin
        if State <> asDevice then
        begin
          Result := OutcomeFail('NO_DEVICE',
            'The phone must be booted into Android for this (' +
            StateName(State) + ').');
          Exit;
        end;
        Count := 0;
        for I := 0 to High(COtaPackages) do
        begin
          P((I * 100) div (High(COtaPackages) + 1), COtaPackages[I]);
          if AAdb.Adb('shell pm path ' + COtaPackages[I], Res) and Res.Ok and
             (Trim(Res.Output) <> '') then
          begin
            L('Found ' + COtaPackages[I] + ': ' + Trim(Res.Output));
            if AAdb.Adb('shell pm disable-user --user 0 ' + COtaPackages[I],
              Res) then
            begin
              L(Trim(Res.Output));
              if Res.Ok then
                Inc(Count)
              else
                L('Disabling it needs a rooted phone or the device owner.');
            end;
          end
          else
            L(COtaPackages[I] + ' is not installed on this phone.');
        end;
        if Count = 0 then
        begin
          Result := OutcomeFail('NO_OTA',
            'No OTA updater package could be disabled. Either the phone does ' +
            'not use one of the known package names, or adb may not disable ' +
            'packages for this user.');
          Exit;
        end;
        Result := OutcomeOk(IntToStr(Count) + ' updater package(s) disabled',
          Count);
      end;

    jkResetDmVerity:
      begin
        if State <> asDevice then
        begin
          Result := OutcomeFail('NO_DEVICE',
            'The phone must be booted into Android for this (' +
            StateName(State) + ').');
          Exit;
        end;
        P(30, 'adb disable-verity');
        if not AAdb.Adb('disable-verity', Res) then
        begin
          Result := OutcomeFail('NO_TOOLS', Res.Error);
          Exit;
        end;
        L(Trim(Res.Output));
        if not Res.Ok then
        begin
          Result := OutcomeFail('VERITY',
            'adb refused to disable verity. It needs an unlocked bootloader ' +
            'and a userdebug build; on a stock user build the command is ' +
            'blocked by design.');
          Exit;
        end;
        if Pos('reboot', LowerCase(Res.Output)) > 0 then
        begin
          L('Rebooting so the change takes effect ...');
          AAdb.RebootTo('', Res);
        end;
        Result := OutcomeOk('dm-verity disabled');
      end;
  else
    Result := OutcomeFail('NO_JOB',
      'This job is not served by adb / fastboot.');
  end;
end;

function RunAndroidOffline(AKind: TJobKind; AAdb: TAdbTool;
  ALog: TAndroidLog): TJobOutcome;

  procedure L(const AText: string);
  begin
    if Assigned(ALog) then
      ALog(AText);
  end;

begin
  case AKind of
    jkDisableOrangeState:
      begin
        L('"ORANGE STATE" is the warning a device with an unlocked bootloader ' +
          'shows at power-on. It is drawn by the verified-boot chain itself, ' +
          'so it cannot be switched off from a PC.');
        L('The only ways to make it go away are:');
        L('  1. lock the bootloader again (Locks tab, Relock Bootloader). The ' +
          'phone must be completely stock, or it will not boot;');
        L('  2. flash a signed vbmeta with verification disabled ' +
          '(fastboot --disable-verity --disable-verification flash vbmeta ' +
          'vbmeta.img) - the warning still appears on many boards;');
        L('  3. replace the bootloader warning bitmap, which needs a signed ' +
          'image for that exact model.');
        if AAdb <> nil then
          L('fastboot present: ' + IfThen(AAdb.HasFastboot, 'yes', 'no'));
        L('Nothing was sent to a phone: this job only explains the options.');
        Result := OutcomeOk('Explained - no device was touched');
      end;
  else
    Result := OutcomeFail('NO_JOB', 'No offline handler for this job');
  end;
end;

end.
