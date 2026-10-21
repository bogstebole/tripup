"""Tiny local receiver: a page POSTs PNG bytes to http://localhost:8766/<name>.png and they're saved to Assets/map/styles/.
Used by tools/map_styles.html?save=1 to export MapLibre canvases (headless Chrome screenshots fire before vector tiles finish)."""
import http.server, os, re
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'Assets', 'map', 'styles')
class H(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', 'http://localhost:8765')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
    def do_OPTIONS(self):
        self.send_response(204); self._cors(); self.end_headers()
    def do_POST(self):
        name = self.path.strip('/')
        if not re.fullmatch(r'lisbon-[a-z-]+\.png', name):
            self.send_response(400); self._cors(); self.end_headers(); return
        data = self.rfile.read(int(self.headers['Content-Length']))
        os.makedirs(OUT, exist_ok=True)
        open(os.path.join(OUT, name), 'wb').write(data)
        self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b'ok')
        print('saved', name, len(data), flush=True)
http.server.HTTPServer(('127.0.0.1', 8766), H).serve_forever()
