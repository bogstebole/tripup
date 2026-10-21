"""Download OpenStreetMap tiles for a bounding box at one zoom level and stitch them.
Usage: python3 -I tools/osm_map.py <out_dir> <zoom> <lon_min> <lat_min> <lon_max> <lat_max>
Tiles: (c) OpenStreetMap contributors, ODbL. Keep the attribution on anything made from them.
Small one-off areas only (OSM tile usage policy); tiles are cached in <out_dir>/tiles-z<zoom>."""
import math, os, sys, time, json, urllib.request
from PIL import Image, ImageEnhance, ImageOps

out, z = sys.argv[1], int(sys.argv[2])
lon0, lat0, lon1, lat1 = map(float, sys.argv[3:7])
def tx(lon): return (lon + 180) / 360 * 2 ** z
def ty(lat): r = math.radians(lat); return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * 2 ** z
x0, x1 = int(tx(lon0)), int(tx(lon1)); y0, y1 = int(ty(lat1)), int(ty(lat0))
cache = os.path.join(out, f"tiles-z{z}"); os.makedirs(cache, exist_ok=True)
W, H = (x1 - x0 + 1) * 256, (y1 - y0 + 1) * 256
img = Image.new("RGB", (W, H))
fetched = 0
for x in range(x0, x1 + 1):
    for y in range(y0, y1 + 1):
        f = os.path.join(cache, f"{x}_{y}.png")
        if not os.path.exists(f):
            req = urllib.request.Request(f"https://tile.openstreetmap.org/{z}/{x}/{y}.png", headers={"User-Agent": "TripUp-design-prototype/1.0 (one-off mockup map)"})
            with urllib.request.urlopen(req, timeout=30) as r, open(f, "wb") as fh: fh.write(r.read())
            fetched += 1; time.sleep(0.25)
        img.paste(Image.open(f).convert("RGB"), ((x - x0) * 256, (y - y0) * 256))
img.save(os.path.join(out, f"lisbon-osm-z{z}.png"), optimize=True)
# Quiet version used in the mid-fi prototype: mostly grey so stickers carry the color
grey = Image.blend(img, ImageOps.grayscale(img).convert("RGB"), 0.7)
grey = ImageEnhance.Contrast(ImageEnhance.Brightness(grey).enhance(1.04)).enhance(0.92)
grey.save(os.path.join(out, f"lisbon-osm-z{z}-grey.png"), optimize=True)
# Pixel position of a lon/lat on the stitched image, for placing pins
meta = {"zoom": z, "tile_x0": x0, "tile_y0": y0, "width": W, "height": H, "fetched_now": fetched,
        "px": "x = (tx(lon) - tile_x0) * 256, y = (ty(lat) - tile_y0) * 256"}
json.dump(meta, open(os.path.join(out, f"lisbon-osm-z{z}.json"), "w"), indent=1)
print(json.dumps(meta))
