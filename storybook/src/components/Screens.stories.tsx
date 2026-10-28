import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence } from 'motion/react';
import { useState } from 'react';
import {
  billTotal, euros, EVENT, EVERYONE_THERE, PEOPLE, peopleAt, personById, planDetails, PLANS, REN_JOINS, SCANNED_BILL, THE_BILL, TODAY, TRIP,
  TRIP_DAYS, TRIP_NOW, upNextAt, YOUR_TRIPS, type Bill, type Person, type Plan,
} from '../data';
import { ActionBar, TopBar } from './Bars';
import { Camera } from './BillScan';
import { ToggleChips } from './ToggleChips';
import { DetailSheet, openingTab, type DetailTab } from './DetailSheet';
import { ENTER_ORDER, useEnteredLast } from './Entrance';
import { HomeLayer } from './Home';
import { JoinLayer, type JoinStep } from './Join';
import { NoticeLayer, useNotice } from './Notice';
import { UpNextWidget } from './UpNextWidget';

const faces = Object.fromEntries(PEOPLE.map(p => [p.id, p.sticker]));
const phone = { width: 393, height: 852, position: 'relative' as const, overflow: 'hidden', borderRadius: 'var(--radius-sheet)', background: 'var(--color-bg-canvas)' };

const meta = { title: 'Screens/Trip', parameters: { layout: 'centered' } } satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Bars: Story = {
  name: 'Top bar and action bar',
  parameters: { docs: { description: { story: 'Top: back, the trip and its dates, the people, and the day filter, over a white that fades out down the map. Bottom: three 56 px glass buttons, each opening its pop-up (see Pop-ups): Itinerary (map pin, soft), Money (soft, with the whole group as a little pile of stickers) and Add (primary). md above them, 2xl below (the home indicator\'s inset on the phone when there is one). Behind them, white strongest at the bottom fades to clear at the top; no blur. Both fades ease in and out (a smoothstep), so their ends never show as a line.' } } },
  render: function Render() {
    const [days, setDays] = useState<number[]>([]);
    return (
      <div style={{ ...phone, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
        <TopBar title={TRIP.title} dates={TRIP.dates} filter={<ToggleChips label="Filter by day" options={TRIP_DAYS.map(d => ({ id: d.day, label: d.label }))} selected={days} onChange={setDays} />} />
        <ActionBar />
      </div>
    );
  },
};

/** The full view in its place, opening where the app would (`start`, or Group while the plan is on), of La Brasserie or
 *  of another `plan`. While the plan is on, Scan the bill opens the camera over it, and Add brings the bill in and
 *  tells everyone at the top. Notes (a dish added on the Menu, with Undo) come down at the top of the screen. */
function Sheet({ start, active, bill: scanned, people = PEOPLE, now = TRIP_NOW, plan }: { start?: DetailTab; active?: boolean; bill?: Bill; people?: Person[]; now?: Date; plan?: Plan }) {
  const [tab, setTab] = useState<DetailTab>(start ?? openingTab(active));
  const [bill, setBill] = useState(scanned);
  const [scanning, setScanning] = useState(false);
  const notices = useNotice();
  const [, showNotice] = notices;
  const add = (b: Bill) => {
    setBill(b);
    setScanning(false);
    showNotice(`Dinner added · ${euros(billTotal(b))}, split by who had what`);
  };
  return (
    <div style={{ ...phone, padding: 'var(--d-sheet-inset)', paddingTop: 'calc(var(--space-xl) + var(--d-button-md))' }}>
      <NoticeLayer state={notices}>
        <DetailSheet {...(plan ? planDetails(plan) : EVENT)} people={people} now={now} faces={faces} tab={tab} onTabChange={setTab} active={active} bill={bill} onScan={() => setScanning(true)} />
        <AnimatePresence>{scanning && <Camera key="camera" onAdd={add} onClose={() => setScanning(false)} />}</AnimatePresence>
      </NoticeLayer>
    </div>
  );
}

export const Overview: Story = {
  name: 'Full view · Overview',
  parameters: { docs: { description: { story: 'The place: its name and rating, its photos, what it is, then the one highlighted block, Know before you go (Bogdan\'s, Figma 62:4828): a subtle group (bg-subtle) with a brand heading, each tip a plain line in brand (label-sm) on a muted block (bg-muted, radius-card, at least 56 high), read, not tapped, so no arrow and no glass (see Components › Basics › KnowSection). Then its facts, as on its Google Maps card.' } } },
  render: () => <Sheet start="Overview" />,
};
export const OverviewPlain: Story = {
  name: 'Full view · a plain plan',
  parameters: { docs: { description: { story: 'A plan we know little about (Tram 28, tomorrow at 10; one sent from Add, or a poll\'s place picked by hand, is the same): under its name, when and how far ("Tomorrow, 10 AM · 4.3 km away", label-md, muted: the walk, or past 45 min the distance); then a small map of it instead of photos (plan/map-height 160, radius-card, its sticker in the middle and the map\'s credit; the app draws the live map\'s tiles, here a plain block stands in). Nothing else is known, so no about, no Know before you go, no facts. It has no menu, so its tabs are Overview · Group. It opens from its row in the itinerary (see Pop-ups › Itinerary).' } } },
  render: () => <Sheet start="Overview" plan={PLANS.find(p => p.id === 'tram')} />,
};
export const Menu: Story = {
  name: 'Full view · Menu',
  parameters: { docs: { description: { story: 'The restaurant\'s real menu, with who picked what. Add puts a dish on my picks, and "Added for Today, 5 PM" comes down at the top of the screen, like every other note, with Undo for toast-action-ms (Undo takes the dish back off).' } } },
  render: () => <Sheet start="Menu" />,
};
export const Group: Story = {
  name: 'Full view · Group',
  parameters: { docs: { description: { story: 'Before dinner: who\'s coming and how far each is, what they picked (a little pile of dishes) and roughly what it comes to, and the estimated total at the bottom.' } } },
  render: () => <Sheet start="Group" />,
};
export const GroupDinnerOn: Story = {
  name: 'Full view · Group · dinner on',
  parameters: { docs: { description: { story: 'The dinner is on (its time has come and someone is there), so the full view opens on Group: the group and the bill matter more now than the place\'s details. The tabs keep their order, Overview · Menu · Group. It\'s who has got there now, not who\'s coming: "Who\'s here", "5 of 5 here · Now". Under the estimate: "The bill splits itself once scanned" and Scan the bill, the width of the page and 56 px tall (TextButton lg, wide), which opens the camera; Add brings the bill in here and tells everyone at the top.' } } },
  render: () => <Sheet active people={peopleAt(EVERYONE_THERE)} now={EVERYONE_THERE} />,
};
export const GroupBillIn: Story = {
  name: 'Full view · Group · bill in',
  parameters: { docs: { description: { story: 'Once the bill is in, each person shows exactly what they had (no ≈): You €59.12, Maya €53.32, Nic €35.22, Leo €50.42, Ren €30.72. The bottom says "Bill · You paid · split by who had what", €228.80, and See who owes what, full width and 56 px (in the app it closes the full view and opens Money).' } } },
  render: () => <Sheet active bill={SCANNED_BILL} people={peopleAt(THE_BILL)} now={THE_BILL} />,
};

// ---------- Your trips, and Ren joining

/** The trip's screen at `now`, opening out of your trips' card and under Ren's phone: its bars and day filter on the
 *  canvas (the map isn't drawn here), and Up next a little above the middle, where its place would be. As the trip
 *  opens, the controls arrive one by one and Up next opens from its pin last (see Entrance.tsx). Back goes to your
 *  trips. */
function TripScreen({ onBack, now = TRIP_NOW }: { onBack?: () => void; now?: Date }) {
  // The trip opens on today: that's where the focus is
  const [days, setDays] = useState<number[]>([TODAY]);
  const upNextIn = useEnteredLast();
  return (
    <div style={{ position: 'absolute', inset: 0, background: 'var(--color-bg-canvas)' }}>
      <div style={{ position: 'absolute', inset: 'auto 0 45%', display: 'flex', justifyContent: 'center' }}>
        <UpNextWidget event={upNextAt(now)} state={upNextIn ? 'mid' : 'mini'} />
      </div>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', pointerEvents: 'none' }}>
        <div style={{ pointerEvents: 'auto' }}>
          <TopBar
            title={TRIP.title}
            dates={TRIP.dates}
            onBack={onBack}
            filter={<ToggleChips label="Filter by day" options={TRIP_DAYS.map(d => ({ id: d.day, label: d.label }))} selected={days} onChange={setDays} enterFrom={ENTER_ORDER.firstChip} />}
          />
        </div>
        <div style={{ pointerEvents: 'auto' }}><ActionBar /></div>
      </div>
    </div>
  );
}

/** The app's first screen at `now`: your trips. The current trip's card opens into the trip's screen (your trips fade
 *  and lean in behind it), and the trip's Back closes it into the card again. The bell's note comes down at the top. */
function Home({ now, scrolledToEnd }: { now?: Date; scrolledToEnd?: boolean }) {
  const [inTrip, setInTrip] = useState(false);
  return (
    <div style={phone}>
      <NoticeLayer>
        <HomeLayer inTrip={inTrip} trip={<TripScreen onBack={() => setInTrip(false)} now={now} />} now={now} scrolledToEnd={scrolledToEnd} onOpen={() => setInTrip(true)} />
      </NoticeLayer>
    </div>
  );
}

/** Ren's phone over Ari's trip screen, from `start`. Open the trip closes it, back on Ari's map, where everyone hears
 *  he's in; the × just closes it. */
function Joining({ start, now = REN_JOINS }: { start?: JoinStep; now?: Date }) {
  const [joining, setJoining] = useState(true);
  const notices = useNotice();
  const [, showNotice] = notices;
  const close = (joined = false) => {
    setJoining(false);
    if (joined) showNotice(`${personById('ren').name} joined the trip`);
  };
  return (
    <div style={phone}>
      <NoticeLayer state={notices}>
        <TripScreen now={now} />
        <AnimatePresence>
          {joining && <JoinLayer key="join" start={start} now={now} onJoined={() => close(true)} onClose={() => close()} />}
        </AnimatePresence>
      </NoticeLayer>
    </div>
  );
}

export const YourTrips: Story = {
  name: 'Your trips',
  parameters: { docs: { description: { story: 'The app opens here (the Demo moment "Your trips", 2 PM), on the brand blue (Figma 75:5927). At the top, "Your trips" in white, the bell (soft, md: nothing new yet, so "No new notifications" comes down at the top) and me in a soft glass circle as big as the bell. home-header-gap (28) under them, the trip I\'m on as a card 438 high, with the surface\'s corners and shadow and a 4 px white edge over it all: a still of Lisbon placed as in the design and scaled to cover the card from the top, with Belém, the galo, an azulejo and the caravel on it as stickers, and white rising from the bottom (solid up to home-map-fade-start, 15.2 % of the card, clear by the top). On it, "Happening now" (a soft glass pill with a green bead), the trip\'s name (heading-xl, one line, ending in "…" when it\'s long), its dates, who\'s on it (Ren joins at 2:10, so four faces, 39 px, overlapped) and the arrow in (primary, md). Then Coming up (Berlin) and Previous trips 3 (the count softer), as light brand rows: a 48 px sticker, the name (body-lg, medium), the dates, and the faces on the row\'s bottom edge, some tilted. Nothing folds, and there\'s no Demo button here (it\'s in the trip\'s top bar). The list fades into the blue at the bottom (home-bottom-fade, 89). Tapping the card opens the trip the way Airbnb opens a listing (from Bogdan\'s recording). Your trips stay put and blur and wash out behind it (c-trip-open-wash, white at 60%, and the sheet\'s backdrop blur, ramping in over the first 60% of the way). One rounded surface grows from the card\'s place to the whole screen, lifted by a shadow (elevation-overlay) while it\'s in the air. It starts as the card: the card\'s picture (the still and its stickers) grows inside it, covering it from the top, and the card\'s words leave at once (over the first 25%, at the card\'s size). The live trip, scaled to the surface, fades in over 45–85% of the way, a little blurred while it and the still both show (up to crossfade-blur × 4 × live × (1 − live)), and the corners square up over the last 30%. It runs on spring-open (0.45 s, no bounce: a full-screen container shouldn\'t wobble), the way the app runs it; the trip\'s Back runs it in reverse, quicker (spring-collapse, 0.38 s), and your trips come back as they were, scroll and all. Nothing takes taps while it moves. From the tap the trip\'s controls arrive one by one, each fading in and rising space-xs (open-item-ms 200, ease-out), starting open-delay-ms (220) in and open-stagger-ms (30) apart: back, the title, (the app\'s Demo button), the day chips (the six that show; the rest with the sixth), then the footer\'s three. When the last one starts (550 ms), Up next opens from its pin into the card; it all lands in about a second. Reduced motion: the trip only fades (fade-ms) while your trips blur and wash out, with every control already in. Here the trip\'s screen is its bars and day filter on the canvas, with Up next a little above the middle (the map isn\'t drawn).' } } },
  render: () => <Home now={YOUR_TRIPS} />,
};
export const YourTripsScrolled: Story = {
  name: 'Your trips · scrolled to the end',
  parameters: { docs: { description: { story: 'At the demo\'s start (3:56 PM): Ren is in, so five faces on the card. Scrolled to the end: Previous trips (Mallorca, Tokyo, Hanoi), all of them (they no longer fold away), the last row clear of the fade with home-bottom-fade of room under it; the rows above pass under the fade into the blue as they scroll.' } } },
  render: () => <Home scrolledToEnd />,
};
export const RenInvite: Story = {
  name: "Ren's phone · invite",
  parameters: { docs: { description: { story: 'The Demo moment "Ren joins", 2:10 PM, on Ren\'s phone: it fades in over Ari\'s from a slight zoom (page-zoom-scale, enter-ms) and fades away (fade-ms). At the top, "Ren\'s phone" in a muted pill and × (back to Ari\'s phone), over an eased fade so they read over whatever scrolls by. The invite sits in the middle of the screen, 5xl clear of the top and the bottom (it scrolls only if it doesn\'t fit): everyone already there (their faces), "Ari invited you to", the trip\'s name (two lines at most), "Lisbon · 12–21 May · 4 friends are there", his name in a 56 px muted pill, "No account and no password: your name is all it takes." and Join the trip (TextButton lg, wide). With the name emptied, Join goes to the field instead. Join swaps the page: the invite fades out with a blur (fade-ms) while the trip so far fades in (see Ren\'s phone · trip so far).' } } },
  render: () => <Joining />,
};
export const RenTripSoFar: Story = {
  name: "Ren's phone · trip so far",
  parameters: { docs: { description: { story: 'Just after Join, for someone arriving mid-trip: "Welcome, Ren", then where they\'re staying (a bed: Alfama flat, Airbnb until 21 May, Maya booked it), Been so far (8 places in 2 days, every sticker), Coming up (tonight\'s dinner while the poll hasn\'t decided it, in brand blue with a ballot box: "A poll opens at 2:30 PM: you can vote", "Poll open: where? Your vote counts too" once it\'s open; then the next three plans) and the rule for money: "The €726.00 spent before you joined stays with the four of them." Open the trip closes his phone, back on Ari\'s map, and everyone hears "Ren joined the trip" at the top.' } } },
  render: () => <Joining start="recap" />,
};

