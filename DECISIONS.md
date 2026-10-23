# TripUp: design decisions

What we decided, and why, in the order it happened. Each item: **the decision**, then the reason, then what we didn't do. The full history of every version is in `VERSIONS.md`.

## Direction

- **A middle ground between Bump (amo, ex-Zenly) and Airbnb.** Bump gives the live, playful, map-first feel of being with friends; Airbnb gives calm clarity for plans and money.
- **The map is the trip's history.** Places the group has been to stay on the map as stickers, so there's no separate History tab (dropped in prototype v5).
- **Real content everywhere.** A real restaurant (La Brasserie de L'Entrecôte, Alvalade), its real menu and prices, and its Google Maps facts. Mock data looks fake on stage; real data shows the design holds up.
- **The prototype is a Flutter app on the phone, not a web page.** It runs much smoother on the device than in a mobile browser, and it's what gets presented. Storybook documents the components so they stay clearly defined and consistent.

## Flow (prototypes v1–v11)

- **Joining needs no account.** The invite says it up front: open the link, type a name, you're in. The research showed sign-up is where group apps lose people.
- **A late joiner gets a recap.** Ren first sees the trip so far: the stay, what's decided, any open poll, and that only costs from today count.
- **Polls show the margin** ("Leading by 1 vote", "Tied"), not just percentages.
- **Every line on a bill can be given to anyone.** We dropped the wine banner. Skipping the wine is just one case of assigning lines.
- **A receipt scan splits the bill from what people picked beforehand.** A line nobody picked starts with everyone.
- **Settling up reduces payments** (13 → 4), and each payment can show why it's one payment instead of several.

## Visual language

- **Die-cut photo stickers** for places, food and people: the same white outline and soft shadow everywhere.
- **One source of tokens.** `design-system/tokens.json` builds both the app's Dart tokens and Storybook's CSS. Nothing in a component is a raw value. Where Figma used off-system values, the closest token replaced them.
- **Condensed bold headings** (IBM Plex Sans Condensed), with Geist for body and labels.
- **Smallest text is 14 px** (from 12): 12 px read too small on the phone.
- **Names in lists are 16 px** (Label/LG): people in Group and dishes in Menu are what you scan for.
- **Grey blocks only for what must stand out.** "Know before you go" keeps the grey highlight; lists elsewhere are plain, with hairlines.

## Map

- **Google-like look on free OpenStreetMap data (OpenFreeMap), no key.** Real Google Maps needs a billing key, and using its tiles without one breaks their terms. The map credit always stays readable.
- **Planned events are pins, past places are stickers,** so the future and the past never look alike.
- **Off-screen places slide to the screen edge and point at themselves,** and so does my own location.

## The trip screen (final UI)

- **The Up next card and the mini pin are one object.** It grows out of the pin's tail; the plan's sticker and the name travel between their two places, and the rest follows. A crossfade between two layouts read as two things swapping.
- **The full view grows out of the card,** and closes back into it, or by pulling down from anywhere at the top.
- **Tabs and close moved to the top of the full view.** The bottom was getting crowded.
- **Tabs: Overview, Menu, Group.** "People" became **Group**: the tab holds who's coming, what each person picked, and what it costs. It works for plans without a menu too.
- **A tab change moves.** The old page slides away from the new tab and blurs out; the new one cascades in from the tab's side. A plain swap felt like a flash.
- **Day filter under the header.** All, then each day. The chips are flat when off and blue glass when on: flat so they don't add yet another row of buttons, blue so the picked days stand out. Days combine. The map frames whatever is left, past days show where we were that day, and All brings back the opening view.
- **Times come from a running clock, not text.** The labels read "In 64 mins", "In 2 hrs", "Tomorrow", "In 3 days", and they count down.
- **Overview reads: name and rating, photos, then the description.** The photos are a Material 3 carousel. After "Know before you go" come the place's details from Google Maps (services, address, hours, price, booking, delivery, website, phone).
- **Menu:**
  - The whole real menu, as a plain list. Each dish photo is a sticker. The entrecôte photos are the restaurant's own; the others are illustrative, from Wikimedia Commons, and credited.
  - Under each dish: the price, who else picked it, and an icon-only Add.
  - Filters under the title: All, Picked, Starters, Mains, Desserts, Drinks.
  - Adding shows a minimal flat blue toast from the bottom ("Added for Today, 5 PM" with Undo). It's flat, so it doesn't read as another button. My face joins the faces of whoever else picked that dish.
- **Group:**
  - Next to each person, a little pile of what they picked: at most two dishes, the rest counted as "+N".
  - Then roughly what their picks cost, and the estimated total fixed at the bottom.
- **The top and bottom bars sit on see-through white over a progressive blur of the map,** so they read over any map without a hard white slab. The bottom one is less see-through (85% white against the top's 70%), because the buttons sit right on it.
- **The bottom actions slide away while the map moves** and come back once the map has been still for 0.8 s: exploring gets the whole map, and a short pause between two drags doesn't bring them back (at 0.26 s they kept popping back too soon).
- **The bars' edges over the map have no line.** The blur eases off to nothing and the white fades along a smoothstep, not a straight ramp, which always leaves a visible edge where it ends. We didn't stretch the fade further down the map: it blurred the top of the card.
- **Motion follows Emil Kowalski's rules** for every transition:
  - ease-out, under 300 ms per element, the exit quicker than the entry;
  - a short stagger, blur to mask crossfades;
  - with reduced motion, things only fade.
- **Haptics:**
  - a light tap on every button;
  - a selection tick on tab changes;
  - a firmer one when a pin gets focus.

## Live location (decided 23 Oct)

- **Status is passive: the person does nothing.** We don't add an "I'm leaving" or "I'm here" button; we want fewer features, not more. Their location, shared live, tells us everything: "Already there", "On the way · 12 min", "Leaves in 20 min".
- **What's needed:**
  - One permission, given once when joining the trip. iOS needs "Always" for background location and reminds people about it now and then, so some will say no. They show as "Location off" instead of a status.
  - **Sharing only around the event:** the prototype starts it 90 minutes before. It's easier to accept and easier on the battery. One "Pause" switch stays.
  - ETA from a routing service (Apple Maps or Google) from where the person is to the place.
  - "Leaves in N min" = the start, minus the travel time, minus now.
- **On the map, people near each other merge into one pile of faces with "+N",** so a group walking together or a table of friends doesn't turn into a heap.
- **Once people arrive, their faces leave the map and attach to the place.**
  - On the mini pin, a small pile sits on its corner.
  - On the card, it settles just inside the same corner: the pile stays on the corner through the morph, so it reads as the same badge. It sits inside rather than across the corner because the card's top often lies under the top bar's fade.
  - We first had "1 here" as a chip on the card; it didn't work there, so it moved to the corner.
- **The card's time moved up next to "Up next"** ("Up next · 5 PM"). The two chips are the same width: who's coming (+3) and the real price range (€20–40, from the Google Maps details), which says more than "€€".
- **My dot breathes, like a live location.** Only the blue scales; the white rim stays still (as in Apple Maps). It stops with reduced motion and whenever it can't be seen, since a constant animation keeps the screen redrawing.
- **"Arrived" only after a couple of minutes inside a circle around the place.** City GPS drifts 20–50 m; without that wait, statuses would flicker.
- **In the prototype it's simulated:** people move along routes on the demo clock.

## Sharing with testers (decided 23 Oct)

- **iPhone: TestFlight.** It's the easiest install for people with iPhones, and we have a paid Apple developer account.
- **Android: an APK through Firebase App Distribution.** It's free, and testers get a link by email and install it. We didn't go through Google Play's internal testing, because it needs a paid Play account and a review.
- **No Android phone here, so it's checked on the Android emulator on the Mac.** That shows layout and behaviour, but not real speed; the first Android testers will tell us that.
- **The web link (Vercel) is the fallback for anyone else.** The task needs a public URL anyway, but it runs slower in a phone browser than the app does.

## Performance (decided 23 Oct)

- **Speed comes from drawing once what doesn't change, not from changing the design.** Glass and pin shadows are blurred once and reused, and what's behind the open full view is held as a picture. Measured on the iPhone 15, Menu scrolling went from 25.5 to 3.9 ms a frame, and the map from 18 to 4.7 ms (see `VERSIONS.md` 1.19).
- **No blur under the top and bottom bars; the see-through white fade stays.** That blur was the biggest GPU cost on the map, and the breathing dot made it run 60 times a second, even at rest. On a warm phone every frame was late (about 20 ms); with the blur off it was 3.6 ms with none late. The cost is that the map's labels now show sharp behind the title, the day chips and the buttons.
  - We didn't keep the blur and hold it as a picture while only the dot moves. It would look the same, but it's more code, and the picture could go stale.
  - We didn't make the dot breathe at 30 fps or give the blur fewer bands. Both keep a constant cost and change the look a little.
  - The full view's header keeps its blur. It only works while a page scrolls under it.
- **Not done yet:**
  - On a tab change, the old page vanishes instead of fading out as 1.12 describes, because it gets rebuilt. Fixing it changes the motion, so it waits for a decision.
  - Opening Menu builds all 118 rows at once, about 50 ms. A list that only builds what's on screen would fix it.
