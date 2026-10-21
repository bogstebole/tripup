# TripUp: versions and process

Every version made for the Bending Spoons Task #2, oldest first, with what changed and what was decided. Nothing here is overwritten: each new version gets its own file or folder, and the whole folder is in git, so `git log` shows every saved state.

## 20 Oct 2026

### Research v1: HTML research page (Serbian)
- 13 apps across 4 categories, 38 key screens from the App Store, scenario map, market table, adopt / improve / do differently.
- Files: `research/tripup-research.html`, `research/img/` (the 38 screens), `process/research/appstore-screens/` (all downloaded screens), `process/research/lookup_*.json` (App Store data).
- Link: https://claude.ai/artifact/GhmqH2gvspacKbQCNkjrNY
- Feedback: wanted a regular document instead of an HTML page, with minimal text, side-by-side comparisons, and real user comments.

## 21 Oct 2026

### Research v2 → v3: Claude Doc
- v2 (Serbian): the same research as tables plus one numbered strip of screens per app (`research/strips/`).
- v3 (English): translated, with "What users say" tables (Reddit, App Store, Trustpilot, forums) and a "Payments under the hood" section (PSD2, PIS vs AIS).
- Files: `process/research/tripup-competitive-research-v3-en.md` (local copy)
- Link: https://claude.ai/artifact/Dpmqh2ogHStzncaU3fYxT9 (the doc's own history holds v2 and every edit)

### Visual references
- Direction: a middle ground between Bump (amo) and Airbnb.
- amo.co loading screen: `Assets/Screen Recording 2026-10-21 at 11.03.07.mov` (recording) and `Assets/amo-loading-keyframes.jpg` (12 labeled keyframes).

### Lo-fi wireflow (made by Bogdan in Figma)
- Snapshot for the record: `process/wireflow/wireflow-lofi-full.png` and its parts in `process/wireflow/part-*.png`.
- Source: https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=1-11

### Prototype v1: full user story, flow only
- All 11 steps of the Lisbon scenario. Added on top of the wireflow: poll creation, notification preview, "Today" itinerary with the poll winner and undo, the wine exclusion on the bill, the trip balance (13 → 4 payments), the pay-in-app flow, and the "squared up" screen.
- File: `prototype/versions/v1-flow-only.html`
- Link (same artifact, version 1): https://claude.ai/artifact/CrTYJ7MDGW6JKaFZ7BMWWW

### Prototype v2: plus an amo-style launch animation
- Marker swipe, "TripUp" writes itself, trip stickers pop up into the Home grid.
- File: `prototype/versions/v2-launch-animation.html` (same as `prototype/index.html`)
- Feedback: the launch is "pretty bad". If a logo writes itself, it has to read as the app name. The prototype stays a wireframe; design and motion are Bogdan's.

### Photo stickers: v1 → v2
- Pipeline: photo → Apple Vision cutout (on-device) → white outline + shadow → "puffy" light.
- v1: the puffy light was too subtle. Files: `Assets/stickers-test/iterations/v1-puffy-subtle/`
- v2: stronger puffy. Files: `Assets/stickers-test/*-outline.png`, `*-puffy.png`, `stickers-board.jpg`
- Shared sources: `Assets/source-photos/` (with CREDITS.txt), `Assets/cutouts/`

### 3D icons, made in code: v1 → v2 → v3
- Transport, dinner, stay, activity. Same clay material, camera, light and shadow (three.js).
- v1: colors washed out (color-space bug). v2: colors fixed and a "28" sign on the tram, but the shadows were cut at the edge. v3: camera pulled back, full shadows.
- Files: `Assets/stickers-test/iterations/icons-v1-washed-colors/`, `icons-v2-clipped-shadows/`, `icons-v3-final/`, and a side-by-side `icons-iterations.jpg`. Final: `Assets/stickers-test/icons-3d/`; the combined board is `Assets/stickers-test/style-test-board.jpg`.

### Fridge magnets + Home as a fridge door
- Magnets: white printed rim, 18 px body, resin dome gloss, shadow on the fridge. Six magnets: tram, nata and Belém (Lisbon), plus Berlin, Mallorca and Bansko for the Home mock.
- Home mock: freezer door with the greeting, fridge door with trip magnets, "magnetic poetry" name tiles, friends as round button magnets.
- Files: `Assets/magnets-test/` (`magnets-board.jpg`, `home-fridge-mock.png` and its HTML source, `*-magnet.png`, `magnet.py`, CREDITS.txt)
- Note: the very first magnet render had thin stray lines above each magnet (an image wrap-around bug). It was fixed before it was shown, so that render isn't kept.
- Feedback: the direction is OK and the cut-out photos look good, but it won't go fully this way; it will be packaged differently later.

### Sticker library v1 (Figma)
- In Figma, page **Assets** → frame **Sticker library**. Every sticker is a component, so they all show in the Assets panel:
  - Real people: 6 Unsplash portraits picked by Bogdan, cut out by Apple Vision (main person only), head and shoulders, white outline.
  - Avatars, die-cut: 10 Notionists characters (CC0); the outline follows the figure.
  - Avatars, round: the same 10 on colored circles. This is the first avatar version; after feedback ("cut along the outline like the photo stickers") it became the fallback for people with no photo.
  - Lisbon, Berlin, Mallorca and Bansko: 10 photo stickers each, from Wikimedia Commons.
  - A Credits frame.
- Files: `Assets/sticker-library-v1/` (sticker PNGs, cutouts, source photos, manifests, `CREDITS.md`, `figma-node-ids.json`); raw portraits in `Assets/people-raw/`.
- Figma: https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=11-953
- Notes:
  - One portrait was Unsplash+ (paid, watermarked), so it was skipped, leaving 6 real people.
  - Palma Cathedral only cut out after cropping the photo to the building.
  - The Mallorca windmill keeps a disc of sky inside its wheel.

### Design tokens v1 (Figma variables)
- Tailwind-based variables in Figma: Primitives (348, hidden), Color (37, Light + Dark), Layout (23), Typography (48), plus 12 Geist text styles bound to the variables.
- Brand is a placeholder (blue) and the neutral is zinc; both are one alias ramp each, so they're easy to swap.
- Files: `process/design-tokens/tokens-v1.md` (every semantic token and its value), `process/design-tokens/tailwind-v3-colors.json` (source palette)
- Figma: https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task (Local variables, Text styles)

### Design tokens v1.1: condensed headings
- Display and Heading styles (XL, LG, MD, SM) now use IBM Plex Sans Condensed (Bold / SemiBold) through a new `font/family/display` variable (CSS `--font-display`). Body, Label and Caption stay Geist.
- Heading tracking is now 0, since the condensed face is already tight.
- Files: `process/design-tokens/tokens-v1.1.md`, `process/design-tokens/type-check-v1.1.png` (all 12 styles rendered in Figma). v1 is kept in `tokens-v1.md`.

### Motion test v1: trip folder opens into the trip page
- Home: the active trip is a hero folder. Papers peek out of it (Today, Poll, Balance) and are the trip's real content. Past trips are small folders with stickers.
- Tap: the cover becomes the page header, and each paper grows into its section. Drag the page down to close; it goes back into the folder the same way.
- One spring drives everything, so the motion can be interrupted and reversed mid-way. It has a slow-motion (5×) toggle and a reduced-motion fallback.
- File: `prototype/versions/motion-folder-v1.html` (run `python3 -m http.server` at the project root so the sticker images load)

## Tools
Scripts behind all of the above are in `tools/` (see `tools/README.md`).
