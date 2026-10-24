# TripUp: the brief's scenario, step by step, in the final app

The eleven steps from the brief (`process/research/tripup-competitive-research-v3-en.md`, Scenario map), and how far the Flutter app (`app/`) covers each one. Checked on 23–24 Oct, last at iteration 1.26, on the iPhone simulator, the Android emulator and in the code. The earlier HTML prototypes (`prototype/versions/v1`–`v11`) covered the whole flow at low fidelity; this is about the final UI.

✅ covered · 🟡 partly · ❌ missing

| # | Step | In the app | Status | What's missing |
| --- | --- | --- | --- | --- |
| 01 | Home with all trips | The app opens on Your trips: Lisbon on top with what's on now, who's on it and what you owe; Porto coming up; three past trips folded away. Tapping Lisbon zooms into its map; Back comes out again. | ✅ | |
| 02 | Group view | The map with Up next (who's coming, who's there, price), live locations, and the footer (itinerary, money, add). An open poll stands where Up next would. When the group gets there, the dinner turns "Now" by itself (geofence), and the full view opens on Group. | ✅ | |
| 03 | Ren joins mid-trip | Add → Invite someone: a link to copy, and See what they'll see. On Ren's phone (Demo, 2:10 PM): who invited him, his name (no account), Join; then the trip so far (stay, places, what's coming with the open poll, the costs rule). Back on Ari's map: "Ren joined the trip", and he's on the map from then on. | ✅ | |
| 04 | Poll: 3 restaurants | Maya asks at 2:30 PM. Three real places on Avenida da Igreja, each a card with its sticker, rating, food, price and walking minutes. | ✅ | |
| 05 | Everyone notified | A note at the top of the map when the poll opens, and when it closes. | ✅ | |
| 06 | Leading option, live | On the map card and in the poll: votes arrive on the demo clock, voters' faces, "Leading" on the front-runner, "closes in N mins". It closes early once everyone has voted. | ✅ | |
| 07 | Winner into the itinerary | At close the winner goes into tonight's 5 PM slot by itself: its card and pin appear, and it's in the itinerary. The note offers Undo (6 s); after Undo, anyone picks by hand. | ✅ | |
| 08 | Ren and Nic skip the wine | Scan the bill (only while the dinner is on): every line lands on whoever picked it on the Menu. The wine goes to the three who picked it, so Ren and Nic skip it with nothing special; any line can be changed by tapping faces. | ✅ | |
| 09 | Fewest transfers | Money: "4 payments square everyone, instead of 13", each with a Why: what that person had, what they paid, and why it's one payment. | ✅ | |
| 10 | Pay in the app | Money: "You owe Maya €11.82" and Pay. The others pay on their own a little after the bill is in, each arriving as a note on the map. | ✅ | |
| 11 | "Squared up" to the group | When the last payment lands: "Lisbon is squared up · everyone has paid" as a note for everyone, and Money's top block turns green. | ✅ | |

**Covered: 11 of 11** (iteration 1.26, 24 Oct).

## Open decisions

- ~~Moving through the story in the demo~~: decided. A Demo button jumps the clock between the story's moments; the moments themselves follow from the situation (see the proposal below).
- **Ren at dinner:** the brief needs it for step 08. In the app, Ren is "Not going". The proposal brings Ren.

## Proposal: the dinner, from arriving to squared up (steps 02, 08–11)

Bogdan's direction (23 Oct): the story plays out from the situation, not from special controls. Nothing is built for one case like "two people skip the wine". It all follows from where people are, the time, and what they picked.

### 1. The dinner turns active by itself
- **Geofence:** a circle around the restaurant. Someone counts as "here" after a couple of minutes inside it (already the rule for "here"). In the demo, I walk there too: a route like the others', arriving at about 4:52 PM.
- **Active** = the dinner's time window has started (from 15 minutes before 5 PM) and at least one of us is inside. It stays active until everyone has left, or 3 hours after the start.
- **The card changes with it:**
  - "Up next · 5 PM" becomes "Now · Dinner", with a live dot.
  - The first chip already shows who's here.
  - On the mini pin, the same "Now".
  - When I'm inside, it says "You're here".
- **The full view changes with it:** while the dinner is active, what matters is the group and the bill, not the place's details. It opens on Group, and Overview moves to the end. Open question for Bogdan: keep all three tabs, or fold Overview away while active?

### 2. Scanning the bill (only while the dinner is active)
- **Where the action shows:**
  - In the full view, at the bottom of Group, "Scan the bill" replaces "Estimated total".
  - In Money, the line about tonight's estimate gets the same action.
  - Nowhere else, and never before the dinner is active.
- **The scan:**
  - A camera view with the paper bill on the table. Corner marks lock onto it, then "Reading the bill…".
  - The lines appear one by one, each landing on the faces of whoever it belongs to (ease-out, the motion rules).
- **Matching, from what people picked on the Menu before:**
  - A line that matches a pick goes to whoever picked it, split if several did.
  - Quantities split too: 2 × wine goes to the three who picked it.
  - A line nobody picked starts with everyone at the table, the same rule as the earlier prototypes. Examples: the couvert, water, a bottle ordered at the table.
  - Any line can be changed by tapping faces. The same control works for every line, not one built for wine.
- **So "Ren and Nic skip the wine" falls out of the picks.**
  - If the three of us picked the wine on the Menu, the wine line comes in on those three faces and Ren and Nic pay nothing for it.
  - If nobody picked it beforehand, it comes in on everyone, and two taps take Ren and Nic off.
- **Who paid:** whoever scanned, by default (me). It can be changed.
- **Confirm:** "Add to the trip's money". The dinner becomes an expense with its lines.
  - The full view's Group shows the real amounts, not "≈".
  - Money updates: total spent, balances, the fewest payments.

### 3. Settling up (steps 09–10)
- Money recomputes the fewest payments with the dinner in: 13 payments become 4 with Ren in.
  - Each payment row gets "Why": the expenses behind that amount. The research says people don't trust numbers they can't trace.
- Pay works as now, for my payment.
- **The others pay by themselves, on the demo clock.** Over the next minutes, their payments arrive as in-app notifications ("Leo paid Maya €182.00"), the way they would from their own phones. No control makes them pay.

### 4. Squared up (step 11)
- When the last payment lands, everyone gets "Lisbon is squared up".
  - It's a notification on the map, and Money's top block turns into the squared-up state, with who paid what to whom.
  - No app does this.
- The demo's "Squared up" moment jumps the clock to after the last payment.

### Data this needs (from the real menu and the earlier prototypes)
- Ren comes to dinner, as in the brief: a route, and picks (entrecôte with salad, Sumol).
- Nic also has a Sumol. The wine (2 × Soalheiro Granit, €28.50 each) is picked by me, Maya and Leo.
- The bill: everyone's picks, plus the couvert for five and water, which nobody picked.
- The earlier mock numbers come out as: dinner €209.20, total €935.20, 13 payments → 4 (Leo → Maya €182.00, Nic → Maya €132.80, You → Maya €27.50, Ren → Maya €26.80). These change slightly once the couvert and water are in.

### Out of scope for now
- A real camera and OCR. The scan plays a prepared bill.
- Tips and service charges. They aren't usual in Lisbon, and no step needs them.
