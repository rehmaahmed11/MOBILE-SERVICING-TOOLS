"""Generate Lazarus .lfm form files from the Delphi .dfm files.

The .dfm files are the single source of truth. This strips the few
Delphi-only properties that the LCL streaming system does not know.
Usage: python tools/dfm2lfm.py   (run from src/DeviceSetup)
"""
import pathlib
import re

DELPHI_ONLY = re.compile(r"^\s*(OldCreateOrder|TextHeight|StyleElements|ExplicitLeft|"
                         r"ExplicitTop|ExplicitWidth|ExplicitHeight)\s*=")

root = pathlib.Path(__file__).resolve().parent.parent
for dfm in sorted(root.glob("*.dfm")):
    lines = dfm.read_text(encoding="utf-8").splitlines()
    out = [line for line in lines if not DELPHI_ONLY.match(line)]
    lfm = dfm.with_suffix(".lfm")
    lfm.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"{dfm.name} -> {lfm.name} ({len(lines) - len(out)} Delphi-only lines removed)")
