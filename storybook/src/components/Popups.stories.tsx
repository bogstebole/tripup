import type { Meta, StoryObj } from '@storybook/react-vite';
import { animate, AnimatePresence, motion, useMotionValue, usePresence, usePresenceData, useReducedMotion, useTransform } from 'motion/react';
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  billTotal, BILL_IN, clockTime, dayName, euros, isPaid, moneyWith, MY_ID, payLine, PEOPLE, planDetails, planEnd, planStart, POLL_CLOSES,
  POLL_OPENS, POLL_VOTES, pollClosed, pollLeader, pollOpen, pollOptionById, pollStartedLine, pollWonLine, SCANNED_BILL, squaredUp, TODAY, TRIP,
  BANKS, TRIP_DAYS, TRIP_NOW, VISITED, type Bank, type Bill, type Payment, type Plan, type PollState, type Visited,
} from '../data';
import { ActionBar, TopBar } from './Bars';
import { Camera } from './BillScan';
import { DetailSheet } from './DetailSheet';
import { NoticeLayer, useNotice, type NoticeState } from './Notice';
import { PollCard, PollPage, PollScrim, pollSubtitle } from './Poll';
import { ToggleChips } from './ToggleChips';
import {
  addHeaderOf, AddFooter, AddPage, ITINERARY_SUBTITLE, ItineraryFlow, ItineraryPage, VisitFooter, visitHeaderOf, type AddPageProps, type AddStep,
  type ItineraryPageProps, type MoneySlot, type MoneyStep, type MoneyTab, usePlanDraft, useMoneyFlow,
} from './TripPages';
import { TripSheet } from './TripSheet';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const phone = { width: 393, height: 852, position: 'relative' as const, overflow: 'hidden', borderRadius: 'var(--radius-sheet)', background: 'var(--color-bg-canvas)' };
// The full view's place: under the top bar's buttons, the sheet inset from the other edges. The pop-up lines up at
// its bottom, so Add's shorter one (its choice and its invite) sits low.
const place = {
  position: 'absolute' as const,
  top: 'calc(var(--space-xl) + var(--d-button-md))',
  left: 'var(--space-md)',
  right: 'var(--space-md)',
  bottom: 'var(--space-md)',
  display: 'flex',
  flexDirection: 'column' as const,
  justifyContent: 'flex-end',
  pointerEvents: 'none' as const,
};
// The map and the bars blur away behind it, under a light scrim
const backdrop = { position: 'absolute' as const, inset: 0, background: 'color-mix(in srgb, var(--palette-blue-975) 23%, transparent)', backdropFilter: 'blur(2.5px)', WebkitBackdropFilter: 'blur(2.5px)' };
// The dinner poll's card: where the Up next card would be, under the top bar (a little clear of it), the screen less
// its margins wide, grown from its top. Open, it reaches at most md above the bottom; its places scroll past that.
const pollCardPlace = {
  position: 'absolute' as const,
  top: 'calc(var(--space-xl) + var(--d-button-md) + var(--space-xs) + var(--space-xs))',
  bottom: 'var(--space-md)',
  left: 'var(--space-md)',
  right: 'var(--space-md)',
  display: 'flex',
  flexDirection: 'column' as const,
  pointerEvents: 'none' as const,
  transformOrigin: 'top center',
};
const faces = Object.fromEntries(PEOPLE.map(p => [p.id, p.sticker]));
const space = tokens.space as Record<string, number>;
// A component token is a reference like "{space.xl}"; read the size it points at
const inset = space.md;
/** 0 up to `a`, 1 from `b`, eased in and out between (the app's smoothstep). */
const smoothstep = (a: number, b: number, v: number) => {
  const x = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return x * x * (3 - 2 * x);
};
const dayOptions = TRIP_DAYS.map(d => ({ id: d.day, label: d.label }));

type Which = 'itinerary' | 'money' | 'add' | 'poll';

/** The dinner poll on the screen: its pop-up's subtitle and page, its card on the map while it's open (a PollCard),
 *  and whether that's opened up (`expanded`: the scrim goes behind it, and a tap there calls `onCollapse`). */
type PollSlot = { subtitle: string; page: ReactNode; card?: ReactNode; expanded?: boolean; onCollapse?: () => void };

/**
 * A plan's details, opened from the itinerary. The pop-up and the full view are the same surface in the same place, so
 * the itinerary gives way to them right there: the surface stays, the pop-up's page goes at once, and the details'
 * content fades in where the list was. It runs as the app's full view does, on one value for how far open it is: it
 * starts from 0.45 (a third in already) and springs to 1 (spring-snap), the content showing over 0.3–0.8 of the way.
 * Closing, it leaves the way pop-ups do: down, past the bottom edge (spring-collapse), its content fading over the same
 * part of the way. Reduced motion: it's there at once, and gone at once. The backdrop under it stays as it was.
 */
function PlanDetails({ plan, now, onClose, onBack }: { plan: Plan; now: Date; onClose: () => void; onBack: () => void }) {
  const reduce = !!useReducedMotion();
  const [present, safeToRemove] = usePresence();
  // Back to the itinerary: it goes at once, the itinerary coming back in the same place
  const atOnce = !!usePresenceData();
  const open = useMotionValue(reduce ? 1 : 0.45);
  // 1 once it's leaving: then it slides down as it closes (opening, it stays where the pop-up was)
  const leaving = useMotionValue(0);
  // Opening, it springs the rest of the way; leaving, it springs shut and then goes. (Not run again for a new
  // safeToRemove, which can come with each render while it leaves: the one it had then is enough.)
  useEffect(() => {
    if (present) {
      if (reduce) return;
      const run = animate(open, 1, { type: 'spring', duration: m['spring-snap'].duration, bounce: m['spring-snap'].bounce });
      return () => run.stop();
    }
    if (reduce || atOnce) return safeToRemove();
    leaving.set(1);
    const run = animate(open, 0, { type: 'spring', duration: m['spring-collapse'].duration, bounce: m['spring-collapse'].bounce });
    run.then(safeToRemove);
    return () => run.stop();
  }, [present, reduce, open, leaving]);
  const content = useTransform(() => smoothstep(0.3, 0.8, open.get()));
  // Down by its own height and the inset at most, as a pop-up leaves (full transform strings, for the compositor)
  const transform = useTransform(() => {
    const d = leaving.get() * (1 - open.get());
    return `translate(0px, calc(${d * 100}% + ${d * inset}px))`;
  });
  return (
    <motion.div style={{ position: 'absolute', inset: 0, pointerEvents: 'auto', transform }}>
      <DetailSheet {...planDetails(plan)} people={PEOPLE} now={now} faces={faces} onClose={onClose} onBack={onBack} contentOpacity={content} />
    </motion.div>
  );
}

/**
 * The trip screen with one footer pop-up open. The footer's buttons open the others once it's closed. `money` swaps
 * in another state of the money pop-up (its page and its footer), `itinerary` sets the itinerary's page (the poll, now), `add` the add page's
 * (the step it starts on, a search or a place already picked); `poll` is the dinner poll (its
 * pop-up, and its card on the map while no pop-up covers it); `children` go over everything (the camera, the invited
 * person's phone). Notes for everyone come down at the top: the pages show theirs, and `notices` lets the story show
 * its own too. `open` and `onOpen` say from outside which pop-up is open. The itinerary has its own day filter, pinned
 * under its title: it opens on All (`planDays` picks days for the story's start). A plan in it opens its details right
 * there (PlanDetails); a place we've been closes it (in the app the map flies there). Add's step lives here, as in the
 * app, so the pop-up's header can follow it; each time Add opens, it's on the choice. A plan sent from it closes the
 * pop-up with a note, and is on the itinerary from then on.
 */
function Screen({ start = null, open: shown, onOpen, money, moneyTab, itinerary, visit: firstVisit, add, poll, notices: shared, planDays: firstDays = [], children }: {
  start?: Which | null;
  /** The tab Money opens on (Settle up, by default). */
  moneyTab?: MoneyTab;
  open?: Which | null;
  onOpen?: (which: Which | null) => void;
  /** Money as a story runs it (see useMoneyFlow); left out, the money before dinner, with Pay working. */
  money?: MoneySlot;
  itinerary?: Omit<ItineraryPageProps, 'onVisit' | 'onOpen' | 'onPoll' | 'days' | 'added'>;
  /** The itinerary open on a place we've been (its name). */
  visit?: string;
  add?: Omit<AddPageProps, 'step' | 'onStep' | 'draft'> & { start?: AddStep };
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
  const ownNotices = useNotice();
  const notices = shared ?? ownNotices;
  // The itinerary's own filter (not the map's, so planning ahead doesn't change the map); each time it opens, on All
  const [planDays, setPlanDays] = useState<number[]>(firstDays);
  // A place we've been, open in the itinerary (Back goes to the days)
  const [visit, setVisit] = useState<Visited | null>(VISITED.find(v => v.name === firstVisit) ?? null);
  // Where Add to the trip is: its choice, Plan something or Invite someone; and the plan being made, shared by its page,
  // its footer (Send) and its Back (a different place)
  const [addStep, setAddStep] = useState<AddStep>(add?.start ?? 'choose');
  const draft = usePlanDraft(add?.start === 'plan' ? add?.place : undefined);
  // Plans the group added (Plan something's Send)
  const [added, setAdded] = useState<Plan[]>([]);
  // My payments in Money (its Pay is in the footer and pays through the bank; the page's rows follow)
  const [made, setMade] = useState<Payment[]>([]);
  const ownMoney = useMoneyFlow({ made, onPaid: p => setMade(ms => [...ms, p]), notify: notices[1], tab: moneyTab });
  const moneyFlow = money ?? ownMoney;
  // A plan opened from the itinerary: its details, in the pop-up's place (the pop-up goes as they come)
  const [details, setDetails] = useState<Plan | null>(null);
  // Back from them: the itinerary comes back in the same place, its day filter as it was
  const [back, setBack] = useState(false);
  const openDetails = (plan: Plan) => {
    setBack(false);
    setDetails(plan);
    setOpen(null);
  };
  const backToItinerary = () => {
    setBack(true);
    setDetails(null);
    setOpen('itinerary');
  };
  const [lastOpen, setLastOpen] = useState(open);
  if (open !== lastOpen) {
    setLastOpen(open);
    if (open === 'itinerary' && !back) {
      setPlanDays([]);
      setVisit(null);
    }
    if (open === 'money') moneyFlow.reset();
    if (open === 'add') {
      setAddStep('choose');
      draft.reset();
    }
  }
  const sent = (plan: Plan) => {
    setAdded(a => [...a, plan]);
    close();
    const day = dayName(planStart(plan));
    notices[1](`Sent: ${plan.name}, ${day === 'Today' ? '' : `${day} `}${clockTime(planStart(plan))}–${clockTime(planEnd(plan)!)}`);
  };
  const addHeader = addHeaderOf(addStep);
  const sheet: Record<Which, { title: string; subtitle?: string; page: ReactNode; top?: ReactNode; footer?: ReactNode; onBack?: () => void } | undefined> = {
    itinerary: {
      ...(visit ? visitHeaderOf(visit) : { title: 'Itinerary', subtitle: ITINERARY_SUBTITLE }),
      page: <ItineraryFlow visit={visit} list={<ItineraryPage onVisit={setVisit} onOpen={openDetails} onPoll={poll && (() => setOpen('poll'))} {...itinerary} days={planDays} added={added} />} />,
      top: visit ? undefined : <ToggleChips label="Filter the itinerary by day" options={dayOptions} selected={planDays} onChange={setPlanDays} inset="xs" />,
      footer: visit ? <VisitFooter onMap={close} /> : undefined,
      onBack: visit ? () => setVisit(null) : undefined,
    },
    money: { title: moneyFlow.title, subtitle: moneyFlow.subtitle, page: moneyFlow.page, footer: moneyFlow.footer, onBack: moneyFlow.onBack },
    add: {
      ...addHeader,
      page: <AddPage step={addStep} onStep={setAddStep} draft={draft} query={add?.query} place={add?.place} />,
      footer: <AddFooter step={addStep} draft={draft} onSent={sent} />,
      // Back: from a picked place to the search, from the search or the invite to the choice
      onBack: addStep === 'choose' ? undefined : () => (addStep === 'plan' && draft.spot ? draft.pick(undefined) : setAddStep('choose')),
    },
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
        {/* The poll opened up: the map and its bars behind it tint and blur a little; a tap there closes it */}
        <AnimatePresence>
          {poll?.card && poll.expanded && !current && !details && <PollScrim key="scrim" onClose={poll.onCollapse} />}
        </AnimatePresence>
        {/* While the dinner poll is open its card stands on the map: it fades in and grows a little from its top
            (morph-enter-scale, enter-ms, ease-out) and goes quicker (fade-ms) as the poll closes or a pop-up covers it;
            reduced motion, fades only. Opening it up is the card's own (see PollCard). */}
        <AnimatePresence>
          {poll?.card && !current && !details && (
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
        {/* It stays as it is while a pop-up gives way to a plan's details */}
        <AnimatePresence>
          {(current || details) && (
            <motion.div
              key="backdrop"
              style={backdrop}
              onClick={details ? () => setDetails(null) : close}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1, transition: { duration: (reduce ? m['fade-ms'] : m['enter-ms']) / 1000, ease } }}
              exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
            />
          )}
        </AnimatePresence>
        <div style={place}>
          {/* A pop-up giving way to a plan's details goes at once: they're the same surface, in the same place */}
          <AnimatePresence custom={!!details}>
            {open && current && (
              <TripSheet
                key={open}
                inPlace={back && open === 'itinerary'}
                title={current.title}
                subtitle={current.subtitle}
                compact={open === 'add' && addStep !== 'plan'}
                centered={open === 'add' && addStep === 'invite'}
                onBack={current.onBack}
                top={current.top}
                footer={current.footer}
                onClose={close}
              >
                {current.page}
              </TripSheet>
            )}
          </AnimatePresence>
          <AnimatePresence custom={back}>
            {details && <PlanDetails key={details.id} plan={details} now={itinerary?.now ?? TRIP_NOW} onClose={() => setDetails(null)} onBack={backToItinerary} />}
          </AnimatePresence>
        </div>
        {children}
        {moneyFlow.overlay}
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
  const flow = useMoneyFlow({ money, made, onPaid: pay, notify: showNotice, dinnerOn: true, onScan: () => setScanning(true) });
  return (
    <Screen start="money" money={flow} notices={notices}>
      <AnimatePresence>{scanning && <Camera key="camera" onAdd={add} onClose={() => setScanning(false)} />}</AnimatePresence>
    </Screen>
  );
}

/** Money before dinner, on paying what I owe (€181.50 to Maya): `step` it starts on, `bank` TripUp already knows, and
 *  `banking` with my bank's app up from the start. The rest works as in the app (see useMoneyFlow). */
function PayStory({ step = 'pay', bank, banking }: { step?: MoneyStep; bank?: Bank; banking?: boolean }) {
  const [made, setMade] = useState<Payment[]>([]);
  const notices = useNotice();
  const flow = useMoneyFlow({ made, onPaid: p => setMade(ms => [...ms, p]), notify: notices[1], step, bank, banking });
  return <Screen start="money" money={flow} notices={notices} />;
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
  // The card on the map opened up over the tinted map, or closed to its compact self
  const [expanded, setExpanded] = useState(false);
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
          <PollCard
            expanded={expanded}
            now={now}
            poll={poll}
            onToggle={() => setExpanded(e => !e)}
            // A place's Details: the card closes and the poll's pop-up opens, with walking times
            onDetails={() => {
              setExpanded(false);
              setOpen('poll');
            }}
            onVote={vote}
          />
        ),
        expanded,
        onCollapse: () => setExpanded(false),
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

/** The add pop-up, on `start` (Plan something's search holding `query`, or with `place` picked). */
function AddStory({ start, query, place }: { start?: AddStep; query?: string; place?: string }) {
  return <Screen start="add" add={{ start, query, place }} />;
}

const meta = {
  title: 'Pop-ups',
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: [
          'The footer\'s three pop-ups: Itinerary, Money and Add. They look the same so they read as one family: the full view\'s surface, in the full view\'s place, with a header holding the title, a one-line subtitle and close. The page scrolls up under the header, which picks up the surface\'s white as the page goes under it. The itinerary\'s header also holds its day filter, pinned sm under the title (one chip row, space-2xl; the header grows by as much).',
          '',
          'Motion: the pop-up rises from just past the bottom edge (enter-ms, ease-out) while the map and bars blur away under a light scrim, and goes back down quicker (fade-ms). The page\'s blocks arrive one after another (fade, light blur, a few px up, stagger-ms apart). They close with the ×, a tap outside, or (on the phone) a pull down on the header. Reduced motion: fades only.',
          '',
          'Add\'s choice and its invite are shorter (480), since they have only a few rows; Plan something takes the whole height, and the sheet eases between the two (enter-ms, ease-in-out). A step inside a pop-up shows in its header: a back button (sm) slides in before the title (enter-ms, ease-out) and the title and its line crossfade (the new one in over enter-ms, the old one out over fade-ms). Every note comes down at the top of the screen, where the top bar\'s buttons are, whether it\'s mine ("Link copied", "You paid Maya €181.50") or one for everyone on the trip ("Leo paid Maya €185.92"): the same pill, for toast-ms; one with Undo stays for toast-action-ms, so there\'s time to reach it. The pop-ups have no notes of their own. A line too long for the pill ends in an ellipsis; Undo always shows.',
          '',
          'The dinner poll is a pop-up of the same family, "Dinner tonight". It opens from a place\'s Details on its card on the map (the card stands in Up next\'s place while the poll is open), from tonight\'s Dinner slot in the itinerary, and on Undo.',
          '',
          'A plan in the itinerary opens its details right there, not on the map: the pop-up and the full view are the same surface in the same place, so the list gives way to the plan\'s page (see Itinerary).',
        ].join('\n'),
      },
    },
  },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Itinerary: Story = {
  parameters: { docs: { description: { story: 'Every day of the trip: today first, then the days ahead, then the ones behind us. No grey blocks: a hairline between days, md above and below it (as on a place\'s Group page). Each day has its heading ("Thu 14 · Day 3 · Today", past days muted; the day number is still its place in the trip), then where we\'ve been ("Been there · 10:15 AM", no check) and what\'s planned (its time); a day with nothing yet says "Nothing planned yet". Headings and rows share the page\'s one left edge. Under the title, pinned while the page scrolls under it, the day filter: the same chips as the map\'s (All, Tue 12…), but its own, so planning ahead doesn\'t change what the map shows. It opens on All, on today, just under the header; picking days shows only those, in the same order (they combine; All brings every day back, at once). The next plan says "Up next" in brand blue. A plan with an end (one sent from Add\'s Plan something) says until when: "In 2 hrs · until 8 PM". Every row that does something ends in a chevron with no background (it only says the row can be tapped; the whole row is the target). Tapping a place we\'ve been opens what happened there, in the same pop-up (see Itinerary · a place we\'ve been). Tapping a plan opens its details right there (the full view, as from the Up next card): the pop-up and the full view are the same surface in the same place, so the surface stays, the list goes at once and the plan\'s page fades in where it was (the full view\'s crossfade, already a third in at the start, on spring-snap: 0.35 s, no bounce), the backdrop staying as it is. Closing (its ×, or a tap outside) slides it down past the bottom edge like a pop-up (spring-collapse: 0.38 s, no bounce), its content fading on the way. La Brasserie has its whole place card: photos, about, Know before you go, its facts, and the Menu tab. A plan we know little about (Tram 28, one sent from Add) has its time and how far it is under its name ("Tomorrow, 10 AM · 4.3 km away"), a small map of it with its sticker (plan/map-height 160, radius-card; the app draws the live map\'s tiles, here a plain block stands in), and no Menu tab: Overview · Group. Reduced motion: the details are there at once and gone at once.' } } },
  render: () => <Screen start="itinerary" />,
};

export const ItineraryVisit: Story = {
  name: 'Itinerary · a place we\'ve been',
  parameters: { docs: { description: { story: 'A place we\'ve been, tapped in the itinerary, opens in the same pop-up, the way Money goes into Pay: the title becomes the place, with Back to the days, and the facts under it ("Market · Wed 13 May · 50 min · €46.00 spent"). The day filter goes while it\'s open. The place on a muted block, like Ren\'s catch-up tiles, then What happened, a timeline: a dot per moment on a line down to the next. Got there (the time, who came, their faces); what was paid there (Groceries and drinks: "Leo paid · split 4 ways · yours €11.50", the amount on the right); Left ("50 min there"). A place where nothing was paid has just the two. The footer has Show on the map (soft): the pop-up closes and the map flies there. The page swaps like Money\'s steps: the new one fades in, the old one fades out with a blur.' } } },
  render: () => <Screen start="itinerary" visit="Mercado de Arroios" />,
};

export const ItineraryOneDay: Story = {
  name: 'Itinerary · one day',
  parameters: { docs: { description: { story: 'The filter on Thu 14: only today (what\'s planned, Up next in brand). Pick more days to add them, or All for every day. Closing the itinerary and opening it again starts on All.' } } },
  render: () => <Screen start="itinerary" planDays={[TODAY]} />,
};

export const Money: Story = {
  parameters: { docs: { description: { story: 'Before dinner. Tabs the width of the page, Settle up · Balances · Expenses (SegmentedTabs wide: the three share it equally), one list at a time, each under a section title with a line under it (lg above); so the expenses, the list that grows all trip, never push the rest away. Settle up comes first, as it\'s the one with something to do: "3 payments square everyone, instead of 9" (one expense at a time), each with its Why (tap it). Balances: "Who gets money back, and who owes", in plain words (see Money · balances). Expenses: "Newest first" (see Money · expenses). At the bottom, where the thumb reaches, what I owe, in a rounded pill sm above the footer (bg-muted, radius-pill; xl in on the left, xs on the other sides): a muted "You owe Maya" (body-sm) over €181.50 (heading-sm), each one line, and Pay at its end. The footer stays put while the lists scroll, over a hairline: "Spent so far", "3 expenses · yours €181.50", and €726.00 (heading-lg) on the right, like the Menu\'s total. There\'s no estimate for tonight\'s dinner: it joins once its bill is in. Picking a tab slides the pill to it (spring-snap) and fades its list in (enter-ms, ease-out) while the last one fades out with a blur (fade-ms, enter-blur; reduced motion, no blur). Pay opens paying it, in the same pop-up (see Money · pay): through my bank, or marked as paid. While it\'s on its way the pill says so; once it\'s paid, "You paid Maya €181.50" comes down at the top, the pill fades away as the footer closes up under it (the note is the success, so nothing stays behind), my payment row turns to Paid and the balances follow. Costs from before someone joined stay with the people who were there (Ren joined today).' } } },
  render: () => <Screen start="money" />,
};

/** The money pop-up before dinner, opening on `tab`. */
const moneyOn = (tab: MoneyTab) => <Screen start="money" moneyTab={tab} />;

export const MoneyBalances: Story = {
  name: 'Money · balances',
  parameters: { docs: { description: { story: 'The Balances tab: its title, "Who gets money back, and who owes", then each person with what they get back (green) or owe: Maya gets back €418.50; I owe €181.50, Leo €135.50, Nic €101.50; Ren joined today, so "Joined today · shares costs from then on". Paying (Pay, on top) moves the balances; once someone has paid what they owe, they\'re Square.' } } },
  render: () => moneyOn('Balances'),
};

export const MoneyExpenses: Story = {
  name: 'Money · expenses',
  parameters: { docs: { description: { story: 'The Expenses tab: its title, "Newest first", then each with who paid, the day and how many shared it, its amount and my share ("yours €150.00"). What they come to is in the footer: 3 expenses, mine €181.50 of €726.00. Once the bill is in, the dinner sits on top of the list, split by who had what (see Money · bill in).' } } },
  render: () => moneyOn('Expenses'),
};

export const MoneyDinnerOn: Story = {
  name: 'Money · dinner on',
  parameters: { docs: { description: { story: 'While the dinner is on and before its bill is in, the footer has Scan the bill under the total, the width of the page and 56 px tall (TextButton lg, wide). It opens the camera (see Scan the bill); Add brings the bill in here, with a note for everyone at the top: the footer goes to "4 expenses · yours €240.62" and €954.80, Scan the bill goes, and the others start paying (as in Money · bill in).' } } },
  render: () => <LiveMoney from="dinner-on" />,
};

export const MoneyBillIn: Story = {
  name: 'Money · bill in',
  parameters: { docs: { description: { story: `The bill was just added (€228.80, paid by me, split by who had what): the footer says 4 expenses, yours €240.62, €954.80 spent (no Scan the bill now); 4 payments instead of 13, all to Maya (Leo €185.92, Nic €136.72, Ren €30.72, me €11.82). Each payment (Settle up) has a Why that opens under it: what they had of each expense, what they paid, and why it goes to one person. The others pay on their own: in the app 30 s apart, here ${OTHERS_PAY_EVERY / 1000} s apart, each with a note for everyone at the top ("Leo paid Maya €185.92"). Once they have, the pill\'s line says "You owe Maya · Everyone else has paid" over my €11.82; my Pay sends it and the pill goes, and when the last payment lands, everyone hears "Lisbon is squared up".` } } },
  render: () => <LiveMoney from="bill-in" />,
};

export const MoneySquaredUp: Story = {
  name: 'Money · squared up',
  parameters: { docs: { description: { story: 'Everyone has paid, so there\'s no pill: the note at the top said "Lisbon is squared up" when the last payment landed. Every payment is Paid (each still has its Why); every balance is Square (Balances); and the dinner sits on top of the expenses, by who had what (Expenses). The footer: "Spent so far", "4 expenses · yours €240.62", €954.80.' } } },
  render: () => <LiveMoney from="squared-up" />,
};

export const MoneyPay: Story = {
  name: 'Money · pay',
  parameters: { docs: { description: { story: 'Pay on what I owe opens paying it, in the same pop-up: Back, "Pay Maya" and ×; the line at the top of the page, "It goes straight from your bank to Maya\'s. TripUp never holds the money." (TripUp starts a bank transfer through open banking, PSD2: a provider like Tink or TrueLayer; it never holds the money). Then Maya\'s sticker (space-4xl), €181.50 (display) and "to Maya", centred, xl above what the transfer will say, in a muted box inset like Why\'s: To "Maya · PT50 •••• 4021" (she adds where she gets paid once, the first time someone owes her), From (my bank, once TripUp knows it: a tap picks another), Reference "TRIPUP-…" (so Maya knows what it\'s for, and TripUp can match it), Arrives "In seconds" (SEPA Instant). Why €181.50 opens under it. The footer: Pay with your bank (lg, wide; "Pay with Millennium bcp" once it\'s known), Mark as paid (soft) and "Paid in cash or another way? Maya confirms it." The first time, Pay with your bank goes to the bank list (see Money · your bank); after that, straight to the bank\'s app (see Bank app). Mark as paid: back on the money, the pill says "Waiting for Maya to confirm" with a clock where Pay was, and the row the same; Maya confirms from her notification (here 6 s later): "Maya confirmed your €181.50", Paid. The step fades in while the last fades out with a blur; the title, and the footer, come in once the old one has mostly gone (swap-in-at), so they never read over each other.' } } },
  render: () => <PayStory />,
};

export const MoneyYourBank: Story = {
  name: 'Money · your bank',
  parameters: { docs: { description: { story: 'The first time I pay: "Your bank", Back to paying. "Pick it once and TripUp remembers it. You approve each payment in your bank\'s app; TripUp never sees your login." Then the banks (in the real app, the provider\'s list for my country), each its first letter on a muted disc (space-2xl), its name and an arrow, a hairline between. A tap picks it and opens it to approve (see Bank app); from then on, paying names it and goes straight there.' } } },
  render: () => <PayStory step="bank" />,
};

export const BankApproval: Story = {
  name: 'Bank app',
  parameters: { docs: { description: { story: 'My bank\'s app, over TripUp: it comes in like another phone screen, from a slight zoom (page-zoom-scale, enter-ms) and fades away (fade-ms). In the real app iOS opens the bank\'s own app with the transfer filled in; here it stands in for it, in a plain look of its own (its own zinc greys, radius-control corners, a dark button) so it reads as another app. "‹ TripUp" at the top (iOS\'s back-to-app link), the bank\'s bar (its mark, name and a lock), "Approve payment" (heading-lg), "TripUp asked to send this from your account.", then the transfer in a white card: €181.50 (heading-xl), "SEPA Instant · arrives in seconds", To, IBAN, Reference and From; none of it can be changed. Approve with Face ID (56 tall): Face ID\'s square comes up in the middle (face-id-ms), turns to a green check and Approved (approved-ms), and the bank sends me back to the money, where the pill says "Paying Maya · your bank is confirming" with a spinner; the bank confirms (here 2 s later): "You paid Maya €181.50", the pill goes, Paid. Cancel (or ‹ TripUp): back on paying, "Payment cancelled · nothing was sent", and the pill still there.' } } },
  render: () => <PayStory bank={BANKS[0]} banking />,
};

export const ScanTheBill: Story = {
  name: 'Scan the bill',
  parameters: { docs: { description: { story: 'The camera, over everything, opened from the money pop-up\'s Scan the bill: the paper bill on one plain colour (zinc 900). A moment to find the paper (scan-find-ms 600), then the corner marks close in from the screen\'s edges onto it and turn blue (enter-ms, ease-out); a line reads it top to bottom at an even pace (scan-read-ms 900, linear); then the bill rises (enter-ms) while the colour fades out (enter-ms) and the paper with it (fade-ms), so the bill sits where the pop-up does, on the same blurred backdrop. "The bill", "La Brasserie de L\'Entrecôte · 10 lines"; the total first, big (€228.80); then every line with its menu name, "qty × price · who", its amount and every face of whoever had it, overlapped: whoever picked it on the menu, or everyone if nobody did (the couvert, the water). Each line (Figma 262:12632): the dish, then what it comes to (body-lg, semibold) over how many at what price, and at the end who had it: their faces on a soft pill with a chevron down, or a round add-a-person button for a line nobody has yet. Either opens the line in place: the pill\'s faces leave one after another (100 ms each, 25 apart), it gives way to a round chevron up, the grey block grows (enter-ms) and the whole table comes in one by one (fade-ms each, 30 apart), about 420 ms; closing runs back, quicker. In the block, the ones who had it have a red minus (the sm button\'s danger glass at 0.4), the others are faded with a soft plus; a tap adds or takes someone off, and the mark turns on the spot (the glass fades soft ↔ red, the plus\'s upright bar folds into the minus, fade-ms). A dish nobody picked on the Menu (the fries and the dessert, ordered at the table) comes off the scan with nobody, and the header counts them ("2 nobody has yet"); the couvert and the water are for the whole table. A line left with nobody splits evenly between everyone. The totals under the page follow, to the cent (once the fries are Leo\'s and the dessert Maya\'s: You €59.12, Maya €53.32, Nic €35.22, Leo €50.42, Ren €30.72), each at least 64 px wide, scrolling sideways once they don\'t fit. "You paid" opens a small menu above it, from its corner (fade and scale from press-scale: fade-ms in, press-ms out): everyone at the table, the payer checked; picking one changes who paid, and a tap anywhere else closes it. Add fades and blurs the bill out (fade-ms) into the money under it, which now has the bill, and tells everyone at the top. Reduced motion: straight to the bill, which fades in, and no blur. Replay starts it over.' } } },
  render: () => <ScanStory />,
};

export const Add: Story = {
  parameters: { docs: { description: { story: '"Add to the trip", and "A plan, or someone new" at the top of the page, in the compact sheet (480). Like every pop-up, its header is one line: Back (for a step inside it), the title and Close, on the buttons\' centre line; the pop-up\'s line on what it\'s for opens its page, lined up with the page\'s text, and its actions are in a footer over a hairline. Then two plain choices, Plan something and Invite someone, each a big title (heading-sm) with a line under it (body-sm, muted) and an arrow, md above and below, a hairline between; no icons and no boxes. Picking one changes the header: a back button (sm) slides in before the title (enter-ms, ease-out) and the title crossfades to the step\'s ("Plan something", with "Find a place, pick a time, send it" at the top of its page; "Invite someone"). The step fades in (enter-ms), its blocks arriving one after another, while the choice fades out with a blur (fade-ms). Plan something grows the sheet to the full height (enter-ms, ease-in-out); Back shrinks it again and starts a plan over. Every time Add opens, it\'s on the choice.' } } },
  render: () => <AddStory />,
};

export const AddInvite: Story = {
  name: 'Add · invite',
  parameters: { docs: { description: { story: 'Invite, as it opens from Invite someone, in the middle of the compact sheet (TripSheet centered), md between its blocks: "Send them this link" (heading-sm) and "Share it with a friend. They type their name and they\'re in." (body-sm, muted), centred; and the link in a muted pill as tall as a big button. The footer: Copy link (TextButton lg, wide; "Link copied" comes down at the top).' } } },
  render: () => <AddStory start="invite" />,
};

export const AddPlan: Story = {
  name: 'Add · plan',
  parameters: { docs: { description: { story: 'Plan something, before anything is typed, with the sheet at its full height: a search pill as tall as a big button (bg-muted, radius-pill: the search icon, "Search places in Lisbon"), then "Near you" (lg above), "Or search for anywhere in Lisbon", and the five nearest of 20 well-known Lisbon places, by walking time from where I am (the distance × 1.3 for the streets, at 80 m a minute, rounded up; past 45 min, how far it is instead): Museu Calouste Gulbenkian (22 min walk), Cervejaria Ramiro (3.2 km away), Miradouro da Senhora do Monte, A Ginjinha, Museu Nacional do Azulejo. Each row: its sticker, its name, "kind · area · walk" and an arrow; tapping one picks it, and the page fades over to it (see Add · plan · place picked). Not built: searching beyond the 20 (a real places API), and asking the group before it goes in.' } } },
  render: () => <AddStory start="plan" />,
};

export const AddPlanSearch: Story = {
  name: 'Add · plan · search',
  parameters: { docs: { description: { story: 'Searching "belem": a search matches a place\'s name, what it is or its neighbourhood, ignoring case and accents, so Belém counts. "4 places" (no line under it), in the list\'s order: Pastéis de Belém, Mosteiro dos Jerónimos, Torre de Belém and MAAT, each "7.4 km away" and so on. × clears it, back to Near you. With nothing found: "Nothing found", "Try a name, a kind of place or a neighbourhood".' } } },
  render: () => <AddStory start="plan" query="belem" />,
};

export const AddPlanPicked: Story = {
  name: 'Add · plan · place picked',
  parameters: { docs: { description: { story: 'Time Out Market picked. On top, a small still map of it, plan/map-height (160) tall with radius-card corners, its sticker in the middle and the map\'s credit at the bottom (the app draws the live map\'s tiles; here a plain bg-subtle block stands in for them). Then its name and the line under it; no sticker (it\'s on the map) and no Change: the header\'s Back goes back to the search as it was. "When" (lg above): one day at a time, as chips (Today on, then Tomorrow, Sat 16…), and From and To: tonight 6 PM to 8 PM (from the next hour once it\'s past 5; tomorrow once it\'s past 9 PM). Tapping a time opens a wheel under it (180; it opens over enter-ms and closes quicker), the time in brand while it\'s open; tapping it again closes it. The app\'s wheel is Cupertino\'s (hour, minute and AM/PM, 15-minute steps); here it\'s one column of times 15 minutes apart that scrolls and snaps, the one in the middle band picked once it settles (tap a time, or step with the arrow keys). A From at or past To moves To an hour after it; To stays at least 15 min after From. The footer, in view while the page scrolls: Send to the group (TextButton lg, wide) and, centred under it, "It goes on everyone\'s itinerary and map." Send closes the pop-up and everyone hears "Sent: Time Out Market, 6 PM–8 PM" at the top (with the day when it isn\'t today); the itinerary has it, "In 2 hrs · until 8 PM". In the app the map also flies to it.' } } },
  render: () => <AddStory start="plan" place="timeout" />,
};

export const ItineraryPollOpen: Story = {
  name: 'Itinerary · poll open',
  parameters: { docs: { description: { story: `While the dinner poll hasn't decided, today has a Dinner slot at 5 PM instead of the place: a map pin, "Dinner", and the poll in brand blue ("Poll open · 1 of 5 voted", following the votes as they come in; before 2:30 PM "Poll at 2:30 PM"; after an Undo with nothing picked, "No place yet: pick one"). Tapping it opens the poll. Up next is then the next plan that is decided (Sam Croissants, 6 PM). Once the poll has picked, the place is back in the slot. The clock runs sped up, as in Poll · open (a trip minute every ${POLL_MINUTE_MS / 1000} s).` } } },
  render: () => <PollStory start="itinerary" />,
};

export const PollOpen: Story = {
  name: 'Poll · open',
  parameters: { docs: { description: { story: `Maya asks at 2:30 PM and everyone hears it at the top ("Maya started a poll: where for dinner tonight?"). The pop-up: how it works, then a card per place: its sticker, name, rating, food and price, and how far it is on foot from where I am (16, 17 and 17 min: the distance × 1.3 for the streets, at 80 m a minute, rounded up). Under each, a bar of its share of the five votes (brand for the one ahead, grey for the others, on a white track since the card is grey; it slides out from the left as votes come in, enter-ms, ease-out), then who voted (every face), how many, and Vote, which turns to a blue "✓ Your vote"; a tap on another place moves my vote. There's no Leading tag: the bars show it. The subtitle counts down to 3 PM ("closes in 30 mins"). The timing is sped up: in the app the others vote 6, 11 and 17 min in (Leo for Churrasqueira, then Nic and Ren for La Brasserie); here a trip minute passes every ${POLL_MINUTE_MS / 1000} s, and the clock holds after Ren's vote so the poll stays open to look at. The one ahead follows the count, and a tie goes to whichever got to that many first (the time of its latest vote): when Leo votes, Churrasqueira ties La Brasserie 1–1 and La Brasserie, there first, stays ahead. Vote Churrasqueira before Nic does and it takes the lead (2–1); Nic's vote ties it 2–2, and Churrasqueira, which got to 2 first, keeps it; Ren's vote then puts La Brasserie ahead. The countdown only counts votes already in, so it reads to 3 PM until everyone has voted. It closes as soon as all five have, so with my vote in it closes on Ren's (or on my vote, after his): the page turns to the result and "La Brasserie won · added to tonight" comes down with Undo (see Poll · closed). Close the pop-up to see its card on the map, compact, under the top bar (xs clear of it): "Live poll • closes in N mins" with the red dot, the question, and who has voted, following the votes too. Tap it to open it in place: the map and the bars behind it tint blue and blur a little (blue 975 at 23%, 2.5; enter-ms in, fade-ms out) and the card grows down to show each place, where its check votes right there (primary once it\'s mine; the same vote as the pop-up\'s). A place\'s Details closes the card and opens the poll again; its head, or a tap on the scrim, closes it (see Widget › Up next · Poll · open). Replay starts over.` } } },
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
