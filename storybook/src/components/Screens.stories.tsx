import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence } from 'motion/react';
import { useState } from 'react';
import { billTotal, euros, EVENT, EVERYONE_THERE, PEOPLE, peopleAt, SCANNED_BILL, THE_BILL, TRIP, TRIP_DAYS, TRIP_NOW, type Bill, type Person } from '../data';
import { ActionBar, TopBar } from './Bars';
import { Camera } from './BillScan';
import { ToggleChips } from './ToggleChips';
import { DetailSheet, openingTab, type DetailTab } from './DetailSheet';
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
