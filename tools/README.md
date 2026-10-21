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
