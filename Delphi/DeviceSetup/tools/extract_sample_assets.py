"""Extract the small UI artwork from the user-supplied reference screens.

This is a maintainer tool, not a build/runtime dependency. Install Pillow to
regenerate the committed BMPs. Only icons and the OPPO wordmark are extracted;
all text, tabs, buttons, lists and inputs remain real interactive controls.
"""
from collections import deque
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SAMPLES = ROOT.parent.parent / "UI SAMPLE"
OUT = ROOT / "assets" / "sample-ui"

# Coordinates are in the original, unresized screenshots. S3/S4 are the
# closed/open Flash mode selector; S5 is Read, S8 Locks and S9 Service.
CROPS = {
    "UI_MENU": ("S1", (6, 0, 34, 28), False),
    "UI_START": ("S1", (725, 0, 753, 28), False),
    "UI_DOWNLOAD": ("S1", (769, 0, 797, 28), False),
    "UI_DOCUMENT": ("S1", (813, 0, 841, 28), False),
    "UI_SETTINGS": ("S1", (856, 0, 884, 28), False),
    "UI_REPORT": ("S1", (901, 0, 929, 28), False),
    "UI_FACEBOOK": ("S1", (946, 0, 974, 28), False),
    "UI_HELP": ("S1", (990, 0, 1018, 28), False),
    "UI_OPPO": ("S1", (587, 274, 857, 322), True),
    "UI_SELECT": ("S1", (183, 503, 211, 531), True),
    "UI_WRITE_FIRMWARE": ("S3", (697, 317, 725, 345), True),
    "UI_RESTORE": ("S3", (697, 353, 725, 381), True),
    "UI_WRITE_BIN": ("S3", (697, 429, 725, 457), True),
    "UI_WRITE_OFP": ("S3", (697, 466, 725, 494), True),
    "UI_READ_INFO": ("S5", (695, 298, 723, 326), True),
    "UI_READ_PARTITIONS": ("S5", (695, 334, 723, 362), True),
    "UI_READ_BIN": ("S5", (695, 410, 723, 438), True),
    "UI_READ_REGION": ("S5", (695, 447, 723, 475), True),
    "UI_READ_OTP": ("S5", (695, 483, 723, 511), True),
    "UI_FORMAT": ("S6", (689, 362, 717, 390), True),
    "UI_WIPE_DATA": ("S6", (689, 416, 717, 444), True),
    "UI_WIPE_PARTITIONS": ("S6", (689, 452, 717, 480), True),
    "UI_ERASE_FRP": ("S6", (689, 488, 717, 516), True),
    "UI_ERASE_FRP_WIPE": ("S6", (689, 525, 717, 553), True),
    "UI_REPAIR": ("S2", (696, 357, 724, 385), True),
    "UI_READ_IMEI": ("S2", (696, 393, 724, 421), True),
    "UI_UNLOCK_BOOTLOADER": ("S8", (694, 299, 722, 327), True),
    "UI_RELOCK_BOOTLOADER": ("S8", (694, 335, 722, 363), True),
    "UI_UNLOCK_NETWORK": ("S8", (694, 372, 722, 400), True),
    "UI_READ_CODES": ("S8", (694, 409, 722, 437), True),
    "UI_RESET_PASSWORD": ("S8", (694, 445, 722, 473), True),
    "UI_RESET_ACCOUNT": ("S8", (694, 481, 722, 509), True),
    "UI_REBOOT_RECOVERY": ("S9", (692, 299, 720, 327), True),
    "UI_DISABLE_OTA": ("S9", (692, 336, 720, 364), True),
    "UI_RESET_DM_VERITY": ("S9", (692, 373, 720, 401), True),
    "UI_DISABLE_ORANGE_STATE": ("S9", (692, 410, 720, 438), True),
    "UI_SWITCH_SLOT": ("S9", (692, 446, 720, 474), True),
    "UI_FIX_DL_IMAGE": ("S9", (692, 483, 720, 511), True),
    "UI_RPMB_BACKUP": ("S10", (692, 298, 720, 326), True),
    "UI_RPMB_WRITE": ("S10", (692, 357, 720, 385), True),
    "UI_RPMB_FORMAT": ("S10", (692, 394, 720, 422), True),
}


def mask_background(image):
    """Mask only the edge-connected neutral background, not icon details."""
    image = image.copy()
    pixels = image.load()
    w, h = image.size
    queue = deque([(x, y) for x in range(w) for y in (0, h - 1)] +
                  [(x, y) for y in range(h) for x in (0, w - 1)])
    seen = set()
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        rgb = pixels[x, y]
        if min(rgb) < 205 or max(rgb) - min(rgb) > 16:
            continue
        pixels[x, y] = (255, 0, 255)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    return image


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name, (sample, rect, masked) in CROPS.items():
        image = Image.open(SAMPLES / (sample + ".png")).convert("RGB").crop(rect)
        if masked:
            image = mask_background(image)
        image.save(OUT / (name.lower() + ".bmp"))
        manifest[name] = {"sample": sample + ".png", "rect": list(rect),
                          "masked": masked, "size": list(image.size)}
    # Muted state is only used when no model is selected, not in the reference
    # state. Keep the actual sample artwork for the enabled state unchanged.
    image = Image.open(OUT / "ui_start.bmp").convert("RGB")
    muted = image.convert("L").convert("RGB")
    Image.blend(muted, Image.new("RGB", image.size, (240, 240, 240)), 0.45).save(
        OUT / "ui_start_disabled.bmp")
    manifest["UI_START_DISABLED"] = {"derived_from": "UI_START", "size": [28, 28]}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(manifest)} small UI assets to {OUT}")


if __name__ == "__main__":
    main()
