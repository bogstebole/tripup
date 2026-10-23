# TripUp Storybook

The component spec for the trip screen. Same tokens as the Flutter app (`../design-system/tokens.json`).

```bash
npm install --legacy-peer-deps   # npm 10.8 trips over a peer-deps bug without it
npm run storybook                # http://localhost:6006 (regenerates the tokens first)
```

Sections: Introduction (rules and the Figma → token replacements), Foundations (colors, type, space, shadows, motion), Components (Button, Basics), Widget (Up next states and morph, map marks), Screens (bars, full view tabs).
