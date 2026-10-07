"""Package the committed UI BMPs in a Delphi/FPC-compatible Win32 .res.

Standard library only; no resource compiler, Pillow or external files are
needed to build/run the app. The small .res is committed intentionally so a
normal RAD Studio build works without Python. CI checks it is up to date.
"""
import argparse
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "sample-ui"
TARGET = ROOT / "SampleAssets.res"


def aligned(data):
    return data + b"\0" * (-len(data) % 4)


def resource(name, data, kind=2):
    # TYPE = ordinal RT_BITMAP, NAME = UTF-16 string (or ordinal for the
    # standard empty resource-file header). Bitmap payloads omit BITMAPFILEHEADER.
    identifiers = struct.pack("<HH", 0xFFFF, kind)
    identifiers += (struct.pack("<HH", 0xFFFF, name) if isinstance(name, int)
                    else (name + "\0").encode("utf-16-le"))
    identifiers = aligned(identifiers)
    # The empty first entry must match the standard 32-byte Win32 .res
    # signature exactly; FPC detects the file format from these bytes.
    flags = 0 if kind == 0 else 0x1030
    tail = struct.pack("<IHHII", 0, flags, 0, 0, 0)
    header_size = 8 + len(identifiers) + len(tail)
    return (struct.pack("<II", len(data), header_size) + identifiers + tail +
            aligned(data))


def build():
    manifest = json.loads((ASSETS / "manifest.json").read_text())
    result = resource(0, b"", kind=0)
    for name in sorted(manifest):
        data = (ASSETS / (name.lower() + ".bmp")).read_bytes()
        if data[:2] != b"BM" or struct.unpack_from("<I", data, 14)[0] != 40:
            raise ValueError(f"{name}: expected an uncompressed Windows BMP")
        result += resource(name, data[14:])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = build()
    if args.check:
        if not TARGET.exists() or TARGET.read_bytes() != data:
            raise SystemExit("SampleAssets.res is stale; run tools/make_ui_resources.py")
        print(f"SampleAssets.res is up to date ({len(data):,} bytes)")
    else:
        TARGET.write_bytes(data)
        print(f"Wrote {TARGET.name} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
