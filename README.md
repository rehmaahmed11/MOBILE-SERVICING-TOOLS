# Mobile Servicing Tools — Device Setup

The first screen is implemented as a native **Delphi VCL** Windows application. It presents phone brands and their models side by side; selecting a brand refreshes the model list, and the **Next** button becomes available after a model is selected.

## Delphi project

Open [`Delphi/DeviceSetup/DeviceSetup.dproj`](Delphi/DeviceSetup/DeviceSetup.dproj) in RAD Studio. The project targets both **Win32 (32-bit)** and **Win64 (64-bit)** (`TargetedPlatforms=3`); select the desired target platform in the IDE and build it separately. The matching Delphi compiler/platform support must be installed.

## Current scope

- Brand/model selection screen only — the next workflow screen is intentionally left for the next stage.
- The **Next** button confirms the selection and explains that the next screen is not part of this stage.
- `DeviceCatalog.pas` contains a small in-memory starter catalog for Nokia, Samsung, Google Pixel, Lenovo, and Motorola. This is demo data, not a database or backend; it can be replaced with a service/data source later.

The VCL source and form can be found in `Delphi/DeviceSetup/` (`MainForm.pas` and `MainForm.dfm`).

## EXE artifacts on merges

`.github/workflows/build-delphi.yml` runs on every push to `main` (including merged pull requests) and can also be started manually. It builds **Release Win32 and Win64** executables, then uploads them together as the `DeviceSetup-<commit SHA>` Actions artifact for 30 days. Download it from the workflow run's **Artifacts** section; it contains `DeviceSetup-Win32.exe` and `DeviceSetup-Win64.exe`.

Delphi/RAD Studio is not installed on GitHub-hosted Windows runners, so this workflow requires a **self-hosted Windows x64 runner** with the Delphi installation and both target compilers installed. Add the custom runner label `delphi`. In **Settings → Secrets and variables → Actions → Variables**, add `DELPHI_STUDIO_DIR` with the RAD Studio installation root (the folder containing `bin\rsvars.bat`, for example `C:\Program Files (x86)\Embarcadero\Studio\23.0`). The runner must be online when the workflow runs.
