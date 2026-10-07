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

- **Blue menu icon** (top-left): *Next*, *Save model list…*, *Reload models*, *Export models.csv…*, *Settings…*, *Exit*.
- **Green play icon** (top-right) = **Next**: opens MAIN 2 for the selected model. It is greyed out until a model is selected. Double-clicking a model or pressing **Enter** on it does the same.
- **Orange arrow icon**: saves the model list currently shown to a `.txt` file.
- **Quick search**: matches the model code (e.g. `RMX3511`), the model name or the brand, across all brands. **Esc** clears it.
- **Brand list** (left) and **model list** (right), with models shown as `CODE : Name`.
- The **title bar** shows the version and the model count (e.g. `Realme : 35 model(s)` or `3 result(s) for "RMX35"`).
- The last selected brand/model and the window size and position are remembered.

### MAIN 2 — opened by Next (`Main2Form.pas` / `Main2Form.dfm`)

Laid out to match the MAIN 2 reference screenshot:

- **Toolbar:** menu (left), a **Platform** selector (MediaTek, Unisoc/Spreadtrum, Qualcomm, Samsung or Generic), then on the right:
  - **settings**
  - **Facebook**
  - **help**: version, build and shortcuts
  - **change device**: back to MAIN 1
  - **save log**
  - **start**: runs the first job of the open tab
- **Presets** box.
- **Files** box: **SCAT**, **AUTH**, **BIN**, **OFP**, **BL**, **AP**, **CP**, **CSC**, **USER**. BIN only turns on when *Advanced write* is ticked.
- **Log**: fixed-width font with colours, as in the screenshot: green `OK`, blue values, red `error(...)`. Right-click the log for *Copy*, *Copy all*, *Select all*, *Save* and *Clear*. **Ctrl+C** and **Ctrl+A** also work.
- **Progress** percentage under the log.
- **Jobs** tab:
  - *Connections*: download agent, BROM/Preloader authorization, Force BROM, Read EMI, Read Phone Info, USB speed and battery.
  - *Storage*: one region list (`EMMC(USER) || UFS(LU2)`, …).
- **Flash** tab: mode, **Write Firmware**, **Restore from backup**, *Advanced write* with a 64-bit start address, **Write BIN** and **Write OFP**.
  - Write Firmware takes either a SCAT file (MediaTek) or BL/AP/CP/CSC/USER files (Samsung).
- **Read** tab: **Read Flash Info**, **Read Partitions**, *Address 0x* / *Size 0x*, **Read BIN**, **Read Region** and **Read OTP**.
- The top-level **META** service tab follows the selected platform: it changes to **DIAG** for Unisoc/Spreadtrum and Qualcomm, **DOWNLOAD** for Samsung, and **SERVICE** for Generic. MediaTek keeps **META**. The selector also changes the connection profile and the choices/help text in **Format**, **Service**, and **RPMB**; it is remembered with the job settings.
- **Format**: platform-specific mode and target, optional custom address/size range, and a checked-by-default option to preserve calibration/NV data.
- **Service**: platform-specific service-mode actions and log detail option.
- **RPMB**: platform-specific information/counter/backup choices with eMMC/UFS target selection. RPMB key-write/erase controls are intentionally not exposed.
- **IMEI** and **Locks** remain informational placeholders.
- **Device state** (bottom-right): see *USB detection* below.
- **Esc** goes back to MAIN 1.

Address boxes use the `00000000  00000000` format (high and low 32 bits of a 64-bit hex value). Spaces are ignored.

> **Device communication is not implemented.** The action buttons (including Format, Service and RPMB) validate applicable inputs and write the chosen profile/options to the log, ending with `error(NOT_IMPLEMENTED)`. Nothing is sent to a phone, and no format/read/write action is performed.

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

The app has a built-in starter list. The Realme entries match the reference screenshot; the other brands contain sample entries only. To use your own list:

1. In MAIN 1, choose **Menu > Export models.csv…** and save it next to the EXE.
2. Edit it in Notepad or Excel. Each line is `Brand,Model code,Name`, for example `Realme,RMX3511,Realme C35`. Lines starting with `#` are comments. `;` or a tab also work as the separator.
3. Choose **Menu > Reload models**, or restart the app.

When `models.csv` is next to the EXE it **replaces** the built-in list. Delete the file to go back to the built-in list.

## Delphi project

Open [`Delphi/DeviceSetup/DeviceSetup.dproj`](Delphi/DeviceSetup/DeviceSetup.dproj) in RAD Studio. The project targets both **Win32** and **Win64** (`TargetedPlatforms=3`). The icon (`DeviceSetup.ico`), version info and DPI awareness are set in the project files. The version number is `CAppVersion` in `AppInfo.pas`.

Toolbar icons and button glyphs are drawn in code (`ToolbarIcons.pas`). The only image file is the app icon, which is generated by `tools/make_icon.py`.

| Unit | What it does |
| --- | --- |
| `MainForm` / `Main2Form` | the two screens |
| `DeviceCatalog` | built-in model list and `models.csv` loading/export |
| `AppInfo` | version, data folder, settings file (`DeviceSetup.ini`), options |
| `LogView` | colour codes and drawing for the log |
| `UsbDetect` | read-only USB service-mode detection (SetupAPI) |
| `SettingsDialog` | the Settings window (built in code) |
| `SelfTest` | `DeviceSetup.exe --selftest`, used by CI |
| `ToolbarIcons` | vector-drawn icons and glyphs |

## CI build (fast, free)

`.github/workflows/build-fast.yml` runs on pushes to `main`, on `v*` tags, on every pull request, and manually. It runs on GitHub-hosted Windows runners and builds Win32 and Win64 in parallel with **Lazarus 4.4 / Free Pascal 3.2.2**, which is cached after the first run. Each job:

1. Generates the `.lfm` forms from the `.dfm` files (`tools/dfm2lfm.py`). Edit only the `.dfm` files.
2. Stamps the commit id into `BuildInfo.inc`, which is shown in Help.
3. Compiles.
4. Runs **`DeviceSetup.exe --selftest`**, which:
   - opens both screens (this catches form-loading errors that the compiler cannot see)
   - checks hex parsing, file checks, the `models.csv` round trip, search and the SetupAPI calls
   - takes screenshots of MAIN 1 and MAIN 2 (Flash, Read, Format, Service, RPMB and Unisoc DIAG views)

   The results and PNG screenshots are uploaded as `DeviceSetup-selftest-<platform>-<sha>`. The self-test result is also shown as a notice on the run page.

   **Screenshots of every screen are also published as check runs** (named `ci-shot <screen> <n>/<m>`, base64 GIF chunks) so the UI can be reviewed through the GitHub API without downloading artifacts. This happens on every **pull request**, when you start the workflow by hand (**Actions > Build EXEs (fast) > Run workflow**) and tick *screenshots*, and for any commit that contains the marker file `.github/ci-screenshots`.
5. Uploads the EXE.
6. On `main` or a `v*` tag, publishes the GitHub Release.

To build locally with Lazarus: `python tools/dfm2lfm.py`, then `lazbuild DeviceSetup.lpi`.

### Optional: Delphi build

`.github/workflows/build-delphi.yml` builds with real Delphi but is **manual only**. It needs:

- a self-hosted Windows x64 runner labelled `delphi`, with RAD Studio installed
- the repository variable `DELPHI_STUDIO_DIR`, set to the RAD Studio root folder

The Delphi build is not tested in CI. Only the Lazarus build is.
