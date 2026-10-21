"""Cut out and sticker-treat one city's photos.
usage: python3 build_city.py <scratchpad> <city>"""
import json, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sticker_lib import sticker
from PIL import Image

sp, city = sys.argv[1], sys.argv[2]
base = f'{sp}/library/{city}'
EXISTING = {
    'lisbon': [('tram', 'Tram 28'), ('nata', 'Pastel de nata'), ('belem', 'Torre de Belém')],
    'berlin': [('berlin', 'Ampelmännchen')],
    'mallorca': [('mallorca', 'Ensaïmada')],
    'bansko': [('bansko', 'Flag globe')],
}
os.makedirs(f'{base}/cut', exist_ok=True); os.makedirs(f'{base}/sticker', exist_ok=True)
items = []
for key, label in EXISTING[city]:
    out_key = 'ampelmann' if key == 'berlin' else 'ensaimada' if key == 'mallorca' else 'flag-globe' if key == 'bansko' else key
    Image.open(f'{sp}/cutouts/{key}.png').save(f'{base}/cut/{out_key}.png')
    items.append({'key': out_key, 'label': label, 'existing': True})
for m in json.load(open(f'{base}/manifest.json')):
    src = os.path.join(base, os.path.basename(m['file']))
    r = subprocess.run([f'{sp}/scripts/lift', src, f'{base}/cut/{m["key"]}.png'], capture_output=True, text=True)
    ok = r.returncode == 0
    items.append({'key': m['key'], 'label': m['label'], 'existing': False, 'cut_ok': ok, 'msg': r.stdout.strip()})
tilts = [-4, 3, -2, 4, -3, 2, -4, 3, -2, 4, -3, 2]
for i, it in enumerate(items):
    p = f'{base}/cut/{it["key"]}.png'
    if not os.path.exists(p): continue
    s = sticker(p, tilts[i % len(tilts)], 560)
    s.save(f'{base}/sticker/{it["key"]}.png'); it['size'] = s.size
json.dump(items, open(f'{base}/items.json', 'w'), indent=1, ensure_ascii=False)
# preview sheet
ims = [Image.open(f'{base}/sticker/{it["key"]}.png') for it in items if 'size' in it]
cols = 5; cell = 300
sheet = Image.new('RGB', (cols * cell, ((len(ims) + cols - 1) // cols) * cell), (236, 238, 242))
for i, im in enumerate(ims):
    im = im.copy(); im.thumbnail((cell - 20, cell - 20))
    sheet.paste(im, ((i % cols) * cell + (cell - im.width) // 2, (i // cols) * cell + (cell - im.height) // 2), im)
sheet.save(f'{base}/preview.jpg', quality=85)
print(json.dumps([(it['key'], it.get('cut_ok', True), it.get('size')) for it in items]))
