unit UnimplementedJobs;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ The honest answer for everything this build cannot actually do.

  A servicing tool that writes "OK" for an operation it never performed is
  worse than one that refuses, because the technician believes the phone is
  fixed and hands it back. So every job whose protocol is not public, or whose
  data format is not known to this code, gets a real explanation here:

    * what the app DID do (captured the phone, locked its port, ran the
      bring-up it has),
    * what is missing and why,
    * what the technician can do instead.

  The outcome is always a failure with a specific code, never a success. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes;

type
  { The job engine passes its log routine in so this unit stays UI-free. }
  TUnimplementedLog = procedure(const AText: string) of object;

{ Builds the outcome and writes the explanation through ALog (when assigned).
  ADetail is appended to the message - normally what the session already
  achieved, e.g. "the port was captured and locked". }
function UnimplementedOutcome(AKind: TJobKind; APlatform: TDevPlatform;
  ALog: TUnimplementedLog; const ADetail: string = ''): TJobOutcome;

{ The same text without logging, for dialogs and the self-test. }
function UnimplementedMessage(AKind: TJobKind; APlatform: TDevPlatform): string;

{ True when the job could in principle work on this platform, i.e. the failure
  is about the platform bring-up rather than the operation itself. }
function BlockedByPlatform(AKind: TJobKind; APlatform: TDevPlatform): Boolean;

implementation

uses
{$IFDEF FPC}
  StrUtils;
{$ELSE}
  System.StrUtils;
{$ENDIF}

{ What the platform bring-up is missing, or '' when the platform is served. }
function PlatformGap(APlatform: TDevPlatform): string;
begin
  case APlatform of
    dpUnisoc:
      Result := 'The Unisoc / Spreadtrum service protocol (Diag channel plus ' +
        'the FDL1 / FDL2 boot loaders and the SPD image container) is not ' +
        'public and is not implemented in this build. The FDL1 and FDL2 files ' +
        'that ship with this app are catalogued and can be selected, but they ' +
        'are never parsed or sent: guessing at the protocol could brick the ' +
        'phone. Use a tool that has the Unisoc protocol (SPD Upgrade Tool / ' +
        'ResearchDownload) for this device.';
    dpQualcomm:
      Result := 'Qualcomm EDL is served up to the Sahara stage, which this ' +
        'build implements: hello, hello response, memory read and image ' +
        'transfer. What follows Sahara is firehose, an XML command language ' +
        'driven by the vendor programmer binary (prog_firehose_*.elf or .mbn) ' +
        'for this exact chipset. Firehose is not implemented here and the ' +
        'programmer files are vendor specific, so flashing and partition ' +
        'access cannot continue. Use QFIL / QPST with the programmer for this ' +
        'chipset.';
    dpSamsung:
      Result := 'The Samsung download protocol (Loke, the protocol behind ' +
        'Odin and Heimdall) is not public and is not implemented in this ' +
        'build. The BL / AP / CP / CSC / USER images can be selected and are ' +
        'checked for existence, but they are never sent. Writing a guessed ' +
        'Loke stream to a Samsung phone can hard-brick it and trips Knox ' +
        'irreversibly. Use Odin with the matching firmware for this model.';
    dpGeneric:
      Result := 'No service protocol is known for the "Generic" profile. Pick ' +
        'the platform that matches the phone (MediaTek, Unisoc, Qualcomm or ' +
        'Samsung), or use the Android jobs, which work on any booted phone ' +
        'through adb and fastboot.';
  else
    Result := '';
  end;
end;

{ What this specific operation is missing, independent of the platform. }
function OperationGap(AKind: TJobKind): string;
begin
  case AKind of
    jkUnlockNetwork:
      Result := 'Network unlocking needs the unlock algorithm of this exact ' +
        'modem: the phone answers a challenge and the tool has to produce the ' +
        'matching NCK / NSCK / SPCK code from a secret key. Those algorithms ' +
        'are vendor property and are not public, so this build does not ' +
        'pretend to compute them. A legitimate unlock comes from the carrier ' +
        'or the manufacturer - most will give the code for free once the ' +
        'contract is finished - and is then entered on the phone with the ' +
        'SIM ejected.';
    jkReadCodes:
      Result := 'Reading the network, phone and provider lock codes uses the ' +
        'same vendor algorithms as unlocking them: the codes are not stored ' +
        'in a readable partition, they are derived from a key held by the ' +
        'modem. Not public, so not implemented. Ask the carrier for the code.';
    jkResetPassword:
      Result := 'The screen-lock password of an Android phone is not stored ' +
        'anywhere a PC can reach: it is verified by the gatekeeper against a ' +
        'key inside the secure element or TrustZone. The only ways to remove ' +
        'it are a factory reset from recovery (which erases the data), the ' +
        'owner''s Google / Samsung account, or the vendor''s own service ' +
        'centre. There is nothing this app could honestly send.';
    jkResetAccount:
      Result := 'Removing the account that guards Factory Reset Protection ' +
        'means bypassing an anti-theft measure. On a device that is genuinely ' +
        'yours the honest routes are: sign in with the account that was on ' +
        'it, ask the vendor with proof of purchase, or on a MediaTek board ' +
        'erase the "frp" partition with the Format tab (Erase FRP) and then ' +
        'set the phone up as new - which only works when you can already ' +
        'reach download mode. This job does not send anything by itself.';
    jkWriteOfp:
      Result := 'The OFP container (OPPO / Realme) holds an XML program file ' +
        'and per-partition images that are encrypted with a key derived from ' +
        'the model. Unpacking it is not implemented here, and writing a ' +
        'guessed layout would destroy the partition table. Unpack the OFP ' +
        'with a tool that has the key and write the images with Write BIN, ' +
        'using the addresses from the program file.';
    jkRpmbWrite:
      Result := 'RPMB is replay protected: every frame has to be signed with ' +
        'the 256-bit key provisioned into this exact device and carry a ' +
        'counter higher than the stored one. The legacy download agent offers ' +
        'no key programming command, so a write cannot be authenticated and ' +
        'would corrupt the partition permanently. Backup RPMB can still read ' +
        'it when the agent allows it.';
    jkRpmbFormat:
      Result := 'RPMB cannot be formatted or erased. It is one-time ' +
        'programmable and its counter never goes back - there is no such ' +
        'command in eMMC or UFS. Nothing was sent to the device.';
    jkRepairImei, jkReadImei:
      Result := 'The IMEI lives in the NVRAM / NVDATA partitions in a ' +
        'MediaTek record format whose layout and checksum differ per chip. ' +
        'That codec is not public and is not implemented here, so the app ' +
        'refuses to write and only backs the partitions up. Changing an IMEI ' +
        'is also illegal in many countries - only restore the number the ' +
        'device was born with.';
    jkReadOtp:
      Result := 'One-time-programmable area is only readable when the board ' +
        'exposes it and the download agent implements the OTP read command. ' +
        'MediaTek answers "DA OTP not supported" ($C0040100) on most boards.';
  else
    Result := '';
  end;
end;

function BlockedByPlatform(AKind: TJobKind; APlatform: TDevPlatform): Boolean;
begin
  Result := (PlatformGap(APlatform) <> '') and (OperationGap(AKind) = '');
end;

{ JobNeedsDa lives in JobEngine, which depends on this unit - so the check is
  repeated here rather than creating a cycle. }
function JobNeedsDaKind(AKind: TJobKind): Boolean;
begin
  Result := AKind in [jkWriteFirmware, jkRestoreBackup, jkWriteBin,
    jkWriteOfp, jkReadFlashInfo, jkReadPartitions, jkReadBin, jkReadRegion,
    jkReadOtp, jkFormat, jkWipeData, jkWipePartitions, jkEraseFrp,
    jkEraseFrpAndWipe, jkRpmbBackup, jkRpmbWrite, jkRpmbFormat,
    jkDownloadAgent];
end;

function UnimplementedMessage(AKind: TJobKind; APlatform: TDevPlatform): string;
var
  PlatformText, OperationText: string;
begin
  PlatformText := PlatformGap(APlatform);
  OperationText := OperationGap(AKind);
  if (PlatformText <> '') and (OperationText <> '') then
    Result := OperationText + ' ' + PlatformText
  else if OperationText <> '' then
    Result := OperationText
  else if PlatformText <> '' then
    Result := PlatformText
  else
    Result := 'This job has no implemented handler in this build. It was not ' +
      'run and nothing was sent to the phone.';
end;

function UnimplementedOutcome(AKind: TJobKind; APlatform: TDevPlatform;
  ALog: TUnimplementedLog; const ADetail: string): TJobOutcome;
var
  Msg: string;
  Code: string;

  procedure L(const AText: string);
  begin
    if Assigned(ALog) then
      ALog(AText);
  end;

begin
  Msg := UnimplementedMessage(AKind, APlatform);
  if PlatformGap(APlatform) <> '' then
    Code := 'NO_PROTOCOL_' + UpperCase(PlatformLabel(APlatform))
  else if OperationGap(AKind) <> '' then
    Code := 'UNIMPLEMENTED'
  else
    Code := 'NO_HANDLER';
  { a code with spaces would be awkward to grep in a log file }
  Code := StringReplace(Code, ' ', '_', [rfReplaceAll]);
  Code := StringReplace(Code, '/', '_', [rfReplaceAll]);

  L('--- ' + JobName(AKind) + ' on ' + PlatformLabel(APlatform) + ' ---');
  if ADetail <> '' then
    L('Done so far: ' + ADetail);
  L(Msg);
  if (APlatform = dpMtk) and JobNeedsDaKind(AKind) then
    L('MediaTek note: this build implements the legacy download-agent ' +
      'protocol. Chips whose DA uses xflash or the XML command set ' +
      '(most MT6771, MT6779, MT6833, MT6873 and newer) are reported as ' +
      'unsupported by the bring-up rather than half-driven.');
  Result := OutcomeFail(Code, Msg);
end;

end.
