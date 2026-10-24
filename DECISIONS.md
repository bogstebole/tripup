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
- **The top and bottom bars sit on see-through white that fades out over the map,** so they read over any map without a hard white slab. The bottom one is less see-through (85% white against the top's 70%), because the buttons sit right on it. At first a progressive blur of the map sat under the white; it went for speed (see Performance).
- **No people pill in the header.** The group is on the footer's Money button now, so the header holds only back, the trip's name and dates, and the days. The full name fits.
- **The pin's tail is blue,** with a thin white edge. White was hard to see on the map's pale streets.
- **Three bottom actions instead of four: Itinerary, Money, Add.** Fewer, and each opens one place:
  - Itinerary: every day of the trip, where we've been and what's planned, opening on today. Tapping a stop shows it on the map.
  - Money: its button is the whole group as one little pile, since money is about the people. See Money below.
  - Add: a plan (an idea goes into a free slot, on everyone's itinerary and map) or someone new (a link, no account).
  - They open as pop-ups from the bottom, where their buttons are, on the full view's surface. They look the same so they feel like one family. They close with the ×, a tap outside, or a pull down.
- **Pins at the screen's edge use the bottom corners,** beside the buttons. Before, they stopped at the footer's height across the whole width, even where there are no buttons. The map's credit moved under the buttons, where pins never go, so it stays readable.
- **The bottom actions slide away while the map moves** and come back once the map has been still for 0.8 s: exploring gets the whole map, and a short pause between two drags doesn't bring them back (at 0.26 s they kept popping back too soon).
- **The bars' edges over the map have no line.** The white fades along a smoothstep, not a straight ramp, which always leaves a visible edge where it ends (while the bars still had a blur, it eased off to nothing for the same reason). We didn't stretch the fade further down the map: it blurred the top of the card.
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
  - On the card, the first chip turns into the faces and "here" (Bogdan's Figma states for one to five faces). Before anyone arrives it says how many are coming ("4 coming").
  - On the way there: "1 here" as a chip crowded it, then a pile on the card's corner. The final chip has no number, only the faces, so it reads at a glance.
- **The card's time moved up next to "Up next"** ("Up next · 5 PM"). The second chip is the real price range (€20–40, from the Google Maps details), which says more than "€€". The two chips share the width equally until four or more faces need the room; then the price shrinks to its text.
- **My dot breathes, like a live location.** Only the blue scales; the white rim stays still (as in Apple Maps). It stops with reduced motion and whenever it can't be seen, since a constant animation keeps the screen redrawing.
- **"Arrived" only after a couple of minutes inside a circle around the place.** City GPS drifts 20–50 m; without that wait, statuses would flicker.
- **In the prototype it's simulated:** people move along routes on the demo clock.

## Money (decided 23 Oct)

From the competitor research (`process/research/tripup-competitive-research-v3-en.md`) and the earlier prototypes:
- **What I owe comes first, with Pay next to it.** A prefilled pay button is the pattern that works (Venmo); everything else is context for it.
- **Then the fewest payments that square everyone ("3 payments instead of 9").** Fewest transfers is what wins (Splitwise, Tricount). The research also says people don't trust a number they can't trace, so balances and every expense are listed under it.
- **Balances per person, in plain words:** "Gets back", "Owes", and for Ren, "Joined today · shares costs from then on". Costs from before someone joins stay with the people who were there.
- **Tonight's dinner isn't an expense yet;** it's an estimate from what everyone picked on the menu. It joins once the bill comes, split by who had what (the wine story).
- **Left out:**
  - A switch for simplifying debts: it's always on.
  - Payment methods: they belong to the Pay step.
  - Receipt lines: they belong to the dinner's own detail.
  - Charts and budgets: no story needs them, and users call cluttered money screens a reason to leave.
- **In the prototype only my payment can be made,** so the trip can't reach "squared up" from here yet. That comes with the settle-up story.

## Demo (decided 23 Oct)

- **A small Demo button in the header** (top right, where the people pill was) shows the demo's clock and opens the moments of the brief's story. A tap jumps the clock there, and everything that runs on it follows: where people are, who's here, the times.
  - Moments the app doesn't have yet are listed, greyed out, so the list is also what's left to build.
  - It's a tool for the demo, not part of the product, so it isn't in Storybook.
- **The story should play out from the situation, not from special controls** (Bogdan, 23 Oct). When the group gets to the restaurant (a geofence), the dinner turns active and its actions appear; nothing is built for one case like "two people skip the wine".

## The dinner, the bill, squared up (built 24 Oct)

- **The dinner turns "Now" by itself.** Once its time has come (from a quarter of an hour before) and someone is inside its geofence, the card says "Now", with a dot, and "You're here" once I'm in. The mini pin says "Now". Nobody presses anything.
- **While it's on, the full view opens on Group.** The tabs keep their order (Bogdan: moving them was confusing); only the page it opens on changes. Group then reads "Who's here", not "Who's coming".
- **Scan the bill shows only while the dinner is on,** at the bottom of Group (full width, 56 px, the page's main action) and in Money. Before that there's nothing to scan.
- **The scan reads the bill against what people picked on the Menu.**
  - A line goes to whoever picked it, split if several did. A line nobody picked (the couvert, the water) goes to everyone.
  - Any line can be changed by tapping faces: the same control for every line.
  - So "Ren and Nic skip the wine" needs nothing special. The three of us picked the wine, so it lands on us.
  - We didn't build a wine switch or an "exclude" step: it would only fit this one story.
- **On the bill:**
  - The total is big at the top.
  - Every line shows all its faces (no "+N"; there's room).
  - An opened line shows the table in a grey block, which reads better.
  - Who paid is a menu that opens upward, with faces, not a "Change" that cycles names.
  - The totals per person scroll sideways if the table grows.
- **One background from the camera to Group.** The camera is a plain colour (no photo behind the bill). Once the bill is read, that colour gives way to the same blurred map the full view sits on, and the bill sits where the full view does. "Add" lets it melt (fade and blur) into Group underneath. Before, the jump from a dark camera to the page felt like two different places.
- **The scan shows how it works:** the frame closes in on the paper, a line reads it, and the lines land on faces. In the prototype it plays a prepared bill made from the real menu (€228.80); there's no real camera or OCR.
- **Ren comes to dinner** (the brief needs it), and I walk there too: my blue dot follows my route.
- **The others pay on their own.** After the bill is in, their payments come in a little apart, each a note at the top of the map. No control makes them pay, and the last one to pay sees "Everyone else has paid".
- **Each payment has a Why:** what that person had, what they paid, and why it goes to one person in one payment. Answers the research's "I don't trust a number I can't trace".
- **Squared up is a moment for everyone:** a note on the map, and Money's top block turns green with the total of the payments.

## The dinner poll (built 24 Oct)

- **Real places for the options.** La Brasserie, Dote Alvalade and Churrasqueira de Alvalade are all on Avenida da Igreja, with their public ratings and prices (Intravel and Google for the two new ones). Each has a sticker, as places do everywhere in the app.
- **The poll is tied to a slot,** "Dinner tonight · 5 PM", as the research suggested. Until it's decided, tonight's dinner isn't on the map or the itinerary; the itinerary shows the slot with "Poll open · 3 of 5 voted".
- **While it's open, the poll stands where Up next would,** under the day filter: the question, the three places with who voted for each, "Leading", and the countdown.
- **Everyone hears when it opens and when it closes.** Votes don't each make a note; the card updates live.
- **It closes at 3 PM, or as soon as everyone has voted.** The winner goes into tonight by itself (nobody else does this). Its card and pin appear, and the note offers Undo.
- **A note with an action stays twice as long (6 s),** so there's time to reach Undo.
- **After Undo, anyone can pick by hand** ("Add to tonight").
- **Bars, not a "Leading" tag** (Bogdan's note, 24 Oct). Under each place, a bar of its votes out of the five at the table, so you compare at a glance; the one ahead is in brand, the rest grey. Bars only grow as votes come in, and the fill slides in rather than stretching, so its rounded end keeps its shape. We didn't show percentages: with five people, faces and a bar say it better.
- **Every voter's face,** not two and "+N": there are five people at most.
- **The card is wider** (345, or the screen less its margins) and can **fold into a pill** under the day filter: "Dinner poll · 2 of 5 · closes in 28 mins", with a chevron to unfold. A poll that opens always shows in full first. We didn't fold it by itself after a while: the user decides when it's in the way.
- **A red dot that slowly breathes says it's live,** on the card and the pill ("Live poll · closes in…"). Red is what "live" looks like everywhere. With reduced motion it stays still.
- **Folding is one surface changing shape** (Bogdan: the first version swapped two things). The box springs between the card's size and the pill's while one content fades out and the other in, slightly blurred where they overlap. Both are pinned to the box's left edge, so the live dot and its line ride along. We didn't use a crossfade of two separate widgets: it read as a swap.
- **You vote on the card itself.** Tapping a place votes for it (a ring on the right fills with a check), and its bar and faces update at once. Before, the card only opened the poll, so voting took two taps. Ratings, prices and walks are a link at the bottom ("Ratings, prices and walks →").
- **Not built:** pins for the options on the map. All three are on the same street, so their pins would sit on top of each other; the cards say how far each is instead. The rest of the dinner (the bill and so on) is La Brasserie's; picking another place by hand gives it a plain plan.

## Your trips and joining (built 24 Oct)

- **The app opens on your trips, not inside one.** The brief starts there (step 01), and it's where Porto and the past trips live. The trip you're on is big and on top; past ones are folded away, since they're done and settled.
- **The current trip's card says what's happening now,** in the same words as the map ("Poll open: where for dinner tonight?", "Now: dinner at…", "Up next…"), and what you owe. It's a reason to open the app, not just a title.
- **Going in, the trip card opens into the map** (Bogdan: the zoom-and-fade wasn't continuous or immersive enough). The whole trip screen grows out of the card's place, from a small copy of itself to the real one, on a spring; it fades in over the card's first moments, so the card's still of Lisbon gives way to the live map, while the list behind fades and leans in toward the card. Back closes it into the card. Reduced motion: a fade. We didn't morph only the map: the top bar and buttons arriving with it is what makes it read as entering the trip.
- **The opening must land still** (Bogdan, 24 Oct: after the card opened, the Up next card animated again a second later). The cause: the widgets around the trip changed when the transition finished, so the map and its pins were built anew and the card replayed its entrance. Now the same wrappers stay at rest and in motion; only their values change. The opening uses a spring with no bounce (`springOpen`, 0.5 s): a full-screen container shouldn't wobble.
- **Before that: going in zoomed; coming back settled.** The list zooms past you (to 1.04) and fades, so the map feels underneath it; Back is the same motion reversed. Going in is an exit for the list, so it's quicker (160 ms) than coming back (260 ms). We didn't slide it sideways like a navigation push: the map isn't a page "next to" the list, it's inside the trip.
- **Ren's side is shown as Ren's phone.** The demo can't hand over a second phone, so a small "Ren's phone" pill says whose screen it is, and × goes back to Ari's. After joining, the demo returns to Ari's map, where everyone gets "Ren joined the trip": that's what the group would see.
- **Joining is a name and one button.** No account and no password, as the research found (Splid and Tricount win on this). The name is filled in from the invite, so it's one tap.
- **Then a catch-up, not a tour.** Where they're staying, where they've been, what's coming (an open poll says he can vote), and the money rule in one sentence. We didn't show the full itinerary or the balance: he hasn't spent anything yet.
- **Invite can preview it** ("See what they'll see"), so whoever sends the link knows what the other person gets.
- **Not built:** a real deep link and a second account. It's one app on one phone; the link is a stand-in.

## Itinerary and Money: one thing at a time (24 Oct)

- **Each day of the itinerary is its own section, with a line between days,** the same as a place's Group page. (For a moment each day was a grey block; Bogdan chose consistency with Group over it.) **Today comes first,** then the days ahead, then the ones behind: what matters now is on top. Places you've been say "Been there" without a check mark; the check added nothing.
- **The itinerary filters by day, like the map,** with the same chips (All, Tue 12…) pinned under its title. It opens on All, scrolled to today. It has its own filter rather than following the map's, so planning ahead doesn't change what the map shows.
- **One left edge on Money:** the title, "You owe Maya", the tabs' list titles and the rows all start on the same line. The tabs fill the width. Each tab's list has a real title ("Settle up", "3 payments square everyone, instead of 9") rather than a passing note. The estimate note ("Tonight's dinner isn't on it yet…") is gone: it was extra.
- **What the trip has cost sits in Money's footer,** like the Menu's total: "Spent so far · 3 expenses · yours €181.50 · €726.00", always in view while the lists scroll. While the dinner is on and its bill isn't in, Scan the bill sits under it.
- **"You owe Maya" is a rounded pill,** like Invite's link: smaller, 8 above and below, the line and the amount on the left, Pay on the right. The tight square block looked forced.
- **Money keeps "You owe Maya" on top, then tabs: Settle up · Balances · Expenses.** One list at a time, so the expenses (the list that grows all trip) never push the rest away. Settle up is first: it's the one with something to do. We didn't keep the three sections stacked: with a week of expenses it becomes a long scroll.
- **Ren's invite sits in the middle of the screen,** not at the top.
- **The home screen is Bogdan's design** (Figma 75:5927, built 24 Oct): the brand blue, the trip you're on as a big card with a still of Lisbon and a few places as stickers, "Happening now", its name and dates, who's on it and the way in; then Coming up (Berlin) and Previous trips as light rows. Past trips are no longer folded away. The card shows the trip's own name (a trip has its own name, Bogdan liked that), so a long one ends in "…"; the city goes in the line under it: "Lisbon · 12 May - 21 May".
- **No Demo button on the home screen:** it isn't in the design. The Demo stays in the trip's top bar, and its "Your trips" moment brings you back here.

## Add to the trip (24 Oct, from Bogdan's notes)

- **Two plain choices, not banners:** "Plan something" and "Invite someone" as big titles with a line under each and an arrow, no icons (they were weak and badly aligned), a line between them.
- **A step changes the header, not the page:** once you pick one, the header gets a back button and that step's title ("Invite someone · They join with a link, no account"). No back link under the header.
- **Invite is just the link, in the middle:** "Send them this link", a line, the link with Copy link, and "See what they'll see".
- **Plan something is a real flow:** search Lisbon (by name, kind or neighbourhood; accents don't matter), with what's near you before you type; pick a place and it shows on a small map; pick a day and a time range (From and To, each a wheel in 15-minute steps); then "Send to the group". It lands on everyone's itinerary ("until 8 PM") and map, and the map flies to it. The sheet grows to full height for it, easing in and out, and back down for the others.
- **Not built:** searching beyond a list of 20 well-known Lisbon places (a real places API), and asking the group before it goes in.

## Notes from the top, everywhere (24 Oct)

- **Every short note (toast) comes from the top:** payments, squared up, the poll, Pay, "Link copied", "Added for…", and the Menu's "Added" with Undo. Before, some came from the bottom and some from the top. One place, one direction.

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
