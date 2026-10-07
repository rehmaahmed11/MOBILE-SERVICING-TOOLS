# Mobile Servicing Tools — Device Setup

A native **Delphi VCL** Windows application (it also builds with the free
Lazarus / Free Pascal compiler, which is what produces the EXE artifacts).

## Screens

### MAIN 1 — first screen (`MainForm.pas` / `MainForm.dfm`)

Laid out to match the MAIN 1 reference screenshot:

- **Blue menu icon** (top-left): opens a menu with the live **device status**,
  *Next*, *Save model list…*, *Reload model list*, *Open model data folder…*
  and *Exit*.
- **Green play icon** (top-right) = **Next**: opens MAIN 2 for the selected model. It is greyed out until a model is selected. Double-clicking a model or pressing **Enter** on it does the same.
- **Orange arrow icon** (top-right): saves the model list currently shown to a `.txt` file.
- **Quick search** box: type to search all brands. Every word of the query has to appear somewhere in the model code (e.g. `RMX3511`), the model name or the brand, so `note 11` finds *Redmi Note 11* and `realme c35` finds the model whichever way round it is typed. Clear the box or press **Esc** to go back to the brand's list.
- **Brand list** (left) and **model list** (right), with models shown as `CODE : Name`, e.g. `RMX3382 : Realme 8s 5G`. The last brand and model used are selected again on the next start; on a first run that is Realme.

### MAIN 2 — opened by Next (`Main2Form.pas` / `Main2Form.dfm`)

Laid out to match the MAIN 2 reference screenshot:

- **Toolbar:**
  - **Menu** (left): *Save preset…*, *Delete preset…*, *Change device*, *Save log*, *Clear log*, *Open log folder…*, *Exit*.
  - Right side, in order:
    - **green play**: runs *Write Firmware*. It is drawn grey until a SCAT file has been chosen.
    - **orange arrow**: saves the log
    - **phone**: changes device (back to MAIN 1)
    - **gear**: shows where this build keeps its settings, log and model data
    - **Facebook**
    - **help**
- **Left side:** *Presets*. *Files* has **SCAT**, **AUTH**, **BIN** and **OFP** browse buttons with path boxes; BIN only turns on when *Advanced write* is ticked. Below that are the *Log* and the red progress bar.
- **Right side:**
  - **Jobs** tab:
    - *Connections* group: download agent `MTK_AllInOne_DA.bin`, BROM/Preloader authorization, Force BROM, Read EMI and Read Phone Info, plus USB speed and battery.
    - *Storage* group: type, and a region list that changes with the type.
    - **Flash** tab: *Options* group with the mode list, **Write Firmware**, **Restore from backup**, *Advanced write* with a start/length hex address, **Write BIN** and **Write OFP**.
  - **META**, **Read**, **Format**, **IMEI**, **Locks**, **Service** and **RPMB** tabs: placeholders for now.
  - Device status phone icon (bottom-right) — **live**, see below.
- **Esc** or the phone icon goes back to MAIN 1.

> **Device communication is not implemented.** The action buttons check their inputs (the file is chosen and exists, the address is valid hex) and write the job details to the log. They do not talk to a phone. What *is* real is device **detection** — see below.

Toolbar icons and button glyphs are drawn in code (`ToolbarIcons.pas`), so the project needs no image resources. The icons are drawn in a fixed design space and mapped onto whatever rectangle they get, so they stay correct when Windows scales the form for a high-DPI monitor.

## What the app really does (beyond the reference screens)

### 1. Detects the phone on the USB bus (`DeviceWatch.pas`)

Both screens run a watcher that enumerates the USB devices that are present
**right now** (SetupAPI with `DIGCF_PRESENT`, polled every 1.5 s) and recognises
the ones that matter for servicing:

| Detected as | Typical VID:PID |
| --- | --- |
| MediaTek BROM (download mode) | `0E8D:0003` |
| MediaTek Preloader (VCOM) | `0E8D:2000` |
| MediaTek META / DA port | `0E8D:2001`, `0E8D:2004` |
| Qualcomm EDL 9008 | `05C6:9008` |
| Unisoc / Spreadtrum | `1782:xxxx` |
| Samsung download mode (Odin) | `04E8:685D` |
| Android ADB / fastboot | `18D1:4EE7`, `18D1:D00D`, … |

Devices from other phone vendors (Xiaomi, Oppo/Realme, OnePlus, Vivo, Huawei,
Infinix/Tecno, ZTE, Nokia/HMD, Asus, Rockchip, Allwinner…) are recognised by
vendor plus what Windows calls the device, and the COM port Windows assigned is
read out of the friendly name.

- On MAIN 2 the phone icon at the bottom right turns **green** when something is
  detected, and its hint shows e.g. `MediaTek BROM (download mode) (0E8D:0003) on COM7`.
- Every arrival and removal is written to the log.
- On MAIN 1 the current device is shown as the first (disabled) line of the menu.

Nothing is ever sent to the device — this is pure enumeration, so it is safe to
leave running.

### 2. Remembers the job (`AppSettings.pas`)

All of the MAIN 2 options — the SCAT/AUTH/BIN/OFP paths, download agent,
authorization and BROM checkboxes, USB speed, battery, storage type and region,
flash mode, advanced-write address — plus the last brand and model from MAIN 1
and the last folder used by the file dialogs, are stored in

```
%APPDATA%\MobileServicingTools\settings.ini
```

so the app can be run from Downloads, a USB stick or a read-only share and still
come back exactly as it was left. Closing MAIN 2, pressing Esc and exiting all
save first.

### 3. Presets work

The **Presets** combo at the top left of MAIN 2 is live. Save the current job
with *menu → Save preset…* (give it a name, e.g. `Realme C35 - download only`),
pick a preset from the combo to load it, and delete it with
*menu → Delete preset…*. Presets live in the same `settings.ini`.

### 4. The log is timestamped and written to disk

Every line is prefixed with `[hh:nn:ss]` and copied to

```
%APPDATA%\MobileServicingTools\logs\<yyyymmdd>.txt
```

which gives a service centre an audit trail even when the on-screen log is
cleared. *Menu → Open log folder…* opens it, *Save log…* exports the screen log
with a suggested name such as `RMX3511 log 20261007-1423.txt`.

Unexpected errors are written to `logs\error-<timestamp>.txt` and reported in a
dialog instead of a raw Windows error (`Application.OnException`).

### 5. The model list can be edited without rebuilding (`DeviceCatalog.pas`)

The built-in catalog is starter data. On top of it the app reads plain text
files from a **Data** folder, either next to the EXE or in
`%APPDATA%\MobileServicingTools\Data`:

```
Data\Realme.txt      one model per line:   RMX3511 : Realme C35
Data\models.txt      several brands:       Realme|RMX3511 : Realme C35
                                           (or Realme|RMX3511|Realme C35)
```

- A file named after a brand **replaces** that brand's built-in list, so your
  own data always wins. Any other name adds a new brand.
- Blank lines and `#` or `;` comments are skipped, UTF-8 is supported.
- Brands are listed in case-insensitive alphabetical order.
- Press **Ctrl+R** on MAIN 1 (or use *menu → Reload model list*) to re-read the
  Data folders without restarting. The menu line shows how many brands and
  models are loaded and how many data files were merged.
- [`Delphi/DeviceSetup/Sample Data/models.txt`](Delphi/DeviceSetup/Sample%20Data/models.txt)
  is a ready-to-copy example.

## Delphi project

Open [`Delphi/DeviceSetup/DeviceSetup.dproj`](Delphi/DeviceSetup/DeviceSetup.dproj) in RAD Studio. The project targets both **Win32 (32-bit)** and **Win64 (64-bit)** (`TargetedPlatforms=3`); select the desired target platform in the IDE and build it separately.

Units:

| Unit | Role |
| --- | --- |
| `MainForm.pas` | MAIN 1 |
| `Main2Form.pas` | MAIN 2 |
| `DeviceCatalog.pas` | built-in + Data-folder brand/model catalog |
| `DeviceWatch.pas` | USB device detection |
| `AppSettings.pas` | folders, `settings.ini`, log and error files |
| `ToolbarIcons.pas` | vector-drawn toolbar icons and button glyphs |

`DeviceSetup.exe /selftest` (used by the build pipeline) creates both forms, checks the catalog and exits with 0, or 1 after writing `logs\error-<timestamp>.txt`.

`DeviceCatalog.pas` holds an in-memory starter catalog. The Realme entries match the reference screenshot. The other brands contain sample entries only: check them before production use, or replace them with your own Data files as described above.

## EXE artifacts (fast build)

`.github/workflows/build-fast.yml` runs on every push to `main` (including merged pull requests), on every pull request, and manually. It runs on **GitHub-hosted Windows runners**, so no self-hosted runner is needed. It compiles the app with the free **Lazarus 4.4 / Free Pascal 3.2.2** compiler, building Win32 and Win64 in parallel:

- First run: about 2–3 minutes, because it installs Lazarus.
- Later runs: Lazarus comes from the cache, so the job only compiles.

Each build is verified before it is uploaded:

1. **Compile** — Win32 and Win64.
2. **Self test** — `DeviceSetup.exe /selftest` builds MAIN 1 *and* MAIN 2, checks that the catalog loaded and that MAIN 2 accepted the device, then exits 0. A form-streaming problem (a component in the `.dfm`/`.lfm` that does not match the form class) is invisible to the compiler, so this is what catches it. On failure the error report from the log folder is printed as a build annotation.
3. **Smoke test** — the app is launched normally and must still be running 10 seconds later, then it is closed.

Download the EXEs from the run's **Artifacts** section:

- `DeviceSetup-Win64-<sha>` → `DeviceSetup-Win64.exe`
- `DeviceSetup-Win32-<sha>` → `DeviceSetup-Win32.exe`

Artifacts are kept for 30 days.

The same `.pas` units compile under Delphi and Lazarus (`{$IFDEF FPC}` blocks in the `uses` clauses):

- **Delphi / RAD Studio:** `DeviceSetup.dproj` + `DeviceSetup.dpr`, forms in `.dfm`.
- **Lazarus:** `DeviceSetup.lpi` + `DeviceSetup.lpr`. The `.lfm` forms are generated from the `.dfm` files by `tools/dfm2lfm.py`; edit only the `.dfm`. To build locally, run `python tools/dfm2lfm.py`, then `lazbuild DeviceSetup.lpi`.

### Optional: Delphi build

`.github/workflows/build-delphi.yml` builds with real Delphi but is **manual only**. It needs a self-hosted Windows x64 runner labelled `delphi`, with RAD Studio and both compilers installed. It also needs the repository variable `DELPHI_STUDIO_DIR`, set to the RAD Studio root folder (the one containing `bin\rsvars.bat`). Without that runner the job only waits in the queue, which is why it no longer runs automatically.

## Not done yet

- No writing, reading, formatting, IMEI, lock, service or RPMB operations — the
  tabs are placeholders and the buttons only log the job.
- No settings dialog (the gear shows the file locations), no app icon or version
  resource, no DPI-aware manifest, no per-monitor DPI scaling.
- The progress bar does not move because no job runs yet.
- The built-in catalog outside Realme is sample data.
