"""Fast, platform-independent contracts for the reference UI and resources.

Run from any directory with Python's standard library. Runtime Windows
self-tests separately check actual control bounds, interaction and DPI sizes.
"""
from dataclasses import dataclass, field
import json
from pathlib import Path
import re
import struct
import unittest

from make_ui_resources import build, TARGET

ROOT = Path(__file__).resolve().parent.parent


@dataclass
class Component:
    name: str
    kind: str
    parent: object = None
    props: dict = field(default_factory=dict)
    children: list = field(default_factory=list)

    @property
    def bounds(self):
        return tuple(int(self.props[k]) for k in ("Left", "Top", "Width", "Height"))


def read_form(filename):
    stack = []
    nodes = {}
    for line in (ROOT / filename).read_text().splitlines():
        text = line.strip()
        match = re.fullmatch(r"object (\w+): (\w+)", text)
        if match:
            node = Component(*match.groups(), parent=stack[-1] if stack else None)
            if stack:
                stack[-1].children.append(node)
            stack.append(node)
            nodes[node.name] = node
        elif text == "end":
            stack.pop()
        elif " = " in text:
            key, value = text.split(" = ", 1)
            stack[-1].props[key] = value
    if stack:
        raise ValueError("Unclosed form components")
    return nodes


class UIContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main1 = read_form("MainForm.dfm")
        cls.main2 = read_form("Main2Form.dfm")
        cls.manifest = json.loads((ROOT / "assets/sample-ui/manifest.json").read_text())

    def test_main1_reference_geometry(self):
        self.assertEqual(self.main1["frmMain"].props["ClientWidth"], "1023")
        self.assertEqual(self.main1["frmMain"].props["ClientHeight"], "575")
        for name, rect in {
            "cbSearch": (3, 48, 420, 18),
            "lstBrands": (3, 72, 128, 423),
            "lstModels": (136, 72, 287, 423),
            "btnSelect": (3, 501, 420, 31),
        }.items():
            self.assertEqual(self.main1[name].bounds, rect, name)
        self.assertEqual(self.main1["btnSelect"].props["Centered"], "True")
        for name in ("lstBrands", "lstModels"):
            self.assertEqual(self.main1[name].props["Font.Height"], "-14")
            self.assertEqual(self.main1[name].props["ItemHeight"], "17")

    def test_main2_reference_columns(self):
        self.assertEqual(self.main2["frmMain2"].props["ClientWidth"], "1026")
        self.assertEqual(self.main2["frmMain2"].props["ClientHeight"], "585")
        for name, rect in {
            "grpPresets": (3, 37, 661, 44),
            "grpFiles": (3, 82, 661, 98),
            "grpLog": (3, 184, 661, 378),
            "pcJobs": (672, 37, 337, 526),
            "grpConnections": (8, 5, 328, 188),
            "pcOperations": (0, 201, 337, 305),
        }.items():
            self.assertEqual(self.main2[name].bounds, rect, name)

    def test_operation_tabs_cannot_overflow(self):
        pc = self.main2["pcOperations"]
        self.assertEqual(pc.kind, "TSamplePageControl")
        self.assertEqual([c.props["Caption"] for c in pc.children],
                         ["'Flash'", "'Read'", "'Format'", "'IMEI'", "'Locks'", "'Service'", "'RPMB'"])
        self.assertLessEqual(int(pc.props["TabWidth"]) * len(pc.children), pc.bounds[2])
        self.assertNotIn("Style", pc.props)

    def test_options_frames_and_jobs_fit(self):
        for page in self.main2["pcOperations"].children:
            self.assertEqual(len(page.children), 1, page.name)
            group = page.children[0]
            self.assertEqual(group.kind, "TSampleGroupBox")
            self.assertEqual(group.props["Caption"], "'Options'")
            x, y, w, h = group.bounds
            self.assertLessEqual(x + w, 337, group.name)
            self.assertLessEqual(y + h, 305 - 18, group.name)
            for child in group.children:
                if child.kind == "TSampleButton":
                    self.assertEqual(child.bounds[2:], (300, 34), child.name)
                    cx, cy, cw, ch = child.bounds
                    self.assertLessEqual(cx + cw, w, child.name)
                    self.assertLessEqual(cy + ch, h, child.name)
        self.assertEqual(self.main2["btnEraseFrpAndWipe"].bounds, (14, 240, 300, 34))

    def test_format_radio_groups_are_independent(self):
        self.assertIsNot(self.main2["rbAutoFormat"].parent,
                         self.main2["rbFormatAiFlash"].parent)
        self.assertIs(self.main2["rbAutoFormat"].parent,
                      self.main2["rbManualFormat"].parent)
        self.assertIs(self.main2["rbFormatAiFlash"].parent,
                      self.main2["rbFormatAiExceptBootloader"].parent)
        self.assertEqual(self.main2["rbAutoFormat"].props["Checked"], "True")
        self.assertEqual(self.main2["rbFormatAiFlash"].props["Checked"], "True")

    def test_file_rows_have_the_sample_pitch(self):
        for i, name in enumerate(("Scat", "Auth", "Bin", "Ofp", "Bl", "Ap", "Cp", "Csc", "User")):
            self.assertEqual(self.main2["btn" + name].bounds, (7, 14 + 21*i, 47, 18))
            self.assertEqual(self.main2["edt" + name].bounds, (55, 14 + 21*i, 600, 18))
            self.assertEqual(self.main2["edt" + name].props["AutoSize"], "False")
        source = (ROOT / "Main2Form.pas").read_text()
        self.assertIn("CFileRowPitch = 21;", source)
        self.assertIn("CFilesHeight = 98;", source)

    def test_small_typography_and_connection_defaults(self):
        self.assertEqual(self.main2["frmMain2"].props["Font.Name"], "'Tahoma'")
        self.assertEqual(self.main2["frmMain2"].props["Font.Height"], "-11")
        self.assertEqual(self.main2["chkAuthBrom"].props["Checked"], "True")
        self.assertNotIn("Checked", self.main2["chkAuthPreloader"].props)
        for name in ("cbUsbSpeed", "cbBattery", "cbStorage", "cbFlashMode"):
            self.assertEqual(self.main2[name].props["ItemIndex"], "0")
        self.assertEqual(self.main2["cbDownloadAgent"].bounds[:2], (106, 16))
        self.assertEqual(self.main2["lblDownloadAgent"].bounds[:2], (8, 18))

    def test_artwork_is_small_not_full_screen_images(self):
        self.assertEqual(len(self.manifest), 42)
        for name, info in self.manifest.items():
            w, h = info["size"]
            self.assertLessEqual(w, 270, name)
            self.assertLessEqual(h, 48, name)
            if name != "UI_OPPO":
                self.assertEqual((w, h), (28, 28), name)
            data = (ROOT / "assets/sample-ui" / (name.lower() + ".bmp")).read_bytes()
            self.assertEqual(data[:2], b"BM", name)
            self.assertEqual(struct.unpack_from("<ii", data, 18), (w, h), name)
            self.assertEqual(struct.unpack_from("<H", data, 28)[0], 24, name)

    def test_resource_is_reproducible_and_all_glyphs_exist(self):
        self.assertEqual(TARGET.read_bytes(), build())
        source = (ROOT / "ToolbarIcons.pas").read_text()
        for name in re.findall(r"'((?:UI_)[A-Z_]+)'", source):
            self.assertIn(name, self.manifest)
        self.assertEqual(self.manifest["UI_OPPO"]["sample"], "S1.png")

    def test_form_types_and_event_handlers_match_source(self):
        for nodes, filename in ((self.main1, "MainForm.pas"), (self.main2, "Main2Form.pas")):
            source = (ROOT / filename).read_text()
            for node in nodes.values():
                if node.kind.startswith("TSample"):
                    self.assertRegex(source, rf"\b{node.name}:\s*{node.kind};", node.name)
                for prop, method in node.props.items():
                    if prop.startswith("On"):
                        self.assertRegex(source, rf"procedure T\w+\.{method}\b", method)

    def test_screenshots_are_lossless_client_area_captures(self):
        source = (ROOT / "SelfTest.pas").read_text()
        self.assertIn("GetClientRect(AForm.Handle, R)", source)
        self.assertIn("PW_CLIENTONLY or PW_RENDERFULLCONTENT", source)
        self.assertNotIn("GetWindowRect(AForm.Handle", source)
        for screen in ("main1", "main2-imei", "main2-flash", "main2-flash-modes",
                       "main2-read", "main2-format", "main2-locks", "main2-service",
                       "main2-rpmb", "main2-dpi144", "main2-dpi192"):
            self.assertIn("'" + screen + "'", source)
        workflow = (ROOT.parent.parent / ".github/workflows/build-fast.yml").read_text()
        self.assertIn("base64 PNG chunk", workflow)
        self.assertNotIn("ImageFormat]::Gif", workflow)


if __name__ == "__main__":
    unittest.main(verbosity=2)
