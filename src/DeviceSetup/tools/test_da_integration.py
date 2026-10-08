"""Contracts for the support payloads, portable tree, and installer layout.

Run with ``python tools/test_da_integration.py``. The SHA-256 inventory is
checked against every non-empty support file; hashes establish file identity,
not vendor authenticity or model compatibility.
"""
import configparser
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

TOOLS_DIR = Path(__file__).resolve().parent
DEVICE_SETUP_DIR = TOOLS_DIR.parent
REPO_ROOT = DEVICE_SETUP_DIR.parents[1]
ASSET_ROOT = REPO_ROOT / "data" / "support" / "MOBILO TOOLZ"
DATA_ROOT = ASSET_ROOT / "Data"
DA_ROOT = DATA_ROOT / "DA"

sys.path.insert(0, str(TOOLS_DIR))
from package_app import (  # noqa: E402
    copy_bundle,
    verify_asset_manifest,
    verify_bundle,
    write_archive,
)


class RealDataIntegrationTests(unittest.TestCase):
    def test_manifest_covers_and_verifies_the_complete_support_tree(self):
        entries = verify_asset_manifest()
        paths = {entry["path"] for entry in entries}
        self.assertGreaterEqual(len(entries), 80)
        self.assertIn("Data/DA/models_map.ini", paths)
        self.assertIn("Data/FDL1", paths)
        self.assertIn("Data/FDL2", paths)
        self.assertIn("7z.dll", paths)
        self.assertIn("AdbWinApi.dll", paths)
        self.assertIn("libusb/amd64/libusb0.dll", paths)
        self.assertIn("libusb/arm64/libusb0.dll", paths)
        self.assertIn("libusb/x86/libusb0_x86.dll", paths)

    def test_portable_zip_contains_every_verified_asset_and_the_executable(self):
        entries = verify_asset_manifest()
        with tempfile.TemporaryDirectory(prefix="device-setup-package-") as temp_dir:
            temp = Path(temp_dir)
            exe = temp / "source.exe"
            exe.write_bytes(b"MZ portable bundle packaging test")
            bundle = temp / "bundle"
            archive = temp / "DeviceSetup.zip"

            copy_bundle(exe, bundle)
            self.assertEqual(verify_bundle(bundle, entries), len(entries))
            write_archive(bundle, archive)

            with zipfile.ZipFile(archive) as package:
                names = set(package.namelist())
                self.assertIn("DeviceSetup.exe", names)
                self.assertIn("assets-manifest.json", names)
                self.assertTrue(
                    {entry["path"] for entry in entries} <= names,
                    "portable ZIP must contain every file verified by the asset manifest",
                )
                for relative in ("Data/DA/OPPO.da", "Data/FDL1", "Data/FDL2"):
                    with self.subTest(asset=relative):
                        self.assertEqual(
                            package.getinfo(relative).file_size,
                            (ASSET_ROOT / relative).stat().st_size,
                        )

    def test_installer_places_the_complete_bundle_at_the_selected_app_root(self):
        script = (DEVICE_SETUP_DIR / "DeviceSetup.iss").read_text(encoding="utf-8")
        normalized = " ".join(script.replace("\\", "/").split()).casefold()
        self.assertIn(
            'source: "../../artifacts/package/*"; destdir: "{app}"; '
            'flags: ignoreversion recursesubdirs createallsubdirs',
            normalized,
        )
        self.assertIn("outputdir=../../artifacts", normalized)
        self.assertIn(
            r'defaultdirname={localappdata}/programs/mobile servicing tools',
            normalized,
        )
        self.assertIn("privilegesrequired=lowest", normalized)
        self.assertIn("#ifdef appplatform64", normalized)
        self.assertIn("architecturesallowed=x64", normalized)
        self.assertIn("architecturesinstallin64bitmode=x64", normalized)
        self.assertIn("outputbasefilename=devicesetup-setup-{#installerplatform}", normalized)
        self.assertIn('name: "{autoprograms}/{#appname}"; filename: "{app}/devicesetup.exe"', normalized)

        # This tree becomes {app} itself; therefore the app stays in the root,
        # with DA/FDL beneath Data and the supplied USB library beneath libusb.
        for relative in (
            "Data/DA/OPPO.da",
            "Data/FDL1",
            "Data/FDL2",
            "libusb/x86/libusb0_x86.dll",
            "libusb/amd64/libusb0.dll",
            "libusb/arm64/libusb0.dll",
        ):
            with self.subTest(asset=relative):
                self.assertTrue((ASSET_ROOT / relative).is_file())

    def test_full_size_payloads_replace_the_old_placeholders(self):
        self.assertGreater((DATA_ROOT / "FDL1").stat().st_size, 1_000_000)
        self.assertGreater((DATA_ROOT / "FDL2").stat().st_size, 10_000_000)
        self.assertGreater((DA_ROOT / "OPPO.da").stat().st_size, 5_000_000)
        self.assertGreater((DA_ROOT / "REALME.da").stat().st_size, 4_000_000)
        self.assertGreater((DA_ROOT / "samsung.da").stat().st_size, 15_000_000)
        self.assertGreater((DA_ROOT / "MTK_AllInOne_DA.bin").stat().st_size, 15_000_000)

        for path in DA_ROOT.glob("*.da"):
            with self.subTest(path=path.name):
                with path.open("rb") as source:
                    header = source.read(4096)
                self.assertFalse(header.startswith(b"PK\x03\x04"),
                                 f"{path.name} should be the supplied opaque payload, not a mock ZIP")
                self.assertNotIn(b"MTK_DA_BINARY_CONTENT", header)

        old_data = DEVICE_SETUP_DIR / "data"
        self.assertFalse(any(path.is_file() for path in old_data.rglob("*"))
                         if old_data.exists() else False,
                         "legacy placeholder data must not shadow the real package")

    def test_brand_and_known_model_routes_resolve_to_existing_files(self):
        parser = configparser.ConfigParser(interpolation=None)
        map_path = DA_ROOT / "models_map.ini"
        self.assertTrue(parser.read(map_path, encoding="utf-8"))
        self.assertTrue(parser.has_section("Models"))
        self.assertTrue(parser.has_section("Brands"))
        for brand, file_name in {
            "oppo": "OPPO.da",
            "realme": "REALME.da",
            "samsung": "samsung.da",
            "mediatek": "MTK_AllInOne_DA.bin",
            "tecno": "INFINIX_TECNO.da",
            "huawei": "HUAWEI_HONOR.da",
        }.items():
            with self.subTest(brand=brand):
                self.assertEqual(parser["Brands"][brand].casefold(), file_name.casefold())
                self.assertTrue((DA_ROOT / file_name).is_file())
        self.assertEqual(parser["Models"]["cph1909"], "OPPO.da")
        self.assertEqual(parser["Models"]["rmx3511"], "REALME.da")
        for section in ("Brands", "Models"):
            for route, file_name in parser[section].items():
                with self.subTest(section=section, route=route):
                    self.assertTrue((DA_ROOT / file_name).is_file(),
                                    f"{section} route {route} points to missing {file_name}")

    def test_application_catalogs_opaque_payloads_and_reports_them_honestly(self):
        """The bundled payloads are catalogued byte-for-byte, and the app says
        out loud that an encrypted vendor container cannot be used as a
        download agent instead of quietly pretending it flashed something.

        Device communication is now implemented (JobEngine / DeviceSession /
        BromProtocol / MtkDaLegacy), so the old "error(NOT_IMPLEMENTED)"
        placeholder is gone on purpose. What must survive is the honesty: the
        demo log still labels itself as simulated, and an opaque payload is
        still reported as unusable.
        """
        loader = (DEVICE_SETUP_DIR / "DaLoader.pas").read_text(encoding="utf-8")
        adb_tool = (DEVICE_SETUP_DIR / "AdbTool.pas").read_text(encoding="utf-8")
        main = (DEVICE_SETUP_DIR / "Main2Form.pas").read_text(encoding="utf-8")
        da_image = (DEVICE_SETUP_DIR / "DaImage.pas").read_text(encoding="utf-8")
        engine = (DEVICE_SETUP_DIR / "JobEngine.pas").read_text(encoding="utf-8")
        self.assertIn("'data' + PathDelim", loader)
        self.assertIn("'support' + PathDelim", loader)
        self.assertIn("'MOBILO TOOLZ'", loader)
        self.assertNotIn("FULL APP STRUCTURE", loader)
        self.assertIn("'data' + PathDelim", adb_tool)
        self.assertIn("'support' + PathDelim", adb_tool)
        self.assertIn("'MOBILO TOOLZ' + PathDelim", adb_tool)
        self.assertNotIn("FULL APP STRUCTURE", adb_tool)
        self.assertIn("Candidate := FindDataRootFrom(ExeDir)", loader)
        self.assertIn("FindFileInsensitive(Root, 'FDL1')", loader)
        self.assertIn("FindFileInsensitive(Root, 'FDL2')", loader)
        self.assertIn("AgentFile", loader)
        self.assertIn("IsOpaque", loader)
        self.assertIn("GetBundledDataAssetCount", loader)
        self.assertIn("RefreshAgentSelection", main)
        self.assertIn("ResolveAndExtractDa", main)
        self.assertIn("no phone was queried", main)
        # the placeholder is gone: every action button now starts a real job
        self.assertNotIn("error(NOT_IMPLEMENTED)", main)
        self.assertIn("StartJob(jkWriteFirmware)", main)
        self.assertIn("StartJob(jkReadFlashInfo)", main)
        # an encrypted vendor container is still refused, with a reason
        self.assertIn("Encrypted", da_image)
        self.assertIn("encrypted vendor container", engine)
        # and nothing is ever reported as done that was not done
        self.assertIn("OutcomeFail", engine)

    def test_payload_inventory_has_the_expected_scale(self):
        manifest = (ASSET_ROOT / "assets-manifest.json").read_text(encoding="utf-8")
        self.assertIn('"schema_version": 1', manifest)
        self.assertIn('"sha256"', manifest)
        payloads = [
            path for path in DATA_ROOT.rglob("*")
            if path.is_file() and (
                path.suffix.lower() in {".da", ".bin", ".crp"}
                or path.name.upper() in {"FDL1", "FDL2"}
            )
        ]
        self.assertEqual(len(payloads), 39)
        self.assertGreater(sum(path.stat().st_size for path in payloads), 100 * 1024 * 1024)


class SimulatedStorageReportContractTests(unittest.TestCase):
    """The simulated phone's legacy storage report must be exactly as long as
    the host reads it. A short report shifts every later field and the host
    fails with "Short read ... wanted 10 byte(s), got 2" (seen in CI)."""

    SIM = DEVICE_SETUP_DIR / "SimPort.pas"
    HOST = DEVICE_SETUP_DIR / "MtkDaLegacy.pas"

    @staticmethod
    def _body(text, start_marker, end_marker):
        start = text.index(start_marker)
        end = text.index(end_marker, start)
        return text[start:end]

    @staticmethod
    def _emitted_sections(body):
        """Return [(declared_bytes, emitted_bytes)] for each commented section."""
        import re

        width_rules = [
            (re.compile(r"\bEmitDwordBe\("), 4),
            (re.compile(r"\bEmitQwordBe\("), 8),
            (re.compile(r"\bEmitWordBe\("), 2),
            (re.compile(r"\bEmit\("), 1),
        ]
        repeat = re.compile(r"\bEmitRepeat\(\s*\$00\s*,\s*(\d+)\s*\)")
        loop = re.compile(r"\bfor\s+\w+\s*:=\s*0\s+to\s+(\d+)\s+do")

        def statement_bytes(stmt):
            total = 0
            multiplier = 1
            match = loop.search(stmt)
            if match:
                multiplier = int(match.group(1)) + 1
            for rx in repeat.finditer(stmt):
                total += int(rx.group(1))
            rest = repeat.sub("", stmt)
            for rx, size in width_rules:
                total += len(rx.findall(rest)) * size
            return total * multiplier

        # Only a comment that states a length starts a section; the short
        # inline comments such as "{ boot1 }" are just removed from the code.
        comments = list(re.finditer(r"\{([^}]*)\}", body))
        starts = [c for c in comments if re.search(r"\d+\s+bytes", c.group(1))]
        sections = []
        for index, start in enumerate(starts):
            declared = int(re.search(r"(\d+)\s+bytes", start.group(1)).group(1))
            end = starts[index + 1].start() if index + 1 < len(starts) else len(body)
            code = re.sub(r"\{[^}]*\}", "", body[start.end():end])
            emitted = sum(statement_bytes(part) for part in code.split(";"))
            sections.append((declared, emitted))
        return sections

    def test_each_simulated_section_has_its_declared_length(self):
        body = self._body(
            self.SIM.read_text(encoding="utf-8"),
            "procedure TSimPort.EmitLegacyStorageInfo;",
            "procedure TSimPort.EnterDa;",
        )
        sections = self._emitted_sections(body)
        self.assertEqual(
            [declared for declared, _ in sections],
            [28, 17, 9, 92, 28, 38, 10],
            "the simulated storage report has an unexpected section list",
        )
        for declared, emitted in sections:
            self.assertEqual(emitted, declared, f"simulated section emits {emitted} bytes, expected {declared}")

    def test_simulated_sections_match_the_host_reader(self):
        import re

        host = self._body(
            self.HOST.read_text(encoding="utf-8"),
            "function TMtkDaLegacy.ParseLegacyInfo(ALastBlock: Boolean): Boolean;",
            "{ ------------------------------------------------------------------ bring-up }",
        )
        # The one read whose length is not a literal is the device-code list,
        # which the simulator avoids by reporting zero NAND IDs.
        host_reads = [int(n) for n in re.findall(r"ReadBytesRaw\((\d+),", host)]
        body = self._body(
            self.SIM.read_text(encoding="utf-8"),
            "procedure TSimPort.EmitLegacyStorageInfo;",
            "procedure TSimPort.EnterDa;",
        )
        simulated = [emitted for _, emitted in self._emitted_sections(body)]
        self.assertEqual(simulated, host_reads)
        self.assertIn("IdCount := (Integer(Nand[15]) shl 8) or Integer(Nand[16]);", host)


if __name__ == "__main__":
    unittest.main(verbosity=2)
