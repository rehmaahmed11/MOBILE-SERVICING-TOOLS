#!/usr/bin/env python3
"""Build the Windows setup EXE from the verified portable app bundle.

Run from any directory after package_app.py has assembled
``artifacts/package``. Inno Setup 6's ISCC compiler is the only extra tool.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys

from package_app import verify_asset_manifest, verify_bundle

DEVICE_SETUP_DIR = Path(__file__).resolve().parents[1]
PROJECT_FILE = DEVICE_SETUP_DIR / "DeviceSetup.iss"
APP_INFO_FILE = DEVICE_SETUP_DIR / "AppInfo.pas"
DEFAULT_BUNDLE_DIR = DEVICE_SETUP_DIR / "artifacts" / "package"
DEFAULT_OUTPUT_DIR = DEVICE_SETUP_DIR / "artifacts"


def app_version() -> str:
    """Read CAppVersion so the installer and application stay in sync."""
    text = APP_INFO_FILE.read_text(encoding="utf-8")
    match = re.search(r"^\s*CAppVersion\s*=\s*'([^']+)'\s*;", text, re.MULTILINE)
    if not match:
        raise ValueError(f"could not find CAppVersion in {APP_INFO_FILE}")
    return match.group(1)


def resolve_iscc(value: str) -> str:
    candidate = Path(value)
    if candidate.is_file():
        return str(candidate.resolve())
    discovered = shutil.which(value)
    if discovered:
        return discovered
    raise ValueError(f"Inno Setup compiler not found: {value}")


def build_installer(iscc: str, platform: str, output_dir: Path) -> Path:
    if platform not in {"Win32", "Win64"}:
        raise ValueError(f"unsupported platform: {platform}")
    if not PROJECT_FILE.is_file():
        raise ValueError(f"Inno Setup project is missing: {PROJECT_FILE}")

    entries = verify_asset_manifest()
    verify_bundle(DEFAULT_BUNDLE_DIR, entries)

    output_dir.mkdir(parents=True, exist_ok=True)
    platform_64 = "1" if platform == "Win64" else "0"
    command = [
        iscc,
        f"/DAppPlatform64={platform_64}",
        f"/DAppVersion={app_version()}",
        f"/O{output_dir.resolve()}",
        str(PROJECT_FILE),
    ]
    completed = subprocess.run(command, cwd=DEVICE_SETUP_DIR, check=False)
    if completed.returncode:
        raise ValueError(f"ISCC failed with exit code {completed.returncode}")

    installer = output_dir / f"DeviceSetup-Setup-{platform}.exe"
    if not installer.is_file() or installer.stat().st_size == 0:
        raise ValueError(f"ISCC did not produce the expected installer: {installer}")
    return installer


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iscc", default="ISCC.exe", help="path/name of Inno Setup's ISCC compiler")
    parser.add_argument("--platform", choices=("Win32", "Win64"), required=True)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="directory for the generated setup EXE (default: artifacts)",
    )
    args = parser.parse_args(argv)

    try:
        iscc = resolve_iscc(args.iscc)
        output_dir = args.output
        if not output_dir.is_absolute():
            output_dir = Path.cwd() / output_dir
        installer = build_installer(iscc, args.platform, output_dir)
        print(f"Created verified {args.platform} installer: {installer}")
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"installer error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
