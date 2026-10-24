import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  billTotal, BILL_IN, euros, isPaid, moneyWith, MY_ID, payLine, POLL_CLOSES, POLL_OPENS, POLL_VOTES, pollClosed, pollLeader, pollOpen,
  pollOptionById, pollStartedLine, pollWonLine, SCANNED_BILL, squaredUp, TODAY, TRIP, TRIP_DAYS, type Bill, type Payment, type PollState,
} from '../data';
import { ActionBar, TopBar } from './Bars';
import { Camera } from './BillScan';
import { NoticeLayer, useNotice, type NoticeState } from './Notice';
import { JoinLayer } from './Join';
import { PollOnMap, PollPage, pollSubtitle } from './Poll';
import { ToggleChips } from './ToggleChips';
import {
  ADD_SUBTITLE, AddPage, ITINERARY_SUBTITLE, ItineraryPage, MONEY_SUBTITLE, MoneyPage, moneySubtitle, type AddPageProps, type AddStep,
  type ItineraryPageProps, type MoneyTab,
} from './TripPages';
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
// The dinner poll's card (or pill): where the Up next card would be, under the top bar, centred, grown from its top
const pollCardPlace = {
  position: 'absolute' as const,
  top: 'calc(var(--space-xl) + var(--d-button-md) + var(--d-widget-edge-inset))',
  left: 0,
  right: 0,
  display: 'flex',
  justifyContent: 'center',
  alignItems: 'flex-start',
  transformOrigin: 'top center',
};
const dayOptions = TRIP_DAYS.map(d => ({ id: d.day, label: d.label }));

type Which = 'itinerary' | 'money' | 'add' | 'poll';

/** The dinner poll on the screen: its pop-up's subtitle and page, and its card on the map while it's open (a
 *  PollOnMap, card or pill). */
type PollSlot = { subtitle: string; page: ReactNode; card?: ReactNode };

/**
 * The trip screen with one footer pop-up open. The footer's buttons open the others once it's closed. `money` swaps
 * in another state of the money pop-up, `itinerary` sets the itinerary's page (the poll, now), `add` the add page's
 * (its step, and Invite's preview); `poll` is the dinner poll (its pop-up, and its card on the map while no pop-up
 * covers it); `children` go over everything (the camera, the invited person's phone). Notes for everyone come down at
 * the top: the pages show theirs, and `notices` lets the story show its own too. `open` and `onOpen` say from outside
 * which pop-up is open. The itinerary has its own day filter, pinned under its title: it opens on All (`planDays`
 * picks days for the story's start).
 */
function Screen({ start = null, open: shown, onOpen, money, itinerary, add, poll, notices, planDays: firstDays = [], children }: {
  start?: Which | null;
  open?: Which | null;
  onOpen?: (which: Which | null) => void;
  money?: { subtitle: string; page: ReactNode };
  itinerary?: Omit<ItineraryPageProps, 'onPick' | 'onPoll' | 'days'>;
  add?: AddPageProps;
  poll?: PollSlot;
  notices?: NoticeState;
  planDays?: number[];
  children?: ReactNode;
}) {
  const [own, setOwn] = useState<Which | null>(start);
  const open = shown === undefined ? own : shown;
  const setOpen = onOpen ?? setOwn;
  const reduce = useReducedMotion();
  const close = () => setOpen(null);
  // The itinerary's own filter (not the map's, so planning ahead doesn't change the map); each time it opens, on All
  const [planDays, setPlanDays] = useState<number[]>(firstDays);
  const [lastOpen, setLastOpen] = useState(open);
  if (open !== lastOpen) {
    setLastOpen(open);
    if (open === 'itinerary') setPlanDays([]);
  }
  const sheet: Record<Which, { title: string; subtitle: string; page: ReactNode; top?: ReactNode } | undefined> = {
    itinerary: {
      title: 'Itinerary',
      subtitle: ITINERARY_SUBTITLE,
      page: <ItineraryPage onPick={close} onPoll={poll && (() => setOpen('poll'))} {...itinerary} days={planDays} />,
      top: <ToggleChips label="Filter the itinerary by day" options={dayOptions} selected={planDays} onChange={setPlanDays} inset="xs" />,
    },
    money: { title: 'Money', subtitle: money?.subtitle ?? MONEY_SUBTITLE, page: money?.page ?? <MoneyPage /> },
    add: { title: 'Add to the trip', subtitle: ADD_SUBTITLE, page: <AddPage {...add} /> },
    poll: poll && { title: 'Dinner tonight', subtitle: poll.subtitle, page: poll.page },
  };
  const current = open ? sheet[open] : undefined;
  return (
    <div style={phone}>
      <NoticeLayer state={notices}>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <TopBar title={TRIP.title} dates={TRIP.dates} />
          <ActionBar onItinerary={() => setOpen('itinerary')} onMoney={() => setOpen('money')} onAdd={() => setOpen('add')} />
        </div>
        {/* While the dinner poll is open its card (or its pill) stands on the map: it fades in and grows a little from its
            top (morph-enter-scale, enter-ms, ease-out) and goes quicker (fade-ms) as the poll closes or a pop-up covers
            it; reduced motion, fades only. Folding is the card's own morph (see PollOnMap). */}
        <AnimatePresence>
          {poll?.card && !current && (
            <motion.div
              key="poll"
              style={pollCardPlace}
              initial={{ opacity: 0, scale: reduce ? 1 : m['morph-enter-scale'] }}
              animate={{ opacity: 1, scale: 1, transition: { duration: (reduce ? m['fade-ms'] : m['enter-ms']) / 1000, ease } }}
              exit={{ opacity: 0, scale: reduce ? 1 : m['morph-enter-scale'], pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
            >
              {poll.card}
            </motion.div>
          )}
        </AnimatePresence>
        <AnimatePresence>
          {current && (
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
            {open && current && (
              <TripSheet key={open} title={current.title} subtitle={current.subtitle} compact={open === 'add'} top={current.top} onClose={close}>
                {current.page}
              </TripSheet>
            )}
          </AnimatePresence>
        </div>
        {children}
      </NoticeLayer>
    </div>
  );
}

// ---------- Tonight: the dinner's bill, the others paying, squared up

/** In the app the others' payments come in 30 s apart (on the demo clock). Here they're quicker: two notes' time
 *  apart, so each note has gone before the next. */
const OTHERS_PAY_EVERY = 2 * m['toast-ms'];

/**
 * The money pop-up on the night: `dinner-on` (no bill yet, Scan the bill opens the camera), `bill-in` (the bill was
 * just added; the others start paying on their own) or `squared-up` (everyone has paid). My Pay works throughout.
 * `scanning` starts with the camera up, over the money pop-up.
 */
function LiveMoney({ from, scanning: scanFirst = false }: { from: 'dinner-on' | 'bill-in' | 'squared-up'; scanning?: boolean }) {
  const [bill, setBill] = useState<Bill | undefined>(from === 'dinner-on' ? undefined : SCANNED_BILL);
  const money = useMemo(() => moneyWith(bill), [bill]);
  const [made, setMade] = useState<Payment[]>(from === 'squared-up' ? BILL_IN.settleUp : []);
  const [scanning, setScanning] = useState(scanFirst);
  const notices = useNotice();
  const [, showNotice] = notices;
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
      notices={notices}
    >
      <AnimatePresence>{scanning && <Camera key="camera" onAdd={add} onClose={() => setScanning(false)} />}</AnimatePresence>
    </Screen>
  );
}

/** Starts a story over. */
function Replay({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      className="text-label-md"
      style={{ padding: 'var(--space-xs) var(--space-sm)', borderRadius: 'var(--radius-pill)', background: 'var(--color-bg-inverse)', color: 'var(--color-text-inverse)' }}
      onClick={onClick}
    >
      Replay
    </button>
  );
}

/** The camera from the start, over the money pop-up (as from its Scan the bill); Replay starts it over. Add brings the
 *  bill into the money under it and tells everyone. */
function ScanStory() {
  const [run, setRun] = useState(1);
  return (
    <div style={{ display: 'grid', gap: 'var(--space-md)', justifyItems: 'center' }}>
      <Replay onClick={() => setRun(r => r + 1)} />
      <LiveMoney key={run} from="dinner-on" scanning />
    </div>
  );
}

// ---------- The dinner poll: where to eat tonight

/** In the app the poll runs on the demo clock: half an hour from 2:30 PM, the others voting 6, 11 and 17 minutes in.
 *  Here a trip minute passes every POLL_MINUTE_MS. */
const POLL_MINUTE_MS = 1000;
/** The story's clock holds at the last of the others' votes (Ren's, 2:47 PM), so the open poll stays to look at. */
const HOLD_MINUTE = (POLL_VOTES[POLL_VOTES.length - 1].at.getTime() - POLL_OPENS.getTime()) / 60000;

/** Trip time in the poll: half past each minute from 2:30 PM, a minute every POLL_MINUTE_MS, up to HOLD_MINUTE; or
 *  `fixed`, not running. */
function usePollClock(fixed?: Date) {
  const [minute, setMinute] = useState(0);
  useEffect(() => {
    if (fixed) return;
    const t = window.setInterval(() => setMinute(x => Math.min(x + 1, HOLD_MINUTE)), POLL_MINUTE_MS);
    return () => window.clearInterval(t);
  }, [fixed]);
  return useMemo(() => fixed ?? new Date(POLL_OPENS.getTime() + (minute * 60 + 30) * 1000), [fixed, minute]);
}

/**
 * The trip screen through the dinner poll: `open` (it has just opened; the clock runs, sped up, and the others'
 * votes come in), `closed` (3 PM: the winner has just gone into tonight) or `undone` (the winner was taken back out).
 * The poll's pop-up starts open (`start` opens another); closing it shows the poll's card on the map while it's open.
 */
function LivePoll({ from, start = 'poll' }: { from: 'open' | 'closed' | 'undone'; start?: Which }) {
  const now = usePollClock(from === 'open' ? undefined : POLL_CLOSES);
  const [poll, setPoll] = useState<PollState>(from === 'undone' ? { undone: true } : {});
  const [open, setOpen] = useState<Which | null>(start);
  // The card folded into its pill, off the map
  const [folded, setFolded] = useState(false);
  // My vote, from the pop-up or right on the card
  const vote = (option: string) => setPoll(p => ({ ...p, mine: { option, at: now } }));
  const notices = useNotice();
  const [, showNotice, hideNotice] = notices;

  // Undo takes the winner back out of tonight; the poll opens so someone can pick one by hand
  const undo = useCallback(() => {
    setPoll(p => ({ ...p, undone: true }));
    hideNotice();
    setOpen('poll');
  }, [hideNotice]);
  const won = useCallback((at: Date, p: PollState) => showNotice(pollWonLine(pollOptionById(pollLeader(at, p)!)), { label: 'Undo', onTap: undo }), [showNotice, undo]);

  // The story starts as the poll opens (everyone hears of it) or as it closes (the winner went in, with Undo)
  useEffect(() => {
    if (from === 'open') showNotice(pollStartedLine());
    if (from === 'closed') won(POLL_CLOSES, {});
  }, [from, showNotice, won]);

  // It closes while you watch: at the deadline, or as soon as everyone has voted
  const closed = pollClosed(now, poll);
  const wasClosed = useRef(closed);
  useEffect(() => {
    if (closed && !wasClosed.current && !poll.undone) won(now, poll);
    wasClosed.current = closed;
  }, [closed, now, poll, won]);

  return (
    <Screen
      open={open}
      onOpen={setOpen}
      itinerary={{ poll, now }}
      poll={{
        subtitle: pollSubtitle(now, poll),
        page: (
          <PollPage now={now} poll={poll} onVote={vote} onPick={option => setPoll(p => ({ ...p, picked: option }))} />
        ),
        card: pollOpen(now, poll) && (
          <PollOnMap
            folded={folded}
            now={now}
            poll={poll}
            onFold={() => setFolded(true)}
            onUnfold={() => setFolded(false)}
            onOpen={() => setOpen('poll')}
            onVote={vote}
          />
        ),
      }}
      notices={notices}
    />
  );
}

/** A live poll with Replay, which starts it over from 2:30 PM. */
function PollStory({ start }: { start?: Which }) {
  const [run, setRun] = useState(1);
  return (
    <div style={{ display: 'grid', gap: 'var(--space-md)', justifyItems: 'center' }}>
      <Replay onClick={() => setRun(r => r + 1)} />
      <LivePoll key={run} from="open" start={start} />
    </div>
  );
}

// ---------- Add: a plan, or someone new

/** The add pop-up, on `start`. Invite's See what they'll see opens the invited person's phone over everything (as in
 *  Screens · Invite preview); its × or Close the preview goes back to Invite. */
function AddStory({ start }: { start?: AddStep }) {
  const [preview, setPreview] = useState(false);
  return (
    <Screen start="add" add={{ start, onPreview: () => setPreview(true) }}>
      <AnimatePresence>{preview && <JoinLayer key="preview" preview onJoined={() => setPreview(false)} onClose={() => setPreview(false)} />}</AnimatePresence>
    </Screen>
  );
}

const meta = {
  title: 'Pop-ups',
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: [
          'The footer\'s three pop-ups: Itinerary, Money and Add. They look the same so they read as one family: the full view\'s surface, in the full view\'s place, with a header holding the title, a one-line subtitle and close. The page scrolls up under the header, which picks up the surface\'s white as the page goes under it. The itinerary\'s header also holds its day filter, pinned sm under the title (one chip row, toggle-chip-height; the header grows by as much).',
          '',
          'Motion: the pop-up rises from just past the bottom edge (enter-ms, ease-out) while the map and bars blur away under a light scrim, and goes back down quicker (fade-ms). The page\'s blocks arrive one after another (fade, light blur, a few px up, stagger-ms apart). They close with the ×, a tap outside, or (on the phone) a pull down on the header. Reduced motion: fades only.',
          '',
          'Add is shorter (sheet/compact-height) since it has only a few rows. Every note comes down at the top of the screen, where the top bar\'s buttons are, whether it\'s mine ("Link copied", "You paid Maya €181.50") or one for everyone on the trip ("Leo paid Maya €185.92"): the same pill, for toast-ms; one with Undo stays for toast-action-ms, so there\'s time to reach it. The pop-ups have no notes of their own. A line too long for the pill ends in an ellipsis; Undo always shows.',
          '',
          'The dinner poll is a pop-up of the same family, "Dinner tonight". It opens from its card on the map (in its place while it\'s open), from tonight\'s Dinner slot in the itinerary, and on Undo.',
        ].join('\n'),
      },
    },
  },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Itinerary: Story = {
  parameters: { docs: { description: { story: 'Every day of the trip, in order, each in its own grey block (bg-muted, radius-sheet, sm apart), so what belongs to which day is plain: its heading ("Thu 14 · Day 3 · Today", past days muted), then where we\'ve been (a check) and what\'s planned (its time), with hairlines between; a day with nothing yet says "Nothing planned yet". Under the title, pinned while the page scrolls under it, the day filter: the same chips as the map\'s (All, Tue 12…), but its own, so planning ahead doesn\'t change what the map shows. It opens on All, scrolled to today, just under the header; picking days shows only those (they combine; All brings every day back, at once). The next plan says "Up next" in brand blue. Tapping a stop closes the pop-up and shows it on the map.' } } },
  render: () => <Screen start="itinerary" />,
};

export const ItineraryOneDay: Story = {
  name: 'Itinerary · one day',
  parameters: { docs: { description: { story: 'The filter on Thu 14: only today\'s block (been there, then what\'s planned, Up next in brand). Pick more days to add them, or All for every day. Closing the itinerary and opening it again starts on All.' } } },
  render: () => <Screen start="itinerary" planDays={[TODAY]} />,
};

export const Money: Story = {
  parameters: { docs: { description: { story: 'Before dinner. On top, what I owe and Pay, in the one grey block (it\'s the thing to act on), and tonight\'s dinner as an estimate until the bill comes. Then tabs, Settle up · Balances · Expenses (SegmentedTabs, from the page\'s left edge, lg above), one list at a time, each with a short muted line on top; so the expenses, the list that grows all trip, never push the rest away. Settle up comes first, as it\'s the one with something to do: "3 payments square everyone, instead of 9" (one expense at a time), each with its Why (tap it). Balances: "Who gets money back, and who owes", in plain words (see Money · balances). Expenses: "3 expenses · €726.00 · newest first" (see Money · expenses). Picking a tab slides the pill to it (spring-snap) and fades its list in (enter-ms, ease-out) while the last one fades out with a blur (fade-ms, enter-blur; reduced motion, no blur). Pay flips the block to "You\'re square with Maya" and a note comes down at the top; my payment row turns to Paid and the balances follow. Costs from before someone joined stay with the people who were there (Ren joined today).' } } },
  render: () => <Screen start="money" />,
};

/** The money pop-up before dinner, opening on `tab`. */
const moneyOn = (tab: MoneyTab) => <Screen start="money" money={{ subtitle: MONEY_SUBTITLE, page: <MoneyPage tab={tab} /> }} />;

export const MoneyBalances: Story = {
  name: 'Money · balances',
  parameters: { docs: { description: { story: 'The Balances tab: "Who gets money back, and who owes", then each person with what they get back (green) or owe: Maya gets back €418.50; I owe €181.50, Leo €135.50, Nic €101.50; Ren joined today, so "Joined today · shares costs from then on". Paying (Pay, on top) moves the balances; once someone has paid what they owe, they\'re Square.' } } },
  render: () => moneyOn('Balances'),
};

export const MoneyExpenses: Story = {
  name: 'Money · expenses',
  parameters: { docs: { description: { story: 'The Expenses tab: "3 expenses · €726.00 · newest first", then each with who paid, the day and how many shared it, its amount and my share ("yours €150.00"). Once the bill is in, the dinner sits on top of the list, split by who had what (see Money · bill in).' } } },
  render: () => moneyOn('Expenses'),
};

export const MoneyDinnerOn: Story = {
  name: 'Money · dinner on',
  parameters: { docs: { description: { story: 'While the dinner is on and before its bill is in, the estimate gives way to "Dinner is on" and Scan the bill. Scan the bill opens the camera (see Scan the bill); Add brings the bill in here, with a note for everyone at the top, and the others start paying (as in Money · bill in).' } } },
  render: () => <LiveMoney from="dinner-on" />,
};

export const MoneyBillIn: Story = {
  name: 'Money · bill in',
  parameters: { docs: { description: { story: `The bill was just added (€228.80, paid by me, split by who had what): €954.80 spent, 4 expenses, and 4 payments instead of 13, all to Maya (Leo €185.92, Nic €136.72, Ren €30.72, me €11.82). Each payment (Settle up) has a Why that opens under it: what they had of each expense, what they paid, and why it goes to one person. The others pay on their own: in the app 30 s apart, here ${OTHERS_PAY_EVERY / 1000} s apart, each with a note for everyone at the top ("Leo paid Maya €185.92"). Once they have, the top block says "Everyone else has paid" over my €11.82; my Pay makes it "You\'re square with Maya", and when the last payment lands, the block turns green and everyone hears "Lisbon is squared up".` } } },
  render: () => <LiveMoney from="bill-in" />,
};

export const MoneySquaredUp: Story = {
  name: 'Money · squared up',
  parameters: { docs: { description: { story: 'Everyone has paid: the top block is green, "Lisbon is squared up", 4 payments, €365.18 in all. Under the tabs, every payment is Paid (each still has its Why); every balance is Square (Balances); and the dinner sits on top of the expenses, by who had what (Expenses: "4 expenses · €954.80 · newest first").' } } },
  render: () => <LiveMoney from="squared-up" />,
};

export const ScanTheBill: Story = {
  name: 'Scan the bill',
  parameters: { docs: { description: { story: 'The camera, over everything, opened from the money pop-up\'s Scan the bill: the paper bill on one plain colour (c-scan-bg, zinc 900). A moment to find the paper (scan-find-ms 600), then the corner marks close in from the screen\'s edges onto it and turn blue (enter-ms, ease-out); a line reads it top to bottom at an even pace (scan-read-ms 900, linear); then the bill rises (enter-ms) while the colour fades out (enter-ms) and the paper with it (fade-ms), so the bill sits where the pop-up does, on the same blurred backdrop. "The bill", "La Brasserie de L\'Entrecôte · 10 lines"; the total first, big (€228.80); then every line with its menu name, "qty × price · who", its amount and every face of whoever had it, overlapped: whoever picked it on the menu, or everyone if nobody did (the couvert, the water). Tap a line to change who had it: the whole table in a grey block under it (faces toggle; someone always has it); the totals under the page follow, to the cent (You €59.12, Maya €53.32, Nic €35.22, Leo €50.42, Ren €30.72), each at least 64 px wide, scrolling sideways once they don\'t fit. "You paid" opens a small menu above it, from its corner (fade and scale from press-scale: fade-ms in, press-ms out): everyone at the table, the payer checked; picking one changes who paid, and a tap anywhere else closes it. Add fades and blurs the bill out (fade-ms) into the money under it, which now has the bill, and tells everyone at the top. Reduced motion: straight to the bill, which fades in, and no blur. Replay starts it over.' } } },
  render: () => <ScanStory />,
};

export const Add: Story = {
  parameters: { docs: { description: { story: 'Two choices: plan something, or invite someone. Plan shows ideas nearby, each with the free slot it would go in, and an Add button (a note confirms the slot). Invite shows the link with Copy link (a note confirms), says what joining costs, and can show what they\'ll see (see Add · invite). Back returns to the choice; a step fades out with a blur while the next one arrives.' } } },
  render: () => <AddStory />,
};

export const AddInvite: Story = {
  name: 'Add · invite',
  parameters: { docs: { description: { story: 'Invite, as it opens from Invite someone: the link with Copy link, the note on what joining costs, and under it, from the page\'s left edge, a soft "See what they\'ll see" (TextButton soft, 44 px). It opens the invited person\'s phone over everything, the way Ren\'s phone opens (it fades in from page-zoom-scale, enter-ms, and fades away, fade-ms; reduced motion, fades only): "What they\'ll see" at the top, the name field empty, and the trip as anyone joining now would see it (see Screens · Invite preview). Nobody joins; × or Close the preview goes back to Invite, the pop-up still open.' } } },
  render: () => <AddStory start="invite" />,
};

export const ItineraryPollOpen: Story = {
  name: 'Itinerary · poll open',
  parameters: { docs: { description: { story: `While the dinner poll hasn't decided, today has a Dinner slot at 5 PM instead of the place: a map pin, "Dinner", and the poll in brand blue ("Poll open · 1 of 5 voted", following the votes as they come in; before 2:30 PM "Poll at 2:30 PM"; after an Undo with nothing picked, "No place yet: pick one"). Tapping it opens the poll. Up next is then the next plan that is decided (Sam Croissants, 6 PM). Once the poll has picked, the place is back in the slot. The clock runs sped up, as in Poll · open (a trip minute every ${POLL_MINUTE_MS / 1000} s).` } } },
  render: () => <PollStory start="itinerary" />,
};

export const PollOpen: Story = {
  name: 'Poll · open',
  parameters: { docs: { description: { story: `Maya asks at 2:30 PM and everyone hears it at the top ("Maya started a poll: where for dinner tonight?"). The pop-up: how it works, then a card per place: its sticker, name, rating, food and price, and how far it is on foot from where I am (16, 17 and 17 min: the distance × 1.3 for the streets, at 80 m a minute, rounded up). Under each, a bar of its share of the five votes (brand for the one ahead, grey for the others, on a white track since the card is grey; it slides out from the left as votes come in, enter-ms, ease-out), then who voted (every face), how many, and Vote, which turns to a blue "✓ Your vote"; a tap on another place moves my vote. There's no Leading tag: the bars show it. The subtitle counts down to 3 PM ("closes in 30 mins"). The timing is sped up: in the app the others vote 6, 11 and 17 min in (Leo for Churrasqueira, then Nic and Ren for La Brasserie); here a trip minute passes every ${POLL_MINUTE_MS / 1000} s, and the clock holds after Ren's vote so the poll stays open to look at. The one ahead follows the count, and a tie goes to whichever got to that many first (the time of its latest vote): when Leo votes, Churrasqueira ties La Brasserie 1–1 and La Brasserie, there first, stays ahead. Vote Churrasqueira before Nic does and it takes the lead (2–1); Nic's vote ties it 2–2, and Churrasqueira, which got to 2 first, keeps it; Ren's vote then puts La Brasserie ahead. The countdown only counts votes already in, so it reads to 3 PM until everyone has voted. It closes as soon as all five have, so with my vote in it closes on Ren's (or on my vote, after his): the page turns to the result and "La Brasserie won · added to tonight" comes down with Undo (see Poll · closed). Close the pop-up to see its card on the map, which follows the votes too. Tap a place on it to vote right there (its ring fills with a check, and its bar and faces update at once; it\'s the same vote as the pop-up\'s), "Ratings, prices and walks →" to open the poll again, or its chevron to fold it into a pill under the day filter: one surface changing shape (tap the pill to unfold it; see Widget › Up next · Poll card ↔ pill). Replay starts over.` } } },
  render: () => <PollStory />,
};

export const PollClosed: Story = {
  name: 'Poll · closed',
  parameters: { docs: { description: { story: 'At 3 PM it closed (I hadn\'t voted, as at the app\'s Demo moment "The poll closes"): "Closed · La Brasserie won, 3 votes to 1". The winner went into tonight\'s 5 PM slot by itself and is tagged Tonight; the other two step back (d-poll-lost-opacity) and nothing can be voted any more. Everyone hears "La Brasserie won · added to tonight" at the top, with Undo, for toast-action-ms (twice a plain note\'s time, so there\'s time to reach it). Undo takes the winner back out (see Poll · undone).' } } },
  render: () => <LivePoll from="closed" />,
};

export const PollUndone: Story = {
  name: 'Poll · undone',
  parameters: { docs: { description: { story: 'After Undo: "The winner was taken back out. Pick tonight\'s place yourself." Nothing is in tonight ("Closed · nothing added yet"); La Brasserie keeps its Won tag, and each place has Add to tonight. Adding one puts it in the 5 PM slot ("Dote added for tonight, 5 PM" comes down at the top), tags it Tonight and steps the others back, each still with Add to tonight to switch; the subtitle says "Dote picked by hand", and the itinerary has it at 5 PM. Before that, the itinerary\'s Dinner slot says "No place yet: pick one".' } } },
  render: () => <LivePoll from="undone" />,
};
