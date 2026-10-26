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

### Final UI, iteration 1: trip screen in Flutter + Storybook spec
- From the Figma screens "First few screens to test" and "Widget states" (node 62-4522, 62-4859).
- **Tokens, one source:** `design-system/tokens.json` (primitives → semantic → component) builds `storybook/src/tokens.css` and `app/lib/design/tokens.dart`. Nothing in the components is a raw value. Where Figma used off-system values, the closest token replaced them (e.g. `#e7e7e7` → `bg/muted`, `#1237d9` → `blue.700`); the list is in Storybook → Introduction.
- **Storybook** (`storybook/`, React, Storybook 10): Button documented in full, plus Surface, PeopleButton, RatingLine, InfoChips, SegmentedTabs, KnowSection, the Up next widget (mid, mini, edge, morph), map marks, top and action bars, the full view with Overview, Menu and People. Lucide icons.
- **Flutter app** (`app/`): the map in the Google-like style, past places as stickers, all planned events as pins, the Up next card. Moving the map collapses it to mini, tapping grows it back, off-screen places slide to the edge and point at themselves, the card grows into the full view (map blurs), close by X, backdrop or pulling down. My location with heading cone, edge capsule and recenter. Springs from tokens throughout; Jakub's libraries.dev effects are React-only, so motion is built natively.
- New tabs in the full view: **Menu** (menu picks: dishes, prices, who picked what) and **People** (who's coming, ETA).
- Checked on the iPhone 16 simulator (every state and transition above) and installed on Bogdan's iPhone.
- Files: `design-system/`, `storybook/`, `app/` (see each README)

### Final UI, iteration 1.1: haptics, 2 px icons, transitions without blank frames
- **Full view → card:** the "second of nothing, then the card pops in" was a layout bug: the card's content inside the morph had no height bound and was never drawn, so only the real card appeared at the end. Fixed, and the crossfade now overlaps (the sheet's content leaves while the card's arrives) with a 2 px blur on the seam, per Emil's crossfade recipe. Closing uses a new `spring-collapse` (0.38 s, no bounce): the system's answer is quicker than the opening. The real card takes over the moment the morph lines up with it.
- **Pin mid ↔ mini ↔ edge:** the same blank-middle problem (both contents at 0 halfway); now overlapping with the seam blur, and the card's content shrinks with the surface instead of being cut off.
- **Haptics:** light on every button and row, a selection tick on tab changes, medium when a pin gets focus, light when pulling the full view down commits.
- **Icons:** Lucide drawn as SVG from the same lucide-react package as Storybook, with a true 2 px stroke at 16 px (token `icon/stroke`). `design-system/build-icons.mjs` writes them for Flutter.
- Checked frame by frame on the simulator at 6× slow motion; installed on Bogdan's iPhone.

### Final UI, iteration 1.2: real menu, 14 px text, tabs that replace the page
- **Real data** from the Google Maps link: 4.2 (173 reviews), Av. da Igreja 12B, Alvalade (the pin is now at the real address, and the demo map opens around it). The whole menu (118 items in 15 sections: starters, mains, menu exécutif, sandwiches, extras, desserts, wines by glass and bottle, sparkling, beers, soft drinks, coffee, cocktails, spirits) comes from the restaurant's own English menu (brasserieentrecote.pt, same in every restaurant; Alvalade has no separate one). One file for both Storybook and the app: `app/assets/data/brasserie-menu.json`.
- **Tabs replace everything above them.** Overview keeps photos, name, rating and "Know before you go". Menu: title, how many have picked, then the full menu as a plain list (name, note, price, who picked it, small **Add** button that turns into "Added"). People: plain list with each person's status. The grey block stays only on Overview, for what has to stand out.
- **Tab switch:** the old page fades out with a light blur; the new one's blocks arrive one by one (40 ms apart, capped at 8), each fading in, sharpening from a 4 px blur and settling 8 px up. Content under the tab bar fades out instead of being cut off.
- **Text:** every 12 px style (Label/SM, Caption) is now 14 px (Label/MD, Body/SM) in the app and in Storybook. The mini pin is 140 wide to fit it. The Figma screens still use the 12 px styles.
- **Backdrop** behind the full view: blur 12 instead of 20.
- New tokens: `button/pill-height`, `tab/enter-shift`, `motion.stagger-ms`, `stagger-max`, `enter-ms`, `enter-blur`. New components: `AddButton`, `StaggerIn` (Flutter).
- Checked on the simulator (tab switch frame by frame at 6× slow motion) and installed on Bogdan's iPhone.

### Final UI, iteration 1.3: card ↔ mini as one object, day filter, dish photos
- **Card ↔ mini pin** rebuilt as one object instead of two crossfading layouts. The card grows out of the pin's tail. The plan's sticker is the same picture in both states, so it travels from the mini's slot into the middle of the fan, growing. The name slides between its two places and crossfades between the two styles. The other fan stickers open out from the shared one, the label and rating follow the name, the eta leaves with the mini name, and the chips rise in last. Parts blur while half faded. Checked frame by frame on the simulator at 20× slow motion, both ways, and tapping the mini still grows it back. Storybook mirrors it with shared `layoutId`s.
- **Day filter** right under the top bar: All, then every day of the trip ("Tue 12" … "Thu 21"), scrolling sideways. Toggles: flat (muted fill, no shadow) when off, primary glass when on, so only the picked days stand out. Days combine; with none picked, All is on. On the map, other days' pins and places fade and shrink away, and the map frames what is left; past days show the places visited that day. All brings back the opening view with the Up next card. Four more plans fill the later days (sail from Parque das Nações, fado at Tasca do Chico, Oceanário, Tile Museum).
- **Menu:** a photo next to every dish (28). The entrecôte ones are the restaurant's own (from its menu); the rest are illustrative photos from Wikimedia Commons, credited in `app/assets/photos/menu/CREDITS.md` and in the menu's footer. Drinks have none. The Add button is now just an icon: a plus in soft glass, a check in primary glass once added (32 px circle, 44 px touch target).
- **Tab switcher:** the selected tab's heavier weight made the row wider after the pill had measured it, so the pill ran past the track and its shadow was cut. Each tab now reserves the heavier width, and the pill's shadow may spill past the track.
- New tokens: `motion.morph-enter-scale`, `day-chip/off-bg`, `day-chip/off-fg`, `day-chip/height`, `day-chip/padding-x`, `day-chip/gap`, `menu/photo`, `menu/photo-radius`. New components: `DayFilter` and `DayChip` (Flutter and Storybook).

### Final UI, iteration 1.4: header blur, sheet that scrolls, menu cards, picks, place details
- **Header:** the white fade now runs past the day filter (it starts fading halfway down instead of near the top, and ends 32 px below the chips), with a progressive blur of the map under it: full strength behind the title, less in each of 8 bands below. A masked blur doesn't render on iOS, so it's bands reading one shared backdrop. Same in Storybook with a masked `backdrop-filter`.
- **Full view scrolls everywhere.** The photos and title used to be the handle for pulling the sheet down, which also meant you couldn't scroll from them. Now every page scrolls from anywhere and bounces at the bottom, and pulling past the top pulls the sheet. While it's pulled, moving back up lifts the sheet first. The bottom fade is 16 px instead of 24, and the last block can scroll clear of it.
- **Menu as cards:** the dish photo as a sticker (white 4 px edge, soft shadow, ±3° tilt), then the name and the whole description, which now runs to the edge. The card's footer holds the price, the faces of whoever else picked it, and Add. Add and remove now work on my earlier picks too.
- **People:** next to each person, a little pile of the dishes they picked ("No picks yet" if none), so you can see at a glance who has chosen. My pile follows what I add in Menu.
- **Overview → Details**, from the place's Google Maps card: Dine-in, Takeaway, Delivery; address; hours ("Open · Closes 11 PM"); €20–40 per person (57 reports); Find a table (TheFork); Place an order (Uber Eats); website; phone. Plain rows with Lucide icons.
- New tokens: `top-bar/blur`, `sheet/fade`, `menu/photo-edge`, `menu/photo-tilt`, `dish-pick/size`, `dish-pick/edge`, `dish/edge`; `top-bar/fade-start` 0.17 → 0.5. New components: `DishSticker` (Flutter and Storybook). New icons: clock, banknote, truck, globe, phone.
- Checked on the simulator: the header, scrolling and pull-to-close on Overview, Menu cards, People piles, and the Details rows.

### Final UI, iteration 1.5: menu as a plain list, soft top edge in the full view
- **Menu:** the same layout per dish (sticker photo, name, full description, then price, who picked it and Add), but as a plain list with hairlines instead of cards.
- **Top edge of the full view:** pages now scroll up to the sheet's edge instead of being cut 8 px below it. As content goes under the edge it passes under a progressive blur and a fade to the surface's white (32 px, blur 8). It shows only once the page has scrolled, so a page at rest isn't faded at the top. The progressive blur is now one shared component (`ProgressiveBlur`, used by the header too).
- New tokens: `sheet/top-fade`, `sheet/top-blur`.

### Final UI, iteration 1.6: tabs and close in the full view's header
- The tab switcher and the close button moved from the bottom of the full view into a header at the top, so the bottom no longer crowds. Pages start under the header and scroll up beneath it, through the same progressive blur and white fade (shown only once a page has scrolled). The header is also a handle for pulling the sheet down, as is pulling a page past its top. The bottom fade stays at the sheet's lower edge.

### Final UI, iteration 1.7: Overview photos as a Material 3 carousel
- **Order on Overview:** name and rating, then the photos, then the description.
- **Photos are a Material 3 multi-browse carousel:** a large photo first, then a medium and a small one. Each photo is a mask that grows or shrinks as it moves between those places (the picture inside isn't squashed), and scrolling snaps to whole photos. Small and medium keep the design's peek widths (36 and 62); large takes the rest. In the app it's Flutter's own `CarouselView.weighted`; Storybook has a `PhotoCarousel` that follows the same places.
- Five photos instead of three: two more of the restaurant's entrecôte, from its own menu (`brasserie-4`, `brasserie-5`).

### Final UI, iteration 1.8: what each person's picks cost, see-through header
- **People:** next to each person's pile of picks, roughly what they come to (≈ €36.20 for my entrecôte with salmon and crème brûlée), and at the bottom an estimated total from what everyone has picked so far (≈ €122.50). It follows what I add or remove in Menu. A line with two prices ("1 scoop €3.40 · 2 scoops €5.10") counts the first.
- **Header:** the white over the blurred map is see-through now (70%, new token `top-bar/bg`), so the bar is lighter while the blur keeps it readable.

### Final UI, iteration 1.9: "+N" on a pile of picks, total fixed at the bottom
- **People:** a pile shows at most two dishes, the priciest ones (usually the mains), and one more sticker counts the rest ("+2", "+3"), in the count bubble's colours.
- **Estimated total** is now a footer fixed at the bottom of People while the list scrolls above it, on one line: "Estimated total" (Label/LG) on the left, the amount (Heading/LG) on the right. The line explaining it is gone.

### Final UI, iteration 1.10: times from a running clock, not typed in
- Every plan has a real start (day and time), and the labels come from it against the demo's "now", which starts at Thursday 14 May, 15:56 and runs on while the app is open (it ticks every minute, so "In 64 mins" counts down).
- How soon, on the pins: minutes for the next hour and a half ("In 64 mins"), then hours the same day ("In 2 hrs"), "Tomorrow", then days ("In 2 days" … "In 5 days"); "Now" once it starts. The Up next card's time chip ("5 PM • Today") and the People subtitle ("Today, 5 PM") come from the same start.
- Day filter: tapping a chip that's half off the edge slides it fully into view.

### Final UI, iteration 1.11: People tab is now Group
- The full view's third tab is called **Group**: it holds who's coming, what each person picked, roughly what they'll pay and the total, not only a list of people, and it fits plans without a menu too. The page title stays "Who's coming". Storybook's story is now "Full view · Group".

### Final UI, iteration 1.12: tabs that move, titles that line up
- **Titles:** Menu and Group open with a title the same size and in the same place as the restaurant's name on Overview (Heading/MD), with their line under it.
- **Tab change, following Emil's rules:**
  - The old page leaves toward the side away from the new tab: it fades, blurs (4 px) and slides 24 px in 160 ms, ease-out.
  - 80 ms later the new page comes in from the side its tab is on. It cascades block by block, 40 ms apart and capped at 8, each fading in, sharpening and settling over 260 ms, ease-out.
  - Exit is quicker than entry, and the direction follows the tab order, so going right moves left.
  - Menu and Group now stagger per dish and per person, instead of a whole section at once.
  - With reduced motion, nothing slides; it only fades.
- **No empty flash:** the Menu and Group pages had one empty frame while the already-loaded menu was handed over; they now draw it on the first frame.
- **Storybook:** a block no longer remounts and replays its entrance on every re-render (tapping Add did that). It uses full transform strings, so Motion runs on the compositor.
- New tokens: `tab/slide`, `motion.page-enter-delay-ms`.

### Final UI, iteration 1.13: blur and fade under the bottom controls
- The action bar gets the top bar's treatment, upside down: a light progressive blur of the map (8, strongest at the bottom), under a 70% white that fades out 32 px above the buttons. The progressive blur component now works from either edge.
- The map's credit moved out of the map onto the bar's layer, so the blur never softens it (the OSM credit stays readable).
- New tokens: `action-bar/bg`, `action-bar/blur`, `action-bar/fade-start`.

### Final UI, iteration 1.14: menu filters, an "added" toast, my face on what I pick
- **Menu filters** right under the Menu title: All, Picked, Starters, Mains, Desserts, Drinks. They are the same toggles as the days, now one component (`ToggleChips`, tokens renamed to `toggle-chip/*`), and they combine ("Picked" plus "Desserts" shows both). A new filter swaps the list: the old one fades out, the new one cascades in from below. Each menu section carries its course in the data.
- **Add:**
  - The plus/check swap now grows in from a little smaller and sharpens from a blur.
  - A toast comes up from past the bottom edge: a flat brand-blue pill (not glass, so it isn't another button) with a check, "Added for Today, 5 PM" and Undo. It stays 3 s (`motion.toast-ms`) and leaves the way it came, a little quicker. A new add while it's up just restarts it, and Undo takes the dish back off.
  - My face joins the faces of whoever else picked the dish, coming in from Add's side, and leaves the same way.
- New tokens: `toast/bg`, `toast/fg`, `motion.toast-ms`. New components: `ToggleChips`/`ToggleChip` (replaces `DayFilter`), `Toast`, `ToastSlot`.

### Final UI, iteration 1.15: live locations, who's here, a decision log
- **Live locations, simulated.** Each person who's coming has a route to the restaurant and times to leave and arrive, on the demo clock. In the real app this would be their location, shared passively from 90 minutes before. Positions and statuses are worked out from it, and nobody taps anything:
  - "Already there";
  - "On the way · 8 min";
  - "Leaves in 20 min". Mine comes from how far the blue dot is from the place: the start, minus 5 minutes early, minus the walk.
- **On the map,** people on their way show as their stickers. Anyone closer than a sticker's width merges into one pile with "+N". Whoever has arrived leaves the map:
  - on the mini pin, they show as a small pile on its corner;
  - on the card, as the first chip ("1 here" with their faces). The time chip then shows just "5 PM", so the row fits.
- **Group's statuses** come from the same simulation and count down.
- **Names in Group and Menu are 16 px** (Label/LG).
- **`DECISIONS.md`:** a new log of what was decided and why, for the presentation.
- New components: `PeopleLayer`, `FacePile` (Flutter and Storybook), and faces on `InfoChip`.

### Final UI, iteration 1.16: the time moves up to "Up next"
- The Up next card's time left the chip row and sits by the label: "Up next · 5 PM" (or "Up next · Tomorrow, 10 AM"). The two chips left, who's coming / who's here and the price level, are the same width, so "2 here" no longer squeezes anything.
- Not installed on the phone yet: the performance session is profiling on it.

### Final UI, iteration 1.17: actions out of the way while panning
- The bottom actions slide down past the edge and fade out as soon as the map is moved (160 ms), and come back up once it has been still for 260 ms (also 260 ms to return), ease-out both ways. Their white is less see-through, 85% instead of 70%.
- The full view has 16 px more room between its header (the tabs) and the page title.
- Not installed on the phone yet: the performance session is profiling on it.

### Final UI, iteration 1.18: price range, who's here on the corner, a softer header, my dot breathes
- The card's chips are who's coming (+3) and the real price range (€20–40, from the Google Maps details) instead of €€. "1 here" left the chips: whoever has arrived sits on the pin's top-right corner, across it on the mini pin and just inside it on the card, and stays on that corner through the morph.
- The bottom actions wait until the map has been still for 800 ms before coming back (was 260 ms).
- The top bar's edge over the map no longer shows a line: its blur now eases off to nothing (falls with the square of the distance, the faintest bands dropped) and its white fades along a smoothstep instead of a straight ramp. The bottom bar and the full view's header use the same fade. We tried hanging the fade 24 px lower; it blurred the top of the card (and the face on its corner), so it went.
- My location breathes: only the blue scales (to 75% and back, 1.2 s each way, an ease-in-out sine); the white rim stays still. It holds still with reduced motion and pauses while the full view covers the map or I'm off-screen.
- Storybook: the same chips, corner badge and breathing dot; new tokens settle-ms, pulse-ms, ease-breathe and me/pulse-scale in Foundations → Motion. InfoChip's `faces` is gone (nothing used it any more).

### Final UI, iteration 1.19: smooth frames on the phone (nothing looks or moves differently)
- **Measured** on Bogdan's iPhone 15, profile build (on 1.14, before 1.15–1.18 were merged in), with `app/perf/trip_perf.dart`: it plays each scenario with scripted touches at the display's pace and records every frame (how to run it is at the top of the file). Before, the GPU side (raster) took 18–25 ms a frame in every scenario, against 16.7 ms at 60 Hz, so most frames came late. The UI side was never the problem (about 1 ms).
- **What cost the frames**, found by switching each suspect off in turn:
  - The inset shadows on every glass button, blurred again three times per button every frame: half of the map's 18 ms, and one Add button per menu row.
  - The bars' progressive blurs: about 5 ms.
  - With the full view up, the map and bars drawn and blurred again behind it on every frame.
- **Changes:**
  - Glass inset shadows, and the pin tail and edge arrow shadows, are blurred once per shape and size, then reused as an image.
  - Behind the full view, the map and bars become a picture from the first frame of opening (when the map isn't moving), and the blurred backdrop joins it once the view rests open. Both go back to live drawing as it closes. When something behind changes (the minute tick), the picture is retaken once nothing is moving.
  - The top and bottom bars' blurs share one read of the map. The full view's header skips the blur band that sits under opaque white.
  - The stagger and page-leave blurs stay in place and switch off once sharp. Removing them rebuilt every block, all 118 menu rows at once, at the end of each entrance.
- **Results** (raster ms per frame, average / 90th percentile; late frames):

| Scenario | Before | After |
| --- | --- | --- |
| Map: pan and zoom | 18.0 / 19.4; 178 of 240 late | 4.7 / 7.8; 3 of 239 |
| Up next: open and close the full view | 22.4 / 28.4; 187 of 191 | 3.1 / 5.1; 2 of 247 |
| Full view: switch tabs | 20.4 / 23.7; 223 of 225 | 2.2 / 3.7; 4 of 313 |
| Full view: scroll the Menu | 25.5 / 26.3; 530 of 530 | 3.9 / 4.3; 0 of 622 |
| Full view: Overview photos and scroll | 17.8 / 19.9; 398 of 540 | 4.2 / 4.5; 2 of 628 |
| Full view: scroll Group | 17.9 / 18.8; 238 of 274 | 4.5 / 4.6; 3 of 360 |
| Map: tap day filters | 18.7 / 21.8; 225 of 247 | 6.3 / 13.4; 9 of 273 |

- **Checked:** screenshots of the old and new builds on the simulator match pixel for pixel; the cached shadows are within 3/255.
- **With 1.18's breathing dot** (main + these fixes): the map redraws about 60 times a second even at rest, and each redraw runs the bars' blurs again. On a cool phone that's 4.8 ms a frame with none late; plain 1.18 is 18.9 ms with every frame late. On a warm phone, after a few minutes, it climbs back to about 20 ms; with the bars' blur off it's 3.6 ms. The day filter shows the same thing.
- **Still open:**
  - The breathing dot keeps the bars' blur running. Options that keep it: hold the bars' blur as a picture while only the dot moves (no visual change), or breathe at 30 fps (half the work, hard to tell apart).
  - Opening Menu builds all 118 rows in one frame: about 50 ms of UI work, so one visible hitch at the start of the switch.
  - The page being left is rebuilt from scratch on every tab change, so it vanishes at once instead of fading, blurring and sliding out as 1.12 describes. Fixing it changes the motion, so it waits for a decision.

### Android version: built and checked on the emulator
- `app/android/` added with `flutter create --platforms=android` (app ID `com.bogste.tripup`, name TripUp, internet access declared so release builds can load the map).
- Built as a release APK (`releases/TripUp-android.apk`, 32 MB, arm64) and checked on the Android emulator (Pixel 8, Android 16): map, card, header and bottom blur, full view, Menu. It renders like the iPhone. Speed isn't checked: the emulator runs on the Mac's GPU.
- Two fixes Android needed. Its first frame comes before the screen has a size: the safe area for pins turned inside out (and clamping into it threw), and the pin measured its card as 0 × 0 and never measured again, so only the tail showed. Now the safe area is never inside out, and the pin waits for a real size.
- The builds hung at first because iCloud had moved project files off the disk to make room (the Android tools take about 6 GB). See `app/README.md`.

### Final UI, iteration 1.20: no blur under the bars
- Bogdan's call after the measurements in 1.19: the blur under the top and bottom bars was the biggest GPU cost on the map, and with the breathing dot it ran 60 times a second. On a warm phone that made every frame late, even at rest.
- Both bars now only fade the map out under their see-through white; the fades themselves didn't change. The full view's header keeps its blur.
- Measured beforehand on the phone with the blur switched off: about 3.6 ms a frame and no late frames, where it had been about 20 ms with nearly every frame late.
- The map's labels now show sharp through the white behind the title, the day chips and the buttons.
- Tokens `top-bar/blur` and `action-bar/blur` are removed; Storybook's bars drop their `backdrop-filter` too.

### Final UI, iteration 1.21: three actions, three pop-ups, a blue tail, pins in the corners
- **Footer** (Bogdan's Figma, node 70:5362): Itinerary, Money (the group as one pile of stickers) and Add, 56 px each. A white fade from the bottom, no blur. The map's credit moved under the buttons.
- **Pop-ups** rise from the bottom in the full view's place, over the same blurred map, and close with ×, a tap outside, or a pull down. New `TripSheet`, `SheetSection` and `SheetRow` (`lib/components/trip_sheet.dart`); the pages are in `lib/components/trip_pages.dart`.
  - **Itinerary:** every day, opening on today. Visited places get a check; plans show their time, and Up next is marked. Tapping one flies the map there.
  - **Money:**
    - "You owe Maya €181.50" with Pay, which flips to "You're square with Maya" with a toast.
    - Then the €726 spent so far, and 3 payments instead of 9.
    - Then each person's balance (Ren joined today), and the expenses.
    - Tonight's dinner shows as an estimate from the menu's picks.
  - **Add:** Plan something (three ideas, each going into a free slot, shown at once on the map and the itinerary), or Invite someone (a link to copy).
- **Card chips** (Figma 70:5191): "4 coming", or once people arrive their faces and "here", next to "€20–40". The price shrinks to its text once four or more faces need the room. The corner pile is back to the mini pin only.
- **Blue tail** (Figma 67:5034): `pin/tail` is `color.bg/brand`, with a white edge just inside.
- **Edge pins** go down beside the buttons. They avoid only the buttons' row (`PinArea` with a dock), not the whole width.
- Tokens:
  - new: `chip/face-overlap` 10, `pin/tail`, `pin/tail-edge`, `sheet/compact-height` 480;
  - changed: `action-bar/bg` 100% white, `action-bar/fade-start` 0.
  - New Lucide icons: copy, user-plus, map-pin-plus, chevron-left, circle-check.
- Android: checked on the emulator before these changes (card, full view, tabs, Add with toast, Group, day filter, panning). The widgets were missing there only because the emulator still had the build from before the 0 × 0 fix.

### TestFlight build 1.0.0 (1): app icon, iPhone only
- **App icon:** the location button from Figma ("ikonica", node 73-5468), centred on the app's canvas grey with a soft shadow below. Before, it was Flutter's placeholder. The dark variant and the raw Figma export are kept in `Assets/app-icon/`.
- **For the App Store:** the app runs on iPhone only, in portrait. It declares that it uses no non-exempt encryption, so App Store Connect doesn't ask on every build.
- **The archive** (1.0.0, build 1) is built from main at 539889d plus these changes. Uploading it and the public TestFlight link need Bogdan's Apple account.

### TestFlight build 1.0.0 (2) and the Android icon (branch `release/1.21-testflight`)
- **TestFlight 1.0.0 (2)** is built from 1.21 plus the TestFlight settings and app icon above (`flutter build ipa`). The archive is open in Xcode's Organizer. The upload needs Bogdan's Apple account in Xcode, plus the app in App Store Connect (TripUp, `com.bogste.tripup`). Build 1 shouldn't be sent: it predates 1.21.
- The same build is installed on Bogdan's iPhone 15.
- **Android icon:** the same light icon, as an adaptive icon (`mipmap-anydpi-v26`). The launcher's mask cuts it to shape over the icon's own grey (#F4F4F5). The full icon is also kept for older launchers. The APK is rebuilt (`releases/TripUp-android.apk`); checked in the emulator's app drawer.
- From now on, every bigger change gets its own branch and goes into `main` once it's checked.
- **Storybook mirrors 1.21:**
  - the three-button footer with the group pile, the blue tail, and the face chips ("4 coming", faces + "here");
  - new Pop-ups stories (Itinerary, Money with Pay, Add with ideas and invite) on `TripSheet`, with the same numbers as the app.
  - Not mirrored: pull-down to close, and the springs (Storybook uses ease-out tweens).
  - New stories: `pop-ups--itinerary`, `pop-ups--money`, `pop-ups--add`, `widget-up-next--mid-nobody-there`, `widget-up-next--mid-four-there`, `components-button--text`, `foundations--component-dimensions`.

### Final UI, iteration 1.22: no people pill in the header
- The two-faces-and-"+3" pill is gone from the top bar (app and Storybook); the trip's name gets the room. `PeopleButton` is removed in both, and so are `topFaces` and `moreFaces`.

### Demo moments (branch `feature/demo-moments`)
- A Demo button in the top bar ("Demo · 3:56 PM") opens Story, a pop-up listing the brief's moments in order. Jumping moves the demo clock (`jumpTo` in `data.dart`), and the people, the "here" chip, times and the Up next card follow at once.
  - Built so far: On the way (3:30 PM), Before dinner (3:56 PM), Everyone's there (4:50 PM), and Settle up, which opens Money.
  - Not built yet, shown greyed: Your trips, Ren joins, Dinner poll, The poll closes, The bill, Squared up.

### Final UI, iteration 1.23: the dinner, from arriving to squared up (branch `feature/dinner-bill`)
- **Active dinner:** `isActive` (time window plus someone in the geofence). The card says "Now · You're here", the mini says "Now". The full view's tabs become Group · Menu · Overview (`DetailPage.forPlan`).
- **People:** Ren comes to dinner (route, picks: entrecôte with salad, Sumol). I walk there too (`myPosition`, the blue dot moves).
- **Menu picks:** the wine (Soalheiro Granit) for me, Maya and Leo; Sumol for Nic and Ren. My picks are shared app-wide (`myPicks`), so the bill matches what I chose.
- **Scan the bill** (`lib/components/bill_scan.dart`):
  - The camera view: the paper bill on the table, a frame closing in and turning blue, a reading line (`scan-find-ms` 600, `scan-read-ms` 900). Then the bill rises with each line on the faces of whoever had it.
  - Tap a line to change who had it. Per-person totals are at the bottom, "You paid · Change", and "Add to the trip's money".
  - The bill: €228.80 (couvert ×5, 3 entrecôte with salad, salmon, seitan, fries, fondant, 2 crème brûlée, 2 Soalheiro, 2 Sumol, 2 Luso water). Shares: you €59.12, Maya €53.32, Nic €35.22, Leo €50.42, Ren €30.72.
- **Money:**
  - The dinner becomes an expense with shares: total €954.80, 4 payments instead of 13 (Leo → Maya €185.92, Nic → Maya €136.72, Ren → Maya €30.72, You → Maya €11.82).
  - The others pay 30 s apart, each as a note at the top. Every payment has a Why.
  - The last payment brings "Lisbon is squared up" for everyone.
- **Group tab:** while the dinner is on, the Estimated total gets Scan the bill. After the scan, it shows the exact amounts, the bill's total, and "See who owes what" (closes the full view, opens Money).
- **Demo moments:** Everyone's there (5 PM), The bill (7:30 PM), Settle up (7:40 PM, bill in, the others start paying), Squared up (7:50 PM, everyone paid). Jumping sets the money to match.
- Tokens: `scan/*` colors and sizes, `scan-find-ms`, `scan-read-ms`. Icons: scan-line, receipt. `TripSheet` gets a fixed `footer`.
- **Checked:**
  - iPhone simulator: the whole story, frame by frame for the scan.
  - Android emulator: Now, Group first, scan, bill in, Money.
  - Installed on Bogdan's iPhone.
- **Storybook mirrors it**, with the same numbers. New stories:
  - `widget-up-next--mid-now`, `screens-trip--group-dinner-on`, `screens-trip--group-bill-in`;
  - `pop-ups--scan-the-bill` (with Replay), `pop-ups--money-dinner-on`, `pop-ups--money-bill-in`, `pop-ups--money-squared-up`.
  - In Storybook the others pay 6 s apart (30 s in the app), and "See who owes what" doesn't navigate.

### Final UI, iteration 1.24: the dinner poll (branch `feature/dinner-poll`)
- **Poll data** (`data.dart`, poll section):
  - three options with real ratings and prices;
  - the others' votes on the demo clock (Maya 2:30, Leo 2:36, Nic 2:41, Ren 2:47), plus my vote;
  - it closes at 3 PM or when all five have voted; the leader wins (a tie goes to whoever got there first);
  - `dinnerChoice` decides whether tonight's plan exists, with `pollUndone` and `pickedDinner` for Undo and the hand pick.
- **`lib/components/poll.dart`:**
  - `PollCard` on the map while the poll is open;
  - `PollPage` in a pop-up: place cards (sticker, rating · food · price, walking minutes), voters' faces and count, Leading / Won / Tonight, and Vote / Your vote;
  - after Undo, Add to tonight.
- **Notes:** "Maya started a poll…" when it opens, and "La Brasserie won · added to tonight" with Undo when it closes. Only changes that just happened make a note; a demo jump over them doesn't. The Toast label now shortens with an ellipsis when it's too long.
- **Demo moments** Dinner poll (2:30 PM) and The poll closes (3 PM) are built; every jump resets the poll.
- Tokens: `poll/lost-opacity` 0.6, `motion.toast-action-ms` 6000.
- Checked on the simulator: open, vote, leading, close, the winner on the map, Undo, the hand pick.

### Final UI, iteration 1.25: Bogdan's notes on the dinner (branch `feature/bill-polish`)
- **Tabs:** they keep their order (Overview · Menu · Group); while the dinner is on, the sheet only opens on Group (`DetailPage.openingFor`).
- **Group:** "Who's here · N of 5 here · Now" while the dinner is on. Scan the bill and See who owes what are full width and 56 px (`TuTextButton` gets `size` and `wide`).
- **The bill:**
  - the total big at the top;
  - every face on each line;
  - the line editor in a grey block;
  - per-person totals that scroll sideways once they don't fit;
  - who paid as an upward menu (`_PayerPicker`: OverlayPortal anchored to the trigger, fade and scale from its corner, 160 ms in and 120 ms out).
- **Camera:** a plain `scan/bg` (zinc 900), with no photo. In review the colour fades, so the bill sits on the full view's blurred map. Add lets the bill fade and blur into the page under it.
- **Notes:** `TripSheet` lost its own toast; every note goes through `tripNotice` at the top, the Menu's "Added" with Undo included.
- Token removed: `scan/photo-opacity`. Icon: chevron-up.
- **Poll fixes** (found while mirroring in Storybook):
  - The countdown and the early close count only votes cast by now; before, they peeked at votes still to come.
  - A tie now goes to whichever place reached that count first, as intended; before, the first in the list won it.
- Tapping a note's action (Undo) also puts the note away (the Menu's Undo used to leave it up). `ToastSlot`, the old bottom toast, is removed: nothing used it.
- **Storybook mirrors 1.24 and 1.25.**
  - New stories: `widget-up-next--poll-card`, `pop-ups--poll-open` (live, with Replay), `pop-ups--poll-closed`, `pop-ups--poll-undone`, `pop-ups--itinerary-poll-open`.
  - The bill polish, the camera, the payer menu and notes from the top are mirrored; there's a new shared `Notice`.
  - The payer menu renders at the camera's top level rather than through a portal; it looks and behaves the same.

### Final UI, iteration 1.26: your trips and Ren joining (branch `feature/trips-and-joining`)
- **Your trips (step 01).** The app opens on a list of trips:
  - the one you're on, big and on top: the places so far as stickers, "Lisbon · 12–21 May · Day 3 of 10", what's on now ("Up next…", "Poll open…", "Now: dinner at…"), who's on it, and what you owe;
  - Porto, coming up;
  - three past trips, folded away (each "squared up").
- **Into the trip and back.** Tapping the current trip zooms the list past you as it fades (160 ms) and the map is there; Back settles the list from that zoom (260 ms, ease-out). With reduced motion it only fades. While the list covers the map, the map isn't drawn and its breathing dot stops.
- **Ren joins (step 03), on Ren's phone.** The Demo's "Ren joins" (2:10 PM) shows what Ren sees from the link:
  - "Ari invited you to…", the four faces, his name (no account, no password), Join the trip;
  - then the trip so far: where they stay, where they've been, what's coming (the dinner poll, with "you can vote"), and the money rule ("the €726 spent before you joined stays with the four of them");
  - Open the trip goes back to Ari's map, where everyone hears "Ren joined the trip".
- **Invite → See what they'll see:** the same screens as a preview (empty name, nobody joins).
- Ren isn't on the map before he joins (`onTrip`).
- Token: `motion/page-zoom-scale` 1.04. Icons: bed-double (`TuIcons.stay`), vote (`TuIcons.poll`).
- Checked on the iPhone simulator. A "lost tap" while testing turned out to be the simulator's screenshot arriving before the next frame, not the app.
- **Storybook mirrors 1.26:** Screens/Trip gets Your trips (folded and open), Ren's phone (invite and the trip so far) and the Invite preview; Pop-ups gets Add · invite. The card's arrow is drawn but not separately clickable (no button inside a button on the web).

### Final UI, iteration 1.27: the poll card (branch `feature/poll-card`)
Bogdan's notes on the poll card: wider, a bar under each choice, who voted for what, no "Leading", and a way to put it away or make it clearer that it's live.
- **Card:** 345 wide (or the screen less its margins), left-aligned. "Live poll · closes in N mins" with a breathing red dot, the question, then each place: its sticker, name, every voter's face, and a bar of its votes (brand for the one ahead).
- **Fold:** a chevron in the card's corner folds it into a pill under the day filter; tapping the pill unfolds it. Card and pill swap with a fade and a slight scale into the top (260 ms in, 160 ms out; fade only with reduced motion). A poll that opens, or a Demo jump, shows it in full again.
- **Poll page:** the same bar on each place (on a white track, since the cards are grey), every voter's face, and no "Leading" (Won and Tonight stay once it has closed).
- Tokens: `poll/width` 345, `poll/bar-height` 6, `poll/live-dot` 8, `poll/live-dim-opacity` 0.35; colours `poll/bar-track`, `poll/bar-track-on-muted`, `poll/bar`, `poll/bar-lead`, `poll/live`. Icons: chevron-down (`TuIcons.unfold`), `TuIcons.fold`.
- **Storybook mirrors 1.27:** Widget/Up next gets Poll card, Poll pill and Poll card ↔ pill; Pop-ups › Poll · open folds and unfolds on the map. On the web the fold button can't sit inside the card's button, so a transparent open button covers the card and the fold button sits above it.

### Final UI, iteration 1.28: Bogdan's notes on the poll, itinerary, money and joining (branch `feature/poll-vote-itinerary`)
- **Poll card ↔ pill is one surface:** `PollOnMap` springs its box (`springMorph`) between the two measured sizes, crossfading the contents with a slight blur where they overlap; both contents are anchored to the box's left edge. Reduced motion: the box jumps, the contents fade.
- **Vote on the card:** each place is a row you tap to vote, with a ring (`VoteMark`) that fills with a check; bars and faces update at once. "Ratings, prices and walks →" opens the poll.
- **Itinerary:** a grey block per day, and a day filter pinned under the title (`TripSheet.top`). Opens on All, scrolled to today.
- **Money:** the top block stays; under it, `SegmentedTabs` Settle up · Balances · Expenses, one list at a time (fades in, blurs out).
- **Ren's phone:** the invite is centred on the screen.
- Tokens: `poll/mark` 24, `poll/mark-ring` 2.
- Home screen: waiting for Bogdan's design.
- **Storybook mirrors 1.28:** the poll's one-surface fold (Motion spring between measured sizes), voting on the card (new story Widget › Poll card · your vote), the itinerary's filter and day blocks (Pop-ups › Itinerary · one day), Money's tabs (Money · balances, Money · expenses) and the centred invite. No hairlines inside the itinerary's grey day blocks, in either: they didn't show on the grey.

### Final UI, iteration 1.29: Your trips, from Bogdan's design (branch `feature/home-design`)
- Built from Figma 75:5927: brand blue background with a white status bar; "Your trips" with a bell (no notifications yet: it says so) and my avatar; the current trip as a 438-high card with a white 5 px edge, the Lisbon still (`assets/map/home-lisbon.png`, placed as in the design and scaled to the card), four place stickers on it, a white fade from the bottom, "Happening now" with a green bead, the trip's name and dates, the faces of everyone on it, and the arrow in. Then Coming up and Previous trips (3) as light brand rows: sticker, name, dates, faces on the bottom edge. The list fades into the blue at the bottom.
- Data: Berlin (23 June - 23 July) replaces Porto; Mallorca gets the windmill sticker. New stickers: `brandenburg`, `windmill`. Icon: bell.
- Tokens: `home/*` colours and sizes, `now-dot/*`.
- The Demo button is off the home screen (it's in the trip's top bar).
- After Bogdan's look: the trip keeps its own name as the card's title, and the city leads the line under it ("Lisbon · 12 May - 21 May"); `tripCity` in the data.
- **Storybook mirrors 1.29:** Screens/Trip › Your trips (the bell shows its note) and Your trips · scrolled to the end (replaces "past open"). The card's arrow is drawn, not a separate button (no button in a button on the web). `Sticker` takes its height from CSS when no size is given.

### Final UI, iteration 1.30: Bogdan's notes on Money, the itinerary and going in (branch `feature/money-itinerary-open`)
- **Money:** tabs fill the width (`SegmentedTabs.wide`); one left edge for every text; each tab's list has a section title; the estimate note is gone; a footer holds "Spent so far" (count, my part, the total) and, while the dinner is on, Scan the bill (`MoneyFooter`). The pop-up's subtitle is "5 people · split by who had what".
- **Itinerary:** today first, then the days ahead, then the past ones; a hairline between days and no grey blocks (like Group); no check on "Been there".
- **Going in:** the trip screen opens out of the trip card (scaled to the card's width, clipped to its rounded rect, both growing to the screen on `springExpand`; Back on `springCollapse`), fading in over the first 30%; the list fades and leans in toward the card. The poll card no longer shows over Your trips or mid-transition.
- The Add pop-up waits for Bogdan's design.
- **Storybook mirrors 1.30:** wide `SegmentedTabs`, Money's sections and `MoneyFooter`, the itinerary's order and dividers, and `HomeLayer` opening the trip out of the card (one motion value for both layers; the hidden layer keeps its scroll).

### Final UI, iteration 1.31: the opening lands still, Money's pill, and Add rebuilt (branch `feature/add-and-opening-fix`)
- **Opening the trip:** the wrappers around the trip no longer change when the transition lands, so the map and the Up next card aren't rebuilt and nothing plays twice (checked by logging the card's morphs: one at launch, none on going in, out and in again). New `springOpen` (0.5 s, no bounce).
- **Money:** "You owe Maya" is a rounded pill (padding 16/8/8/8): the line and amount left, Pay right.
- **Add:** `AddStep` lives in the trip screen, so `TripSheet` shows a back button (`onBack`) and the step's title, which crossfades. Choices are plain rows with big titles. Invite is centred (`TripSheet.centered`). Plan something: a search over `lisbonPlaces` (20 places, accent-insensitive), "Near you" by walking time, a small still map of the pick (`_mapOf`, with the map's credit), day chips, From/To wheels (`CupertinoDatePicker`, 15 min), "Send to the group" → `addedPlans` with an end time (`Plan.endHour`), the map flies to it, a note at the top. The sheet animates between compact and full height (`AnimatedPositioned`, ease-in-out).
- Tokens: `spring-open`, `plan/map-height` 160, `plan/picker-height` 180. Icon: search.
- **Storybook mirrors 1.31:** Money's pill; Add with the step in the header, the centred invite, Plan something (search over the 20 places, a picked place, day chips, From/To with a small custom wheel in 15-minute steps, Send); the itinerary's "until". New stories: Add · plan, Add · plan · search, Add · plan · place picked. No live map in Storybook: the small map is a plain block with the sticker and the credit.

### Final UI, iteration 1.32: the trip opens like an Airbnb listing (branch `feature/add-and-opening-fix`)
- From Bogdan's recording of Airbnb (`RPReplay_Final1792837535.mov`, frames at 30 fps): the list stays and blurs/washes out (`trip-open/wash`, the sheet's backdrop blur); one rounded surface grows from the card's rect to the screen, holding the card's still (`TripCardStill`) and, for the first quarter, the card's words (`TripCardFace`, at card size); the live trip fades in over 0.45–0.85 of the way with a slight seam blur; the corners square up over the last 30%; a lift shadow while in the air. Back runs it in reverse on `springCollapse`.
- `springOpen` is now 0.45 s (no bounce). The home card is split into `TripCardStill` and `TripCardFace` so the opening can carry them.
- Checked at 10× slow motion, opening and closing, on the simulator; nothing moves after it lands.
- **Orchestrated entrance** (Bogdan's note): `entrance.dart` (`TripEntrance` clock, `EnterItem`, `EnterOrder`): back, title, Demo, six day chips, the footer's three buttons, each 30 ms after the last (`open-delay-ms` 220, `open-stagger-ms` 30, `open-item-ms` 200), then Up next opens from its pin (and the poll card shows only then). Up next waits small while you're on your trips and jumps there unseen (`PlanPin._go` jumps when the trip isn't ticking), so it never shrinks on screen. Whole thing ≈1 s. Checked at 8× slow motion, and in, out and in again.
- **Storybook mirrors 1.32:** `Entrance.tsx` (the same order and timing), `TripCardStill`/`TripCardFace`, and `HomeLayer` as the Airbnb-style opening, with Up next opening from mini to mid when the last control starts. The opening and closing springs use Flutter's own spring formula so they keep time with the entrance clock.

### Final UI, iteration 1.33: the trip opens on today
- `_days` starts as `{today}` and `_goIn` resets it (and the camera) before the opening, unseen. `_setDays` keeps Up next open when the picked days include its day. Storybook's trip screen opens on today too.

### Final UI, iteration 1.34: Bogdan's poll widget and Overview, details from the itinerary, a clean landing (branch `feature/poll-widget-design`)
- **Poll** (Figma 82:3): `PollCard(expanded, onToggle, onDetails)` replaces `PollOnMap`/`PollPill`/`VoteMark`. Compact: live line + dot, the question, the meta line with the table's faces (not yet voted at 0.4). Open: a scrim (`poll/scrim` = #001e81 at 23%, blur 2.5) behind the same card, which grows (`AnimatedSize`, ease-in-out; folding: the places blur out first) while `_Place` cards stagger in: name, star + rating • food • price, sticker 48, an 8 px brand bar on white, Details, voters, and a 40 px check button (soft, or primary once yours). Tokens: `poll/scrim`, `poll/scrim-blur`, `poll/option-sticker`, `poll/meta-face`, `poll/meta-face-overlap`, `poll/not-voted-opacity`; `poll/bar-height` 6 → 8, `poll/live-dot` 8 → 9; primitive `blue.975`.
- **Overview** (Figma 62:4828): `KnowSection` on `bg/subtle`, tips as `KnowTip` (muted block, label-sm brand, no arrow). `KnowRow` removed.
- **Itinerary → details:** `ItineraryPage.onOpen`; `_openDetails` turns the pop-up into the full view in place (`_sheetPlan`, content from a third in, `springSnap`), closing slides it down. `DetailSheet` takes `mapOf` and handles plain plans (time and distance, a small map, Menu only with a menu).
- **Landing back on Up next:** the shrinking card copy gets `here`; `PlanPin` no longer hides the tail while the full view is open. Checked at 8× slow motion.
- A plain plan's Group no longer shows La Brasserie's menu picks (found while mirroring).
- **Storybook mirrors 1.34:** `PollCard` (compact and open, `PollScrim`), `KnowTip`, details for any plan (Menu only with a menu, a map stand-in for plain plans), itinerary plan rows opening details in place. Stories: Poll · compact, Poll · open, Poll · open · your vote, Full view · a plain plan.

### Final UI, iteration 1.35: the poll outside the app on iOS (branch `feature/poll-live-activity`)
- **Live Activity** (`ios/PollWidget`, a new widget extension, iOS 17): `PollLiveActivity` for the lock screen and the Dynamic Island (compact "● Poll" + countdown, minimal dot, expanded places). Shared with the app: `ios/Shared/PollActivityAttributes.swift` and `PollVote.swift` (`PollVoteIntent`, a `LiveActivityIntent` that runs in the app).
- **Notification** with a vote action per place (`UNNotificationCategory`), handled in `AppDelegate` → `PollBridge.vote`.
- **Bridge:** `ios/Runner/PollBridge.swift` (channel `tripup/poll`: start, update, end, clear, takeVote; votes go back as `voted`) and `lib/platform/poll_activity.dart` (`PollActivity.sync` from `_pollTick` and on my vote; the in-app note only when the notification couldn't go out).
- **Tokens:** `build-tokens.mjs` also writes `ios/PollWidget/Tokens.swift` (colours light and dark, spaces, radii, dims, text sizes). New dims `poll/activity-mark`, `poll/activity-bar`, `poll/activity-timer`.
- `NSSupportsLiveActivities` in the app's Info.plist. The extension is embedded before Flutter's Thin Binary phase (else Xcode reports a cycle).
- Checked on the iPhone 16 simulator: the activity on the lock screen and in the Island, voting from the lock screen (the activity updates at once and the app shows the vote), the notification as the poll opens. Not checked there: the notification's buttons (the simulator doesn't open a notification on a long press); same code path as the activity's buttons.

### Final UI, iteration 1.36: the poll's fold and a clearer Live Activity (branch `feature/poll-polish`)
- **Poll card fold:** `PollCard` is stateful with one controller (`enter` to open, new `fold` 200 ms to close) and an ease-out edge both ways; the places are clipped by `Align.heightFactor` and fade over the first half of the fold; the scrim fades over `fold` too. Checked at 8× slow motion.
- **Live Activity:** places as three side-by-side cards (sticker 28, ring 20 / filled check, name + count, 4 px bar); whole card is the vote; brand-subtle when picked, 0.6 once another place won; the lock screen follows `colorScheme`; padding and gaps cut to fit the 160 pt height; the Island's expanded view uses the same cards with "2/5 voted". Checked on the simulator in light and dark, voting from the lock screen.
- Tokens: `fold-ms` 200; `poll/activity-mark` 28 → 20.

### Final UI, iteration 1.37: from outside the app straight to the poll
- The notification's tap (`UNNotificationDefaultActionIdentifier`) and the Live Activity's tap (`widgetURL` "tripup://poll", lock screen and Island; URL scheme `tripup`, `FlutterDeepLinkingEnabled` off; `PollBridge` is a `FlutterSceneLifeCycleDelegate` added via `registrar.addSceneDelegate`) set a flag Flutter takes at start (`takeOpen`) or hears at once (`openPoll`). `_showPoll` closes what's up, goes into the trip, and opens the poll card after the entrance (`EnterOrder.total`), or the poll pop-up if it has closed.
- Checked on the simulator: from Your trips, tapping the Live Activity on the lock screen opens the trip with the poll open.

### Final UI, iteration 1.38: Android performance and edge to edge (branch `fix/android-perf`; nothing looks or moves differently; made on top of 1.32 as "1.33", renumbered when merged after 1.37)
- **The report:** on a tester's Huawei Y7 2019 (Android 8.1, Snapdragon 450: eight slow Cortex-A53 cores, Adreno 506, 2-3 GB) the app "barely opens": about 10 s before the map is there. On Android the status bar and navigation bar sat on top of and under the app instead of the app drawing under them as on iOS.
- **Measured** with a new startup log (`lib/startup_timings.dart`, below) on two emulators: an Android 8.1 one set up like the Y7 (720 × 1520 at 2x, 2 GB, 4 cores) and the Pixel 8 one (Android 16). No Android phone here: the emulators run on the Mac's CPU and GPU, so their milliseconds are not a phone's. They show where the time goes, not how long it takes on the Y7. On Android 8.1, Flutter 3.47 draws with Skia (Impeller needs Android 10); on the Pixel emulator with Impeller (OpenGL ES).
- **What cost the time:**
  - Drawing the map's vector tiles. vector_map_tiles draws every tile on the UI thread; on the Y7-like emulator about half a second a tile, and the first screen asked for 24 (the 8 on screen and a ring around them), so the map took 22-28 s there. All that time the UI thread was busy, so the trip's opening (0.45 s) took 7-9 s: "barely opens".
  - Fetching them: 24 tiles of about 200 KB each (5 MB), each over a new TLS connection, and none before the tile list (TileJSON) came back from the network, which only started after the first frame.
  - Bitmaps much bigger than the screen: the Lisbon still on the trip card was 3584 × 2048 (30 MB decoded) for the 722 × 876 pixels the card shows; the 21 stickers were about 600 px tall (28 MB decoded) for at most 80 pt on screen.
- **Changes:**
  - **The tiles around Lisbon come with the app, already drawn** (Android): `assets/map/tiles/`, 111 tiles (zoom 14 around the opening view, every plan and every place visited; the whole trip at 13 and 12), 5.1 MB as WebP. `tools/bake_map_tiles.sh` draws them on the Android emulator with the app's own tile code. The app only uses them while the style is the one they were drawn with (its hash is in the index), and draws every other tile on the phone as before.
  - **Our own tile layer** (`lib/components/map_tiles.dart`, from vector_map_tiles' parts; it draws what `VectorTileLayer` drew): one HTTP connection pool for all tiles; the tile list kept on disk (refreshed in the background, fetched again if this week's tiles are gone); loading starts right after the first frame; the tile workers (isolates) and the parsed style are set up a second after it, or when a tile first needs them. vector_map_tiles is pinned to 9.0.0-beta.13.
  - **The Lisbon still is cut to what the card shows** (730 × 884, the same 2 px a design unit, so the card is the same pixels; the whole one is in `Assets/map/home-lisbon-full.png`): 2.6 MB → 0.23 MB, 30 MB → 2.6 MB decoded. Storybook's rect follows.
  - **Stickers are 320 px on their long side** (still 1.3 × what a 3x screen needs at the largest they're shown; the originals are in `Assets/stickers-app-full/`): 8.4 MB → 2.5 MB, 28 MB → 7 MB decoded. Your trips before and after: on average 0.08/255 apart, the most at a few sticker edges.
- **Results** (median of 3 cold starts with no cache, ms from the process starting; Y7-like emulator, then Pixel 8 emulator):

| | Before | After |
| --- | --- | --- |
| Y7-like: Your trips' first frame | 1,149 | 1,072 |
| Y7-like: map on screen and the ring around it | 27,650 | 1,545 (24 baked tiles) |
| Y7-like: opening the trip, tap to full screen | 9,047 | 999 |
| Pixel 8: map on screen and the ring around it | 3,071 (second launch 991) | 869 (second launch 909) |
| Pixel 8: opening the trip | 782 | 774 |
| Release APK (arm64) | 37.4 MB | 34.0 MB |

  - A second run of the Y7-like emulator on its slow cores only gave the same picture: map 22.0 s → 1.3 s, opening 6.9 s → 1.0 s.
  - **Not measurable here:** the GPU. Frame raster times on both emulators follow their own graphics emulation: the Pixel one paces at about 16.6 ms whenever frames come one after another (the same build measured pan and zoom at 2.9 and at 15.9 ms a frame, run to run), and the Android 8.1 one takes 80-230 ms for any frame. Turning off both of the opening's blurs there only went from about 95-135 to 80-88 ms, so the blurs aren't its main cost; on the Y7's Adreno 506 it's unknown. The real phone's numbers come from the timings panel.
- **Startup timings, for testers' phones:** a long press on "Your trips" opens a hidden panel: the phone, Android version, cores, memory, screen, the renderer Flutter picked (Skia, Impeller with OpenGL ES or Vulkan), each step in ms since the app's process started (Dart starts, first frame, the still and the stickers decoded, the map's style, tile list, first tile, all tiles in, card tapped, trip open) and the frames of the launch and of opening the trip (count, late ones, build and raster ms). Open the trip, come back, long-press, screenshot. The same lines go to the log (`adb logcat -s flutter`, "TripUp startup"). `MainActivity` answers the panel's questions (`tripup/startup` channel).
- **Edge to edge on Android, like on iOS:** the app draws under see-through status and navigation bars, with no scrim. Icons are white over Your trips' blue and the camera, dark over the map, the pop-ups and Ren's screen (`systemBarsOver` in `theme.dart`, set per screen with `AnnotatedRegion`). Android 10+ does it through Flutter; Android 8-9 (the Y7) through `MainActivity`, which also asks for the insets again once the window is laid out (Flutter otherwise took the navigation bar for a keyboard and padded nothing). Below Android 8 the navigation bar stays the system's opaque one (its icons can't turn dark). The launch screen is Your trips' blue (`@color/home_bg`, now written by `build-tokens.mjs`), so the app no longer flashes white and doesn't change colour when Flutter's first frame comes.
- **The map's credit on Android** sits just above the navigation bar (three buttons or the gesture handle), never on it, and the action buttons sit one credit line (24 dp) higher to make room (`ActionBar.rowInset`/`creditInset`; pins and the recenter button follow). iOS keeps the credit in the home indicator's inset, as before.
- **Checked** on both emulators with screenshots: Your trips, the map, Money; the credit clear of the 3-button bar and of the gesture handle. The web build still compiles; iOS not rebuilt here (no iOS-only code changed; `flutter analyze` clean).
- `app/perf/trip_perf.dart` runs on Android too, with new scenarios (`launch`, `trip_open`, `popup_itinerary`, `popup_money`) and `--dart-define=PERF_ONLY=…`.

### Final UI, iteration 1.39: light effects on weak Android phones (branch `fix/android-light-effects`)
- From the Y7's timings panel (two photos, 24 Oct): startup 0.73 s to Your trips, 0.95 s to the whole map; frames 351 ms average at launch and 184 ms while opening the trip, from the blurs.
- `lightEffects` (`lib/design/theme.dart`), set before the first frame from Android's API level (`StartupTimings.weakGraphics`, MainActivity's `sdk`): below 29 it turns off the blur in `StaggerIn` and `fadeBlurOut`, the pin's part blur and `crossfadeSeam`, `ProgressiveBlur`, the sheet backdrop (with the flatter `sheet/scrim-flat` wash), the poll scrim, and the opening's wash and seam.
- On the Y7-like emulator it looks right (map, Money); its GPU is the Mac's, so the frame times there don't tell. The real check is the Y7's panel again.

### Final UI, iteration 1.40: Website and Directions on Overview, one darker backdrop (branch `feature/overview-actions`)
- Overview's footer stays put under the scrolling page: **Website** (soft, only when the place has one) and **Directions** (primary). Directions opens Apple Maps on iPhone (walking, to the place's pin) and Google Maps elsewhere; Website opens the browser. `url_launcher` added; Android's manifest may now ask for https links. New icon `TuIcons.directions` (Lucide `navigation`).
- Every backdrop behind a sheet or pop-up is now the expanded poll's: `sheet/scrim` = `{blue.975}@23` with a 2.5 blur (was a light wash with a stronger blur); `sheet/scrim-flat` (Android before 10) = `{blue.975}@35`. The trip's opening keeps its own blur through the new `trip-open/blur` token.
- **Checked** on the iPhone 16 simulator: the footer on La Brasserie's Overview, Directions opening Maps, Website opening Safari, the darker backdrop behind the details and Money.
- Storybook: the same footer on `DetailSheet`'s Overview (`EVENT` now carries La Brasserie's `at`); its tokens follow the new scrim.

### Figma: the final UI, 1:1 with the app (branch `feature/figma-final-ui`, 25 Oct)
- Figma file, page **Final UI**: six epics in the format of Bogdan's example section (epic card, story cards with the user story and acceptance criteria in our fonts, one section per story with its screens joined by his green connector, no Monday chip, borders excluded from layout). Your trips · The group, on the map (4 stories) · Ren joins mid-trip · Choosing dinner · The bill · Settling up: 32 screens, 440 × 956 (iPhone 16/17 Pro Max), radius 40.
- Every screen is made of components with auto layout, the way the widgets are built: buttons, chips, tabs, top and action bars, Up next, pins, sheets, pop-ups, rows, the poll, the bill, toasts and system bars (section **Components**, 176 components). Colours, spacing, radii, sizes and shadows are Figma variables and styles: the existing collections plus **Component** (55 colours, light and dark) and **Component size** (93 sizes) from `tokens.json`, and glass and surface effect styles.
- Stickers are Bogdan's sticker components; the restaurant and dish photos are the app's own. The map is the one picture: `app/perf/figma_map.dart` draws the trip map with the app's tiles at the app's camera for each moment of the story (and the small maps of single places), and records where every pin, person and me sit, so the Figma markers are placed where the app puts them (`figma/map/`).
- Checked against the app on the iPhone 17 Pro Max simulator, screen by screen (reference shots in `figma/shots/`, not used in the file).
- Added after: the story **Vote from outside the app** in Choosing dinner: the lock screen with the Live Activity, voting from it, the notification held with a button per place, and the Dynamic Island compact and held (built from `PollLiveActivity.swift` and `PollBridge.swift`; the held island and the notification's buttons can't be captured on the simulator).

### Final UI, iteration 1.41: Bogdan's buttons (branch `feature/button-edge`)
- From his buttons (Figma 129:7592): a thin white edge outside every raised button (`button/edge`, `button/edge-width` 0.96, outside), and his pressed-in edges: soft `inset.button-soft` = white 3.2 down, `zinc.350` (#c0c0c0, new) −8 with −4.8 spread, white 25% −1; primary `inset.button-primary` = `sky.650` (#0186df, new) 4.2 down, `blue.975`@51 −8 with −1.8 spread, `sky.650`@68 −2. His soft fill (#e7e7e7) stays our `button/soft-bg` (#e4e4e7).
- App: `Glass` draws the edge (a border outside the rounded box); every button, chip, pill and the Money pile follows. Storybook: the same edge as an outer ring before the inset. Figma: effect styles renamed **Button/Soft** and **Button/Primary** (they were "Glass", which they aren't), with his values, and the edge on every component that uses them.
- **Checked** side by side with his two buttons in Figma, and on the iPhone 17 Pro Max simulator (the trip map's buttons).
- Reverted in the app by 1.42: his buttons were meant for Figma only.

### Final UI, iteration 1.42: the app's buttons back (branch `feature/figma-docs`)
- Bogdan: the app's buttons were right, only Figma's needed fixing. `tokens.json`, `Glass`, Storybook's Button and Home CSS, and the generated tokens are back to 1.40, byte for byte; no white edge.
- Figma keeps his pressed-in edges in the effect styles **Button/Soft** and **Button/Primary** (Figma blurs inner shadows differently, so it needs its own values); the white edge is gone there too, with the `button/edge` variables.
- **Checked** on the iPhone 17 Pro Max simulator: Your trips' buttons as before 1.41.

### Figma: one story card per row, and a Components page (branch `feature/figma-docs`, 25 Oct)
- Final UI: every epic now has one story card per flow row, beside it at the same height, like Bogdan's Settling up. **Vote from outside the app** is back in Choosing dinner as its third row (it had landed in The bill), and The bill and Settling up moved down so no two epics overlap.
- New page **Components**: a Read me, then a section per category and per component (86), each with a docs card: what it does, use, avoid, props and how they map to the code, the widget and its file, the Storybook story, the tokens it uses (read from its variables) and where it's used (screens and parent components). The same text is each component's description, and its documentation link opens its file on GitHub. All components moved here from Final UI, and the sticker library from Assets; every screen instance still points at them (2,078 checked).
- Duplicate property names fixed: Sheet row and Icon row (Subtitle color), Payment row (State).
- `design-system/components.json` + `design-system/build-components-doc.mjs` → `design-system/COMPONENTS.md`: the index for agents, with node ids, component keys and property APIs.
- **Checked** with Figma's MCP: `get_design_context` on a component returns its description, documentation link and its nested icon's `TuIcons` name.

### Final UI, iteration 1.43: mini pin ↔ Up next without the overlap (branch `feature/pin-morph`)
- Bogdan: the orchestration was bad, everything overlapped. Frames from the simulator showed why: the mini's name and sticker travelled and scaled into the card's while the card's own name, rating, fan and chips faded in over them, so two layouts showed at once.
- Now, like the Dynamic Island: the old content fades out with a blur as the surface starts to spring (`pin-out-ms` 150, an even fade), and the new one comes in once the surface is nearly its new size. Growing, the card's parts follow one another from the top at 0.55 of the spring (`pin-in-at`): label, name, rating, the fan, the chips, each rising 8 px and sharpening (30 ms apart, 200 ms each); they hang from the card's top edge, so they ride up with it. Shrinking, the mini's content comes back at 0.35 of the way left (`pin-mini-at`), all at once, with whoever is there on its corner.
- Gone: the shared sticker and name travelling between the two layouts, and the part-by-part geometry it needed.
- Storybook's Widget/Up next morphs the same way (the delays come from the same spring).
- **Checked** on the iPhone 17 Pro Max simulator, frame by frame from screen recordings: opening the trip (mini → card) and moving the map (card → mini); and in Storybook, by sampling each part's opacity per frame.

### Final UI, iteration 1.44: the splash (branch `feature/splash`)
- On a cold start, on Your trips' blue: my dot pops in (the app icon's motif), **TripUp** comes in under it, and the four stickers on the Lisbon card (Belém, the rooster, the tile, the caravel) pop up around them, 70 ms apart. At 1.25 s the mark blurs away, the blue thins out to Your trips, and the stickers fly onto their exact places on the trip card (they're hidden on the card until they land). About 1.85 s from the first frame; a tap skips ahead to the flight; with reduced motion there's no splash.
- Your trips is drawn under the splash from the first frame, so revealing it costs nothing: drawing it for the first time at the reveal dropped frames on the simulator.
- iOS's launch screen is now the same blue (a `LaunchBackground` colour generated from `home/bg` by `build-tokens.mjs`), so there's no white flash before it; Android's already was.
- Tokens: `spring-pop` (0.4 s, bounce 0.3), `spring-fly` (0.7 s, 0.12), the splash's timings (`splash-*`) and sizes (`splash/dot-scale`, `splash/word`, `splash/sticker`, `splash/ring`); the stickers' places around TripUp are `splashStickers` in `data.dart`. The perf and Figma drivers skip it (`splashOnStart`).
- **Checked** on the iPhone 17 Pro Max simulator from cold launches, frame by frame, and by the recording's frame times (no gaps over 50 ms during the splash).

### Final UI, iteration 1.59: concentric corners (branch `feat/concentric-radii`)
- Bogdan: the radii felt too small all round. Every container that holds a shape in its corner now has a radius of its padding plus that shape's radius (DECISIONS, Concentric corners):
  - sheets 44, their header buttons 24 in, the footer 16 in;
  - the trip card 51;
  - Up next 28, with round-ended info chips;
  - the map's poll 36 around places of 28;
  - the poll pop-up's places 34.
- `build-tokens.mjs` evaluates dimension expressions. New tokens: `surface/head-inset`, `surface/head-side`, `surface/foot-inset`, `surface/foot-side`, `widget/mid-radius`, `home/card-padding`, `home/card-radius`, `home/now-pill-inset`, `poll/place-radius`, `poll/radius`, `poll/option-radius`. `surface/radius` and `chip/radius` are computed now.
- The full view grows from Up next's 28 to its own 44 as it opens. The trip's opening squares off from the card's 51.
- Storybook the same. Figma: the variables with their formulas, Pop-up header, Sheet header, Sheet footer, Money footer, Trip card, Up next card, Mini pin, Poll card and Poll place rebound; the screens' footers; the bill's Add at lg. The Read me states the rule.
- **Checked:**
  - on the iPhone 17 Pro Max simulator: Your trips, the map, Money, Pay Maya, the full view, the open poll and the bill;
  - in Storybook: Money · pay, Overview, Your trips, Up next, the poll on the map and the poll pop-up;
  - in Figma: Your trips, Overview, The poll, open, The bill and Pay Maya.

### Figma: the Wireflow page (27 Oct)
- A new first page, Wireflow, with the section "Wireflow · the thinking". It has a note on what it is, then 10 mid-fi screens (390×844) in one row, each with a Decision / State / Interaction note under it, and 9 labelled connectors (DECISIONS: A wireflow page, as the brief asks). Colours are bound to the file's variables.
- Checked on a screenshot of the whole section.

### Final UI, iteration 1.71: a smaller type scale (branch `feat/smaller-type`)
- All 12 text tokens are about 18% smaller and rounded (DECISIONS: A smaller type scale). The smallest is 11.
- tokens.json → tokens.dart, tokens.css, Tokens.swift, tokens.xml. Figma: the 24 typography variables, plus the Live Activity and Island text by hand.
- Checked: the simulator (Your trips, the trip map), Storybook (Pop-ups · Scan the bill), Figma (The bill). Installed on Bogdan's iPhone 15.

### Final UI, iteration 1.70: text size fixed everywhere (branch `fix/fixed-text-size`)
- Bogdan's phone uses the smallest text size, and the native app followed it. Now the text scale is 1 on iOS, Android and the web (web_phone_frame.dart), so the app always looks like the design (DECISIONS: The web on a phone doesn't zoom).
- Checked on the simulator: at extra-small and at the default text size, Your trips is identical. Installed on Bogdan's iPhone 15.

### Web, iteration 1.69: no zoom on phones (branch `fix/web-mobile-zoom`)
- **index.html:** locks the viewport, re-locking it whenever Flutter rewrites it, and stops Safari's gesture events. It sets `touch-action: none`, `overflow: hidden` and `text-size-adjust: 100%`.
- **web_phone_frame.dart:** text scale is 1 on the web, with or without the phone frame (DECISIONS: The web on a phone doesn't zoom).
- **Checked:** iPhone 15 emulation in Chromium, where the viewport stays locked after Flutter starts, the page is 393×659 with no scroll, and the layout matches the app. Real iOS Safari still needs Bogdan's check.

### Final UI, iteration 1.68: a softer bottom fade (branch `fix/sheet-bottom-fade`)
- Bogdan: the fade behind the bill's summary looked sharp. sheet/fade goes from 16 to 40 (space/3xl), and the mask is eased instead of linear, in the app (trip_sheet, detail_sheet), Storybook (TripSheet.css, DetailSheet.css) and Figma. In Figma that's the variable and the 15 sheet "Bottom fade" rectangles, each with 9 eased stops.
- Checked on the simulator (the bill). Installed on Bogdan's iPhone 15.

### Final UI, iteration 1.67: the bill's summary in a grey block (branch `feat/bill-summary-box`)
- Bogdan's sketch: shares, a line and the total in one bg/muted block. It has radius/card, md top and bottom, xs at the sides, and the total md in. The footer's top border is gone, the line is border/strong, and share cells are 56.
- Figma: The bill (126:5932) brought fully to the new layout. That covers the total out of the page, "How it splits" removed, the Summary block, and Who paid as a soft 56 button. Bogdan's separate draft frame (209:8183) is gone from the file.
- Checked on the simulator, in Storybook (Pop-ups · Scan the bill) and in Figma.

### Final UI, iteration 1.66: the bill line's faces next to the quantity (branch `fix/bill-line-faces`)
- Bogdan, in Figma (Bill line 211:8478): the faces sit right after "3 × €23.90", xs apart, and the total fills the rest, aligned to the end. Before, they floated in the middle. App, Storybook and Figma.
- Checked on the simulator. Installed on Bogdan's iPhone 15.

### Final UI, iteration 1.65: the bill's new layout (branch `feat/bill-line-layout`)
- Bogdan's Figma bill sheet (209:8186) and Bill line (209:8483), everywhere (DECISIONS: The bill, laid out again). Each line has the dish on its own row, then quantity × price, the faces and the total. The total sits in the footer under the shares, the explanation line is gone, and Who paid is a soft 56 button.
- **Figma:** Bill line is a component set, Expanded=no|yes. The yes state shows the picker under the line, with Nic faded and his face hidden. Bogdan's frame is now an instance, and the subtitles lost their names on both bill screens.
- **App:** bill_scan.dart. **Storybook:** BillScan (`tu-bill__line`, `tu-bill__meta`, total in the footer, `tu-payer` as a soft pill).
- **Checked:** the simulator (the bill, a line opened, the footer), Storybook Pop-ups · Scan the bill, and Figma The bill.

### Storybook online: https://tripup-storybook.vercel.app (26 Oct)
- **For reviewers:** the component library is on Vercel, as project "tripup-storybook", deployed to production and public. `tools/deploy_storybook.sh` builds Storybook and deploys it the same way as deploy_web.sh: copied outside the repo, static files only. `--preview` gives a preview URL instead.
- **Checked:** the live site loads Pop-ups · Itinerary with no errors, and index.json answers.

### Storybook: a clean shell for reviewers (branch `chore/storybook-clean`)
- **Shell:** no setup checklist ("Get started 37%") in the sidebar or the menu, no "What's new" notifications, no telemetry (main.ts). The addons panel starts hidden (press A to show it) and the sidebar says "TripUp · design system" (manager.ts, new).
- **Introduction:** the "In Figma → token used" table was showing raw pipes (MDX here has no GFM tables). It's an HTML table now.
- **Checked:** all 68 stories and doc pages loaded headless with no errors or empty canvases. The Introduction and the shell were checked on screenshots.
- Storybook shots for the case study video re-taken (`releases/case-study/` 23–27).

### Final UI, iteration 1.64: the full view's tabs wrap under Back and × (branch `feat/detail-header-wrap`)
- When the tabs don't fit between Back and Close, they go on a second row under them, and the header grows by a row.
  - App: DetailSheet measures the tabs' labels against the sheet's width.
  - Storybook: DetailSheet measures the bar, with a `tu-sheet--stacked` class.
- Checked: the simulator at the Accessibility Medium text size (Brasserie from the itinerary: Back and × on top, Overview · Menu · Group under them). Storybook Pop-ups · Itinerary at its phone width stacks too.
- Figma is unchanged: at 440 wide everything fits on one row.

### Final UI, iteration 1.63: Back from a plan to the itinerary (branch `feat/itinerary-back`)
- Bogdan: details opened from the itinerary need Back to it, inside the same sheet. The full view's header now has Back before the tabs when it came from the itinerary, and Back brings the itinerary back in place, with its day filter (DECISIONS: Back from a plan to the itinerary).
- App: `DetailSheet.onBack`, `_backToItinerary` in trip_screen.dart. Storybook: DetailSheet `onBack`, TripSheet `inPlace`, Pop-ups · Itinerary. Figma: Sheet header gets a Back boolean (Lead frame: Back + tabs, 8 apart), and Plan the days gets a third screen, "Plan details · from the itinerary", with a "Tap a plan" connector.
- Checked on the iPhone 17 Pro Max simulator: Itinerary → Tram 28 → Back → Itinerary → ×; Up next → full view has no Back. Also checked Storybook Pop-ups · Itinerary and Figma Plan the days.

### Final UI, iteration 1.62: Ren's recap has a footer (branch `fix/recap-footer`)
- Bogdan: on "Welcome, Ren" the button should be fixed at the bottom, like a footer, not at the end of the list. Open the trip now stays at the bottom over an eased fade of the screen's colour (the action bar's), and the recap scrolls up under it.
- App (join.dart), Storybook (Join: a sticky footer) and Figma (Ren's phone · The trip so far: an absolute Footer frame at the bottom).
- Checked: the iPhone 17 Pro Max simulator, at rest and scrolled to the end; Storybook Ren · trip so far; Figma. Not yet on Bogdan's iPhone 15 (it couldn't be reached).

### Figma: gaps instead of spacer frames (26 Oct)
- Bogdan: no empty frames for space, only gap sizes. All 18 spacer frames on Final UI and Components are gone.
  - Where the spacing was uneven, the rows that share a gap are now grouped, and the gap sits on the group: Why's lines, the Group pages' people, Plan something's times, Ren's invite and recap, the bank approval's top.
  - The poll option's Details fills its row.
  - The bank approval uses space-between.
  - The bars that were centered with a "Balance" frame (Ren's phone, the camera) now center the middle, with the side button set to absolute.
- Every gap is bound to a space variable. Checked on screenshots: the bank approval, Ren's invite and recap, the camera, Plan something · when, Group.

### Storybook: computed dimensions show their value (branch `fix/storybook-computed-dims`)
- Foundations → Component dimensions showed "undefined px" for every token computed by formula since 1.59 (surface/radius, chip/radius and the rest). It now reads them from the built CSS, so surface/radius says 48 px.
- Found while taking process shots for the case study video (`releases/case-study/`, not in git).

### Final UI, iteration 1.61: one inset of 24 for sheets (branch `feat/sheet-even-inset`)
- Bogdan: after 1.60 the top (24) looked bigger than the sides (16). Everything in a sheet now sits 24 from every edge, and the sheet's radius is 48 (DECISIONS, Concentric corners).
- New tokens `surface/inset` (24) and `surface/body-side` (16, the sheet's own padding, rows add their 8). `surface/radius`, `head-inset`, `foot-inset`, `head-side` and `foot-side` follow from them. `build-tokens.mjs` takes a bare component dimension (`{surface/inset}`).
- App, Storybook (TripSheet, DetailSheet) and Figma (the variables; the 22 Pop-up and Full view frames' side padding bound to `surface/body-side`).
- Figma docs follow: the Components page's docs card and the Corners notes on Sheet header, Pop-up header, Sheet footer and Money footer say 24 and 48 now.
- Checked: the iPhone 17 Pro Max simulator (Overview, Money); Figma Money and Overview. Installed on Bogdan's iPhone 15.

### Final UI, iteration 1.60: one side edge for sheets (branch `fix/sheet-edge-alignment`)
- Bogdan: the sheet header was lopsided (title 16 in, × 24 in) and didn't line up with the content or the footer. The header's title, Back, tabs and × now sit 16 from the sides, like every row and the footer's buttons; 24 from the top stays (DECISIONS, Concentric corners).
- `surface/head-side` is now `{surface/foot-inset} - {space.xs}` (8, inside the sheet's 8). App, Storybook (Trip sheet header, Detail sheet bar) and Figma (the variable, so Pop-up header and Sheet header follow).
- Checked: Figma Sheet header both variants; installed on Bogdan's iPhone 15.

### The web build: the baked map tiles, for real this time (branch `fix/web-zoom-baked`)
- **Correction:** the web never used the baked tiles, although `perf/web` said so. The style's FNV-1a hash came out wrong in the browser (numbers there are doubles, and h × prime, up to 2^56, lost its low bits), so the web took them for another style's and drew every tile live; the "baked vs drawn" screenshots compared drawn with drawn. The prime is now multiplied in two parts (2^24 and 403), the same result everywhere (`f816c147`, as the bake). On the web the map's first screen is now 24 baked tiles in 0.5 s, none drawn (before: 24 drawn, 4.4 s).
- **On the web, zooming in past the baked tiles enlarges them** (`maxNativeZoom` = the deepest baked zoom, 14) instead of drawing finer ones. Deep zoom is a little softer (Bogdan's call).
- Checked side by side: baked and drawn-on-the-web tiles look the same, labels included.
- **Measured** (Chromium, phone size), longest frame from the first web build to now: launch 2.66 → 0.15 s, first trip open 1.26 → 0.06, trip open 0.49 → 0.02, map pan and zoom 0.35 → 0.01 (no frame over 33 ms), full view 0.45 → 0.03, day filter 0.42 → 0.05, Overview photos 0.15 → 0.07. Tabs still ~0.07 (the page being left is rebuilt, see "Still open").

### The web build: the full view grows from the card again, and no blurs (branch `fix/web-frame-positions`)
- Bogdan: in the frame the full view slid in from the side instead of growing out of the Up next card, and it still felt slow. The card's place was measured in the window's coordinates, which in the frame are off by the frame's place and scale, so the full view started ~500 px to the side. The same for the splash's stickers landing on the trip card and the paper in the bill scan. Now they're measured on the app's screen (`WebPhoneFrame.screen`; without the frame it's the window, as before). The frame's key also holds the app without the frame, so resizing the window across 600 keeps where you are.
- **No blurs on the web** (`lightEffects`, as on Android before 10): on the 4K screen at 1× every trip opening hitched about 0.4 s, and without the blurs it doesn't (0.46 → 0.02 s the first time, 0.41 → 0.02 after), because each new blur strength first compiles a GPU program. The motion, fades and tints stay; behind pop-ups the map gets the flat white wash.
- The perf driver now takes the app's own choice of blurs; `--dart-define=LIGHT_EFFECTS=true|false` forces it.
- **Checked:** the full view's opening stepped frame by frame in Chromium with a frozen clock (it grows from the card), and in the iOS app nothing changes (the frame and the blur choice are web-only).
- **Still open:** zooming in past the baked tiles draws them live (0.4–1.1 s in the test, longer on a large window).

### The web build: a phone frame on a computer, and no map hitches (branch `perf/web`)
- Bogdan: on the web everything looked blown up, and it stuttered. On a computer the app filled the whole window, so what's sized from the screen (the map still on the trip card, its stickers) grew with it. Now a window wider than 600 shows the app in a phone-sized frame in the middle (440 × 956, as the Figma screens, radius 40, on bg/muted), scaled down to fit a shorter window (`WebPhoneFrame`, tokens `web-frame/*`). In a phone's browser and in the app nothing changes.
- **Measured** with `tools/web_perf.mjs`: the perf driver (`app/perf/trip_perf.dart`, now able to run on the web) in Chromium with the GPU on (Apple M3 Pro), at phone size (390 × 844 at 3×), each frame's gap as the browser saw it. Idle and scrolling were already smooth (120 fps, 1–2 ms a frame); the stutter was single long frames, all of them map tiles and pictures made on the main thread (the web has no isolates):
  - vector_map_tiles encoded every drawn tile as a PNG and wrote it to the browser's storage (3.7 s of the run). On the web drawn tiles now stay in memory only (`_MemoryOnlyImages`).
  - Four tiles drawn at once landed in one frame. On the web they're drawn one at a time.
  - The baked tiles around Lisbon (z12–14) are used on the web too: drawing one there takes 100–250 ms, and they look the same (the style's Noto Sans falls back to Roboto on Android and on the web alike).
  - Holding what's under the full view as a picture reads the whole screen back from the GPU on the web, a hitch right as it opens. On the web it's drawn live.
- Longest frame, before → after: launch 2.7 s → 0.14 s, first trip open 1.25 s → 0.04 s, trip open 0.49 → 0.02, full view open 0.45 → 0.03, day filter 0.42 → 0.08, Overview photos 0.15 → 0.09.
- **Still open:** zooming in past the baked tiles (z15 and up) draws them live, 100–250 ms each, so a deep pinch still hitches (0.39 s in the test). Baking z15 for the demo's streets would fix it; not done.
- At a computer's window size (1440 × 900 at 2×) the frame costs nothing extra: the same 120 fps idle.

### The web prototype on Vercel (branch `feat/web-on-vercel`)
- The whole app as Flutter's web build, on Vercel: **https://tripup-three.vercel.app** (project `tripup`, team bole's projects, production). Static files only; the same code as 1.58.
- `tools/deploy_web.sh` builds it and deploys it (`--preview` for a preview URL). The build is copied to `~/Library/Caches/tripup-app/vercel/tripup` first, so Vercel's link file stays out of git. The Vercel CLI runs through npx, pinned to 65.2.0.
- The page's title and the home-screen name are TripUp (were "tripup").
- **Checked** live at phone size: the splash, Your trips, into the trip, the map with Up next. Location, haptics and the Live Activity are phone-only, as before.

### Final UI, iteration 1.58: Know before you go at 14 px (branch `fix/know-tip-14`)
- Bogdan: the tips read small. A Know tip's line is Label/MD now (14 px, medium), not Label/SM (12): the same weight and brand colour, the row still at least know-row/height (56). The three tips on Overview each fit in two lines.
- Storybook the same (`KnowSection.tsx`, `text-label-md`). Figma: Know tip's text uses the Label/MD/Medium style, and its docs card and description list the label/md tokens; the three instances on Overview follow.
- **Checked** on the iPhone 17 Pro Max simulator (Overview of La Brasserie) and in Figma (Overview, 108:2104).

### Final UI, iteration 1.57: the itinerary opens at its top (branch `fix/itinerary-opens-at-top`)
- Bogdan: opening the itinerary, it was scrolled a little and "12–21 May · Day 3 of 10" was hidden. The scroll to today came from 1.21, when the days ran in calendar order; since 1.30 today comes first, so it only pushed the pop-up's line above the header. Now every pop-up opens at its top: `TripSheet` lost its `focus` (the itinerary was its only user) and `ItineraryPage` its `todayKey`. Storybook the same (`data-sheet-focus` and its scroll are gone from TripSheet and the itinerary). Figma already shows it from the top.
- **Checked** on the iPhone 17 Pro Max simulator (Itinerary from the map: the line under the chips shows, today first; a day filter and a plan's details as before) and in Storybook (Pop-ups · Itinerary opens at scroll 0).

### Final UI, iteration 1.56: paying through the bank (branch `feat/pay-flow`)
- Pay opens **Pay Maya** in Money (Back to the money): the amount, Maya's account, the reference and Why; Pay with your bank and Mark as paid in the footer. The first time, **Your bank** (Back to Pay Maya); then **my bank's app**, simulated (`bank_app.dart`): the transfer filled in, Approve with Face ID (the Face ID square, then Approved) or Cancel. Back on the money the owe pill has two new states, paying (spinner) and waiting (clock), and my row says so; the bank's answer (2 s) or Maya's confirmation (6 s) records it, with a note. See DECISIONS, Paying from the app.
- Tokens: `bank/*` colours and sizes, `pay/amount-sticker`, `face-id-ms`, `approved-ms`, `swap-in-at` (a pop-up's new title and footer come in once the old ones have mostly gone; for every pop-up). Icons: chevron-right, scan-face, landmark, lock.
- Fixed on the way: the owe pill threw after the bank's answer (a null check), and each step now opens at its top.
- Storybook: `useMoneyFlow` runs the same steps for every Money story; new stories Money · pay, Money · your bank and Bank app (`BankApp.tsx`).
- Figma: in Settling up, **Pay through the bank** (Pay Maya → Your bank → Bank app → Approved → Money · paying → Money · paid) and a new row **Paid another way** (Pay Maya with the bank known → Money · waiting for Maya → Maya confirmed), each with its story card and connectors. New components (documented, in COMPONENTS.md): Pay amount, Pay line, Bank logo (Pop-ups), and a new category **Paying** with Face ID and Bank approval; Owe pill has paying and waiting states.
- **Checked** on the iPhone 17 Pro Max simulator (video, frame by frame: Pay → bank → Face ID → Paying → Paid; Cancel; Mark as paid → Maya confirmed), in Storybook (the same three paths) and in Figma.

### Final UI, iteration 1.55: no banner after paying (branch `fix/owe-pill-only-owing`)
- Bogdan: once I've paid, the note at the top is enough. The owe pill shows only while I owe; after Pay it fades away as the footer closes up under it, and there's no green "squared up" pill either (everyone hears it as a note). Storybook the same; Figma: the paid and squared-up Money screens have no pill, and Owe pill keeps only its owe state.
- **Checked** on the iPhone 17 Pro Max simulator (Pay: the note, the row Paid, the pill gone).

### Final UI, iteration 1.54: what I owe, at the bottom (branch `fix/owe-at-bottom`)
- Bogdan: the owe pill (You owe Maya · Pay) goes down, just above the footer, for reach. It's now `OwePill` at the top of `MoneyFooter`, sm above its hairline, so it stays in view while the lists scroll; Money's page opens on its tabs. The pill follows payments itself (built as a const inside the footer, it didn't update after Pay at first).
- Storybook the same (OwePill in MoneyFooter; the payments are kept by the story's host, so the rows and the pill change together). Figma: the four Money screens have the pill in an Owe slot above the Money footer.
- **Checked** on the iPhone 17 Pro Max simulator (Pay: the row turns Paid and the pill "You're square with Maya"), in Storybook (Pop-ups · Money, Pay) and in Figma.

### Final UI, iteration 1.53: text buttons without icons (branch `fix/text-buttons-no-icons`)
- Bogdan: the label says what a button does, so no icons on text buttons. Gone from Website, Directions, Scan the bill (both) and Copy link. The one icon left is a state mark, the check on Your vote. Storybook the same (its TextButton story shows Pay, Vote, Your vote); Figma's Text button has Show icon off by default and on no screen.
- **Checked** on the iPhone 17 Pro Max simulator (Overview's footer) and in Figma (Overview, Who's here).

### Final UI, iteration 1.52: Money's top, simpler (branch `fix/money-top`)
- Bogdan: "5 people · split by who had what" was more than Money needs, so its page opens straight on what I owe. The owe pill has space/xl (24) in on the left, as Bogdan set it on the Figma component, so the words sit clear of the curve; app and Storybook follow, and the four Money screens in Figma lost their intro line.
- **Checked** on the iPhone 17 Pro Max simulator.

### Final UI, iteration 1.51: Invite without See what they'll see (branch `fix/invite-footer`)
- Bogdan: Invite someone doesn't need it. Its footer is Copy link alone, and the preview it opened (Ren's phone as "What they'll see") is gone with it, in the app (JoinFlow's `preview`) and Storybook (Screens · Invite preview, Add · invite's layer). Figma: Invite's Sheet footer without its second action.
- **Checked** on the iPhone 17 Pro Max simulator.

### Final UI, iteration 1.50: Up next opens by itself once (branch `feature/popup-header-footer`)
- Bogdan: the card opens by itself only the first time into the trip after the app starts, to show what's next. Once it's been made small, changing the day filter (All included), moving the map or going back to Your trips and in again leaves it small; a tap on its pin opens it. News about it still opens it: the poll's winner, a dinner picked by hand, a moment of the demo.
- **Checked** on the iPhone 17 Pro Max simulator: in (open) → tap beside (small) → Wed 13 → All (still small) → Your trips → in again (still small).

### Final UI, iteration 1.49: pop-ups with one header and their actions in a footer (branch `feature/popup-header-footer`)
- Bogdan: in Plan something the Back button lined up with the title but the line under it didn't, and Send to the group sat in the page. Now every pop-up is built the same way: the header is one line (Back for a step inside it, the title, Close, all on the buttons' centre line); the line on what it's for opens the page, lined up with the page's text; and its actions are in a footer that stays put (`SheetFooter`, which Money's footer now uses too).
- Plan something: once a place is picked, its row is just its name and the line under it (the sticker is on the map above, and Change is gone: the header's Back goes back to the search, then to the choice). Send to the group and "It goes on everyone's itinerary and map." are the footer. The plan being made (`PlanDraft`) is shared by the page, the footer and Back.
- Invite someone: the link alone in its pill; Copy link and See what they'll see are the footer.
- Money keeps Pay in its pill: it's the action on that one debt, like Vote on a place, not the page's.
- Storybook the same (TripSheet, SheetFooter, AddFooter, usePlanDraft; the Add stories' notes). Figma: Pop-up header one line (no Subtitle property), an Intro line at the top of the 10 pop-ups' pages, Sheet row's new Sticker shown, the Link pill without its button, and the new **Sheet footer** on Plan something · when and Invite someone (documented on Components and in COMPONENTS.md).
- **Checked** on the iPhone 17 Pro Max simulator (Add, Plan something, a picked place, Back twice, Invite, Money), in Storybook (Add · plan · place picked, Add · invite) and in Figma against the app.

### Final UI, iteration 1.48: the mini pin's faces a little higher (branch `feature/mini-faces-lift`)
- Bogdan: up by 8–12 px. They're lifted 10 px off the top edge now (`widget/here-lift`, new), in the app and Storybook.
- **Checked** on the iPhone 17 Pro Max simulator and in Storybook (centred, 10 px above the edge).

### Final UI, iteration 1.47: who's there sits on the middle of the mini pin (branch `feature/mini-faces-centre`)
- Bogdan: the faces of whoever has arrived moved from the mini pin's top-right corner to the middle of its top edge, at the same height.
- Storybook's mini pin the same, and its Widget/Up next notes now describe the 1.43 morph (they still told the old shared-sticker one). In Figma no screen shows a mini pin with faces, so only the Mini pin's description says where they go.
- **Checked** on the iPhone 17 Pro Max simulator (Maya on La Brasserie's mini pin at 3:56 PM) and in Storybook (the pile's centre on the card's top centre).

### Final UI, iteration 1.46: a tap on the map leaves the actions where they are (branch `fix/actions-on-tap`)
- Bogdan: every tap with the card open sent the actions away. The map's handler slid them down for any event the person made, a tap included; now only while the map really moves (`MapEventWithMove`: dragging, flinging, zooming).
- **Checked** on the iPhone 17 Pro Max simulator from a recording: a tap beside the card shrinks it and the actions stay; a drag still slides them down and they come back once the map is still.

### Final UI, iteration 1.45: a tap on the map shrinks the card (branch `feature/tap-map-shrinks`)
- Bogdan: with the Up next card open, a tap anywhere else on the map steps it back to a mini pin, with the same morph as moving the map. Pins keep their own taps (the mini pin still grows it back, the card still opens the full view).
- **Checked** on the iPhone 17 Pro Max simulator: card → tap beside it → mini pin → tap the pin → card.

### Figma: the splash, as the Open the app story (branch `figma/splash`)
- Your trips now has two rows: **Open the app** first (its story card, then four screens: the dot, TripUp, the stickers, onto the card, joined by connectors with their times, the last one down to Your trips), then See all my trips as before. The epics under it moved down a row.
- The screens are built from components: the new **Splash mark** (Step=dot|word: my dot four times the map's size, from the Me marker's dot, with its ring, and TripUp at `splash/word`), the Lisbon stickers at the app's places and tilts, and, for the last one, the Your trips screen with the card's stickers hidden and the splash's copies 60% of the way there under the thinning blue.
- New variables in Component size: `splash/word`, `splash/word-gap`, `splash/sticker`, `splash/ring`, `splash/dot-scale`. The mark is documented on the Components page (Your trips) and in COMPONENTS.md.
- **Checked** against a frame of the app's splash on the simulator.

### Figma: the buttons look like Bogdan's (branch `figma/buttons-clip`)
- The cause, measured on a white compare frame: Clip content was off on our buttons, so Figma drew the inner shadows bigger and darker (a thick grey band at the bottom of the soft ones). On now for Button, Text button, Toggle chip, Demo button, Happening now and Avatar button; the effect styles' descriptions say they need it.
- The Money button (Crew button) has the glass as a body layer behind the faces, like his frames, so the faces still spill over as in the app.
- Button and Text button document their states: Kind × Size; pressed is the app's 0.97 scale, not a look of its own.
- **Checked** pixel by pixel against his 129:7592 (same values down each column, but for our fill token), and the Action bar and the Trip card by eye.

### Storybook: no credit to Emil's rules (branch `docs/storybook-motion`)
- Introduction's Motion no longer says the motion follows Emil Kowalski's rules (Bogdan: we used too few of them to claim it). The rules it lists stay, since they describe what the app does.

### One link to the latest prototype
- `prototype/latest.html` always opens the newest `prototype/versions/vN-*.html` (highest N). Locally: http://localhost:8765/prototype/latest.html

## Tools
Scripts behind all of the above are in `tools/` (see `tools/README.md`).
