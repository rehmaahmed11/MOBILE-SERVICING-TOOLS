# Mobile Servicing Tools — Device Setup

A native **Delphi VCL** Windows application.

## Screens

### MAIN 1 — first screen (`MainForm.pas` / `MainForm.dfm`)

Laid out to match the MAIN 1 reference screenshot:

- **Blue menu icon** (top-left): opens a menu with *Next*, *Save model list…* and *Exit*.
- **Green play icon** (top-right) = **Next**: opens MAIN 2 for the selected model. It is greyed out until a model is selected. Double-clicking a model or pressing **Enter** on it does the same.
- **Orange arrow icon** (top-right): saves the model list currently shown to a `.txt` file.
- **Quick search** box: type to search all brands. Matches can be in the model code (e.g. `RMX3511`), the model name or the brand. Clear the box or press **Esc** to go back to the brand's list.
- **Brand list** (left) and **model list** (right), with models shown as `CODE : Name`, e.g. `RMX3382 : Realme 8s 5G`. Realme is selected when the app starts.

### MAIN 2 — opened by Next (`Main2Form.pas` / `Main2Form.dfm`)

Laid out to match the MAIN 2 reference screenshot:

- **Toolbar:**
  - **Menu** (left): *Change device*, *Save log*, *Clear log*, *Exit*.
  - Right side, in order:
    - **green play**: runs *Write Firmware*
    - **orange arrow**: saves the log
    - **phone**: changes device (back to MAIN 1)
    - **gear**: settings (placeholder)
    - **Facebook**
    - **help**
- **Left side:** *Presets*. *Files* has **SCAT**, **AUTH**, **BIN** and **OFP** browse buttons with path boxes; BIN only turns on when *Advanced write* is ticked. Below that are the *Log* and the red progress bar.
- **Right side:**
  - **Jobs** tab:
    - *Connections* group: download agent `MTK_AllInOne_DA.bin`, BROM/Preloader authorization, Force BROM, Read EMI and Read Phone Info, plus USB speed and battery.
    - *Storage* group: type, and a region list that changes with the type.
    - **Flash** tab: *Options* group with the mode list, **Write Firmware**, **Restore from backup**, *Advanced write* with a start/length hex address, **Write BIN** and **Write OFP**.
  - **META**, **Read**, **Format**, **IMEI**, **Locks**, **Service** and **RPMB** tabs: placeholders for now.
  - Device status phone icon (bottom-right).
- **Esc** or the phone icon goes back to MAIN 1.

> **Device communication is not implemented.** The action buttons check their inputs (the file is chosen and exists, the address is valid hex) and write the job details to the log. They do not talk to a phone.

Toolbar icons and button glyphs are drawn in code (`ToolbarIcons.pas`), so the project needs no image resources.

## Delphi project

Open [`Delphi/DeviceSetup/DeviceSetup.dproj`](Delphi/DeviceSetup/DeviceSetup.dproj) in RAD Studio. The project targets both **Win32 (32-bit)** and **Win64 (64-bit)** (`TargetedPlatforms=3`); select the desired target platform in the IDE and build it separately.

`DeviceCatalog.pas` holds an in-memory starter catalog. The Realme entries match the reference screenshot. The other brands contain sample entries only: check them before production use, or replace the catalog with a real data source.

## EXE artifacts on merges

`.github/workflows/build-delphi.yml` runs on every push to `main` (including merged pull requests) and can also be started manually. It builds **Release Win32 and Win64** executables, then uploads them together as the `DeviceSetup-<commit SHA>` Actions artifact for 30 days. Download it from the workflow run's **Artifacts** section; it contains `DeviceSetup-Win32.exe` and `DeviceSetup-Win64.exe`.

Delphi/RAD Studio is not installed on GitHub-hosted Windows runners, so this workflow requires a **self-hosted Windows x64 runner** with the Delphi installation and both target compilers installed. Add the custom runner label `delphi`. In **Settings → Secrets and variables → Actions → Variables**, add `DELPHI_STUDIO_DIR` with the RAD Studio installation root (the folder containing `bin\rsvars.bat`, for example `C:\Program Files (x86)\Embarcadero\Studio\23.0`). The runner must be online when the workflow runs.
