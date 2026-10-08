unit MtkChips;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ MediaTek chip identification.

  After the BROM handshake the BootROM answers GET_HW_CODE (0xFD) with a
  dword: the low word is the hardware version, the high word is the hardware
  code. That code is what identifies the chip, and it decides

    - which download-agent protocol the device speaks (legacy / xflash / xml),
    - where the watchdog timer register lives (it has to be stopped, or the
      phone resets in the middle of a transfer),
    - the UART, CQ-DMA, misc-lock and payload addresses used by the later
      stages,
    - where ME_ID and SOC_ID are kept.

  The table below is the hardware-code list of MediaTek BootROM builds. It is
  data, not guesses: every row names the hwcode, the chip, and the addresses
  that BootROM exposes for it. A hwcode that is not listed falls back to the
  generic legacy values, which is what the vendor tools also do.

  Generated from the public MediaTek BootROM configuration table
  (bkerler/mtkclient, mtkclient/config/brom_config.py, GPLv3). }

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  { Which download-agent dialect the chip uses. }
  TDaMode = (dmLegacy, dmXFlash, dmXml);

  TMtkChipInfo = record
    HwCode: Word;
    DaCode: Word;
    Name: string;
    Description: string;
    Watchdog: UInt32;
    Uart: UInt32;
    DaMode: TDaMode;
    Has64Bit: Boolean;
    MiscLock: UInt32;
    MeidAddr: UInt32;
    SocIdAddr: UInt32;
    CqDmaBase: UInt32;
    BromPayloadAddr: UInt32;
    DaPayloadAddr: UInt32;
  end;

const
  CMtkChipCount = 89;

  CMtkChips: array[0..CMtkChipCount - 1] of TMtkChipInfo = (
    (HwCode: $0279; DaCode: $6797; Name: 'MT6797/MT6767'; Description: 'Helio X23/X25/X27'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $10002050; MeidAddr: $001030AC; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0321; DaCode: $6735; Name: 'MT6735/T,MT8735A'; Description: ''; Watchdog: $10212000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10001838; MeidAddr: $001030B0; SocIdAddr: $00000000; CqDmaBase: $10217C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0326; DaCode: $6755; Name: 'MT6755/MT6750/M/T/S'; Description: 'Helio P10/P15/P18'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $10001838; MeidAddr: $001030AC; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0335; DaCode: $6735; Name: 'MT6737M/MT6735G'; Description: ''; Watchdog: $10212000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001030B0; SocIdAddr: $00000000; CqDmaBase: $10217C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0337; DaCode: $6735; Name: 'MT6753'; Description: ''; Watchdog: $10212000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10001838; MeidAddr: $001030B0; SocIdAddr: $00000000; CqDmaBase: $10217C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0507; DaCode: $6758; Name: 'MT6759'; Description: 'Helio P30'; Watchdog: $10210000; Uart: $11020000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0551; DaCode: $6757; Name: 'MT6757/MT6757D'; Description: 'Helio P20'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $10001838; MeidAddr: $001030B4; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0562; DaCode: $6799; Name: 'MT6799'; Description: 'Helio X30/X35'; Watchdog: $10211000; Uart: $11020000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001033B8; SocIdAddr: $001033C8; CqDmaBase: $11B30000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0571; DaCode: $0571; Name: 'MT0571'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0598; DaCode: $0598; Name: 'ELBRUS/MT0598'; Description: ''; Watchdog: $10211000; Uart: $11020000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0601; DaCode: $6755; Name: 'MT6750'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $10001838; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0633; DaCode: $6570; Name: 'MT6570/MT8321'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $1020AC00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0688; DaCode: $6758; Name: 'MT6758'; Description: 'Helio P30'; Watchdog: $10211000; Uart: $11020000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00102BF8; SocIdAddr: $00102C08; CqDmaBase: $10200000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0690; DaCode: $6763; Name: 'MT6763'; Description: 'Helio P23'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B78; SocIdAddr: $00102B88; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0699; DaCode: $6739; Name: 'MT6739/MT6731/MT8765'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102AF8; SocIdAddr: $00102B08; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0707; DaCode: $6768; Name: 'MT6768/MT6769'; Description: 'Helio P65/G85 k68v1'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102AF8; SocIdAddr: $00102B08; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0717; DaCode: $6761; Name: 'MT6761/MT6762/MT3369/MT8766B/MT8761/AC8259/AC8257'; Description: 'Helio A20/P22/A22/A25/G25'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102AF8; SocIdAddr: $00102B08; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0725; DaCode: $6779; Name: 'MT6779'; Description: 'Helio P90 k79v1'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B38; SocIdAddr: $00102B48; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0766; DaCode: $6765; Name: 'MT6765/MT8768t'; Description: 'Helio P35/G35'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102AF8; SocIdAddr: $00102B08; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0788; DaCode: $6771; Name: 'MT6771/MT8385/MT8183/MT8666'; Description: 'Helio P60/P70/G80'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B38; SocIdAddr: $00102B48; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0813; DaCode: $6785; Name: 'MT6785'; Description: 'Helio G90'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B38; SocIdAddr: $00102B48; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0816; DaCode: $6885; Name: 'MT6885/MT6883/MT6889/MT6880/MT6890'; Description: 'Dimensity 1000L/1000'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B78; SocIdAddr: $00102B88; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0886; DaCode: $6873; Name: 'MT6873'; Description: 'Dimensity 800/820 5G'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B78; SocIdAddr: $00102B88; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0907; DaCode: $0907; Name: 'MT6983'; Description: 'Dimensity 9000/9000+'; Watchdog: $1C007000; Uart: $11001000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0908; DaCode: $8696; Name: 'MT8696'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0930; DaCode: $8195; Name: 'MT8195 Chromebook'; Description: ''; Watchdog: $10007000; Uart: $11001200; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0950; DaCode: $6893; Name: 'MT6891/MT6893'; Description: 'Dimensity 1200'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00102B98; SocIdAddr: $00102BA8; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0959; DaCode: $6877; Name: 'MT6877/MT6877V/MT8791N'; Description: 'Dimensity 900/1080/7050'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00102B98; SocIdAddr: $00102BA8; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0989; DaCode: $6833; Name: 'MT6833'; Description: 'Dimensity 700 5G k6833'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00102B98; SocIdAddr: $00102BA8; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0992; DaCode: $0992; Name: 'MT6880/MT6890 Modem'; Description: ''; Watchdog: $10007000; Uart: $11003000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $0996; DaCode: $6853; Name: 'MT6853'; Description: 'Dimensity 720 5G'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $1001A100; MeidAddr: $00102B78; SocIdAddr: $00102B88; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1066; DaCode: $6781; Name: 'MT6781'; Description: 'Helio G96'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00102B98; SocIdAddr: $00102BA8; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1129; DaCode: $1129; Name: 'MT6855'; Description: 'Dimensity 8100'; Watchdog: $1C007000; Uart: $11001000; DaMode: dmXml; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1172; DaCode: $1172; Name: 'MT6895'; Description: 'Dimensity 8200'; Watchdog: $1C007000; Uart: $11001000; DaMode: dmXml; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1203; DaCode: $1203; Name: 'MT6897'; Description: 'Dimensity 8300 Ultra'; Watchdog: $1C007000; Uart: $11002000; DaMode: dmXml; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $020E7090; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1208; DaCode: $1208; Name: 'MT6789/MT8781V'; Description: 'MTK Helio G99'; Watchdog: $10007000; Uart: $11002000; DaMode: dmXml; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1209; DaCode: $1209; Name: 'MT6835V/ZA'; Description: 'MTK Dimensity 6100+'; Watchdog: $1C007000; Uart: $11002000; DaMode: dmXml; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02001000),
    (HwCode: $1229; DaCode: $1229; Name: 'MT6886'; Description: 'Dimensity 7200 Ultra'; Watchdog: $1C007000; Uart: $11002000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02001000),
    (HwCode: $1236; DaCode: $1236; Name: 'MT6989W'; Description: 'Dimensity 9300 Plus'; Watchdog: $1C00B000; Uart: $11002000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02001000),
    (HwCode: $1296; DaCode: $1296; Name: 'MT6985'; Description: 'Dimensity 9200/9200+'; Watchdog: $1C007000; Uart: $1C011000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1357; DaCode: $1357; Name: 'MT6991'; Description: 'Dimensity 9400 Ultra'; Watchdog: $1C010000; Uart: $16000000; DaMode: dmXml; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $020E7090; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $1375; DaCode: $1375; Name: 'MT6878'; Description: 'Dimensity 7300'; Watchdog: $1C00A000; Uart: $11001000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02010000),
    (HwCode: $1471; DaCode: $1471; Name: 'MT6993'; Description: 'Dimensity 9500'; Watchdog: $1C010000; Uart: $16010000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $2523; DaCode: $2523; Name: 'MT2523'; Description: ''; Watchdog: $10007000; Uart: $11005000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $11142C34; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02008000),
    (HwCode: $2601; DaCode: $2601; Name: 'MT2601'; Description: ''; Watchdog: $10007000; Uart: $11005000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $11142C34; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02008000),
    (HwCode: $2625; DaCode: $2625; Name: 'MT2625'; Description: ''; Watchdog: $10007000; Uart: $11005000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $11142C34; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $04001000),
    (HwCode: $3967; DaCode: $3967; Name: 'MT3967'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $5932; DaCode: $5932; Name: 'MT5932'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6225; DaCode: $6225; Name: 'MT6225'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6226; DaCode: $6226; Name: 'MT6226'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6236; DaCode: $6236; Name: 'MT6236'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6238; DaCode: $6238; Name: 'MT6238'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6253; DaCode: $6253; Name: 'MT6253'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6255; DaCode: $6255; Name: 'MT6255'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6256; DaCode: $6256; Name: 'MT6256'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $625A; DaCode: $625A; Name: 'MT625a'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6261; DaCode: $6261; Name: 'MT6261/MT2503'; Description: ''; Watchdog: $A0030000; Uart: $A0080000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6268; DaCode: $6268; Name: 'MT6268'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6270; DaCode: $6270; Name: 'MT6270'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6276; DaCode: $6276; Name: 'MT6276'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6280; DaCode: $0000; Name: 'MT6280'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6291; DaCode: $6291; Name: 'MT6291'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6516; DaCode: $6516; Name: 'MT6516'; Description: ''; Watchdog: $10003000; Uart: $10023000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6571; DaCode: $6571; Name: 'MT6571'; Description: ''; Watchdog: $10007400; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $1000141C; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $02009000),
    (HwCode: $6572; DaCode: $6572; Name: 'MT6572'; Description: ''; Watchdog: $10007000; Uart: $11005000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $1000141C; MeidAddr: $11142C34; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $010036A0; DaPayloadAddr: $02008000),
    (HwCode: $6573; DaCode: $6573; Name: 'MT6573/MT6260'; Description: ''; Watchdog: $70025000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $90006000),
    (HwCode: $6575; DaCode: $6575; Name: 'MT6575/MT8317'; Description: ''; Watchdog: $C0000000; Uart: $C1009000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $F0002AF4; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $F0000A00; DaPayloadAddr: $C2001000),
    (HwCode: $6577; DaCode: $6577; Name: 'MT6577'; Description: ''; Watchdog: $C0000000; Uart: $C1009000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $C2001000),
    (HwCode: $6580; DaCode: $6580; Name: 'MT6580'; Description: ''; Watchdog: $10007000; Uart: $11005000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10001838; MeidAddr: $001030B4; SocIdAddr: $00000000; CqDmaBase: $1020AC00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6582; DaCode: $6582; Name: 'MT6582/MT6574/MT8382'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10002050; MeidAddr: $001030CC; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6583; DaCode: $6583; Name: 'MT6583/6589'; Description: ''; Watchdog: $10000000; Uart: $11006000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10002050; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $12001000),
    (HwCode: $6592; DaCode: $6592; Name: 'MT6592/MT8392'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10002050; MeidAddr: $001030A8; SocIdAddr: $00000000; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00111000),
    (HwCode: $6595; DaCode: $6595; Name: 'MT6595'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001030A4; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00111000),
    (HwCode: $6752; DaCode: $6752; Name: 'MT6752'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10001838; MeidAddr: $001030B4; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $6795; DaCode: $6795; Name: 'MT6795'; Description: 'Helio X10'; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001030A0; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00110000),
    (HwCode: $6899; DaCode: $6899; Name: 'MT6899'; Description: 'Dimensity 8400 Turbo/Ultra'; Watchdog: $1C00B000; Uart: $11001000; DaMode: dmXml; Has64Bit: True; MiscLock: $00000000; MeidAddr: $001008EC; SocIdAddr: $00100934; CqDmaBase: $10212000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $7682; DaCode: $7682; Name: 'MT7682'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $7686; DaCode: $7686; Name: 'MT7686'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8127; DaCode: $8127; Name: 'MT8127/MT3367/AC8227L'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10002050; MeidAddr: $001031CC; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8135; DaCode: $8135; Name: 'MT8135'; Description: ''; Watchdog: $10000000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $12001000),
    (HwCode: $8163; DaCode: $8163; Name: 'MT8163'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $10002050; MeidAddr: $001031C0; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8167; DaCode: $8167; Name: 'MT8167/MT8516/MT8362'; Description: ''; Watchdog: $10007000; Uart: $11005000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00103478; SocIdAddr: $00103488; CqDmaBase: $10212C00; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8168; DaCode: $8168; Name: 'MT8168/MT6357'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00106438; SocIdAddr: $00106448; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8172; DaCode: $8173; Name: 'MT8173'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $01202050; MeidAddr: $001230B0; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00120A00; DaPayloadAddr: $000C0000),
    (HwCode: $8176; DaCode: $8173; Name: 'MT8176'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $01202050; MeidAddr: $001230B0; SocIdAddr: $00000000; CqDmaBase: $10212C00; BromPayloadAddr: $00120A00; DaPayloadAddr: $000C0000),
    (HwCode: $8512; DaCode: $8512; Name: 'MT8512'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00104638; SocIdAddr: $00104648; CqDmaBase: $10214000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00111000),
    (HwCode: $8518; DaCode: $8518; Name: 'MT8518 VoiceAssistant'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $00000000; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8590; DaCode: $8590; Name: 'MT8590/MT7683/MT8521/MT7623'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001031D8; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
    (HwCode: $8695; DaCode: $8695; Name: 'MT8695'; Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmXFlash; Has64Bit: False; MiscLock: $00000000; MeidAddr: $001032B8; SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00; DaPayloadAddr: $00201000),
  );

  { Fallback used for an hwcode that is not in the table. }
  CGenericChip: TMtkChipInfo = (
    HwCode: $0000; DaCode: $0000; Name: 'Unknown MediaTek device';
    Description: ''; Watchdog: $10007000; Uart: $11002000; DaMode: dmLegacy;
    Has64Bit: False; MiscLock: $10002050; MeidAddr: $00000000;
    SocIdAddr: $00000000; CqDmaBase: $00000000; BromPayloadAddr: $00100A00;
    DaPayloadAddr: $00201000);

{ Looks the hardware code up. AFound tells whether the code was known. }
function ChipByHwCode(AHwCode: Word; out AFound: Boolean): TMtkChipInfo;
{ Same, but always returns something usable. }
function ChipInfo(AHwCode: Word): TMtkChipInfo;
{ 'MT6765/MT8768t (Helio P35/G35)' - for the log. }
function ChipLabel(const AInfo: TMtkChipInfo): string;
function DaModeLabel(AMode: TDaMode): string;

implementation

function ChipByHwCode(AHwCode: Word; out AFound: Boolean): TMtkChipInfo;
var
  I: Integer;
begin
  for I := 0 to CMtkChipCount - 1 do
    if CMtkChips[I].HwCode = AHwCode then
    begin
      Result := CMtkChips[I];
      AFound := True;
      Exit;
    end;
  Result := CGenericChip;
  Result.HwCode := AHwCode;
  AFound := False;
end;

function ChipInfo(AHwCode: Word): TMtkChipInfo;
var
  Found: Boolean;
begin
  Result := ChipByHwCode(AHwCode, Found);
  if not Found then
    Result.Name := 'Unknown MediaTek device (hwcode $' +
      IntToHex(AHwCode, 4) + ')';
end;

function ChipLabel(const AInfo: TMtkChipInfo): string;
begin
  Result := AInfo.Name;
  if AInfo.Description <> '' then
    Result := Result + ' (' + AInfo.Description + ')';
end;

function DaModeLabel(AMode: TDaMode): string;
begin
  case AMode of
    dmXFlash: Result := 'XFLASH';
    dmXml: Result := 'XML';
  else
    Result := 'LEGACY';
  end;
end;

end.
