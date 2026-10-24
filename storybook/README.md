# TripUp Storybook

The component spec for the trip screen. Same tokens as the Flutter app (`../design-system/tokens.json`).

```bash
npm install --legacy-peer-deps   # npm 10.8 trips over a peer-deps bug without it
npm run storybook                # http://localhost:6006 (regenerates the tokens first)
```

Sections: Introduction (rules and the Figma → token replacements), Foundations (colors, type, space, shadows, motion), Components (Button, Basics), Widget (Up next states and morph, the dinner poll's card, map marks), Screens (bars, full view tabs, Group while the dinner is on and once the bill is in), Pop-ups (the footer's itinerary, money and add; the money on the night, squared up, and Scan the bill; the dinner poll open, closed and undone, and the itinerary while it's open).
