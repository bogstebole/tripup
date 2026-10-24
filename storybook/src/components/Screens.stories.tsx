import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence } from 'motion/react';
import { useState } from 'react';
import {
  billTotal, euros, EVENT, EVERYONE_THERE, PEOPLE, peopleAt, personById, REN_JOINS, SCANNED_BILL, THE_BILL, TRIP, TRIP_DAYS, TRIP_NOW,
  YOUR_TRIPS, type Bill, type Person,
} from '../data';
import { ActionBar, TopBar } from './Bars';
import { Camera } from './BillScan';
import { ToggleChips } from './ToggleChips';
import { DetailSheet, openingTab, type DetailTab } from './DetailSheet';
import { HomeLayer } from './Home';
import { JoinLayer, type JoinStep } from './Join';
import { NoticeLayer, useNotice } from './Notice';

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

/** The full view in its place, opening where the app would (`start`, or Group while the plan is on). While the plan
 *  is on, Scan the bill opens the camera over it, and Add brings the bill in and tells everyone at the top. Notes
 *  (a dish added on the Menu, with Undo) come down at the top of the screen. */
function Sheet({ start, active, bill: scanned, people = PEOPLE, now = TRIP_NOW }: { start?: DetailTab; active?: boolean; bill?: Bill; people?: Person[]; now?: Date }) {
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
        <DetailSheet {...EVENT} people={people} now={now} faces={faces} tab={tab} onTabChange={setTab} active={active} bill={bill} onScan={() => setScanning(true)} />
        <AnimatePresence>{scanning && <Camera key="camera" onAdd={add} onClose={() => setScanning(false)} />}</AnimatePresence>
      </NoticeLayer>
    </div>
  );
}

export const Overview: Story = { name: 'Full view · Overview', render: () => <Sheet start="Overview" /> };
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

/** The trip's screen under your trips and Ren's phone: its bars (the map isn't drawn here). Back goes to your trips. */
function TripScreen({ onBack }: { onBack?: () => void }) {
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
      <TopBar title={TRIP.title} dates={TRIP.dates} onBack={onBack} />
      <ActionBar />
    </div>
  );
}

/** The app's first screen at `now`: your trips, over the trip's screen. The current trip goes in (your trips zoom past
 *  and fade) and the trip's Back comes back to them (they settle from the same zoom). */
function Home({ now, pastOpen }: { now?: Date; pastOpen?: boolean }) {
  const [home, setHome] = useState(true);
  return (
    <div style={phone}>
      <TripScreen onBack={() => setHome(true)} />
      <AnimatePresence initial={false}>{home && <HomeLayer key="home" now={now} pastOpen={pastOpen} onOpen={() => setHome(false)} />}</AnimatePresence>
    </div>
  );
}

/** Ren's phone (or, with `preview`, what anyone invited would see) over Ari's trip screen, from `start`. Open the trip
 *  closes it, back on Ari's map, where everyone hears he's in; the × (or Close the preview) just closes it. */
function Joining({ start, preview, now = REN_JOINS }: { start?: JoinStep; preview?: boolean; now?: Date }) {
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
        <TripScreen />
        <AnimatePresence>
          {joining && <JoinLayer key="join" start={start} preview={preview} now={now} onJoined={() => close(!preview)} onClose={() => close()} />}
        </AnimatePresence>
      </NoticeLayer>
    </div>
  );
}

export const YourTrips: Story = {
  name: 'Your trips',
  parameters: { docs: { description: { story: 'The app opens here (the Demo moment "Your trips", 2 PM). The trip I\'m on sits on top, on the surface: the first five places we\'ve been (stickers, overlapped), its name, "Lisbon · 12–21 May · Day 3 of 10", what\'s on right now in brand blue ("Poll open: where for dinner tonight?", "Now: dinner at La Brasserie de L\'Entrecôte", or the next plan: at 2 PM the dinner isn\'t decided yet, so "Up next: Sam Croissants, 6 PM"), who\'s on it (Ren joins at 2:10, so four faces) and "You owe Maya €181.50" ("4 on this trip" once I\'ve paid), with an arrow. Under it, Coming up (Porto weekend) and Past trips, folded, with how many and a chevron (see Your trips · past open). Tapping the card goes into the trip: your trips zoom past (to page-zoom-scale 1.04) and fade as an exit (fade-ms), the trip\'s screen under them; its Back brings them back, settling from that zoom (enter-ms, ease-out). Reduced motion: fades only.' } } },
  render: () => <Home now={YOUR_TRIPS} />,
};
export const YourTripsPastOpen: Story = {
  name: 'Your trips · past open',
  parameters: { docs: { description: { story: 'At the demo\'s start (3:56 PM): Ren is in, so five faces, and the poll has put La Brasserie in tonight ("Up next: La Brasserie de L\'Entrecôte, 5 PM"). Past trips are unfolded: Tokyo, Mallorca and Hanoi, each squared up, with hairlines between. A tap on "Past trips" folds them back: the list closes from the bottom (enter-ms, ease-out) and the chevron turns down with it; reduced motion, it fades.' } } },
  render: () => <Home pastOpen />,
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
export const InvitePreview: Story = {
  name: "Invite preview · what they'll see",
  parameters: { docs: { description: { story: 'From Add\'s Invite step, See what they\'ll see (see Pop-ups · Add · invite): the same phone, as anyone invited now would see it. The pill says "What they\'ll see" and × closes the preview; the name field is empty (Join the trip goes to it until there\'s a name); everyone is there, Ren too ("5 friends are there"). Nobody joins: after Join, the trip so far is as it stands now (the poll decided, so no Dinner row; La Brasserie is next), and its last button is Close the preview.' } } },
  render: () => <Joining preview now={TRIP_NOW} />,
};
