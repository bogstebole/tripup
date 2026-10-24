# TripUp Storybook

The component spec for the trip screen. Same tokens as the Flutter app (`../design-system/tokens.json`).

```bash
npm install --legacy-peer-deps   # npm 10.8 trips over a peer-deps bug without it
npm run storybook                # http://localhost:6006 (regenerates the tokens first)
```

Sections: Introduction (rules and the Figma → token replacements), Foundations (colors, type, space, shadows, motion), Components (Button, Basics), Widget (Up next states and morph, the dinner poll's compact card and its open state with voting, map marks), Screens (bars, full view tabs, a plain plan's Overview, Group while the dinner is on and once the bill is in; your trips, past folded and open, going into the trip and back; Ren's phone: the invite, the trip so far, and the invite preview), Pop-ups (the footer's itinerary, also filtered to one day, money, with its Balances and Expenses tabs, and add, and Add's Invite with See what they'll see; the money on the night, squared up, and Scan the bill; the dinner poll open, closed and undone, and the itinerary while it's open; a plan's details opened from the itinerary).
