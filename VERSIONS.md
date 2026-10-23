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

### One link to the latest prototype
- `prototype/latest.html` always opens the newest `prototype/versions/vN-*.html` (highest N). Locally: http://localhost:8765/prototype/latest.html

## Tools
Scripts behind all of the above are in `tools/` (see `tools/README.md`).
