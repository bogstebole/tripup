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
import { EnterItem, ENTER_ORDER, useEnteredLast } from './Entrance';
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
    <div style={{ ...phone, padding: 'var(--space-md)', paddingTop: 'calc(var(--space-xl) + var(--d-button-md))' }}>
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

/** The trip's screen at `now`, under Your trips and under Ren's phone: its bars and day filter over the map (here
 *  HomeLayer's still, or nothing: the map isn't drawn in Storybook), and Up next a little above the middle, where its
 *  place would be. As the trip opens, Up next's pin comes in with the first control, the controls arrive one by one
 *  and Up next opens from its pin last (see Entrance.tsx). Back goes to your trips. */
function TripScreen({ onBack, now = TRIP_NOW }: { onBack?: () => void; now?: Date }) {
  // The trip opens on today: that's where the focus is
  const [days, setDays] = useState<number[]>([TODAY]);
  const upNextIn = useEnteredLast();
  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      <div style={{ position: 'absolute', inset: 'auto 0 45%', display: 'flex', justifyContent: 'center' }}>
        <EnterItem index={ENTER_ORDER.back}><UpNextWidget event={upNextAt(now)} state={upNextIn ? 'mid' : 'mini'} /></EnterItem>
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

/** The app's first screen at `now`: your trips, over the trip. See trip details: Your trips' parts leave one by one,
 *  the map zooms in and the trip's controls arrive; the trip's Back runs it the other way. The bell's note comes down
 *  at the top. */
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
        <div style={{ position: 'absolute', inset: 0, background: 'var(--color-bg-canvas)' }}><TripScreen now={now} /></div>
        <AnimatePresence>
          {joining && <JoinLayer key="join" start={start} now={now} onJoined={() => close(true)} onClose={() => close()} />}
        </AnimatePresence>
      </NoticeLayer>
    </div>
  );
}

export const YourTrips: Story = {
  name: 'Your trips',
  parameters: { docs: { description: { story: 'The app opens here (the Demo moment "Your trips", 2 PM) (Figma 258:12058). Your trips is an overlay on the trip I\'m on: its map shows through the top (in the app the live map, with none of the trip\'s pins, people or controls; here a still of it), and over it "Your trips" (heading-lg, dark on the map), the bell (soft, md: nothing new yet, so "No new notifications" comes down at the top) and me in a soft glass circle as big as the bell, xl in from the sides. In the middle of the 356 under the header: the trip\'s name, big (40, the display face, with a sticker\'s white edge 4 outside the letters and elevation-raised under it, up to two lines), the city and dates (label-md), then everyone on it (57 high, 22 overlapped, standing 8 over the button) on See trip details (primary, lg, with the trip\'s green bead). Under it the blue rises over the map, clear to solid over 275, blurring it a little (2). Then Coming up (Berlin) and Previous trips 3 (the count softer), as soft glass cards (radius-sheet, md in): a sticker in a 48 square (wide ones shrink to fit), the name (body-lg, medium), the dates, and the faces at the end (32 high, 18 overlapped). Nothing folds, and there\'s no Demo button here (it\'s in the trip\'s top bar). The list fades into the blue at the bottom (120). The header (Your trips, the bell and me) stays put while the list scrolls under it, over the trip\'s top bar\'s see-through white once the list goes under it. Pulling past the last card shows blue. Tapping the trip (or See trip details) goes in. Your trips\' elements leave one after another, each on its own: the header, the name, the dates, the faces, the button, each heading and each card, then the blue. Each fades, blurs (up to enter-blur) and rises space-xs (enter-ms 260 each, open-stagger-ms 30 apart, ease-out; all gone by about 600 ms). At the same moment the map under it zooms in on the trip (one zoom level, on spring-open, no bounce). Only once the last part has gone does the trip\'s clock run, so nothing of the trip arrives while Your trips is still leaving: its pins come in open-delay-ms (220) into it, as the last part lands, its controls arrive one by one, each fading in and rising space-xs (open-item-ms 200, ease-out), open-stagger-ms (30) apart: back, the title, (the app\'s Demo button), the day chips (the six that show; the rest with the sixth), then the footer\'s three. When the last one starts (550 ms into the trip\'s clock), Up next opens from its pin into the card (the first time in a launch); it all lands in about 1.15 s. The trip\'s Back runs it the other way: its controls and pins go at once (fade-ms), the map zooms back out (spring-collapse, 0.38 s), and Your trips\' parts come back top to bottom, the blue first so the cards never land on the bare map, as they were, scroll and all. Nothing takes taps while it moves. Reduced motion: everything only fades. Here the map is the still of Lisbon (Storybook has no live map): it zooms in, then gives way to the trip\'s canvas once its controls are in.' } } },
  render: () => <Home now={YOUR_TRIPS} />,
};
export const YourTripsScrolled: Story = {
  name: 'Your trips · scrolled to the end',
  parameters: { docs: { description: { story: 'At the demo\'s start (3:56 PM): Ren is in, so five faces on the button. Scrolled to the end: Previous trips (Mallorca, Tokyo, Hanoi), all of them (they no longer fold away), the last card clear of the fade with 120 of room under it; the cards above pass under the fade into the blue as they scroll.' } } },
  render: () => <Home scrolledToEnd />,
};
export const RenInvite: Story = {
  name: "Ren's phone · invite",
  parameters: { docs: { description: { story: 'The Demo moment "Ren joins", 2:10 PM, on Ren\'s phone: it fades in over Ari\'s from a slight zoom (page-zoom-scale, enter-ms) and fades away (fade-ms). At the top, "Ren\'s phone" in a muted pill and × (back to Ari\'s phone), over an eased fade so they read over whatever scrolls by. The invite sits in the middle of the screen, 5xl clear of the top and the bottom (it scrolls only if it doesn\'t fit): everyone already there (their faces), "Ari invited you to", the trip\'s name (two lines at most), "Lisbon · 12–21 May · 4 friends are there", his name in a 56 px muted pill, "No account and no password: your name is all it takes." and Join the trip (TextButton lg, wide). With the name emptied, Join goes to the field instead. Join swaps the page: the invite fades out with a blur (fade-ms) while the trip so far fades in (see Ren\'s phone · trip so far).' } } },
  render: () => <Joining />,
};
export const RenTripSoFar: Story = {
  name: "Ren's phone · trip so far",
  parameters: { docs: { description: { story: 'Just after Join, for someone arriving mid-trip: "Welcome, Ren", then where they\'re staying (the flat\'s building as a sticker: Alfama flat, Airbnb until 21 May, Maya booked it, with Directions and Open in Airbnb under it, both soft), Been so far (8 places in 2 days, every sticker), Coming up (the next four plans, tonight\'s dinner among them at 5 PM as if already decided, even while the poll hasn\'t picked the place) and the rule for money: "The €726.00 spent before you joined stays with the four of them." Open the trip closes his phone, back on Ari\'s map, and everyone hears "Ren joined the trip" at the top.' } } },
  render: () => <Joining start="recap" />,
};

