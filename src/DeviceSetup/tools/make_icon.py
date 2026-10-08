"""Draw the application icon (DeviceSetup.ico).

The .ico is committed, so this only needs to run again if the design changes.
Needs Pillow:  pip install pillow
Usage:         python tools/make_icon.py   (run from src/DeviceSetup)
"""
import pathlib

from PIL import Image, ImageDraw

S = 1024  # drawing size; every icon size is downsampled from this


def gradient_tile(size):
    """Rounded blue tile with a vertical gradient."""
    top, bottom = (52, 140, 230), (14, 70, 160)
    grad = Image.new("RGBA", (size, size))
    px = grad.load()
    for y in range(size):
        t = y / (size - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,)
        for x in range(size):
            px[x, y] = c
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (24, 24, size - 24, size - 24), radius=200, fill=255)
    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile.paste(grad, (0, 0), mask)
    return tile


def draw_icon():
    img = gradient_tile(S)
    d = ImageDraw.Draw(img)

    # phone
    d.rounded_rectangle((300, 150, 650, 860), radius=70, fill=(255, 255, 255, 255))
    d.rounded_rectangle((335, 240, 615, 740), radius=14, fill=(28, 44, 70, 255))
    d.rounded_rectangle((430, 185, 520, 205), radius=10, fill=(150, 160, 175, 255))
    d.ellipse((450, 770, 500, 820), fill=(150, 160, 175, 255))

    # green "flash" arrow on the screen
    d.polygon([(400, 440), (500, 440), (500, 370), (590, 490),
               (500, 610), (500, 540), (400, 540)], fill=(40, 200, 90, 255))

    # orange gear badge (bottom right)
    import math
    cx, cy, ro, ri, teeth = 720, 720, 210, 160, 10
    pts = []
    n = teeth * 4
    for i in range(n):
        a = i * 2 * math.pi / n - math.pi / 2
        r = ro if i % 4 in (0, 1) else ri
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.ellipse((cx - ro - 22, cy - ro - 22, cx + ro + 22, cy + ro + 22),
              fill=(14, 70, 160, 255))
    d.polygon(pts, fill=(255, 140, 30, 255))
    d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=(14, 70, 160, 255))
    return img


def main():
    root = pathlib.Path(__file__).resolve().parent.parent
    big = draw_icon()
    # Classic BMP frames only: the Lazarus/LCL icon reader cannot read
    # PNG-compressed frames ("Bitmap with unknown compression").
    sizes = [128, 64, 48, 32, 24, 16]
    frames = [big.resize((s, s), Image.LANCZOS) for s in sizes]
    out = root / "DeviceSetup.ico"
    frames[0].save(out, format="ICO", sizes=[(s, s) for s in sizes],
                   append_images=frames[1:], bitmap_format="bmp")
    print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
