import sys
from PIL import Image, ImageChops, ImageFilter, ImageDraw, ImageEnhance

sp, out = sys.argv[1], sys.argv[2]
RIM, T, MARGIN = 12, 18, 90
TILT = {'tram': -4, 'nata': 5, 'belem': -3, 'berlin': 4, 'mallorca': -5, 'bansko': 3}

def grow(mask, r):
    return mask.filter(ImageFilter.GaussianBlur(r * 0.6)).point(lambda v: 255 if v > 10 else 0).filter(ImageFilter.GaussianBlur(1.1))

def solid(size, rgb, alpha):
    L = Image.new('RGBA', size, rgb + (0,)); L.putalpha(alpha); return L

def shift(img, dx, dy):
    out = Image.new(img.mode, img.size, 0)
    out.paste(img, (dx, dy))
    return out

def scale(mask, k):
    return mask.point(lambda v: int(v * k))

def magnet(name, max_side=620):
    cut = Image.open(f'{sp}/cutouts/{name}.png').convert('RGBA')
    cut.thumbnail((max_side, max_side), Image.LANCZOS)
    rgb = ImageEnhance.Contrast(ImageEnhance.Color(cut.convert('RGB')).enhance(1.12)).enhance(1.05)
    cut = Image.merge('RGBA', (*rgb.split(), cut.getchannel('A')))
    size = (cut.width + 2 * MARGIN, cut.height + 2 * MARGIN)
    img = Image.new('RGBA', size, (0, 0, 0, 0)); img.alpha_composite(cut, (MARGIN, MARGIN))
    top = grow(img.getchannel('A'), RIM)
    canvas = Image.new('RGBA', size, (0, 0, 0, 0))
    # body silhouette (top + thickness) for shadows
    body = top.copy()
    for k in range(1, T + 1):
        body = ImageChops.lighter(body, shift(top, round(k * 0.25), k))
    # shadow on the fridge: soft ambient + tight contact
    canvas.alpha_composite(solid(size, (40, 38, 34), scale(shift(body.filter(ImageFilter.GaussianBlur(22)), 10, 30), 0.30)))
    canvas.alpha_composite(solid(size, (30, 28, 26), scale(shift(body.filter(ImageFilter.GaussianBlur(4)), 3, 6), 0.38)))
    # thickness: stacked copies, darker toward the bottom
    for k in range(T, 0, -1):
        c = int(222 - (k / T) * 70)
        canvas.alpha_composite(solid(size, (c, c, c + 4), shift(top, round(k * 0.25), k)))
    # printed top face
    canvas.alpha_composite(solid(size, (255, 255, 255), top))
    canvas.alpha_composite(img)
    # resin dome: lighting from a blurred height map
    h = top.filter(ImageFilter.GaussianBlur(26)); d = 7
    lit = ImageChops.subtract(shift(h, -d, -d), shift(h, d, d)).point(lambda v: min(255, v * 6))
    shade = ImageChops.subtract(shift(h, d, d), shift(h, -d, -d)).point(lambda v: min(255, v * 5))
    canvas.alpha_composite(solid(size, (255, 255, 255), ImageChops.multiply(scale(lit, 0.55), top)))
    canvas.alpha_composite(solid(size, (20, 24, 40), ImageChops.multiply(scale(shade, 0.35), top)))
    # glossy reflection band, clipped to the face
    bb = top.getbbox(); w, hgt = bb[2] - bb[0], bb[3] - bb[1]
    band = Image.new('L', size, 0); bd = ImageDraw.Draw(band)
    bd.ellipse([bb[0] - w * 0.15, bb[1] - hgt * 0.25, bb[0] + w * 0.75, bb[1] + hgt * 0.38], fill=255)
    band = band.filter(ImageFilter.GaussianBlur(min(w, hgt) * 0.06))
    canvas.alpha_composite(solid(size, (255, 255, 255), ImageChops.multiply(scale(band, 0.4), top)))
    # crisp rim highlight on the top-left edge of the dome
    rim = ImageChops.subtract(top, shift(top, 3, 4)).filter(ImageFilter.GaussianBlur(1))
    canvas.alpha_composite(solid(size, (255, 255, 255), scale(rim, 0.85)))
    canvas = canvas.rotate(TILT.get(name, 0), resample=Image.BICUBIC, expand=True)
    return canvas.crop(canvas.getbbox())

for n in ['tram', 'nata', 'belem', 'berlin', 'mallorca', 'bansko']:
    m = magnet(n); m.save(f'{out}/{n}-magnet.png'); print(n, m.size)
