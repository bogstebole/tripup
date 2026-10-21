# Tools

Scripts used to make the research and visual tests. Paths inside them point at the session scratchpad they ran in; change them before re-running.

| Script | What it does |
| --- | --- |
| `dl.py` | Downloads App Store screenshots for the competitor apps (iTunes Lookup API). |
| `prep.py` | Resizes the chosen screenshots for the research page. |
| `strip.py` | Joins each app's 3–5 screens into one numbered strip (for the research doc). |
| `lift.swift` | Cuts the subject out of a photo with Apple Vision (`VNGenerateForegroundInstanceMaskRequest`, the same API an iOS app would use). Run: `swift lift.swift in.jpg out.png`. |
| `sticker_v1.py` | Sticker treatment, first version (subtle puffy). |
| `sticker.py` | Sticker treatment, final version: white outline + shadow, and a stronger puffy light. |
| `magnet.py` | Fridge-magnet treatment: white printed rim, 18 px body, resin dome gloss, shadow on the fridge. |
| `icons3d.html` | The 3D icons (three.js): `icons3d.html?icon=tram|dinner|stay|activity`. |
| `render_icons.sh` | Renders the 3D icons to transparent PNGs with headless Chrome. |
| `lift_main.swift` | Like `lift.swift`, but keeps only the subject under a point (default: centre, 40% from the top), so people in the background are dropped. Used for the portraits. |
| `sticker_lib.py` | Shared sticker treatment for the sticker library: trims the cutout, white die-cut outline, soft shadow, optional tilt. |
| `build_city.py` | Runs a city's photos through the Vision cutout and `sticker_lib.py`, and writes `items.json` plus a preview sheet. |
| `figma_upload.sh` | Uploads PNGs to the upload URLs returned by the Figma MCP `upload_assets` tool. |

## Maps
- `osm_map.py`: downloads OpenStreetMap tiles for a bounding box at one zoom and stitches a color and a grey image (`Assets/map/lisbon-osm-z15*.png`). Small one-off areas only.
- `map_styles.html` + `save_receiver.py`: renders the same area in other styles (Positron, Positron without labels, Toner Lite, Watercolor). Serve the project at http://localhost:8765, run `python3 tools/save_receiver.py`, then open `tools/map_styles.html?style=<name>&save=1` in a browser; the PNG lands in `Assets/map/styles/`. Headless Chrome screenshots fire before vector tiles finish, so the browser export is the reliable path.
