import sys
from PIL import Image, ImageChops, ImageFilter, ImageDraw, ImageFont

sp, out = sys.argv[1], sys.argv[2]
OUTLINE, MARGIN = 20, 70
TILT = {'tram': -4, 'nata': 5, 'belem': -2}

def grow(mask, r):
    # Blur + threshold = dilation with rounded corners, then 1px blur for smooth edges
    m = mask.filter(ImageFilter.GaussianBlur(r * 0.6)).point(lambda v: 255 if v > 10 else 0)
    return m.filter(ImageFilter.GaussianBlur(1.2))

def base(name):
    cut = Image.open(f'{sp}/cutouts/{name}.png').convert('RGBA')
    cut.thumbnail((640, 640), Image.LANCZOS)
    canvas = Image.new('RGBA', (cut.width + 2 * MARGIN, cut.height + 2 * MARGIN), (0, 0, 0, 0))
    canvas.alpha_composite(cut, (MARGIN, MARGIN))
    return canvas

def outline_sticker(img):
    a = img.getchannel('A')
    ring = grow(a, OUTLINE)
    white = Image.new('RGBA', img.size, (255, 255, 255, 255)); white.putalpha(ring)
    shadow = Image.new('RGBA', img.size, (20, 22, 30, 0))
    shadow.putalpha(ring.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.28)))
    shadow = ImageChops.offset(shadow, 0, 12)
    s = Image.new('RGBA', img.size, (0, 0, 0, 0))
    s.alpha_composite(shadow); s.alpha_composite(white); s.alpha_composite(img)
    return s, ring

def puffy_sticker(img):
    s, ring = outline_sticker(img)
    h = ring.filter(ImageFilter.GaussianBlur(34))
    d = 9
    lit = ImageChops.subtract(ImageChops.offset(h, -d, -d), ImageChops.offset(h, d, d)).point(lambda v: min(255, v * 7))
    shade = ImageChops.subtract(ImageChops.offset(h, d, d), ImageChops.offset(h, -d, -d)).point(lambda v: min(255, v * 6))
    gloss = lit.point(lambda v: 255 if v > 200 else 0).filter(ImageFilter.GaussianBlur(3))
    inside = ring.point(lambda v: v)
    def layer(color, alpha, k):
        L = Image.new('RGBA', s.size, color)
        L.putalpha(ImageChops.multiply(alpha.point(lambda v: int(v * k)), inside))
        return L
    s.alpha_composite(layer((255, 255, 255, 0), lit, 0.85))
    s.alpha_composite(layer((30, 30, 60, 0), shade, 0.6))
    s.alpha_composite(layer((255, 255, 255, 0), gloss, 0.8))
    return s

def tilt(img, deg):
    return img.rotate(deg, resample=Image.BICUBIC, expand=True)

rows = []
for name in ['tram', 'nata', 'belem']:
    b = base(name)
    o, _ = outline_sticker(b)
    p = puffy_sticker(b)
    o, p = tilt(o, TILT[name]), tilt(p, TILT[name])
    o.save(f'{out}/{name}-outline.png'); p.save(f'{out}/{name}-puffy.png')
    src = Image.open(f'{sp}/commons/{name}.jpg').convert('RGB')
    rows.append((src, b, o, p))
    print(name, o.size)

# comparison board
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 26)
small = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 20)
cols = ['1  Photo', '2  Cut out (Apple Vision)', '3  Outline sticker', '4  Puffy sticker']
CW, RH, PAD, HEAD = 420, 440, 30, 70
board = Image.new('RGB', (PAD + len(cols) * (CW + PAD), HEAD + len(rows) * (RH + PAD) + PAD), (244, 245, 247))
dr = ImageDraw.Draw(board)
for i, c in enumerate(cols):
    dr.text((PAD + i * (CW + PAD), 26), c, font=font, fill=(20, 21, 26))
checker = Image.new('RGB', (CW, RH), (255, 255, 255)); cd = ImageDraw.Draw(checker)
for y in range(0, RH, 20):
    for x in range(0, CW, 20):
        if (x // 20 + y // 20) % 2: cd.rectangle([x, y, x + 19, y + 19], fill=(232, 234, 238))
for r, row in enumerate(rows):
    y0 = HEAD + r * (RH + PAD)
    for i, im in enumerate(row):
        x0 = PAD + i * (CW + PAD)
        tile = checker.copy() if i == 1 else Image.new('RGB', (CW, RH), (244, 245, 247) if i > 1 else (255, 255, 255))
        im = im.copy(); im.thumbnail((CW - 20, RH - 20), Image.LANCZOS)
        pos = ((CW - im.width) // 2, (RH - im.height) // 2)
        if im.mode == 'RGBA': tile.paste(im, pos, im)
        else: tile.paste(im, pos)
        board.paste(tile, (x0, y0))
board.save(f'{out}/stickers-board.jpg', quality=88)
print('board', board.size)
