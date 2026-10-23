import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import { billTotal, BILL_IN, euros, isPaid, moneyWith, MY_ID, payLine, SCANNED_BILL, squaredUp, TRIP, type Bill, type Payment } from '../data';
import { ActionBar, TopBar } from './Bars';
import { BillScan } from './BillScan';
import { Toast } from './Toast';
import { ADD_SUBTITLE, AddPage, ITINERARY_SUBTITLE, ItineraryPage, MONEY_SUBTITLE, MoneyPage, moneySubtitle } from './TripPages';
import { TripSheet } from './TripSheet';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const phone = { width: 393, height: 852, position: 'relative' as const, overflow: 'hidden', borderRadius: 'var(--radius-sheet)', background: 'var(--color-bg-canvas)' };
// The full view's place: under the top bar's buttons, the sheet inset from the other edges. The pop-up lines up at
// its bottom, so Add's shorter one sits low.
const place = {
  position: 'absolute' as const,
  top: 'calc(var(--space-xl) + var(--d-button-md))',
  left: 'var(--d-sheet-inset)',
  right: 'var(--d-sheet-inset)',
  bottom: 'var(--d-sheet-inset)',
  display: 'flex',
  flexDirection: 'column' as const,
  justifyContent: 'flex-end',
  pointerEvents: 'none' as const,
};
// The map and the bars blur away behind it, under a light scrim
const backdrop = { position: 'absolute' as const, inset: 0, background: 'var(--c-sheet-scrim)', backdropFilter: 'blur(var(--d-sheet-backdrop-blur))', WebkitBackdropFilter: 'blur(var(--d-sheet-backdrop-blur))' };

type Which = 'itinerary' | 'money' | 'add';

/**
 * The trip screen with one footer pop-up open. The footer's buttons open the others once it's closed. `money` swaps
 * in another state of the money pop-up; `notice` is a note for everyone, at the top; `children` go over everything
 * (the camera).
 */
function Screen({ start, money, notice, children }: { start: Which | null; money?: { subtitle: string; page: ReactNode }; notice?: Notice; children?: ReactNode }) {
  const [open, setOpen] = useState<Which | null>(start);
  const reduce = useReducedMotion();
  const close = () => setOpen(null);
  const sheet = {
    itinerary: { title: 'Itinerary', subtitle: ITINERARY_SUBTITLE, page: <ItineraryPage onPick={close} /> },
    money: { title: 'Money', subtitle: money?.subtitle ?? MONEY_SUBTITLE, page: money?.page ?? <MoneyPage /> },
    add: { title: 'Add to the trip', subtitle: ADD_SUBTITLE, page: <AddPage /> },
  };
  return (
    <div style={phone}>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
        <TopBar title={TRIP.title} dates={TRIP.dates} />
        <ActionBar onItinerary={() => setOpen('itinerary')} onMoney={() => setOpen('money')} onAdd={() => setOpen('add')} />
      </div>
      <AnimatePresence>
        {open && (
          <motion.div
            key="backdrop"
            style={backdrop}
            onClick={close}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1, transition: { duration: (reduce ? m['fade-ms'] : m['enter-ms']) / 1000, ease } }}
            exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
          />
        )}
      </AnimatePresence>
      <div style={place}>
        <AnimatePresence>
          {open && (
            <TripSheet key={open} title={sheet[open].title} subtitle={sheet[open].subtitle} compact={open === 'add'} onClose={close}>
              {sheet[open].page}
            </TripSheet>
          )}
        </AnimatePresence>
      </div>
      {children}
      {notice && <Toast place="top" label={notice.label} shown={notice.shown} />}
    </div>
  );
}

// ---------- Tonight: the dinner's bill, the others paying, squared up

type Notice = { label: string; shown: boolean };

/** A note for everyone on the trip, at the top of the screen, for toast-ms; a new one replaces it. */
function useNotice() {
  const [notice, setNotice] = useState<Notice>({ label: '', shown: false });
  const timer = useRef<number | undefined>(undefined);
  const show = useCallback((label: string) => {
    setNotice({ label, shown: true });
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setNotice(n => ({ ...n, shown: false })), m['toast-ms']);
  }, []);
  useEffect(() => () => window.clearTimeout(timer.current), []);
  return [notice, show] as const;
}

/** In the app the others' payments come in 30 s apart (on the demo clock). Here they're quicker: two notes' time
 *  apart, so each note has gone before the next. */
const OTHERS_PAY_EVERY = 2 * m['toast-ms'];

/** The camera, fading in over the screen like any modal (enter-ms) and out quicker (fade-ms). */
function Camera({ onAdd, onClose }: { onAdd: (b: Bill) => void; onClose: () => void }) {
  return (
    <motion.div
      style={{ position: 'absolute', inset: 0 }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      <BillScan onAdd={onAdd} onClose={onClose} />
    </motion.div>
  );
}

/**
 * The money pop-up on the night: `dinner-on` (no bill yet, Scan the bill opens the camera), `bill-in` (the bill was
 * just added; the others start paying on their own) or `squared-up` (everyone has paid). My Pay works throughout.
 */
function LiveMoney({ from }: { from: 'dinner-on' | 'bill-in' | 'squared-up' }) {
  const [bill, setBill] = useState<Bill | undefined>(from === 'dinner-on' ? undefined : SCANNED_BILL);
  const money = useMemo(() => moneyWith(bill), [bill]);
  const [made, setMade] = useState<Payment[]>(from === 'squared-up' ? BILL_IN.settleUp : []);
  const [scanning, setScanning] = useState(false);
  const [notice, showNotice] = useNotice();
  const pay = useCallback((p: Payment) => setMade(ps => (isPaid(p, ps) ? ps : [...ps, p])), []);

  // Once the bill is in, the others pay what they owe on their own, one after another, and everyone hears of it
  useEffect(() => {
    if (!bill || from === 'squared-up') return;
    const others = moneyWith(bill).settleUp.filter(p => p.from !== MY_ID);
    const timers = others.map((p, i) => window.setTimeout(() => { pay(p); showNotice(payLine(p)); }, OTHERS_PAY_EVERY * (i + 1)));
    return () => timers.forEach(t => window.clearTimeout(t));
  }, [bill, from, pay, showNotice]);

  // When the last payment lands, everyone hears the trip is squared up
  const square = squaredUp(money, made);
  const wasSquare = useRef(square);
  useEffect(() => {
    if (square && !wasSquare.current) {
      const t = window.setTimeout(() => showNotice('Lisbon is squared up · everyone has paid'), m['toast-ms'] / 2);
      wasSquare.current = square;
      return () => window.clearTimeout(t);
    }
    wasSquare.current = square;
  }, [square, showNotice]);

  const add = (b: Bill) => {
    setBill(b);
    setMade([]);
    setScanning(false);
    showNotice(`Dinner added · ${euros(billTotal(b))}, split by who had what`);
  };
  return (
    <Screen
      start="money"
      money={{ subtitle: moneySubtitle(money), page: <MoneyPage money={money} made={made} onPay={pay} dinnerOn onScan={() => setScanning(true)} /> }}
      notice={notice}
    >
      <AnimatePresence>{scanning && <Camera key="camera" onAdd={add} onClose={() => setScanning(false)} />}</AnimatePresence>
    </Screen>
  );
}

/** The camera on its own, playing from the start; Replay starts it over. Add closes it and tells everyone. */
function ScanStory() {
  const [run, setRun] = useState(1);
  const [scanning, setScanning] = useState(true);
  const [notice, showNotice] = useNotice();
  return (
    <div style={{ display: 'grid', gap: 'var(--space-md)', justifyItems: 'center' }}>
      <button
        type="button"
        className="text-label-md"
        style={{ padding: 'var(--space-xs) var(--space-sm)', borderRadius: 'var(--radius-pill)', background: 'var(--color-bg-inverse)', color: 'var(--color-text-inverse)' }}
        onClick={() => { setScanning(true); setRun(r => r + 1); }}
      >
        Replay
      </button>
      <Screen start={null} notice={notice}>
        <AnimatePresence>
          {scanning && (
            <Camera
              key={run}
              onAdd={b => { setScanning(false); showNotice(`Dinner added · ${euros(billTotal(b))}, split by who had what`); }}
              onClose={() => setScanning(false)}
            />
          )}
        </AnimatePresence>
      </Screen>
    </div>
  );
}

const meta = {
  title: 'Pop-ups',
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: [
          'The footer\'s three pop-ups: Itinerary, Money and Add. They look the same so they read as one family: the full view\'s surface, in the full view\'s place, with a header holding the title, a one-line subtitle and close. The page scrolls up under the header, which picks up the surface\'s white as the page goes under it.',
          '',
          'Motion: the pop-up rises from just past the bottom edge (enter-ms, ease-out) while the map and bars blur away under a light scrim, and goes back down quicker (fade-ms). The page\'s blocks arrive one after another (fade, light blur, a few px up, stagger-ms apart). They close with the ×, a tap outside, or (on the phone) a pull down on the header. Reduced motion: fades only.',
          '',
          'Add is shorter (sheet/compact-height) since it has only a few rows. Notes ("Link copied", "You paid Maya €181.50") come up at the bottom of the pop-up for toast-ms. Notes for everyone on the trip ("Leo paid Maya €185.92") slide down at the top of the screen instead, the same pill, for toast-ms.',
        ].join('\n'),
      },
    },
  },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Itinerary: Story = {
  parameters: { docs: { description: { story: 'Every day of the trip, in order: where we\'ve been (a check), what\'s planned (its time), and today marked. It opens on today, just under the header. The next plan says "Up next" in brand blue. Tapping a stop closes the pop-up and shows it on the map.' } } },
  render: () => <Screen start="itinerary" />,
};

export const Money: Story = {
  parameters: { docs: { description: { story: 'Before dinner: what I owe and Pay, tonight\'s dinner as an estimate until the bill comes, the fewest payments that square everyone (3 instead of 9, one expense at a time), each person\'s balance in plain words, and the expenses (€726.00). Pay flips the block to "You\'re square with Maya" and shows a note; my payment row turns to Paid and the balances follow. Tap a payment for its Why. Costs from before someone joined stay with the people who were there (Ren joined today).' } } },
  render: () => <Screen start="money" />,
};

export const MoneyDinnerOn: Story = {
  name: 'Money · dinner on',
  parameters: { docs: { description: { story: 'While the dinner is on and before its bill is in, the estimate gives way to "Dinner is on" and Scan the bill. Scan the bill opens the camera (see Scan the bill); Add brings the bill in here, with a note for everyone at the top, and the others start paying (as in Money · bill in).' } } },
  render: () => <LiveMoney from="dinner-on" />,
};

export const MoneyBillIn: Story = {
  name: 'Money · bill in',
  parameters: { docs: { description: { story: `The bill was just added (€228.80, paid by me, split by who had what): €954.80 spent, 4 expenses, and 4 payments instead of 13, all to Maya (Leo €185.92, Nic €136.72, Ren €30.72, me €11.82). Each payment has a Why that opens under it: what they had of each expense, what they paid, and why it goes to one person. The others pay on their own: in the app 30 s apart, here ${OTHERS_PAY_EVERY / 1000} s apart, each with a note for everyone at the top ("Leo paid Maya €185.92"). Once they have, the top block says "Everyone else has paid" over my €11.82; my Pay makes it "You\'re square with Maya", and when the last payment lands, the block turns green and everyone hears "Lisbon is squared up".` } } },
  render: () => <LiveMoney from="bill-in" />,
};

export const MoneySquaredUp: Story = {
  name: 'Money · squared up',
  parameters: { docs: { description: { story: 'Everyone has paid: the top block is green, "Lisbon is squared up", 4 payments, €365.18 in all. Every payment is Paid (each still has its Why), every balance is Square, and the dinner sits on top of the expenses, by who had what.' } } },
  render: () => <LiveMoney from="squared-up" />,
};

export const ScanTheBill: Story = {
  name: 'Scan the bill',
  parameters: { docs: { description: { story: 'The camera, over everything: the restaurant dim behind the paper bill. A moment to find the paper (scan-find-ms 600), then the corner marks close in from the screen\'s edges onto it and turn blue (enter-ms, ease-out); a line reads it top to bottom at an even pace (scan-read-ms 900, linear); then the bill rises (enter-ms) and the paper fades back. Every line has its menu name, "qty × price · who", its amount and the faces of whoever had it: whoever picked it on the menu, or everyone if nobody did (the couvert, the water). Tap a line to change who had it (faces toggle; someone always has it); the totals under it follow, to the cent (You €59.12, Maya €53.32, Nic €35.22, Leo €50.42, Ren €30.72). "Change" changes who paid. Add closes the camera and tells everyone. Reduced motion: straight to the bill, which fades in. Replay starts it over.' } } },
  render: () => <ScanStory />,
};

export const Add: Story = {
  parameters: { docs: { description: { story: 'Two choices: plan something, or invite someone. Plan shows ideas nearby, each with the free slot it would go in, and an Add button (a note confirms the slot). Invite shows the link with Copy link (a note confirms) and says what joining costs. Back returns to the choice; a step fades out with a blur while the next one arrives.' } } },
  render: () => <Screen start="add" />,
};
