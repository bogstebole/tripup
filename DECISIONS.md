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
  - Payment methods: they belong to the Pay step (built 25 Oct: see Paying from the app).
  - Receipt lines: they belong to the dinner's own detail.
  - Charts and budgets: no story needs them, and users call cluttered money screens a reason to leave.
- **In the prototype only my payment can be made,** so the trip can't reach "squared up" from here yet. That comes with the settle-up story.

## Demo (decided 23 Oct)

- **A small Demo button in the header** (top right, where the people pill was) shows the demo's clock and opens the moments of the brief's story. A tap jumps the clock there, and everything that runs on it follows: where people are, who's here, the times.
  - Moments the app doesn't have yet are listed, greyed out, so the list is also what's left to build.
  - It's a tool for the demo, not part of the product, so it isn't in Storybook.
- **The story should play out from the situation, not from special controls** (Bogdan, 23 Oct). When the group gets to the restaurant (a geofence), the dinner turns active and its actions appear; nothing is built for one case like "two people skip the wine".

## The bill, laid out again (Bogdan, 26 Oct)
- **A line is the dish on its own row, then quantity × price with the faces right next to it, and the total at the far end.** (First the faces sat in the middle. Bogdan moved them next to the quantity, so the price and who had it read as one thing.) Bogdan's Figma layout (Final UI 209:8483). Long dish names get the full width instead of wrapping next to the amount. The names left the subtitle: the faces already say who.
- **The total moved into the footer,** under everyone's share, so it stays in view while the lines scroll. The explanation line ("Each line goes to whoever picked it…") went: tapping a line shows it.
- **Who paid is a soft button,** as tall as Add to the trip's money next to it.
- **The summary sits in a grey block** (Bogdan's idea, tried on 26 Oct): everyone's share, a line, the total. It separates the result from the lines above, so the footer lost its top edge. On grey the line takes border/strong; border/default is the same zinc as the grey. A share cell is 56 wide (it was 64), so all five fit on a 393-wide phone.
- **A page fades out at its bottom over 40, eased** (sheet/fade: space/3xl, smoothstep in 8 steps, as the header's fade). It was 16 and linear. With the footer's edge gone, the list cut off hard above the grey block (Bogdan). It applies to every pop-up and the full view.
- **Figma's Bill line has an Expanded state now:** the line with everyone at the table under it, the ones who had it full and the others faded, as in the app.

## A smaller type scale (26 Oct)
- **Every text style is about 18% smaller, rounded to whole sizes with even line heights.** Bogdan's phone was set to the smallest system text size, and he liked how the app looked there better than the design's size. Once the app stopped following the system size (1.70), the tokens themselves took that look.
  - display 30/36, heading xl 24/30, lg 20/26, md 16/22, sm 15/22.
  - body lg 15/22, md 13/20, sm 12/16.
  - label lg 13/20, md 12/16, sm 11/14; caption 11/14.
- **The smallest stays at 11.** 18% off 12 would be 10, under Apple's 11 pt minimum (Material's is 12), so label-sm and caption stop at 11.
- **Changed at the source, not with a global scale factor.** tokens.json feeds the app, Storybook, the iOS widget and Android. Figma's typography variables are now raw values instead of aliases to the Tailwind size scale, which has no 11, 13 or 15. The Live Activity's unbound text in Figma was scaled by hand. Buttons, cards and spacing keep their sizes; only the text is smaller.
- We didn't keep the old sizes and scale the whole app: the design file would then show a size the app never draws.

## The web on a phone doesn't zoom (26 Oct)
- **The page itself never zooms or scrolls.** Bogdan: on his phone the web build looked blown up, showed a scrollbar and lagged. Flutter writes its own viewport tag, which allows pinch zoom up to 5×. One pinch or double tap zoomed the whole app and made the canvas redraw at that size. index.html now locks the viewport (max 1, no user scaling), turns off the browser's own touch gestures, and stops Safari's pinch events. Flutter handles every gesture itself.
- **Text is always the design's size, on every platform** (text scale pinned to 1). Bogdan's iPhone is set to the smallest text size, so the app looked about 18% smaller than the design and the web build. The prototype is judged on its layout, so it ignores the phone's text size (Dynamic Type, Android's font size) and the browser's. A real app would follow them, at least upward. The full view's tabs still wrap under Back and × on a narrow phone. The iOS widget and Live Activity already used fixed sizes.

## Back from a plan to the itinerary (26 Oct)
- **A plan opened from the itinerary has Back, and Back returns to the itinerary in the same sheet** (Bogdan: the navigation happens inside the itinerary). The itinerary and the full view are the same surface in the same place, so Back just brings the itinerary back there, with the day filter as it was. × still closes everything.
- **Tabs that don't fit between Back and × go on a row of their own under them** (Bogdan). With Back, three tabs and × need about 318 pt. A phone or a text size that leaves less moves the tabs to a second row, and the page starts lower. We didn't shrink the tabs or drop Menu.
- From Up next there's no Back: the full view grew out of the card, so closing it is the way back.
- We didn't make the details a step inside the pop-up (a Back plus a title, like Money's): the full view keeps its own tabs, and the Back sits before them.

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
- **The poll is Bogdan's widget now** (Figma 82:3, 24 Oct). On the map it's a compact card under the day filter: "Live poll • closes in 30 mins" with the red dot, the question, "5 PM • Maya asked • 2 of 5 voted" and everyone at the table as tiny faces, the ones yet to vote faded. Tapping it opens it in place over a blue-tinted, slightly blurred map: the same card grows down and each place arrives in turn (name, rating, food and price, its sticker, a bar of its votes, Details, who voted for it, and a round vote button that turns brand once it's yours). The chevron or a tap outside closes it. This replaces the earlier fold into a pill and voting on rows with rings. All bars are brand here, as in the design (the poll page still marks the leader).
- **Details** on a place opens the poll page, with walking times.
- **Not built:** pins for the options on the map. All three are on the same street, so their pins would sit on top of each other; the cards say how far each is instead. The rest of the dinner (the bill and so on) is La Brasserie's; picking another place by hand gives it a plain plan.

## Your trips and joining (built 24 Oct)

- **The app opens on your trips, not inside one.** The brief starts there (step 01), and it's where Porto and the past trips live. The trip you're on is big and on top; past ones are folded away, since they're done and settled.
- **The current trip's card says what's happening now,** in the same words as the map ("Poll open: where for dinner tonight?", "Now: dinner at…", "Up next…"), and what you owe. It's a reason to open the app, not just a title.
- **Going in, the trip card opens into the map** (Bogdan: the zoom-and-fade wasn't continuous or immersive enough). The whole trip screen grows out of the card's place, from a small copy of itself to the real one, on a spring; it fades in over the card's first moments, so the card's still of Lisbon gives way to the live map, while the list behind fades and leans in toward the card. Back closes it into the card. Reduced motion: a fade. We didn't morph only the map: the top bar and buttons arriving with it is what makes it read as entering the trip.
- **The opening is Airbnb's** (Bogdan's screen recording of opening a listing, 24 Oct, studied frame by frame at 30 fps). What we took from it:
  - **The list stays put; it blurs and washes out** behind the opening surface (nothing behind it scales).
  - **One rounded surface grows from the card to the screen,** with the card's picture (the still of Lisbon) growing inside it.
  - **The card's words leave at once** (first quarter); **the live trip arrives late** (from about half way to 85%), over the still, slightly blurred while both show, so the still map becomes the live map without a hard swap.
  - **The corners square up only at the very end.** A soft shadow lifts it while it's a card in the air.
  - **Closing runs it back,** quicker (`springCollapse` 0.38 s against `springOpen` 0.45 s, both without bounce): the trip fades back to the still, the card's words return, the list un-blurs.
  - We didn't copy Airbnb's sheet over a photo: our trip screen is a full map, so the whole screen is the destination.
- **It's orchestrated, one element at a time** (Bogdan: each element on its own, not whole sections; Up next last; under a second). On the tap the card's words leave; while the surface grows, the live map comes in with its pins; then, from 220 ms, each control arrives on its own, 30 ms apart, fading in and rising 8 px (200 ms each, ease-out): back, the title, Demo, each day chip (the six that fit; the rest arrive with the sixth), then the footer's three buttons. When the last one starts (550 ms), Up next opens from its small pin into the card (or the poll comes in). It all lands by about one second. With reduced motion everything just fades in with the map.
- **The opening must land still** (Bogdan, 24 Oct: after the card opened, the Up next card animated again a second later). The cause: the widgets around the trip changed when the transition finished, so the map and its pins were built anew and the card replayed its entrance. Now the same wrappers stay at rest and in motion; only their values change. The opening uses a spring with no bounce (`springOpen`, 0.5 s): a full-screen container shouldn't wobble.
- **Before that: going in zoomed; coming back settled.** The list zooms past you (to 1.04) and fades, so the map feels underneath it; Back is the same motion reversed. Going in is an exit for the list, so it's quicker (160 ms) than coming back (260 ms). We didn't slide it sideways like a navigation push: the map isn't a page "next to" the list, it's inside the trip.
- **Ren's side is shown as Ren's phone.** The demo can't hand over a second phone, so a small "Ren's phone" pill says whose screen it is, and × goes back to Ari's. After joining, the demo returns to Ari's map, where everyone gets "Ren joined the trip": that's what the group would see.
- **Joining is a name and one button.** No account and no password, as the research found (Splid and Tricount win on this). The name is filled in from the invite, so it's one tap.
- **Then a catch-up, not a tour.** Where they're staying, where they've been, what's coming (an open poll says he can vote), and the money rule in one sentence. We didn't show the full itinerary or the balance: he hasn't spent anything yet.
- **Invite can preview it** ("See what they'll see"), so whoever sends the link knows what the other person gets.
- **Not built:** a real deep link and a second account. It's one app on one phone; the link is a stand-in.

## Itinerary and Money: one thing at a time (24 Oct)

- **Each day of the itinerary is its own section, with a line between days,** the same as a place's Group page. (For a moment each day was a grey block; Bogdan chose consistency with Group over it.) **Today comes first,** then the days ahead, then the ones behind: what matters now is on top. Places you've been say "Been there" without a check mark; the check added nothing.
- **The itinerary filters by day, like the map,** with the same chips (All, Tue 12…) pinned under its title. It opens on All, at its top: today is already first, so the line under the chips ("12–21 May · Day 3 of 10") stays in view. (It used to scroll to today, from when the days ran in calendar order.) It has its own filter rather than following the map's, so planning ahead doesn't change what the map shows.
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

## The trip opens on today (24 Oct)

- **Going into a trip picks today in the day filter,** every time, and the map starts where it does. Bogdan: the focus should be on today, not on everything at once. Past days' places (the stickers of where we've been) show again under All or their own day. Up next stays open with today picked; picking another day still folds it into its pin.

## Details from anywhere, and landing back cleanly (24 Oct)

- **Know before you go is Bogdan's block** (Figma 62:4828): a subtle grey group with a brand title, and each tip as a plain muted line in brand, at 14 px (Label/MD; at 12 it read too small). Tips are read, not tapped, so no arrows and no glass.
- **A plan in the itinerary opens its details right there,** not the map: the itinerary's sheet and the details are the same surface in the same place, so the details' content fades in where the list was, and closing slides it down like a pop-up. A plan we know little about (Tram 28, an added one) shows its time, how far it is and a small map; the Menu tab appears only for a place with a menu. Places we've been still show on the map.
- **Coming back from the details lands without a change** (Bogdan: the chips changed and the pin blinked at the end). The card that shrinks back is now exactly the card on the map, who's there included (it showed "N coming" until it landed), and the pin's tail stays under it the whole time instead of popping in when the card arrived.

## Bogdan's buttons (25 Oct)

- **His buttons fix Figma, not the app** (Figma 129:7592). The app's buttons were right; only their Figma copies looked off, because Figma blurs inner shadows differently from the app's painter, so the same numbers read flatter there. So his pressed-in edges live in the Figma effect styles only, and the app, Storybook and `tokens.json` stay as they were (1.40).
  - First we put his values into the tokens and the app (1.41), with the thin white edge his frames have. Bogdan: keep the app's buttons. Reverted in 1.42.
- **Why ours looked worse in Figma (found 25 Oct): one setting.** Side by side on white, his and ours had the same effects to the last decimal, yet ours had a thicker, darker grey band at the bottom. Testing one difference at a time, it was Clip content: off on ours, on in his inner circle. Without it Figma draws inner shadows bigger. Every raised body now has it on and matches his pixel for pixel, except the fill, which stays our `button/soft-bg` (#e4e4e7, the app's) rather than his #e7e7e7.
  - Where something may spill over the edge (the Money button's faces), the glass is a body layer behind the content, his structure, so the faces aren't cut.
  - We didn't rebuild every button from his frames: his are two of our twelve variants with the same values, and rebuilding would have broken the 175 instances on the screens.
- **No white edge anywhere.** It was a hidden stroke in his file, not part of the design; it's gone from Figma too (and the `button/edge` variables with it).
- **Not "glass":** in Figma the styles are named Button/Soft and Button/Primary, and their descriptions say why their values differ from `inset.button-*`. The app's widget keeps its name (`Glass`) to avoid a rename across the code.

## The final UI in Figma (25 Oct)

- **Built as design, not pictures** (Bogdan: every screen in Figma, 1:1 with the app, clearly defined auto layout following what we built). Each screen is composed from components that mirror the app's widgets, with the same structure and the same tokens as variables, so a change in Figma reads like a change in code. Screenshots of the app were only references to check against.
- **One library, one source of truth for values.** The tokens already in Figma stayed; what the app had and Figma didn't (component colours and sizes, the glass and surface shadows) was added from `tokens.json` and aliased to the existing variables, not duplicated.
- **The map stays a picture,** like a photo: it's drawn from the same tiles at the same camera as the app (a small driver in `app/perf/`), with nothing on it. Everything on top of it (pins, people, me, the bars) is components, placed where the app puts them at that moment.
- **Scenes per moment of the story** (3:56 PM at launch, 2:10, 2:30, 3:00, 5 PM, a plan just sent) are components, so every sheet or pop-up of that moment sits on the same map, under the same blue scrim as in the app.
- **The flows follow the brief's scenario,** grouped as epics with their stories and criteria, in Bogdan's example format: the stories read as the acceptance criteria for the screens next to them.
- **What we didn't do:** a flat export of the app's drawing into Figma (it would match pixels but have no auto layout or components).
- **The Live Activity is its own story** (Vote from outside the app): the activity, the island and the notification are components built from the Swift code; the lock screen's wallpaper is a plain stand-in, since it's the phone's, not the app's.
- **One story card per row** (Bogdan, from his Settling up): each flow row has its own card beside it, at the same height. Dividers only split extra detail within the same row's flow, never one story from the next.

## Components, documented for people and agents (25 Oct)

- **A page of their own, like Storybook:** page **Components**, a Read me first, then one section per category (Buttons, System, Your trips, Map, Scenes, Full view, Pop-ups, Poll, Bill, Live Activity, Assets) and one section per component. Each component section holds a docs card (what it does, use, avoid, props, code, Storybook, tokens, used in) and the component itself. The stickers moved here from Assets too.
- **Written where agents actually read it.** We checked what Figma's MCP hands an agent: `get_design_context` returns the code, the property API (Kind → `kind`), variables by their code syntax (`var(--c-button-soft-bg)`), and every component's **description and documentation link**, nested ones included; `get_metadata` returns only names and positions. So the docs card's text is also the component's description, in labelled lines (Use:, Avoid:, Props:, Code:, Tokens:), and the documentation link opens the widget's file on GitHub. Icons name their `TuIcons` constant, stickers their `Sticker('…')` file.
- **Names an agent can't misread:** sections, cards and components share one name; text layers are named by role (What, Props, Code); property names follow the code's parameters, and no component has two properties with the same name (Sheet row's and Icon row's colour variant became Subtitle color = `subtitleColor`, Payment row's became State).
- **An index in the repo:** `design-system/COMPONENTS.md`, built from `design-system/components.json` (the hand-written docs plus node ids, component keys and property APIs), split by category with an index on top, so an agent can find a component without opening Figma.
- **What we didn't do:** Code Connect (it needs a paid Organization plan and a published library; the description and documentation link carry the same pointer to the code), and Dev Mode annotations (Figma's MCP docs don't say they reach the agent; descriptions demonstrably do).

## Getting there from the details, and one backdrop (24 Oct)

- **Overview ends with Website and Directions,** fixed at the bottom while the page scrolls, like the Group page's Scan the bill. Directions is the primary one: on a trip the question is "how do I get there", and it opens the phone's maps app straight to walking directions (Apple Maps on iPhone, Google Maps elsewhere), with no step in between. Website is the soft one and only shows when the place has a site. We didn't draw directions inside TripUp: the maps apps already do it better, and the trip's map is for the group, not for routing.
- **Every backdrop is the poll's** (Bogdan: the expanded poll's darker backdrop was better). Behind sheets, pop-ups and details the map now gets the same deep blue tint at 23% with a light blur, instead of a white wash with a heavier blur. The sheet stands out more, and it's one look everywhere. On Android before 10 it's the same tint, a little stronger, with no blur. The trip's opening keeps its own stronger blur, since that's a transition, not a backdrop.

## Pop-ups: one header, actions in the footer (25 Oct)

- **Every pop-up is built the same way** (Bogdan): navigation in the header (Back where there's a step to go back from, Close), doing things in the footer, whether one wide button or two stacked. The full view (Overview's Website and Directions) already worked like that.
- **The header is one line.** Back, the title and Close share the buttons' centre line; the line under the title fell out of that alignment, so it moved to the top of the page, lined up with the page's text, instead of being dropped (it says what the pop-up is for).
- **No duplicate ways back:** a picked place's Change did what Back does, so it's gone, and the place's sticker (already on the map above it) left its row.
- **Pay stays in Money's pill, and the pill moves down** (Bogdan, on second thought): Pay is the action on that one debt (like Vote on a place), so it keeps its pill, but the pill sits at the bottom just above the footer, where the thumb reaches, and stays in view while the lists scroll. The page opens straight on its tabs.
- **Once I've paid, the pill goes** (Bogdan): the note at the top ("You paid Maya €181.50") is the success, and the row turning Paid is the record; a green pill that stays says it a third time. The same once everyone has paid: "Lisbon is squared up" is a note, not a banner.

## Text buttons without icons (25 Oct)

- **The label says it.** Icons had crept onto buttons that leave the app or use the phone (Website, Directions, the camera, the clipboard), but not consistently (Pay has none), and the words already say where each goes. So none; Bogdan chose it over keeping Directions and Scan the bill.
- **One exception, and it's not an action:** the check on Your vote marks a state, so it stays.

## Up next opens by itself once (25 Oct)

- **Once per launch, the first time into the trip** (Bogdan): that's when "what's next" helps. After it's been made small, browsing the days or the map shouldn't keep pushing it back open; a tap on its pin does. News about it (the poll's winner, a dinner picked by hand) still opens it, since that changes what's next.

## Concentric corners (26 Oct)

- **Bogdan: the corners looked too small everywhere.** The reason: the round shapes inside were rounder than the corners around them. The footer's big buttons (56 tall, radius 28) sat 16 from a sheet corner of 24.
- **The rule, everywhere a shape sits in a container's corner: outer radius = padding + the inner shape's radius.** Then the two curves run parallel. Apple uses the same rule in iOS 26 ("concentric" corners).
- **Each radius is a token computed from the others.** It isn't a hand-picked number, so it follows when a button or a padding changes (`tokens.json` now takes expressions like `{space.md} + {button/lg} / 2`). Figma can't compute, so its variables hold the results, and each variable's description says how it's made.
  - **Sheets** (pop-ups, the full view, the bill): 44 = 16 + 56 ÷ 2. The header's round buttons (40) need 44 − 20 = 24 from the top and sides, so the header moved in (`surface/head-inset`). The footer stays 16 in (`surface/foot-inset`). The bill's Add became a big button like every other footer action.
  - **Trip card:** 51 = its padding of 29 + the arrow's 22. Happening now sits 4 further in, so it's concentric too.
  - **Up next:** 28 = 8 + the arrow's 20. The info chips' outer ends became round (radius 20, half their height) to match.
  - **The map's poll:** its places 28 (8 + the vote's 20, now 8 from the corner), the card around them 36. The poll pop-up's places: 34 (12 + Vote's 22).
- **Where the rule doesn't apply:** where nothing sits in the corner (lists, text, Why's box), or where it already held (Know before you go: 24 = 8 + 16; the owe pill; tabs and dishes with an edge).
- **One inset for the whole sheet: 24, top, sides and bottom (26 Oct).** Bogdan, twice: first the header was lopsided (title 16 in, × 24 in), then, with everything 16 from the sides, the top's 24 looked bigger than the sides. One number everywhere (`surface/inset` = space/xl, 24) reads calmest: header, rows, titles and footer buttons all share it.
  - **Strict concentricity can't hold for both rows at once:** at 24 in, the header's round buttons (40) want a radius of 44, the footer's big ones (56) want 52. The sheet's radius is 48, the middle (`surface/inset + (button/sm + button/lg) / 4`), so each is 4 off, which nobody sees. We didn't make every button 48 (exact everywhere, but a taller header and lower CTAs), and didn't keep 44 (the bottom corners 8 off, the "too small" look from before).
  - The cards in a sheet (tabs' track, Know before you go, the owe pill, photos) sit 16 in, 8 past the text, as before, so their text lines up with the rest.
- **Not chased: the phone's own corner.** With the sheet 16 in, a radius of 44 matches a screen corner of 60. Apple doesn't publish the iPhone 17 Pro Max's; developers report about 55 for the 15 and the 14/15 Pro. Close enough, and the sheet follows what's in it.

## Paying from the app (25 Oct)

From the research (`process/research/tripup-competitive-research-v3-en.md`, Payments under the hood), now built as a flow in the prototype:
- **TripUp never holds the money.** Pay starts a bank transfer through open banking (PSD2 payment initiation, through a provider like Tink or TrueLayer): SEPA Instant from my bank to Maya's, with a reference ("TRIPUP-9SP5") so she knows what it's for and TripUp can match it. Holding money would make TripUp a payment institution (licences, KYC); a wallet or card payments would also cost fees. We didn't build "send a request with a link to Revolut or PayPal" as the main way: it leaves TripUp guessing whether anyone paid.
- **The flow, for anyone who owes (Ren too, who joined with a link and has no account):**
  - Pay on the pill opens **Pay Maya** in the same pop-up (Back, title, ×): who and how much, big; what the transfer will say (To with Maya's account, From once my bank is known, Reference, Arrives in seconds); Why that amount. Actions in the footer: **Pay with your bank** and **Mark as paid**, with "Paid in cash or another way? Maya confirms it."
  - The first time, **Your bank**: pick it once and TripUp remembers it. No login in TripUp; the bank asks me to approve each payment in its own app. From then on Pay says "Pay with Millennium bcp" and goes straight there; From is a way to pick another.
  - **My bank's app** opens with the transfer filled in, which can't be changed there. Approve with Face ID, or Cancel ("Payment cancelled · nothing was sent", back on Pay Maya, the pill still there).
  - Back in TripUp on the money, the pill says **"Paying Maya · your bank is confirming"** with a spinner, and my row "Paying…". The bank's answer closes it: the note "You paid Maya €11.82", the row Paid, the pill gone (as in 1.55: the note is the success).
  - **Mark as paid** for money that went another way: the pill and my row say "Waiting for Maya to confirm" (a clock) until Maya confirms from her notification; then "Maya confirmed your €11.82" and Paid.
- **Maya adds where she gets paid once,** the first time someone owes her (not shown: the prototype has her IBAN).
- **In the prototype the bank is simulated:** a stand-in for the bank's app in a plain look of its own (its own `bank/*` tokens, square-ish corners, a dark button), so it reads as another app, with "‹ TripUp" at the top as iOS shows when one app opens another. The bank answers 2 s after approving; Maya confirms 6 s after Mark as paid. The banks listed are Portuguese and European ones by name only, no logos (the real list and logos come from the provider).
- **Not built:** the Serbian case (no PSD2: an NBS IPS QR code moves the money but tells TripUp nothing, so it would be Mark as paid with a QR), and Maya's side (her notification and Confirm).
- **A step's title and footer come in once the old ones have mostly gone** (`swap-in-at` 0.4 of enter-ms, for every pop-up), so "Pay Maya" and "Your bank" never read over each other; the pages keep their fade and blur.

## The splash (25 Oct)

- **The loader becomes the page** (the amo.co reference from 21 Oct): no spinner and no logo screen that cuts to the app. The trip's own stickers pop up around the mark and then fly onto the trip card, so the splash assembles Your trips instead of standing in front of it.
- **The mark is my dot and TripUp,** because that's the app icon (my location) and there's no other logo; the wordmark is our display face, bigger.
- **Short and out of the way:** under 2 s, a tap skips ahead, none with reduced motion; the launch screen is the same blue on iOS and Android, so the first frame doesn't cut.
- **Delight is allowed here:** it's seen once per cold start, so the stickers pop with a bouncier spring than the rest of the app (`spring-pop`).
- **What we didn't do:** a long amo-style collage (11 s is for a website, not a cold start), more stickers than the card has (they'd have nowhere to land), or a logo that writes itself (there's no script logo to draw).

## Mini pin ↔ Up next: one content at a time (25 Oct)

- **Swap the content, not morph it** (Bogdan: everything overlapped). The surface still grows and shrinks as one object with its spring; what's on it swaps like the Dynamic Island's: the old leaves, the surface changes size, the new comes in. Two layouts are never on screen together.
- **Exit fast, enter in order:** leaving is an even 150 ms fade with a blur (the strong ease-out made it a cut); coming in, the card's parts follow one another from the top, the order people read them. The next content starts from the spring's progress, not a timer, so it never comes in while the surface is still far from its size.
- **The card's content hangs from its top edge** while it grows, so the label can come in early without being clipped; the surface is only empty for about three frames.
- **What we didn't do:** keep the shared sticker and name travelling between the two (the cause of the overlap), or scale the card's content with the surface (text would stretch).
- **A tap beside the card shrinks it** (Bogdan), like moving the map: the card is a peek, and tapping away is how people dismiss a peek. No haptic for it: it's the background, not a control.

## Voting from outside the app (24 Oct)

- **A Live Activity, not a home-screen widget.** The poll lasts half an hour and is about "now", which is what Live Activities are for: it appears on the lock screen and in the Dynamic Island as the poll opens, with the countdown, how many have voted, each place with a bar and its count, and a vote button per place (filled in brand once it's yours). Tapping a button votes without opening the app; the vote shows on the activity at once and in the app. A home-screen widget suits something that lasts (the trip's Up next), so we didn't build one.
- **The poll's notification carries a button per place** ("La Brasserie", "Dote", "Churrasqueira"): hold it and vote. It's sent as the poll opens and stands in for the note at the top; it says "closes in 30 min" rather than a clock time, since the demo's clock isn't the phone's.
- **Same look as the app's poll card, with room to breathe** (Bogdan: the first version was cramped). The three places sit side by side as small cards, like the app's places: sticker and vote ring on top, the name and count, then a bar. The whole card is the vote; once it's mine it turns brand-subtle with a filled check. A Live Activity has 160 points of height, so the gaps are counted. The lock screen follows the system's light or dark look; the Island is always dark. Both use the app's tokens (the token build now writes Swift too). The places keep their order whatever the count, so nothing jumps. The Island's expanded view shows "2/5 voted", the countdown and the three cards.
- **The poll card on the map folds as one motion** (Bogdan: the collapse wasn't right). Before, the places faded out first while the card stayed tall and empty, then it snapped short. Now one value drives it: the card's edge rises at once (ease-out, 200 ms, quicker than opening), the places fade over the first half, and the scrim fades in step.
- **Once the poll closes** the activity shows "Tonight: La Brasserie, 5 PM" for 15 minutes, then goes. A demo jump away from the poll ends it at once.
- **Tapping the notification or the activity opens the poll, open** (not Your trips): whatever was up gives way, the trip opens if you were on your trips, and once its entrance is done the poll card opens over the map. A vote button still votes without opening the app; tapping anywhere else on the activity, or on the Island, opens it. A poll that has already closed opens the poll's pop-up with the result instead.
- **What a real build needs on top:** a server sending ActivityKit pushes, so votes from the others reach the activity while the app is asleep (here the app updates it while it's running).

## Light effects on weak Android phones (24 Oct)

- **The first real numbers from the Huawei Y7 2019** (Android 8.1, Skia), after the Android fixes: Your trips on screen at 0.73 s and the whole map at 0.95 s (it used to take about 10 s). But the GPU was the next wall: 4 frames in the first 3 s at 351 ms each (999 at worst), and the opening 7 frames at 184 ms (357 at worst), where smooth needs 16 ms. The blurs were the cost: every entrance sharpens from a blur, the backdrops behind sheets and the poll are blurred, and crossfades hide their seam with one; on Skia with that GPU each is redrawn every frame.
- **On Android before 10 (Skia), no blurs anywhere.** The motion, fades, order and timing stay the same; behind sheets the map gets a stronger white wash instead of a blur (`sheet/scrim-flat`, 55%), the poll's scrim is its tint alone, and the opening's wash is plain. iPhones and newer Androids (Impeller) are unchanged. We didn't make a separate "lite" design or cut the animations: the problem was one effect, so only that effect goes.

## Notes from the top, everywhere (24 Oct)

- **Every short note (toast) comes from the top:** payments, squared up, the poll, Pay, "Link copied", "Added for…", and the Menu's "Added" with Undo. Before, some came from the bottom and some from the top. One place, one direction.

## Sharing with testers (decided 23 Oct)

- **iPhone: TestFlight.** It's the easiest install for people with iPhones, and we have a paid Apple developer account.
- **Android: an APK through Firebase App Distribution.** It's free, and testers get a link by email and install it. We didn't go through Google Play's internal testing, because it needs a paid Play account and a review.
- **No Android phone here, so it's checked on the Android emulator on the Mac.** That shows layout and behaviour, but not real speed; the first Android testers will tell us that.
- **The web link (Vercel) is the fallback for anyone else:** https://tripup-three.vercel.app (built 25 Oct, `tools/deploy_web.sh`). The task needs a public URL anyway, but it runs slower in a phone browser than the app does. It's the whole app as Flutter's web build, static files on Vercel's free plan; nothing in it needs a server.
- **On a computer the web app sits in a phone frame** (25 Oct, Bogdan: it looked blown up). A browser window is far wider than a phone, and the app stretched across it enlarges whatever is sized from the screen. In the frame it looks as on the phone. In a phone's browser it fills the screen.
- **No blurs on the web** (26 Oct): each new blur strength compiles a GPU program the first time, so on a large screen every trip opening hitched for almost half a second. It's the same choice as for Android before 10: the motion stays, the blurs go.
- **On the web, the map doesn't draw what it can avoid drawing:** the baked tiles are used there too, drawn tiles aren't stored as PNGs, and one tile is drawn at a time. The web has no background threads, so every tile drawn there freezes the screen for a moment (see VERSIONS, the web build).

## Performance (decided 23 Oct)

- **Speed comes from drawing once what doesn't change, not from changing the design.** Glass and pin shadows are blurred once and reused, and what's behind the open full view is held as a picture. Measured on the iPhone 15, Menu scrolling went from 25.5 to 3.9 ms a frame, and the map from 18 to 4.7 ms (see `VERSIONS.md` 1.19).
- **No blur under the top and bottom bars; the see-through white fade stays.** That blur was the biggest GPU cost on the map, and the breathing dot made it run 60 times a second, even at rest. On a warm phone every frame was late (about 20 ms); with the blur off it was 3.6 ms with none late. The cost is that the map's labels now show sharp behind the title, the day chips and the buttons.
  - We didn't keep the blur and hold it as a picture while only the dot moves. It would look the same, but it's more code, and the picture could go stale.
  - We didn't make the dot breathe at 30 fps or give the blur fewer bands. Both keep a constant cost and change the look a little.
  - The full view's header keeps its blur. It only works while a page scrolls under it.
- **Not done yet:**
  - On a tab change, the old page vanishes instead of fading out as 1.12 describes, because it gets rebuilt. Fixing it changes the motion, so it waits for a decision.
  - Opening Menu builds all 118 rows at once, about 50 ms. A list that only builds what's on screen would fix it.

## Android: speed and edge to edge (24 Oct)

- **The map around Lisbon comes with the app, already drawn (Android).** Drawing vector tiles on a budget phone is the slow part (about half a second a tile on an emulator set up like the Huawei Y7), and it blocks everything else, the trip's opening included. 111 tiles cover where the demo goes; they're drawn by the app's own code on the emulator (`tools/bake_map_tiles.sh`), so they look the same. On an emulator like the Y7 the map went from 28 s to 1.5 s, the opening from 9 s to 1 s.
  - Only on Android: iOS draws map labels in its own system font, and it's fast enough to draw them itself.
  - Only while the style hasn't changed: a new `style-google.json` needs a new bake (the app checks the style's hash and otherwise draws every tile, slowly but correctly).
  - We didn't ship all of Lisbon or more zooms, or lossless tiles: the 111 tiles are 13 MB as lossless WebP and 5.1 MB at quality 95 (about 1/255 off on average, not visible). Zooming in past 14 and the small map in Add → Plan something still draw on the phone.
  - We didn't switch vector_map_tiles to its vector mode (redraws the vectors every frame: worse on a weak GPU), or to bigger tiles drawn at a lower zoom (blurry labels).
- **Bitmaps the size the screen shows.** The card's Lisbon still is cut to the part the card shows, at the same resolution; stickers are 320 px on their long side. Same pixels on screen, a tenth of the memory for the still, a quarter for the stickers. The originals stay in `Assets/`.
- **The renderer stays Flutter's choice.** On Android 8 and 9 (the Y7) Flutter 3.47 draws with Skia; from Android 10 with Impeller on Vulkan, falling back to OpenGL ES on GPUs it knows are bad. We didn't force OpenGL ES or Skia in the manifest: there's no phone data that says it's better, it would apply to every phone, and Skia is on its way out. The timings panel names the renderer, so testers' screenshots will tell.
- **A hidden timings panel instead of guessing.** Long-press "Your trips" for each startup step in ms, the phone, the renderer and the frame times of the launch and of opening the trip. Testers send a screenshot. Nothing shows otherwise.
- **The blurs stay.** On the Android 8.1 emulator every frame is slow (its graphics emulation), and turning off both of the opening's blurs saved little; there's no evidence they're what hurts on a real phone. If the Y7's panel says the opening's frames are slow, the first thing to try is the list's blur as a picture blurred once.
- **Edge to edge, like iOS:** the app draws under see-through status and navigation bars, no scrim, white icons on the blue and the camera, dark ones on the map and the white pages. We didn't hide the bars (immersive mode): the time, battery and the way home matter in a travel app, and Android would show them on every swipe anyway.
  - Below Android 8 the navigation bar's icons can't turn dark, so there it stays the system's opaque bar.
- **On Android the map's credit sits above the navigation bar, and the buttons one line higher.** The credit (required by OpenStreetMap's licence) was on top of the gesture handle, and with three-button navigation under the buttons. iOS keeps it in the home indicator's inset as designed.
- **The launch screen is Your trips' blue** (a token, written into Android's resources), so the app opens without a white flash.
