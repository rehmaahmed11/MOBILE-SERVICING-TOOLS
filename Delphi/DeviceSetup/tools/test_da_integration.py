import os
import unittest
import zipfile
from pathlib import Path

# Repo root is 3 levels up from tools: tools -> DeviceSetup -> Delphi -> Repo root
TOOLS_DIR = Path(__file__).resolve().parent
DEVICE_SETUP_DIR = TOOLS_DIR.parent
REPO_ROOT = DEVICE_SETUP_DIR.parent.parent

class DaIntegrationTests(unittest.TestCase):
    def test_data_folders_exist(self):
        for root in (REPO_ROOT, DEVICE_SETUP_DIR):
            data_dir = root / "data"
            da_dir = data_dir / "da"
            self.assertTrue(data_dir.exists(), f"data folder should exist at {data_dir}")
            self.assertTrue(da_dir.exists(), f"data/da folder should exist at {data_dir}")

    def test_fdl_files_exist(self):
        for root in (REPO_ROOT, DEVICE_SETUP_DIR):
            fdl1 = root / "data" / "fdl1.bin"
            fdl2 = root / "data" / "fdl2.bin"
            self.assertTrue(fdl1.exists(), f"fdl1.bin should exist at {fdl1}")
            self.assertTrue(fdl2.exists(), f"fdl2.bin should exist at {fdl2}")

    def test_da_files_created_and_valid(self):
        da_dir = DEVICE_SETUP_DIR / "data" / "da"
        da_files = list(da_dir.glob("**/*.da"))
        self.assertGreater(len(da_files), 0, "There should be at least one .da file in data/da")
        
        # Verify that zip-based .da files contain da.bin and optionally auth.bin
        for da_path in da_files:
            if zipfile.is_zipfile(da_path):
                with zipfile.ZipFile(da_path, "r") as zf:
                    names = [n.lower() for n in zf.namelist()]
                    self.assertTrue(any("da" in n and n.endswith(".bin") for n in names),
                                    f"{da_path.name} must contain a da.bin file")

    def test_models_map_exists_and_maps_models(self):
        map_path = DEVICE_SETUP_DIR / "data" / "da" / "models_map.ini"
        self.assertTrue(map_path.exists(), "models_map.ini should exist")
        content = map_path.read_text()
        self.assertIn("[Models]", content)
        self.assertIn("A59=", content)

if __name__ == "__main__":
    unittest.main()
