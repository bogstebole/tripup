import os, sys
from PIL import Image, ImageDraw, ImageFont
sp, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 30)
S = lambda a, i: f'{sp}/shots/{a}_{i:02d}.jpg'
W = lambda n: f'{sp}/shots_web/{n}'
sets = {
 'wanderlog': [S('wanderlog',i) for i in (7,5,6,10)],
 'tripit': [S('tripit',i) for i in (3,2,4)],
 'polls': [W('wa_poll_01.jpg'), W('wa_poll_02.jpg'), W('imsg_poll_03.jpg')],
 'howbout': [S('howbout',i) for i in (3,5,4,2)],
 'partiful': [S('partiful',i) for i in (3,9,6,7)],
 'splitwise': [S('splitwise',i) for i in (1,2,3,4)],
 'tricount': [S('tricount',i) for i in (3,4,5,7)],
 'settleup': [S('settleup',i) for i in (3,8,9)],
 'tab': [S('tab',i) for i in (1,4,6)],
 'splid': [S('splid',i) for i in (1,3,5)],
 'venmo': [S('venmo',i) for i in (7,6,1)],
}
H, GAP, PAD, TOP = 900, 28, 28, 64
for name, files in sets.items():
    ims = [Image.open(f).convert('RGB') for f in files]
    ims = [im.resize((round(im.width * H / im.height), H), Image.LANCZOS) for im in ims]
    width = PAD * 2 + sum(im.width for im in ims) + GAP * (len(ims) - 1)
    canvas = Image.new('RGB', (width, TOP + H + PAD), (242, 244, 247))
    d = ImageDraw.Draw(canvas)
    x = PAD
    for n, im in enumerate(ims, 1):
        mask = Image.new('L', im.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.width - 1, im.height - 1], 22, fill=255)
        canvas.paste(im, (x, TOP), mask)
        cx, cy, r = x + 22, TOP // 2, 20
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(28, 79, 176))
        d.text((cx, cy), str(n), font=font, fill='white', anchor='mm')
        x += im.width + GAP
    if canvas.width > 2400:
        canvas = canvas.resize((2400, round(canvas.height * 2400 / canvas.width)), Image.LANCZOS)
    canvas.save(f'{out}/{name}.jpg', quality=84, optimize=True, progressive=True)
    print(name, canvas.size, os.path.getsize(f'{out}/{name}.jpg') // 1024, 'KB')
