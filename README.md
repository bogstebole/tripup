# TripUp

A group-trip app, made by Bogdan ([bogste.com](https://bogste.com)) for the Bending Spoons product design test (Task #2). It follows one scenario from start to end: four friends in Lisbon. Ren joins mid-trip, they vote on where to eat, the bill gets split, and everyone squares up.

- **Web prototype:** https://tripup-three.vercel.app (the Flutter app built for the web; on a phone it runs slower than the native app)
- **Component library:** https://tripup-storybook.vercel.app
- **Case study:** https://bogste.com/tripup (password protected)

## What's here

| Folder | What it is |
| --- | --- |
| `app/` | The app, in Flutter: iOS (with a Live Activity and a home screen widget), Android and web. How to run it is in [`app/README.md`](app/README.md). |
| `storybook/` | Every component and screen, with how it's built and why, on the same tokens as the app. See [`storybook/README.md`](storybook/README.md). |
| `design-system/` | `tokens.json` (the one source for colour, type, space, radius, motion), the scripts that write it out for Flutter, Swift, Android and CSS, and [`COMPONENTS.md`](design-system/COMPONENTS.md), a list of every component. |
| `research/`, `process/` | The competitive research, the scenario map, the wireflow and the early explorations. |
| `prototype/` | The first HTML prototypes (v1 onward), for flow only, before the app. |
| `figma/` | Screenshots and notes from syncing the app to the Figma file. |
| `tools/` | Scripts: sticker cutouts, baked map tiles, the Vercel deploys. See [`tools/README.md`](tools/README.md). |
| `Assets/` | Source images: sticker originals, map renders, references. |

## How it was made

- [`VERSIONS.md`](VERSIONS.md) lists every version, oldest first: what changed, what was checked, and where it ran (iPhone build number, Vercel).
- [`DECISIONS.md`](DECISIONS.md) records the design decisions: what was decided, why, and what we didn't do.
- [`USER-STORIES.md`](USER-STORIES.md) takes the brief's eleven steps one by one and shows how far the app covers each.

Every change went on its own branch and was merged into `main` once it had been checked. Nothing is overwritten, so `git log` shows each saved state.

## Run it

```bash
# the app, on a simulator with hot reload
cd app && flutter run

# Storybook, on http://localhost:6006
cd storybook && npm install && npm run storybook

# after editing design-system/tokens.json
node design-system/build-tokens.mjs
```

Built with Flutter 3.47 and Node 20.
