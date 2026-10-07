# Mobile Servicing Tools — Device Setup

A native **Delphi VCL** Windows application (also builds with free Lazarus / Free Pascal).

## Download

- **Releases (easiest):** open the repository's **Releases** page and download from **Latest build (main)**:
  - `DeviceSetup-Win64.exe` for 64-bit Windows
  - `DeviceSetup-Win32.exe` for 32-bit Windows

  This release is replaced on every push to `main`. Pushing a tag such as `v1.1.0` also creates a versioned release that stays.
- **Build artifacts:** every CI run also uploads the EXEs under **Artifacts**. You need to be logged in to GitHub, they come zipped, and they're kept for 30 days.

The EXE is portable: it saves its settings and logs next to itself. If that folder is read-only (e.g. Program Files), it uses `%APPDATA%\MobileServicingTools` instead.

## Screens

### MAIN 1 — first screen (`MainForm.pas` / `MainForm.dfm`)

Reference client layout: `UI SAMPLE/S1.png`, **1023 × 575 at 96 DPI**. A fresh install opens the OPPO / CPH1909 selection shown in the sample; existing saved selections are preserved:

- **Blue menu icon** (top-left): *Next*, *Save model list…*, *Reload models*, *Export models.csv…*, *Settings…*, *Exit*.
- **Toolbar** (top-right, left to right): green **play** = Next, orange **download** = save the model list, green **document** = reload models, **gear** = Settings, **paper plane** = report a problem (opens the issue tracker), **f** = Facebook, **?** = help (version, build and shortcuts).
- **Quick search**: matches the model code (e.g. `RMX3511`), the model name or the brand, across all brands. **Esc** clears it.
- **Brand list** (left) and **model list** (right), with models shown as `CODE : Name`.
- **Brand wordmark** in the free area on the right. OPPO uses the actual lowercase logo cropped from S1; other brands retain their own coloured wordmarks.
- **Select** button at the bottom-left, with a green tick. It is greyed out until a model is selected; double-clicking a model or pressing **Enter** does the same as pressing Select.
- The **title bar** shows the version and the model count (e.g. `Realme : 35 model(s)` or `3 result(s) for "RMX35"`).
- The last selected brand/model and the window size and position are remembered.

### MAIN 2 — opened by Next (`Main2Form.pas` / `Main2Form.dfm`)

Reference client layout: `UI SAMPLE/S2.png` … `S10.png`, **1026 × 585 at 96 DPI**. Compact painted tab strips, frames and button faces avoid differences between themed/unthemed Windows and VCL/LCL client offsets:

- **Toolbar**: menu (left); on the right, left to right: **start** (runs the first job of the open tab), **save log**, **change device** (back to MAIN 1), **settings**, **report a problem**, **Facebook**, **help**.
- **Presets** box.
- **Files** box: **SCAT**, **AUTH**, **BIN**, **OFP**. BIN only turns on when *Advanced write* is ticked. On the **Samsung** profile the box grows to show **BL**, **AP**, **CP**, **CSC** and **USER** as well.
- **Log**: empty on opening the job screen, until a job or USB event occurs. Fixed-width font with colours, as in the samples: green `OK`, blue values, red `error(...)`. Right-click the log for *Copy*, *Copy all*, *Select all*, *Save* and *Clear*. **Ctrl+C** and **Ctrl+A** also work.
- **Progress** percentage with a red strip along the bottom edge.
- **Jobs** tab:
  - *Connections*: download agent, BROM/Preloader authorization, Force BROM, Read EMI, Read Phone Info, USB speed, battery and the storage list (`EMMC(USER) || UFS(LU2)`, …).
  - Then the operations pages.
- **Operations pages** (top row: *Flash | Read | Format | IMEI | Locks | Service | RPMB*), each starting with an **Options** header:
  - *Flash*: mode (`Download only`, `Upgrade`, `Format all + download`), **Write Firmware**, **Restore from backup**, *Advanced write* with a 64-bit start address, **Write BIN** and **Write OFP**.
    Write Firmware takes either a SCAT file (MediaTek) or BL/AP/CP/CSC/USER files (Samsung).
  - *Read*: **Read Flash info**, **Read Partitions**, *Address 0x* / *Size 0x*, **Read BIN**, **Read Region** and **Read OTP**.
  - *Format*: **Auto/Manual Format**, **Format All Flash / Except Bootloader**, **Format**, *Create Default FS*, **Wipe Data**, **Wipe Partitions**, **Erase FRP**, **Erase FRP and Wipe**.
  - *IMEI*: **IMEI1** and **IMEI2** with their Luhn check digit shown next to the field, an *Advanced settings* link, **Repair** and **Read IMEI**.
  - *Locks*: **Unlock Bootloader**, **Relock Bootloader**, **Unlock Network**, **Read Codes**, **Reset Password [SAFE WIPE]**, **Reset Account**.
  - *Service*: **Reboot to Recovery**, **Disable OTA Updates**, **Reset Dm-Verity Error**, **Disable Orange State**, **Switch Slot**, **Fix DL Image Fail**.
  - *RPMB*: **Backup RPMB**, *Address 0x*, **Write RPMB**, **Format RPMB**.
- The **service-mode tab** next to *Jobs* follows the selected platform: **META** for MediaTek, **DIAG** for Unisoc/Spreadtrum and Qualcomm, **DOWNLOAD** for Samsung and **SERVICE** for Generic. The **Platform** selector lives on that tab; it also changes the connection profile and the button set. It is remembered with the job settings.
- All **seven operation tabs** fit in one row, without native scroll arrows. The complete Format page, including **Erase FRP and Wipe**, stays within the minimum window size.
- The Format mode and range radio buttons have **independent parents**, so both selections work correctly.
- **Device state** (bottom, next to the progress strip) appears only while a phone is connected.
- **Esc** goes back to MAIN 1.

Address boxes use the `00000000  00000000` format (high and low 32 bits of a 64-bit hex value). Spaces are ignored.

> **Device communication is not implemented.** The action buttons (including Format, Locks, Service and RPMB) validate applicable inputs and write the chosen profile/options to the log, ending with `error(NOT_IMPLEMENTED)`. Nothing is sent to a phone, and no format/read/write action is performed.

### USB detection (read only)

MAIN 2 checks the Windows device list every second and logs phones as they are plugged in or removed. The phone icon (bottom-right) turns green when one is found. It recognises:

- MediaTek **BROM**, **PRELOADER**, **DA** and **META**
- Qualcomm **EDL** (9008) and **DIAG**
- Samsung **DOWNLOAD** mode
- Unisoc/Spreadtrum download
- **Fastboot**
- Common Android phones in normal mode

It only reads the device list (SetupAPI) and never sends anything to the phone. You can turn it off in Settings.

### Settings (gear icon, or Menu > Settings)

- Show the time in front of every log line (off by default, to match the screenshot).
- Save every session log to the `logs` folder (on). Saved logs always include the time.
- Remember file paths and job options (on).
- Detect phones connected by USB (on).

## Model list (`models.csv`)

The app has a built-in starter list. The visible OPPO models and brand headings match S1; the existing Realme and other starter models are retained. A heading without supplied model data is an empty category, not a fabricated device. CSV export preserves those categories as `Brand,,` rows. This is not a complete manufacturer/model database. To use your own list:

1. In MAIN 1, choose **Menu > Export models.csv…** and save it next to the EXE.
2. Edit it in Notepad or Excel. Each line is `Brand,Model code,Name`, for example `Realme,RMX3511,Realme C35`. Lines starting with `#` are comments. `;` or a tab also work as the separator.
3. Choose **Menu > Reload models**, or restart the app.

When `models.csv` is next to the EXE it **replaces** the built-in list. Delete the file to go back to the built-in list.

## Delphi project

Open [`Delphi/DeviceSetup/DeviceSetup.dproj`](Delphi/DeviceSetup/DeviceSetup.dproj) in RAD Studio. The project targets both **Win32** and **Win64** (`TargetedPlatforms=3`). The icon (`DeviceSetup.ico`), version info and DPI awareness are set in the project files. The version number is `CAppVersion` in `AppInfo.pas`.

Toolbar cards, all job glyphs and the OPPO logo use **the actual artwork from the supplied screenshots**, not vector approximations. The 42 small BMPs in `assets/sample-ui` are linked into `SampleAssets.res`, so the EXE still needs no external images. The committed resource is reproducible with `python tools/make_ui_resources.py`; CI checks it byte-for-byte. `tools/extract_sample_assets.py` is an optional maintainer tool (requires Pillow) for repeating the documented crops.

Buttons, group frames and compact tab strips are interactive controls in `SampleControls.pas`. Lists, editable inputs, combos, checkboxes and radio buttons remain native controls. No full-screen reference bitmap is used as a fake interface. See [UI matching and verification](docs/UI-MATCHING.md) for the sample/screenshot map.

| Unit | What it does |
| --- | --- |
| `MainForm` / `Main2Form` | the two screens (`UI SAMPLE/S1.png` … `S10.png` are the layout references) |
| `DeviceCatalog` | built-in model list and `models.csv` loading/export |
| `AppInfo` | version, data folder, settings file (`DeviceSetup.ini`), options |
| `LogView` | colour codes and drawing for the log |
| `UsbDetect` | read-only USB service-mode detection (SetupAPI) |
| `SettingsDialog` | the Settings window (built in code) |
| `SelfTest` | `DeviceSetup.exe --selftest`, used by CI |
| `ToolbarIcons` / `SampleAssets` | embedded reference toolbar/action artwork and logo |
| `SampleControls` | theme-independent button faces, group frames and compact keyboard-operable tabs |

## CI build (fast, free)

`.github/workflows/build-fast.yml` runs on pushes to `main`, on `v*` tags, on every pull request, and manually. It runs on GitHub-hosted Windows runners and builds Win32 and Win64 in parallel with **Lazarus 4.4 / Free Pascal 3.2.2**, which is cached after the first run. Each job:

1. Generates the `.lfm` forms from the `.dfm` files (`tools/dfm2lfm.py`). Edit only the `.dfm` files.
2. Runs the platform-independent UI/resource contracts (`python tools/test_ui_contract.py`, 12 tests) and checks the embedded artwork is up to date.
3. Stamps the commit id into `BuildInfo.inc`, which is shown in Help.
4. Compiles.
5. Runs **`DeviceSetup.exe --selftest`**, which:
   - opens both screens (this catches form-loading errors that the compiler cannot see)
   - checks hex parsing, file checks, the `models.csv` round trip, search and the SetupAPI calls
   - checks actual control bounds, all seven tabs, empty idle log, connection defaults and independent radio groups
   - captures clean **client-only**, lossless screenshots of MAIN 1 and MAIN 2 (including the open Flash dropdown from S4) before running tests that write to the log
   - separately captures the colour log, advanced Flash, progress, service-mode profiles and 144/192-DPI layouts; scaled layouts must keep all tabs and Format actions visible

   The results and PNG screenshots are uploaded as `DeviceSetup-selftest-<platform>-<sha>`. The self-test result is also shown as a notice on the run page.

   **Screenshots of every screen are also published as check runs** (named `ci-shot <screen> <n>/<m>`, lossless base64 PNG chunks) so the UI can be reviewed through the GitHub API without downloading artifacts. This happens on every **pull request**, when you start the workflow by hand (**Actions > Build EXEs (fast) > Run workflow**) and tick *screenshots*, and for any commit that contains the marker file `.github/ci-screenshots`.
6. Uploads the EXE.
7. On `main` or a `v*` tag, publishes the GitHub Release.

To build locally with Lazarus: `python tools/dfm2lfm.py`, then `lazbuild DeviceSetup.lpi`.

### Optional: Delphi build

`.github/workflows/build-delphi.yml` builds with real Delphi but is **manual only**. It needs:

- a self-hosted Windows x64 runner labelled `delphi`, with RAD Studio installed
- the repository variable `DELPHI_STUDIO_DIR`, set to the RAD Studio root folder

The Delphi build is not tested in CI. Only the Lazarus build is.
