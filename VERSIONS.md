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

### Prototype v3: mid-fi wireframe, Airbnb style
- The whole Lisbon flow in mid-fi, focused on UX and flow. Visual design comes last.
- Full screen and responsive, with no phone frame. On desktop the content sits in a 640 px column.
- Airbnb patterns mapped to the flow:
  - wishlist grid → Trips (current trip as a hero collage);
  - wishlist members sheet and "You've joined" dialog → adding Ren mid-trip;
  - collaborative wishlist voting (thumbs up/down, notes, voter avatars) → restaurant poll;
  - experience "Where we'll meet" → dinner detail;
  - sticky price bar → balance and pay bars.
- Flow: Trips → Lisbon → add Ren → new poll → live votes → winner added to today → itemized bill (Ren and Nic skip the wine) → balance (13 → 4 payments) → pay Maya → squared up.
- Files: `prototype/versions/v3-midfi-airbnb.html`, photos in `prototype/assets/photos/` (from the sticker library sources, see their CREDITS)
- Feedback that led here: "Airbnb style, mid-fi, full screen, not inside a phone mockup."

### Prototype v4: mid-fi, trip on a map
- Trips: "Plan a new trip" is now an icon button next to the title.
- Trip page: full-screen map with Lisbon stickers on the places the group visited (OpenStreetMap, greyed so the stickers carry the color). The dinner pin appears once the poll picks a place.
- Bottom sheet over the map: drag between half and full. A "Today" strip of horizontal cards, then segmented tabs: People (with "Add people" at the top and each person's balance), Expenses (with Settle up), History. On desktop the sheet becomes a side panel.
- Adding people: icon button in the trip header and a row at the top of People.
- Poll: horizontal cards with a photo, a vote bar and %, plus a progress block on top (one segment per person, who voted, who we're waiting for, closing time).
- File: `prototype/versions/v4-midfi-map.html` (v3 kept), sticker pins in `prototype/assets/stickers/`, place photos in `prototype/assets/photos/place-*.jpg`
- Feedback that led here: polls as horizontal cards, not empty; map with stickers and a bottom sheet with People / Expenses / History; a visible way to add people; a small new-trip button.

### Prototype v5: the map is the history
- The History tab is gone from the trip sheet; the map with stickers already shows where the group has been. Tabs: People, Expenses.
- File: `prototype/versions/v5-midfi-map.html` (v4 kept)

### Lisbon map for Figma
- OpenStreetMap tiles, zoom 15, stitched into one image (3584 × 2048, placed @2x), in a color and a grey version. The grey one matches the prototype map.
- Figma, page Assets → section "Map · Lisbon (OSM)": the grey map with sticker pins at the real places (instances from the sticker library, plus Flat and Dinner pins), and the color map. Keep the "© OpenStreetMap contributors" line on anything that uses it.
- Files: `Assets/map/lisbon-osm-z15.png`, `lisbon-osm-z15-grey.png`, `lisbon-osm-z15.json` (pixel math for placing pins); script `tools/osm_map.py`. The tile cache isn't committed.

### Map style previews (Figma)
- The same Lisbon area in four simpler styles, with the same sticker pins: Positron (OpenFreeMap), Positron without labels, Toner Lite (Stamen via Stadia), Watercolor (Stamen via Stadia).
- Figma, page Assets → section "Map styles · Lisbon", under the OSM map. Each frame has its own attribution line.
- Positron is free with no key and its style can be edited (colors, labels). Toner Lite and Watercolor need a free Stadia key for a public URL.
- Files: `Assets/map/styles/` (four images, 3584 × 2048, same pixels as the OSM map), `tools/map_styles.html`, `tools/save_receiver.py`

### Prototype v6: planning from a + menu
- Trip page: the "Today" strip is gone. "Add people" stays only in the trip header; the row in People is removed.
- New + button with a gooey menu (liquid-gooey from libraries.dev, MIT, loaded as a small React piece): "Plan something" and "Add expense". On the half-open sheet the + sits on the map, so it never covers the list.
- Plan something: pick what (Food and drinks, Activity, Getting around, with the 3D icons) and when, then decide how: "Let the group vote" opens a poll with options for that category, or "Just pick one" adds it straight to the plan.
- Plans show up as pins on the map ("20:30 · Tasca do Largo"); an open poll shows as a "Voting · 3 of 5" pin that updates live. Tap a pin for details or to vote.
- File: `prototype/versions/v6-midfi-plan.html` (v5 kept), category icons in `prototype/assets/icons/`
- Feedback that led here: no Today section, one Add people, and a clear way to plan something from the trip.

### Prototype v7: the + menu as a Gooey droplet split
- Built with the libraries.dev skill's Gooey reference: round droplets split upward out of the + and melt back in on close, with crisp labels beside them.
- Fixes against the library's rules: the pieces are now transparent (the liquid is the surface), the group is sized to the open menu so the liquid isn't clipped, and positions use Liquid.Item instead of our own CSS.
- File: `prototype/versions/v7-midfi-gooey.html` (v6 kept, with the earlier pill version)

### Prototype v8: the + as a real FAB, stronger goo
- The + stays in the bottom-right corner over the sheet, like a FAB. It no longer rides on the sheet's edge.
- No grey box behind the buttons: the menu's backdrop was squeezed into a column by the old positioning. It's now invisible and only catches the tap that closes the menu.
- Drop icons show only while the menu is open, so nothing stacks under the +.
- Gooey tuning: blur 10 (was 6), contrast 20, 20px gaps, open 600ms with a small overshoot, close 260ms with no overshoot, 80ms stagger. On close the farthest drop goes first.
- A `?tune` slider panel was tried and then removed at Bogdan's request (it's in commit b4a8537).
- File: `prototype/versions/v8-midfi-fab.html` (v7 kept)
- Feedback that led here: the gooey effect was weak, closing overshot a lot, icons stacked into a mess, there was a grey box behind the buttons, and the + should be a FAB.

### Prototype v9: Google-style map, no key
- The trip map now looks like Google Maps (light grey land, white streets, blue water, green parks, yellow highways), but runs on free OpenStreetMap data from OpenFreeMap. No API key and no billing.
- Drawn with MapLibre inside Leaflet, so the stickers, plan pins and the poll pin work as before. If MapLibre doesn't load, the old OSM tiles show instead.
- Real Google Maps was ruled out: it needs a key with a billing account, and pulling Google's tiles without one breaks their terms.
- Files: `prototype/versions/v9-midfi-google-map.html` (v8 kept), `prototype/assets/map/style-google.json`, `tools/google_style.py`
- Credit line on the map: OpenFreeMap © OpenMapTiles © OpenStreetMap.

### Google-like map in Figma
- A fifth frame in Figma, page Assets → "Map styles · Lisbon": the v9 Google-like style over the same Lisbon area, with the same pins and credit line.
- Figma: https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=41-4
- Files: `Assets/map/styles/lisbon-google.png` (3584 × 2048), `tools/map_styles.html?style=google`

### Prototype v10: research gaps closed
- Four points from the competitive research that had dropped out over v3–v9:
  - **Recap for Ren:** after joining, Ren first sees the trip so far: where you're staying, what's decided, any open poll, the places on the map, and that only costs from today count (€726 before stays with the four of you).
  - **No account:** the invite says it up front: open the link, type a name, you're in. No app, no sign-up.
  - **Why for each payment:** tap a payment on Balance (or "See why" on Pay) to see every shared cost, what it did to that person's balance, the total, and why it's one payment instead of several.
  - **Leading by N votes:** the poll tag shows the margin ("Leading by 1 vote"), and a tie shows "Tied" on both options.
- File: `prototype/versions/v10-midfi-research.html` (v9 kept)
- Source: `process/research/tripup-competitive-research-v3-en.md` (key findings and design direction)

### Prototype v11: scan the receipt, assign any line
- No more wine banner. Every line on the bill can be given to anyone or taken away: tap the line, tap people in or out, and the line total splits between whoever is in. Skipping the wine for Ren and Nic is just one case of that.
- Receipt scan: Add expense opens a camera frame with the receipt. "Scan receipt" reads the 7 lines and gives each one to the people who picked that dish before dinner. A line nobody picked (the wine) starts with everyone. "No receipt? Split equally" skips the scan.
- Menu picks: the dinner's place sheet has a "Menu picks" row (5 of 5 picked). There you pick your own dishes and see what the others picked.
- A line with nobody on it blocks Save ("1 line has nobody").
- File: `prototype/versions/v11-midfi-receipt.html` (v10 kept)
- Feedback that led here: the wine shouldn't need its own banner; any item should be assignable; and an OCR scan could split the bill from what people picked beforehand.

### Design tokens v1.2: clearer surface layers
- In light mode the old surfaces were nearly the same tone (white, base-50, base-100, white). Each layer now has its own step: canvas base-100 → default white → raised white with a shadow; inside a card, subtle base-150, then muted base-200. In dark mode the layers get lighter toward the front: 950 → 900 → 750, with subtle 850 and muted 800.
- New: `bg/canvas`, zinc and base 150 / 750 / 850, Elevation/Raised and Elevation/Overlay effect styles. `bg/surface` is renamed to `bg/raised`; existing bindings keep working.
- Changed values: bg/default (dark), bg/subtle, bg/muted (light), border/subtle (dark).
- Figma: page Assets → "Surfaces · tokens v1.2" (Light and Dark side by side): https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=46-11
- Files: `process/design-tokens/tokens-v1.2.md`, `process/design-tokens/surfaces-v1.2.png` (v1.1 kept)
- Feedback that led here: the surface layers were too similar.

### Stickers: pho, chicken wings, ice cream (Bogdan's photos)
- Same pipeline as the sushi plate. The pho photo had two subjects (the bowl and a herb plate cut off at the bottom of the photo), so only the bowl is used (`tools/lift_main.swift`).
- Files: `Assets/user-stickers/pho/`, `wings/`, `ice-cream/` (`source.png`, `cutout.png`, `sticker.png`)
- Figma: Sticker library → Lisbon (now 14), components `Sticker / Lisbon / Pho`, `Chicken wings`, `Ice cream`: https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=18-2

### Sticker: sushi plate (Bogdan's photo)
- Apple Vision cutout of the whole plate, then the library treatment: white die-cut outline and soft shadow (`tools/sticker_lib.py`).
- Files: `Assets/user-stickers/sushi-plate/` (`source.png`, `cutout.png`, `sticker.png` 622 × 687). The source photo is only 344 px wide, so the sticker is soft at full size; it's fine at map-pin size.
- Figma: Sticker library → Lisbon (now 11), component `Sticker / Lisbon / Sushi plate`: https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=52-5

### Design tokens v1.3: Body and Label in every weight
- Body LG / MD / SM now come in Regular, Medium, Semibold and Bold; Label LG / MD / SM in Medium, Semibold and Bold. 15 new text styles, 27 in total.
- The existing styles were renamed, not replaced (`Body/MD` → `Body/MD/Regular`, `Label/MD` → `Label/MD/Medium`), so text already using them keeps working.
- New Typography variables `font-weight/regular · medium · semibold · bold` (Tailwind `--font-weight-*`); the variants bind their weight to them and share size and line height with their base style.
- Figma: page Assets → "Type weights · tokens v1.3": https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=55-21
- Files: `process/design-tokens/tokens-v1.3.md`, `process/design-tokens/type-weights-v1.3.png` (v1.2 kept)

### One link to the latest prototype
- `prototype/latest.html` always opens the newest `prototype/versions/vN-*.html` (highest N). Locally: http://localhost:8765/prototype/latest.html

## Tools
Scripts behind all of the above are in `tools/` (see `tools/README.md`).
