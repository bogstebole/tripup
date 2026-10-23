# TripUp: the brief's scenario, step by step, in the final app

The eleven steps from the brief (`process/research/tripup-competitive-research-v3-en.md`, Scenario map), and how far the Flutter app (`app/`) covers each one. Checked on 23 Oct, at iteration 1.22, on the iPhone simulator, the Android emulator and in the code. The earlier HTML prototypes (`prototype/versions/v1`–`v11`) covered the whole flow at low fidelity; this is about the final UI.

✅ covered · 🟡 partly · ❌ missing

| # | Step | In the app | Status | What's missing |
| --- | --- | --- | --- | --- |
| 01 | Home with all trips | Only the trip screen. Its Back button goes nowhere. | ❌ | A trips list: Lisbon active and on top, past trips folded away. |
| 02 | Group view | The map with Up next (who's coming, who's there, price), the day filter, live locations, and the footer (itinerary, money, add). | 🟡 | An open poll and the group's balance aren't on the screen itself; they sit behind buttons. |
| 03 | Ren joins mid-trip | Add → Invite someone: a link to copy, "no account", and "only costs from the day they join". In the data, Ren joined today. | 🟡 | Ren's side: opening the link, typing a name, and the recap of the trip so far (stay, decided plans, open poll, the costs rule). |
| 04 | Poll: 3 restaurants | Nothing. | ❌ | A poll with three place cards (photo, rating, price, walking minutes). |
| 05 | Everyone notified | Nothing. | ❌ | A notification when the poll opens and when it closes. |
| 06 | Leading option, live | Nothing. | ❌ | "Leading" on the front option, voters' faces, a countdown. |
| 07 | Winner into the itinerary | La Brasserie is already in the itinerary and on the map as Up next, but no poll put it there. Add → Plan something drops an idea into a free slot. | 🟡 | The poll's winner going into the itinerary by itself, with Undo (no app does this). |
| 08 | Ren and Nic skip the wine | Menu: everyone's picks and costs per person. Money: tonight's dinner only as an estimate. In the app Ren isn't at dinner. | ❌ | Ren at dinner (the brief has Ren and Nic skipping the wine). The bill after dinner, with a wine line where two faces are tapped off. |
| 09 | Fewest transfers | Money: "3 payments square everyone, instead of 9". | ✅ | "Why this payment" for each one (the research says people don't trust a number they can't trace). |
| 10 | Pay in the app | Money: "You owe Maya €181.50" and Pay. The row turns Paid and the balances move. | 🟡 | The others paying too, so every debt can close. |
| 11 | "Squared up" to the group | Nothing. | ❌ | "Lisbon is squared up" for everyone once the last payment lands (no app does this). |

**Covered: 1 of 11, partly: 4, missing: 6.**

## Open decisions

- **Moving through the story in the demo.** The demo clock starts at 15:56, before dinner. The poll comes before that and the bill after it. Either the steps follow from what the person taps (the poll closes and the evening jumps ahead to the bill), or there's a small demo control to jump between moments.
- **Ren at dinner:** the brief needs it for step 08. In the app, Ren is "Not going".
