// Frame times of the web build, in a real browser at phone size: serves a web build of app/perf/trip_perf.dart,
// opens it in Chromium (GPU on) or WebKit, collects the driver's PERF lines (Flutter's own build and raster time per
// frame) and, between its marks, how often the browser actually got a frame out (requestAnimationFrame gaps).
//
//   cd app && flutter build web --profile -t perf/trip_perf.dart [--dart-define=LIGHT_EFFECTS=true] [--wasm]
//   node tools/web_perf.mjs <build dir> [chromium|webkit] [--isolate] [--cpu]
//   (--isolate: the headers --wasm needs for threads; --cpu: Chromium's CPU profile, the functions that took the most time)
//
// Prints one line per scenario and writes the whole run next to the build (web_perf-<browser>.json).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { chromium, webkit } from '/Users/bogste/.nvm/versions/node/v20.20.1/lib/node_modules/playwright/index.mjs';

const [dir, which = 'chromium', ...flags] = process.argv.slice(2);
if (!dir) throw new Error('usage: node tools/web_perf.mjs <build dir> [chromium|webkit] [--isolate]');
const isolate = flags.includes('--isolate');
const cpu = flags.includes('--cpu') && which !== 'webkit';
// --size=1440x900@2 for a computer's window; the default is a phone (390x844@3)
const [, w = 390, h = 844, dpr = 3] = (/^--size=(\d+)x(\d+)@(\d+(?:\.\d+)?)$/.exec(flags.find(f => f.startsWith('--size=')) ?? '') ?? []).map(Number);
const phone = w < 600;
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp', '.ttf': 'font/ttf',
  '.otf': 'font/otf', '.bin': 'application/octet-stream', '.svg': 'image/svg+xml' };

const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  const file = path.join(dir, url.endsWith('/') ? url + 'index.html' : url);
  fs.readFile(file, (err, body) => {
    if (err) { res.writeHead(404); res.end(); return; }
    const headers = { 'Content-Type': TYPES[path.extname(file)] ?? 'application/octet-stream' };
    if (isolate) Object.assign(headers, { 'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp' });
    res.writeHead(200, headers);
    res.end(body);
  });
}).listen(0, '127.0.0.1');
await new Promise(r => server.once('listening', r));
const origin = `http://127.0.0.1:${server.address().port}/`;

const browser = which === 'webkit'
  ? await webkit.launch()
  : await chromium.launch({ args: ['--use-angle=metal', '--enable-gpu', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader=false'] });
const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: dpr, hasTouch: phone, ...(which === 'webkit' || !phone ? {} : { isMobile: true }) });

// Every frame the browser runs, and when each PERF line was printed, on the same clock
await page.addInitScript(() => {
  const frames = (window.__frames = []);
  const tick = t => { frames.push(t); requestAnimationFrame(tick); };
  requestAnimationFrame(tick);
  const marks = (window.__marks = []);
  const log = console.log.bind(console);
  console.log = (...a) => { if (typeof a[0] === 'string' && a[0].startsWith('PERF MARK')) marks.push([a[0], performance.now()]); log(...a); };
});

const lines = [];
let done;
const finished = new Promise(r => (done = r));
page.on('console', m => {
  const t = m.text();
  if (!t.startsWith('PERF')) return;
  lines.push(t);
  if (t.startsWith('PERF DONE')) done();
});
page.on('pageerror', e => console.log('PAGE ERROR', e.message));

const cdp = cpu ? await page.context().newCDPSession(page) : null;
if (cdp) {
  await cdp.send('Profiler.enable');
  await cdp.send('Profiler.setSamplingInterval', { interval: 500 });
  await cdp.send('Profiler.start');
}
await page.goto(origin);
const gpu = await page.evaluate(() => {
  const gl = document.createElement('canvas').getContext('webgl2') ?? document.createElement('canvas').getContext('webgl');
  const ext = gl?.getExtension('WEBGL_debug_renderer_info');
  return ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl ? gl.getParameter(gl.RENDERER) : 'no WebGL';
});
const renderer = await page.evaluate(() => (window.flutterCanvasKit ? 'canvaskit' : 'skwasm or html'));
console.log(`${which} · ${w}x${h}@${dpr} · GPU: ${gpu} · isolated: ${isolate}`);
await Promise.race([finished, new Promise(r => setTimeout(r, 20 * 60 * 1000))]);
if (cdp) {
  // Self time per function over the whole run (idle and the GC listed apart), the top 40
  const { profile } = await cdp.send('Profiler.stop');
  const byId = new Map(profile.nodes.map(n => [n.id, n]));
  const self = new Map();
  profile.samples.forEach((id, i) => {
    const f = byId.get(id).callFrame;
    const key = `${f.functionName || '(anonymous)'} ${f.url.split('/').pop()}:${f.lineNumber + 1}`;
    self.set(key, (self.get(key) ?? 0) + (profile.timeDeltas[i] ?? 0) / 1000);
  });
  const busy = [...self].filter(([k]) => !/^\((idle|program)\)/.test(k)).sort((a, b) => b[1] - a[1]);
  const total = busy.reduce((s, [, v]) => s + v, 0);
  console.log(`CPU busy ${Math.round(total)} ms; top functions by self time:`);
  for (const [k, v] of busy.slice(0, 40)) console.log(`  ${String(Math.round(v)).padStart(6)} ms  ${k}`);
  fs.writeFileSync(path.join(dir, 'web_perf-cpu.cpuprofile'), JSON.stringify(profile));
}
const { frames, marks } = await page.evaluate(() => ({ frames: window.__frames, marks: window.__marks }));
console.log(`renderer: ${await page.evaluate(() => (window.flutterCanvasKit ? 'canvaskit' : 'skwasm'))} (at start: ${renderer})`);

// Browser frames between each scenario's start and end marks
const browserFrames = {};
for (const [text, t0] of marks) {
  const m = /^PERF MARK start (.+)$/.exec(text);
  if (!m) continue;
  const end = marks.find(([x, t]) => x === `PERF MARK end ${m[1]}` && t > t0);
  if (!end) continue;
  const inside = frames.filter(t => t >= t0 && t <= end[1]);
  const gaps = inside.slice(1).map((t, i) => t - inside[i]);
  const sorted = [...gaps].sort((a, b) => a - b);
  const q = x => (sorted.length ? Math.round(sorted[Math.min(sorted.length - 1, Math.round((sorted.length - 1) * x))] * 10) / 10 : 0);
  const secs = (end[1] - t0) / 1000;
  browserFrames[m[1]] = { fps: Math.round(inside.length / secs), p50: q(0.5), p90: q(0.9), max: q(1), over33: gaps.filter(g => g > 33.4).length, frames: inside.length };
}

const json = lines.find(l => l.startsWith('PERF JSON '));
const flutter = json ? JSON.parse(json.slice('PERF JSON '.length)) : {};
for (const [k, v] of Object.entries(flutter)) {
  if (typeof v !== 'object') { console.log(`${k}: ${v}`); continue; }
  const b = browserFrames[k] ?? {};
  console.log(`${k.padEnd(22)} browser ${String(b.fps ?? '?').padStart(3)} fps, gap p50 ${b.p50} p90 ${b.p90} max ${b.max}, ${b.over33}/${b.frames} over 33 ms · flutter build ${v.build.avg}/${v.build.p90} raster ${v.raster.avg}/${v.raster.p90} ms (avg/p90), ${v.janky}/${v.frames} late`);
}
const out = path.join(dir, `web_perf-${which}-${w}x${h}${isolate ? '-isolated' : ''}.json`);
fs.writeFileSync(out, JSON.stringify({ which, gpu, isolate, browserFrames, flutter }, null, 2));
console.log(`→ ${out}`);
await browser.close();
server.close();
