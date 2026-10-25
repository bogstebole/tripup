# TripUp app (Flutter)

The trip screen, built to run on a phone: the map with past places and planned pins, the Up next widget and its full view. The components follow the Storybook spec in `../storybook`, and both read the same tokens (`../design-system/tokens.json`).

## Run it

```bash
# on the connected iPhone (signed with team QLXB6T6X9W), as an update: the app keeps its data and permissions
# (flutter install uninstalls the old app first)
flutter build ios --release
xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app   # ids: xcrun devicectl list devices

# on a simulator, with hot reload
flutter run -d "iPhone 16"

# Android: the APK for testers (copied to ../releases/, which git ignores)
flutter build apk --release --no-tree-shake-icons --target-platform android-arm64

# the web build on Vercel (https://tripup-three.vercel.app); --preview for a preview URL
../tools/deploy_web.sh

# on the Android emulator (Pixel 8, API 36)
emulator -avd TripUp_Pixel &
flutter run -d emulator-5554
```

Android tools are the command-line ones from Homebrew (no Android Studio): Java 21 (`openjdk@21`) and the SDK at `/opt/homebrew/share/android-commandlinetools`, both set with `flutter config`. `--no-tree-shake-icons` sidesteps a Flutter tool crash in icon font subsetting; the app draws its icons itself, so nothing is lost.

After changing `design-system/tokens.json`, run `node ../design-system/build-tokens.mjs` to rewrite `lib/design/tokens.dart`.

`build/` is a symlink to `~/Library/Caches/tripup-app/build`: the project sits in iCloud-synced Documents, and Xcode can't sign the Flutter framework there ("resource fork, Finder information, or similar detritus not allowed"). `android/.gradle` is a symlink to `~/Library/Caches/tripup-app/android-gradle` for the same reason.

If a build hangs with no error, check for files iCloud has moved off the disk to save space (`find . -flags +dataless`): reading one waits for it to download. `brctl download <file>` brings it back; Finder → Keep Downloaded on the project folder stops it happening.

### Android: speed, and checking it on testers' phones

- **Baked map tiles:** on Android the map's tiles around Lisbon come with the app, already drawn (`assets/map/tiles/`), because drawing them on a budget phone takes about half a second each. After changing `assets/map/style-google.json`, run `tools/bake_map_tiles.sh` with the emulator running (then reinstall the app); until then the app notices the style changed and draws every tile itself. See `lib/components/map_tiles.dart`.
- **Startup timings:** long-press "Your trips" for a hidden panel with each startup step in ms, the phone, the renderer and the frame times of the launch and of opening the trip; a screenshot of it is the report. The same lines are in the log: `adb logcat -s flutter | grep "TripUp startup"`.
- **Frame times** on Android: `flutter run --profile -t perf/trip_perf.dart -d <id> --dart-define=PERF_ONLY=launch,trip_open` and read the `PERF` lines (see the top of the file).
- **A slow phone on the Mac:** an Android 8.1 emulator set up like a budget phone (`system-images;android-27;default;arm64-v8a`, 720 × 1520 at 320 dpi, 2 GB, `-cores 4`), started with `taskpolicy -b` to keep it on the Mac's efficiency cores. Its CPU timings point the right way; its frame times don't (its graphics emulation is slow at everything).
- **Edge to edge:** the app draws under see-through system bars on Android 8+ (`MainActivity` for 8-9, Flutter from 10), with icons set per screen (`systemBarsOver` in `lib/design/theme.dart`). The launch screen's blue comes from the tokens (`res/values/tokens.xml`, written by `build-tokens.mjs`).

## What's where

- `lib/design/tokens.dart`: generated tokens. `theme.dart`: `context.tok` colors, springs from tokens, inner-shadow painter, press feedback.
- `lib/components/`: `glass.dart` (button glass, `TuButton`), `basics.dart` (surface, sticker, rating, chips, face pile, rows, sections, hairline), `segmented_tabs.dart`, `map_shapes.dart` (pin tail, edge arrow, my location), `bars.dart`, `toggle_chips.dart` (toggles: the days under the top bar, the menu's courses), `plan_pin.dart` (the morphing pin), `people_layer.dart` (the group's live locations, piled when close), `detail_sheet.dart`, `trip_sheet.dart` (the footer's pop-ups: surface, header, rows), `trip_pages.dart` (Itinerary, Money, Add), `stagger.dart`, `toast.dart`, `progressive_blur.dart`.
- `lib/screens/trip_screen.dart`: the map (flutter_map + vector tiles in the Google-like style from `assets/map/style-google.json`, through `lib/components/map_tiles.dart`), pin layers, and the card-to-full-view morph.
- `lib/startup_timings.dart`: the startup log and its hidden panel.
- `lib/data.dart`: demo content. The restaurant's rating, address and whole menu are real: `assets/data/brasserie-menu.json` (shared with Storybook), from the restaurant's own English menu.

## Motion

- Pin: one surface whose size, position and corners follow springs (`spring-morph`) between mid, mini and edge. While the map is dragged the pin follows the finger every frame; changes of state carry their velocity, so they can be interrupted.
- Moving the map collapses the card to mini; tapping the mini grows it back (the map makes room first). When the place leaves the screen the pin slides to the edge and points at it; tapping it flies the map there.
- Full view: the card's rect grows into the sheet on `spring-expand` while the map blurs; its content crossfades. Close with X, a tap on the backdrop, or a pull down on the photos (the pull's speed goes into the close spring).
- My location: dot with a heading cone, or an edge capsule pointing at me when I'm off-screen, plus a recenter button.
- Crossfades overlap (no blank frame) with a light blur on the seam (`crossfade-blur`); closing the full view uses `spring-collapse`, quicker than opening and without bounce, and hands back to the pin's card the moment they line up.
- Tabs in the full view replace everything above them: the old page fades out with a blur, the new one's blocks stagger in (`StaggerIn`: fade, blur → sharp, 8 px up, 40 ms apart).
- Haptics: light on every button and row, a selection tick on tabs, medium when a pin gets focus, light when a pull-to-close commits.
- Icons: Lucide geometry from the same lucide-react package as Storybook (`node ../design-system/build-icons.mjs` writes `lib/design/lucide.dart`), drawn with a 2 px stroke at any size.
- Reduced motion: state changes are instant, fades stay.
