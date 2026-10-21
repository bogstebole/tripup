"""Sticker treatment shared by the whole sticker library: white die-cut outline + soft shadow.
usage: python3 sticker_lib.py <in.png> <out.png> [tilt_degrees] [max_side]"""
import sys
from PIL import Image, ImageChops, ImageFilter

def grow(mask, r):
    return mask.filter(ImageFilter.GaussianBlur(r * 0.6)).point(lambda v: 255 if v > 10 else 0).filter(ImageFilter.GaussianBlur(1.1))

def shift(img, dx, dy):
    out = Image.new(img.mode, img.size, 0); out.paste(img, (dx, dy)); return out

def sticker(src, tilt=0, max_side=600, outline=18, margin=60):
    cut = Image.open(src).convert('RGBA')
    bb = cut.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    if bb: cut = cut.crop(bb)
    cut.thumbnail((max_side, max_side), Image.LANCZOS)
    size = (cut.width + 2 * margin, cut.height + 2 * margin)
    img = Image.new('RGBA', size, (0, 0, 0, 0)); img.alpha_composite(cut, (margin, margin))
    ring = grow(img.getchannel('A'), outline)
    out = Image.new('RGBA', size, (0, 0, 0, 0))
    sh = Image.new('RGBA', size, (20, 22, 30, 0))
    sh.putalpha(shift(ring.filter(ImageFilter.GaussianBlur(12)), 0, 10).point(lambda v: int(v * 0.26)))
    white = Image.new('RGBA', size, (255, 255, 255, 255)); white.putalpha(ring)
    out.alpha_composite(sh); out.alpha_composite(white); out.alpha_composite(img)
    if tilt: out = out.rotate(tilt, resample=Image.BICUBIC, expand=True)
    return out.crop(out.getchannel('A').getbbox())

if __name__ == '__main__':
    tilt = float(sys.argv[3]) if len(sys.argv) > 3 else 0
    side = int(sys.argv[4]) if len(sys.argv) > 4 else 600
    s = sticker(sys.argv[1], tilt, side); s.save(sys.argv[2]); print(sys.argv[2].split('/')[-1], s.size)
