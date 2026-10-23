# TripUp app (Flutter)

The trip screen, built to run on a phone: the map with past places and planned pins, the Up next widget and its full view. The components follow the Storybook spec in `../storybook`, and both read the same tokens (`../design-system/tokens.json`).

## Run it

```bash
# on the connected iPhone (signed with team QLXB6T6X9W)
flutter build ios --release && flutter install --release

# on a simulator, with hot reload
flutter run -d "iPhone 16"
```

After changing `design-system/tokens.json`, run `node ../design-system/build-tokens.mjs` to rewrite `lib/design/tokens.dart`.

`build/` is a symlink to `~/Library/Caches/tripup-app/build`: the project sits in iCloud-synced Documents, and Xcode can't sign the Flutter framework there ("resource fork, Finder information, or similar detritus not allowed").

## What's where

- `lib/design/tokens.dart`: generated tokens. `theme.dart`: `context.tok` colors, springs from tokens, inner-shadow painter, press feedback.
- `lib/components/`: `glass.dart` (button glass, `TuButton`), `basics.dart` (surface, sticker, people pill, rating, chips, rows, sections), `segmented_tabs.dart`, `map_shapes.dart` (pin tail, edge arrow, my location), `bars.dart`, `plan_pin.dart` (the morphing pin), `detail_sheet.dart`.
- `lib/screens/trip_screen.dart`: the map (flutter_map + vector tiles in the Google-like style from `assets/map/style-google.json`), pin layers, and the card-to-full-view morph.
- `lib/data.dart`: demo content.

## Motion

- Pin: one surface whose size, position and corners follow springs (`spring-morph`) between mid, mini and edge. While the map is dragged the pin follows the finger every frame; changes of state carry their velocity, so they can be interrupted.
- Moving the map collapses the card to mini; tapping the mini grows it back (the map makes room first). When the place leaves the screen the pin slides to the edge and points at it; tapping it flies the map there.
- Full view: the card's rect grows into the sheet on `spring-expand` while the map blurs; its content crossfades. Close with X, a tap on the backdrop, or a pull down on the photos (the pull's speed goes into the close spring).
- My location: dot with a heading cone, or an edge capsule pointing at me when I'm off-screen, plus a recenter button.
- Reduced motion: state changes are instant, fades stay.
