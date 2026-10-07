#!/usr/bin/env python3
"""Assemble a portable Windows app bundle with the checked-in support tree.

The native executable is built separately by Lazarus or Delphi. This script
verifies the tracked support payloads against their SHA-256 inventory, then
copies the complete ``FULL APP STRUCTURE/MOBILO TOOLZ`` tree next to the EXE.
It uses only Python's standard library.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
import zipfile

REPO_ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = REPO_ROOT / "FULL APP STRUCTURE" / "MOBILO TOOLZ"
MANIFEST_PATH = ASSET_ROOT / "assets-manifest.json"
MANIFEST_SCHEMA = 1


def iter_manifested_files(root: Path):
    """Yield regular package files, excluding empty Git directory markers."""
    for path in sorted(root.rglob("*"), key=lambda item: item.relative_to(root).as_posix().casefold()):
        if path.is_file() and path.name != ".gitkeep" and path != MANIFEST_PATH:
            yield path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def verify_asset_manifest() -> list[dict[str, object]]:
    """Check exact paths, lengths, and hashes; return verified file entries."""
    if not ASSET_ROOT.is_dir():
        raise ValueError(f"support tree is missing: {ASSET_ROOT}")
    if not MANIFEST_PATH.is_file():
        raise ValueError(f"support manifest is missing: {MANIFEST_PATH}")

    try:
        document = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read support manifest: {exc}") from exc
    if document.get("schema_version") != MANIFEST_SCHEMA:
        raise ValueError("unsupported support manifest schema")

    expected_entries = document.get("files")
    if not isinstance(expected_entries, list):
        raise ValueError("support manifest must contain a files array")

    expected: dict[str, dict[str, object]] = {}
    for entry in expected_entries:
        if not isinstance(entry, dict):
            raise ValueError("support manifest contains a malformed file entry")
        relative = entry.get("path")
        if not isinstance(relative, str) or not relative or relative in expected:
            raise ValueError(f"invalid or duplicate path in support manifest: {relative!r}")
        # Manifests use portable relative paths and may never escape the support tree.
        posix_path = Path(relative)
        if posix_path.is_absolute() or ".." in posix_path.parts or "\\" in relative:
            raise ValueError(f"unsafe manifest path: {relative!r}")
        expected[relative] = entry

    actual_paths = {
        path.relative_to(ASSET_ROOT).as_posix(): path
        for path in iter_manifested_files(ASSET_ROOT)
    }
    if set(actual_paths) != set(expected):
        missing = sorted(set(expected) - set(actual_paths))
        unlisted = sorted(set(actual_paths) - set(expected))
        details = []
        if missing:
            details.append("missing=" + ", ".join(missing[:8]))
        if unlisted:
            details.append("unlisted=" + ", ".join(unlisted[:8]))
        raise ValueError("support manifest does not match the tree (" + "; ".join(details) + ")")

    verified: list[dict[str, object]] = []
    for relative in sorted(expected, key=str.casefold):
        path = actual_paths[relative]
        entry = expected[relative]
        expected_size = entry.get("size_bytes")
        expected_hash = entry.get("sha256")
        if not isinstance(expected_size, int) or expected_size < 0:
            raise ValueError(f"invalid size in support manifest for {relative}")
        if not isinstance(expected_hash, str) or len(expected_hash) != 64:
            raise ValueError(f"invalid SHA-256 in support manifest for {relative}")
        actual_size = path.stat().st_size
        if actual_size != expected_size:
            raise ValueError(
                f"size mismatch for {relative}: expected {expected_size}, got {actual_size}"
            )
        actual_hash = sha256_file(path)
        if actual_hash.casefold() != expected_hash.casefold():
            raise ValueError(f"SHA-256 mismatch for {relative}")
        verified.append(entry)
    return verified


def copy_bundle(exe_path: Path, output_dir: Path) -> None:
    if not exe_path.is_file():
        raise ValueError(f"Windows executable not found: {exe_path}")
    if output_dir.exists() and any(output_dir.iterdir()):
        raise ValueError(f"output directory must be empty: {output_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    # Keep the supplied support tree intact, including Data, DLLs, and the
    # architecture-specific libusb subfolders. The app resolves Data/DA next
    # to the executable at runtime.
    for item in ASSET_ROOT.iterdir():
        destination = output_dir / item.name
        if item.is_dir():
            shutil.copytree(item, destination, dirs_exist_ok=True)
        else:
            shutil.copy2(item, destination)
    shutil.copy2(exe_path, output_dir / "DeviceSetup.exe")


def write_archive(bundle_dir: Path, archive_path: Path) -> None:
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    if archive_path.exists():
        raise ValueError(f"archive already exists: {archive_path}")
    try:
        archive_path.resolve().relative_to(bundle_dir.resolve())
    except ValueError:
        pass
    else:
        raise ValueError("archive path must be outside the bundle directory")
    with zipfile.ZipFile(
        archive_path, mode="w", compression=zipfile.ZIP_DEFLATED, compresslevel=6
    ) as archive:
        for path in sorted(bundle_dir.rglob("*"), key=lambda item: item.as_posix().casefold()):
            if path.is_file():
                archive.write(path, path.relative_to(bundle_dir).as_posix())


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-only", action="store_true", help="verify the checked-in support tree")
    parser.add_argument("--exe", type=Path, help="compiled DeviceSetup.exe to include")
    parser.add_argument("--output", type=Path, help="new/empty portable bundle directory")
    parser.add_argument("--archive", type=Path, help="optional ZIP to create from the bundle directory")
    args = parser.parse_args(argv)

    try:
        entries = verify_asset_manifest()
        if args.verify_only:
            if args.exe or args.output or args.archive:
                parser.error("--verify-only cannot be combined with packaging arguments")
            print(f"Verified {len(entries)} support files from {ASSET_ROOT}")
            return 0
        if not args.exe or not args.output:
            parser.error("--exe and --output are required unless --verify-only is used")
        exe_path = args.exe if args.exe.is_absolute() else (Path.cwd() / args.exe)
        output_dir = args.output if args.output.is_absolute() else (Path.cwd() / args.output)
        copy_bundle(exe_path, output_dir)
        if args.archive:
            archive_path = args.archive if args.archive.is_absolute() else (Path.cwd() / args.archive)
            write_archive(output_dir, archive_path)
        print(f"Packaged {len(entries)} verified support files with {exe_path.name} into {output_dir}")
        if args.archive:
            print(f"Created portable bundle: {archive_path}")
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(f"package error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
