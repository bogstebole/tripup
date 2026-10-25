// The pages of the footer's three pop-ups: the itinerary, the group's money, and adding to the trip. Each goes inside
// a TripSheet, which scrolls it; their notes come down at the top of the screen (see Notice.tsx).
import { ArrowRight, CircleCheck, Copy, MapPin, ScanLine, Search, X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type ReactElement } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  balanceLeft, clockTime, dayName, DINNER, DINNER_TABLE, dinnerChoice, euros, INVITE_LINK, isPaid, LISBON_PLACES, MY_ID, payLine, PEOPLE,
  personById, placeById, placeMatches, planEnd, planStart, plansWith, POLL_OPENS, pollClosed, pollOpen, PRE_DINNER, shareOf, squaredUp,
  timeUntil, TODAY, tripDate, TRIP_DAYS, TRIP_NOW, VISITED, votesIn, walkLabel, walkMinutes, type Money, type Payment, type PlaceSpot,
  type Plan, type PollState,
} from '../data';
import { TextButton } from './Button';
import { Sticker } from './Sticker';
import { useTripNotice } from './Notice';
import { SegmentedTabs } from './SegmentedTabs';
import { ToggleChip } from './ToggleChips';
import { Hairline, SheetFooter, SheetRow, SheetSection, Slot, StaggerIn } from './TripSheet';
import './TripPages.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const name = (id: string) => personById(id).name;
const face = (id: string) => <Slot size="avatar"><Sticker name={personById(id).sticker} size="avatar" /></Slot>;
/** Rows with a hairline between each two, as separate blocks (so each arrives on its own). */
const withHairlines = <T,>(items: T[], row: (x: T) => ReactElement) => items.flatMap((x, i) => (i ? [<Hairline key={`line-${i}`} />, row(x)] : [row(x)]));

// ---------- Itinerary

/** "12–21 May · Day 3 of 10". */
export const ITINERARY_SUBTITLE = `${TRIP_DAYS[0].day}–${TRIP_DAYS[TRIP_DAYS.length - 1].day} May · Day ${TRIP_DAYS.findIndex(d => d.day === TODAY) + 1} of ${TRIP_DAYS.length}`;

export interface ItineraryPageProps {
  /** Tapping a place we've been: show it on the map. */
  onPick?: (place: string) => void;
  /** Tapping a plan: open its details, right there. */
  onOpen?: (plan: Plan) => void;
  /** The dinner poll, while it decides tonight's dinner (my vote, an Undo, a place picked by hand). Leave it out for
   *  the plans as they stand at the demo's start: the poll long closed, La Brasserie at 5 PM. */
  poll?: PollState;
  /** Opens the dinner poll, from tonight's slot while it isn't decided. */
  onPoll?: () => void;
  /** Now, in the trip (the demo's start, 3:56 PM, by default). */
  now?: Date;
  /** The days picked in its filter (the chips under its title); empty or left out means all of them. */
  days?: number[];
  /** Plans the group added (Add's Plan something), on top of the trip's own. */
  added?: Plan[];
}

/**
 * Every day of the trip: today first, then the days ahead, then the ones behind us, a hairline between days (as on a
 * place's Group page): where we've been, what's planned, and today marked. It opens on today. Its filter shows only
 * the days picked. Tapping a place we've been shows it on the map (the pop-up closes and the map flies there); tapping
 * a plan opens its details right there, in the pop-up's place. While the dinner poll hasn't decided, today has a Dinner
 * slot at 5 PM instead of the place ("Poll open · 3 of 5 voted"), which opens the poll. A plan with an end says until
 * when ("In 2 hrs · until 8 PM").
 */
export function ItineraryPage({ onPick, onOpen, poll, onPoll, now = TRIP_NOW, days = [], added = [] }: ItineraryPageProps) {
  const dinner = poll && (dinnerChoice(now, poll) ?? null);
  const plans = [...plansWith(dinner), ...added].sort((x, y) => planStart(x).getTime() - planStart(y).getTime());
  const next = plans.find(p => planStart(p) > now);
  // Today first, then the days ahead, then the ones behind us
  const order = [...TRIP_DAYS.filter(d => d.day === TODAY), ...TRIP_DAYS.filter(d => d.day > TODAY), ...TRIP_DAYS.filter(d => d.day < TODAY)];
  const shown = order.filter(d => !days.length || days.includes(d.day));
  return (
    <StaggerIn>
      {shown.map(({ day, label }, k) => {
        const rows = [
          ...VISITED.filter(v => v.day === day).map(v => (
            <SheetRow
              key={v.name}
              leading={<Slot><Sticker name={v.sticker} size="row" tilt={v.tilt} /></Slot>}
              title={v.name}
              subtitle="Been there"
              onClick={onPick && (() => onPick(v.name))}
            />
          )),
          // Tonight's slot, until the poll has picked a place
          ...(poll && day === TODAY && dinner === null
            ? [
                <SheetRow
                  key="dinner-slot"
                  leading={<Slot><MapPin className="tu-pages__lead" strokeWidth={2} absoluteStrokeWidth aria-hidden /></Slot>}
                  title="Dinner"
                  subtitle={pollOpen(now, poll) ? `Poll open · ${votesIn(now, poll)} of ${DINNER_TABLE.length} voted` : pollClosed(now, poll) ? 'No place yet: pick one' : `Poll at ${clockTime(POLL_OPENS)}`}
                  tone="brand"
                  trailing={<span className="text-label-md weight-semibold tu-pages__strong">{clockTime(DINNER)}</span>}
                  onClick={onPoll}
                />,
              ]
            : []),
          ...plans.filter(p => p.day === day).map(p => (
            <SheetRow
              key={p.id}
              leading={<Slot><Sticker name={p.sticker} size="row" /></Slot>}
              title={p.name}
              subtitle={[p === next && 'Up next', timeUntil(planStart(p), now), planEnd(p) && `until ${clockTime(planEnd(p)!)}`].filter(Boolean).join(' · ')}
              tone={p === next ? 'brand' : undefined}
              trailing={<span className="text-label-md weight-semibold tu-pages__strong">{clockTime(planStart(p))}</span>}
              onClick={onOpen && (() => onOpen(p))}
            />
          )),
        ];
        return (
          <div key={day} className="tu-day-block" data-sheet-focus={day === TODAY || undefined}>
            {k > 0 && <div className="tu-day-block__line"><Hairline /></div>}
            <div className="tu-day">
              <h3 className={`text-heading-sm ${day < TODAY ? 'tu-pages__muted' : 'tu-pages__strong'}`}>{label}</h3>
              <span className="text-body-sm tu-pages__muted">Day {TRIP_DAYS.findIndex(d => d.day === day) + 1}</span>
              {day === TODAY && <span className="tu-tag text-label-md weight-semibold">Today</span>}
            </div>
            {rows.length ? rows : <p className="text-body-sm tu-day__empty">Nothing planned yet</p>}
          </div>
        );
      })}
    </StaggerIn>
  );
}

// ---------- Money

/** "5 people · split by who had what". What it has cost so far is in its footer (see MoneyFooter). */
export const MONEY_SUBTITLE = `${PEOPLE.length} people · split by who had what`;

/** Money's tabs: one list at a time, Settle up first (it's the one with something to do). */
export const MONEY_TABS = ['Settle up', 'Balances', 'Expenses'] as const;
export type MoneyTab = (typeof MONEY_TABS)[number];

export interface MoneyPageProps {
  /** The money as it stands: before the dinner's bill (`PRE_DINNER`, the default) or with it in (`BILL_IN`). */
  money?: Money;
  /** The payments made so far. Leave it out and the page keeps its own (then only my Pay makes one). */
  made?: Payment[];
  /** My Pay, when the payments are kept outside. */
  onPay?: (p: Payment) => void;
  /** The tab it opens on (Settle up, by default). */
  tab?: MoneyTab;
}

/**
 * The group's money: what I owe (and paying it) on top, then one thing at a time in tabs the width of the page
 * (Settle up · Balances · Expenses): the fewest payments that square everyone up (each with a Why that opens), each
 * person's balance after the payments made so far, or the expenses (the list that grows all trip, so it never pushes
 * the rest away). Each tab's list starts with a section title and a line under it. Picking a tab fades its list in
 * (enter-ms) while the last one fades out with a blur (fade-ms; no blur with reduced motion). Tonight's dinner joins
 * once its bill is in, as an expense split by who had what. The top block is a rounded pill, like Invite's link: a muted
 * line ("You owe Maya", "· Everyone else has paid") over the amount, and Pay; "You're square with Maya" over "Paid
 * €181.50"; and, once everyone has paid, a green "Lisbon is squared up". What it has cost so far, and Scan the bill,
 * are in the pop-up's footer (MoneyFooter).
 */
export function MoneyPage({ money = PRE_DINNER, made: kept, onPay, tab: firstTab = 'Settle up' }: MoneyPageProps) {
  const toast = useTripNotice();
  const [own, setOwn] = useState<Payment[]>([]);
  const made = kept ?? own;
  const [tab, setTab] = useState<MoneyTab>(firstTab);
  // The payment whose "why" is open, if any
  const [why, setWhy] = useState<string | null>(null);
  const reduce = useReducedMotion();
  const pays = money.settleUp;
  const mine = pays.find(p => p.from === MY_ID);
  const paid = (p: Payment) => isPaid(p, made);
  const square = squaredUp(money, made), minePaid = !!mine && paid(mine);
  const othersPaid = pays.filter(p => p.from !== MY_ID).every(paid);
  const done = square || minePaid;
  const head = square ? 'Lisbon is squared up' : mine ? (minePaid ? `You're square with ${name(mine.to)}` : `You owe ${name(mine.to)}`) : '';
  const sub = square
    ? `Everyone has paid: ${pays.length} payments, ${euros(pays.reduce((sum, p) => sum + p.amount, 0))} in all`
    : mine && minePaid ? `Paid ${euros(mine.amount)}`
    : othersPaid && money.bill ? 'Everyone else has paid'
    : undefined;
  const pay = (p: Payment) => {
    if (onPay) onPay(p); else setOwn(m => [...m, p]);
    toast(payLine(p));
  };
  const joinedLate = (joined: number) => joined > TRIP_DAYS[0].day;
  const key = (p: Payment) => `${p.from}>${p.to}`;
  return (
    <StaggerIn>
      {/* A rounded pill like Invite's link: what I owe and Pay (or that it's settled) */}
      {(mine || square) && (
        <div key="mine" className={square ? 'tu-owe tu-owe--square' : 'tu-owe'}>
          <div className="tu-owe__text">
            <p className="text-body-sm tu-ellipsis tu-pages__muted">{done ? head : `${head}${sub ? ` · ${sub}` : ''}`}</p>
            <p className={`text-heading-sm tu-ellipsis ${done ? 'tu-pages__success' : 'tu-pages__strong'}`}>{done ? sub : mine && euros(mine.amount)}</p>
          </div>
          {done
            ? <CircleCheck className="tu-owe__done" strokeWidth={2} absoluteStrokeWidth aria-label="Paid" />
            : mine && <TextButton label="Pay" onClick={() => pay(mine)} />}
        </div>
      )}
      <div key="tabs" className={mine || square ? 'tu-money-tabs tu-money-tabs--under' : 'tu-money-tabs'}>
        <SegmentedTabs tabs={[...MONEY_TABS]} value={tab} onChange={t => setTab(t as MoneyTab)} wide />
      </div>
      {/* One tab's list at a time: it fades in while the last one fades out with a blur, both from the top */}
      <div key="list" className="tu-money-list">
        <AnimatePresence initial={false}>
          <motion.div
            key={tab}
            className="tu-money-list__tab"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
            exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
          >
            {tab === 'Settle up' && (
              <>
                <SheetSection title="Settle up" top="lg" subtitle={`${pays.length} payments square everyone, instead of ${money.paymentsOneByOne}`} />
                {withHairlines(pays, p => (
                  <div key={`pay-${key(p)}`}>
                    <SheetRow
                      leading={<span className="tu-pay">{face(p.from)}<ArrowRight className="tu-pay__arrow" strokeWidth={2} absoluteStrokeWidth aria-hidden />{face(p.to)}</span>}
                      title={p.from === MY_ID ? `You pay ${name(p.to)}` : `${name(p.from)} pays ${name(p.to)}`}
                      subtitle={`${paid(p) ? 'Paid' : 'Pending'} · ${why === key(p) ? 'Hide why' : 'Why'}`}
                      tone={paid(p) ? 'success' : undefined}
                      trailing={<span className="text-label-lg tu-pages__strong">{euros(p.amount)}</span>}
                      onClick={() => setWhy(w => (w === key(p) ? null : key(p)))}
                    />
                    {/* Where the amount comes from: it opens under the row, and closes a little quicker */}
                    <AnimatePresence initial={false}>
                      {why === key(p) && (
                        <motion.div
                          key="why"
                          className="tu-why"
                          initial={reduce ? { opacity: 0 } : { height: 0, opacity: 0 }}
                          animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 'auto', opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
                          exit={reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 0, opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
                        >
                          <Why money={money} p={p} />
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                ))}
              </>
            )}
            {tab === 'Balances' && (
              <>
                <SheetSection title="Balances" top="lg" subtitle="Who gets money back, and who owes" />
                {withHairlines(PEOPLE, x => {
                  const b = balanceLeft(money, made, x.id);
                  return (
                    <SheetRow
                      key={`balance-${x.id}`}
                      leading={face(x.id)}
                      title={x.name}
                      subtitle={b > 0.005 ? 'Gets back'
                        : b < -0.005 ? (x.id === MY_ID ? 'You owe' : 'Owes')
                        : joinedLate(x.joined) && Math.abs(money.balanceOf(x.id)) < 0.005 ? `Joined ${dayName(tripDate(x.joined)).toLowerCase()} · shares costs from then on`
                        : 'Square'}
                      trailing={Math.abs(b) > 0.005 ? <span className={`text-label-lg ${b > 0 ? 'tu-pages__success' : 'tu-pages__strong'}`}>{euros(Math.abs(b))}</span> : undefined}
                    />
                  );
                })}
              </>
            )}
            {tab === 'Expenses' && (
              <>
                <SheetSection title="Expenses" top="lg" subtitle="Newest first" />
                {withHairlines(money.expenses, e => (
                  <SheetRow
                    key={`expense-${e.title}`}
                    leading={face(e.paidBy)}
                    title={e.title}
                    subtitle={`${e.paidBy === MY_ID ? 'You' : name(e.paidBy)} paid · ${dayName(tripDate(e.day))} · ${e.split.length} people${e.shares ? ', by who had what' : ''}`}
                    trailing={
                      <span className="tu-amount">
                        <span className="text-label-lg tu-pages__strong">{euros(e.amount)}</span>
                        {shareOf(e, MY_ID) > 0 && <span className="text-body-sm tu-pages__muted">yours {euros(shareOf(e, MY_ID))}</span>}
                      </span>
                    }
                  />
                ))}
              </>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </StaggerIn>
  );
}

export interface MoneyFooterProps {
  /** The money as it stands (`PRE_DINNER`, the default, or with the bill in). */
  money?: Money;
  /** The dinner is on: until its bill is in, Scan the bill. */
  dinnerOn?: boolean;
  onScan?: () => void;
}

/**
 * Money's bottom, in view while the lists scroll (the pop-up's footer, over a hairline): what the trip has cost so far
 * and my part of it, like the Menu's total: "Spent so far", "3 expenses · yours €181.50", and the total, big. While the
 * dinner is on and its bill isn't in, Scan the bill under it, the width of the page and 56 px tall (TextButton lg, wide).
 */
export function MoneyFooter({ money = PRE_DINNER, dinnerOn, onScan }: MoneyFooterProps) {
  const mine = money.expenses.reduce((sum, e) => sum + shareOf(e, MY_ID), 0);
  return (
    <SheetFooter>
      <div className="tu-money-footer__row">
        <div className="tu-money-footer__text">
          <p className="text-label-lg">Spent so far</p>
          <p className="text-body-sm tu-pages__muted">{money.expenses.length} expenses · yours {euros(mine)}</p>
        </div>
        <p className="text-heading-lg tu-pages__strong">{euros(money.spent)}</p>
      </div>
      {!money.bill && dinnerOn && <TextButton label="Scan the bill" icon={ScanLine} size="lg" wide onClick={onScan} />}
    </SheetFooter>
  );
}

/** Why a payment is what it is: the payer's share of each expense, what they paid, and why it all goes to one person. */
function Why({ money, p }: { money: Money; p: Payment }) {
  const who = (id: string, start = false) => (id === MY_ID ? (start ? 'You' : 'you') : name(id));
  const had = money.expenses.filter(e => shareOf(e, p.from) > 0);
  const share = had.reduce((sum, e) => sum + shareOf(e, p.from), 0);
  const paidFor = money.expenses.filter(e => e.paidBy === p.from).reduce((sum, e) => sum + e.amount, 0);
  const oneByOne = had.filter(e => e.paidBy !== p.from).length;
  return (
    <div className="tu-why__box">
      {had.map(e => (
        <p key={e.title} className="text-body-sm tu-why__line"><span>{e.title}</span><span>{euros(shareOf(e, p.from))}</span></p>
      ))}
      {paidFor > 0 && <p className="text-body-sm tu-why__line"><span>Paid for the group</span><span>−{euros(paidFor)}</span></p>}
      <p className="text-body-sm tu-why__sum">
        {who(p.from, true)} had {euros(share)} of it all{paidFor > 0 ? ` and paid ${euros(paidFor)}` : ''}, so {p.from === MY_ID ? 'you owe' : 'owes'} {euros(p.amount)}.{' '}
        {who(p.to, true)} paid the most for everyone, so it goes to {who(p.to)} in one payment instead of {oneByOne}.
      </p>
    </div>
  );
}

// ---------- Add

/** What Add to the trip shows: the two choices, or one of them. */
export type AddStep = 'choose' | 'plan' | 'invite';

/** The pop-up's title and the line at the top of its page, for each step (the app's `AddPage.headerOf`); Invite's page
 *  says it itself. */
export const addHeaderOf = (step: AddStep): { title: string; subtitle?: string } => ({
  choose: { title: 'Add to the trip', subtitle: 'A plan, or someone new' },
  plan: { title: 'Plan something', subtitle: 'Find a place, pick a time, send it' },
  invite: { title: 'Invite someone' },
})[step];

export interface AddPageProps {
  /** Where it is: the two choices, or one of them. The step lives with the pop-up, whose header follows it (its title,
   *  and a way back). */
  step: AddStep;
  onStep: (step: AddStep) => void;
  /** The plan being made, shared with the pop-up's footer (Send) and its Back (see usePlanDraft); its own if not given. */
  draft?: PlanDraft;
  /** What Plan something's search holds when the page opens on it (for a story; empty by default). */
  query?: string;
  /** The place it has picked when the page opens on Plan something (an id in LISBON_PLACES; for a story). */
  place?: string;
}

/** The last time a wheel offers: a quarter to midnight, in minutes from midnight. */
const LAST = 23 * 60 + 45;

/** Tonight from 6 to 8, or from the next hour if it's already later; tomorrow once the evening is gone. A day of the
 *  trip, and a time range in minutes from midnight. */
const startWhen = (now: Date) => {
  const late = now.getHours() >= 21;
  const day = late && TRIP_DAYS.some(d => d.day === TODAY + 1) ? TODAY + 1 : TODAY;
  const from = day === TODAY && now.getHours() >= 17 ? (now.getHours() + 1) * 60 : 18 * 60;
  return { day, from, to: Math.min(from + 120, LAST) };
};
type When = ReturnType<typeof startWhen>;

/**
 * What's being planned in Add (the app's `PlanDraft`): the place picked from the search, if any, and when. The page
 * edits it; the pop-up's footer sends it (AddFooter), and its Back puts the place down again.
 */
export function usePlanDraft(place?: string) {
  const [spot, pick] = useState<PlaceSpot | undefined>(place ? placeById(place) : undefined);
  const [when, setWhen] = useState<When>(() => startWhen(TRIP_NOW));
  const reset = () => {
    pick(undefined);
    setWhen(startWhen(TRIP_NOW));
  };
  const toPlan = (): Plan => {
    const s = spot!, { day, from, to } = when;
    return { id: `added-${s.id}-${day}-${from}`, name: s.name, sticker: s.sticker, at: s.at, day, hour: Math.floor(from / 60), minute: from % 60, endHour: Math.floor(to / 60), endMinute: to % 60 };
  };
  return { spot, pick, when, setWhen, reset, toPlan };
}
export type PlanDraft = ReturnType<typeof usePlanDraft>;

/**
 * Add's footer, for each step: once a place is picked, Send to the group (lg, wide) with a line under it; for Invite,
 * Copy link. Nothing while choosing or searching.
 */
export function AddFooter({ step, draft, onSent }: { step: AddStep; draft: PlanDraft; onSent: (plan: Plan) => void }) {
  const toast = useTripNotice();
  if (step === 'plan' && draft.spot) {
    return (
      <SheetFooter note="It goes on everyone's itinerary and map.">
        <TextButton label="Send to the group" size="lg" wide onClick={() => onSent(draft.toPlan())} />
      </SheetFooter>
    );
  }
  if (step !== 'invite') return null;
  const copy = () => {
    // The story's frame may not be allowed the clipboard; the note shows either way, as in the app
    navigator.clipboard?.writeText(`https://${INVITE_LINK}`).catch(() => {});
    toast('Link copied');
  };
  return (
    <SheetFooter>
      <TextButton label="Copy link" icon={Copy} size="lg" wide onClick={copy} />
    </SheetFooter>
  );
}

/**
 * Adding to the trip: a plan (find a place, pick a day and a time, send it to everyone's itinerary and map) or someone
 * new (a link: no account, and they only share costs from the day they join; Invite can show what they'll see). The
 * step lives with the pop-up: its header shows the step's title and a back button (see TripSheet `onBack`), and
 * going back to the choice starts a plan over. One step (or, in Plan something, the search and then the place) at a
 * time: it fades in (enter-ms) while the last one fades out with a blur (fade-ms; no blur with reduced motion).
 */
export function AddPage({ step, onStep, draft: shared, query: firstQuery = '', place }: AddPageProps) {
  const reduce = useReducedMotion();
  const [query, setQuery] = useState(step === 'plan' ? firstQuery : '');
  const own = usePlanDraft(step === 'plan' ? place : undefined);
  const { spot, when, setWhen } = shared ?? own;
  // Which time's wheel is open, if any
  const [editing, setEditing] = useState<'from' | 'to' | null>(null);

  // Back to the choice starts a plan over next time
  const [lastStep, setLastStep] = useState(step);
  if (step !== lastStep) {
    setLastStep(step);
    if (step === 'choose') {
      setQuery('');
      setEditing(null);
      (shared ?? own).reset();
    }
  }
  // Back from a picked place (the header's) closes any open wheel with it
  const [lastSpot, setLastSpot] = useState(spot);
  if (spot !== lastSpot) {
    setLastSpot(spot);
    if (!spot) setEditing(null);
  }

  const pick = (s: PlaceSpot) => {
    (shared ?? own).pick(s);
    setEditing(null);
  };

  const key = `${step}:${spot?.id ?? ''}`;
  return (
    <div className="tu-add-steps">
      <AnimatePresence initial={false}>
        <motion.div
          key={key}
          className="tu-add-steps__step"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
          exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
        >
          {step === 'choose' && <ChooseStep onPick={onStep} />}
          {step === 'invite' && <InviteStep />}
          {step === 'plan' && !spot && <PlanSearch query={query} onQuery={setQuery} onPick={pick} />}
          {step === 'plan' && spot && (
            <PlanWhen spot={spot} when={when} onWhen={setWhen} editing={editing} onEditing={setEditing} />
          )}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

/** The two choices, as plain lines: what it is, a word on it, and an arrow; a hairline between them. */
function ChooseStep({ onPick }: { onPick: (s: AddStep) => void }) {
  return (
    <StaggerIn>
      <Choice key="plan" title="Plan something" subtitle="A place to eat, see or do. It goes on everyone's itinerary and map." onClick={() => onPick('plan')} />
      <Hairline key="line" />
      <Choice key="invite" title="Invite someone" subtitle="They join with a link, no account. They only share costs from the day they join." onClick={() => onPick('invite')} />
    </StaggerIn>
  );
}

/** One of Add's two choices: a big title (heading-sm), a line on it, and an arrow; no icon, no box around it. */
function Choice({ title, subtitle, onClick }: { title: string; subtitle: string; onClick: () => void }) {
  return (
    <button type="button" className="tu-choice" onClick={onClick}>
      <span className="tu-choice__text">
        <span className="text-heading-sm">{title}</span>
        <span className="text-body-sm tu-pages__muted">{subtitle}</span>
      </span>
      <ArrowRight className="tu-choice__arrow" strokeWidth={2} absoluteStrokeWidth aria-hidden />
    </button>
  );
}

/** The link, in the middle of the sheet (TripSheet `centered`); Copy link is in the footer (AddFooter). */
function InviteStep() {
  return (
    <div className="tu-invite">
      <StaggerIn gap="md">
        <div key="head" className="tu-invite__head">
          <h3 className="text-heading-sm tu-pages__strong">Send them this link</h3>
          <p className="text-body-sm tu-pages__muted">Share it with a friend. They type their name and they're in.</p>
        </div>
        <div key="link" className="tu-link">
          <span className="text-label-lg tu-ellipsis tu-link__text">{INVITE_LINK}</span>
        </div>
      </StaggerIn>
    </div>
  );
}

/** "Food hall · Cais do Sodré · 12 min walk" (or "6.1 km away"). */
const placeLine = (s: PlaceSpot) => `${s.kind} · ${s.area} · ${walkLabel(s.at)}`;

/** Finding a place: a search over Lisbon (by name, kind or neighbourhood; accents don't matter); before you type, the
 *  five nearest on foot. */
function PlanSearch({ query, onQuery, onPick }: { query: string; onQuery: (q: string) => void; onPick: (s: PlaceSpot) => void }) {
  const q = query.trim();
  const found = LISBON_PLACES.filter(s => placeMatches(s, q));
  if (!q) found.sort((a, b) => walkMinutes(a.at) - walkMinutes(b.at));
  const shown = q ? found : found.slice(0, 5);
  return (
    <StaggerIn>
      <div key="search" className="tu-search">
        <Search className="tu-search__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
        <input
          type="search"
          enterKeyHint="search"
          className="text-label-lg tu-search__input"
          placeholder="Search places in Lisbon"
          aria-label="Search places in Lisbon"
          value={query}
          onChange={e => onQuery(e.target.value)}
        />
        {q && (
          <button type="button" className="tu-search__clear" aria-label="Clear the search" onClick={() => onQuery('')}>
            <X className="tu-search__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
          </button>
        )}
      </div>
      <SheetSection
        key="title"
        top="lg"
        title={!q ? 'Near you' : !found.length ? 'Nothing found' : `${found.length} ${found.length === 1 ? 'place' : 'places'}`}
        subtitle={!q ? 'Or search for anywhere in Lisbon' : !found.length ? 'Try a name, a kind of place or a neighbourhood' : undefined}
      />
      {withHairlines(shown, s => (
        <SheetRow
          key={s.id}
          leading={<Slot><Sticker name={s.sticker} size="row" /></Slot>}
          title={s.name}
          subtitle={placeLine(s)}
          trailing={<ArrowRight className="tu-choice__arrow" strokeWidth={2} absoluteStrokeWidth aria-hidden />}
          onClick={() => onPick(s)}
        />
      ))}
    </StaggerIn>
  );
}

/**
 * A small still map of a place, with its sticker on it and the map's credit (Plan something's picked place, a plain
 * plan's details). The app draws the live map's tiles in it (`_mapOf`); here a plain block stands in for them, as the
 * trip screen's canvas does for the map.
 */
export function PlaceMap({ sticker }: { sticker: string }) {
  return (
    <div className="tu-place-map" aria-hidden>
      <Sticker name={sticker} size="map" />
      <span className="text-caption tu-place-map__credit">© OpenFreeMap © OpenMapTiles © OpenStreetMap</span>
    </div>
  );
}

/** The place you picked, on a small map (its sticker is on it), then when: a day, from and to. Send is in the footer
 *  (AddFooter); a different place is the header's Back. */
function PlanWhen({ spot, when, onWhen, editing, onEditing }: {
  spot: PlaceSpot;
  when: When;
  onWhen: (w: When) => void;
  editing: 'from' | 'to' | null;
  onEditing: (e: 'from' | 'to' | null) => void;
}) {
  const { day, from, to } = when;
  return (
    <StaggerIn>
      <PlaceMap key="map" sticker={spot.sticker} />
      <SheetRow key="place" title={spot.name} subtitle={placeLine(spot)} />
      <SheetSection key="when" title="When" top="lg" />
      {/* One day at a time, today on: the same chips as the day filter, without All */}
      <div key="days" className="tu-toggles" role="group" aria-label="Day" style={{ paddingInline: 'var(--space-xs)' }}>
        {TRIP_DAYS.filter(d => d.day >= TODAY).map(d => (
          <ToggleChip key={d.day} label={dayName(tripDate(d.day))} on={d.day === day} onClick={() => onWhen({ ...when, day: d.day })} />
        ))}
      </div>
      <div key="from" className="tu-plan-from">
        <TimeRow
          label="From"
          day={day}
          minutes={from}
          open={editing === 'from'}
          onOpen={open => onEditing(open ? 'from' : null)}
          onChange={x => onWhen({ day, from: x, to: to <= x ? Math.min(x + 60, LAST) : to })}
        />
      </div>
      <Hairline key="line" />
      <TimeRow
        key="to"
        label="To"
        day={day}
        minutes={to}
        open={editing === 'to'}
        onOpen={open => onEditing(open ? 'to' : null)}
        onChange={x => onWhen({ day, from, to: Math.max(x, from + 15) })}
      />
    </StaggerIn>
  );
}

/** A time: its label and value (brand while its wheel is open); tapping it opens a wheel under it, and closes it
 *  again. The wheel opens to its height and closes a little quicker (enter-ms / fade-ms; reduced motion, fades). */
function TimeRow({ label, day, minutes, open, onOpen, onChange }: {
  label: string;
  day: number;
  minutes: number;
  open: boolean;
  onOpen: (open: boolean) => void;
  onChange: (minutes: number) => void;
}) {
  const reduce = useReducedMotion();
  const value = clockTime(tripDate(day, 0, minutes));
  return (
    <div className="tu-time">
      <button type="button" className="tu-time__row" aria-expanded={open} aria-label={`${label} ${value}`} onClick={() => onOpen(!open)}>
        <span className="text-label-lg">{label}</span>
        <span className={`text-label-lg weight-semibold ${open ? 'tu-time__value--open' : ''}`}>{value}</span>
      </button>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            key="wheel"
            className="tu-time__wheel"
            initial={reduce ? { opacity: 0 } : { height: 0 }}
            animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 'auto', transition: { duration: m['enter-ms'] / 1000, ease } }}
            exit={reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
          >
            {/* A new day starts the wheel over, on the time it has */}
            <TimeWheel key={day} label={label} day={day} minutes={minutes} onChange={onChange} />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

/** Every quarter of an hour in a day, in minutes from midnight. */
const QUARTERS = Array.from({ length: 96 }, (_, i) => i * 15);

/**
 * A time wheel in 15-minute steps, plan/picker-height tall. The app's is Cupertino's (three wheels: hour, minute,
 * AM/PM); here it's one column of times that scrolls and snaps, the one in the middle band picked once it settles.
 * Tapping a time brings it to the middle; the arrow keys step it.
 */
function TimeWheel({ label, day, minutes, onChange }: { label: string; day: number; minutes: number; onChange: (minutes: number) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const settle = useRef<number | undefined>(undefined);
  const picked = useRef(minutes);
  const itemHeight = () => ref.current?.querySelector<HTMLElement>('.tu-wheel__item')?.offsetHeight ?? 1;
  const indexOf = (x: number) => Math.round(x / 15);

  // Opens on the time it has, in the middle
  useLayoutEffect(() => {
    if (ref.current) ref.current.scrollTop = indexOf(picked.current) * itemHeight();
  }, []);
  useEffect(() => () => window.clearTimeout(settle.current), []);

  const to = (i: number) => ref.current?.scrollTo({ top: Math.max(0, Math.min(QUARTERS.length - 1, i)) * itemHeight(), behavior: 'smooth' });
  // Once it has stopped, the time in the middle is picked
  const onScroll = () => {
    window.clearTimeout(settle.current);
    settle.current = window.setTimeout(() => {
      const el = ref.current;
      if (!el) return;
      const x = QUARTERS[Math.max(0, Math.min(QUARTERS.length - 1, Math.round(el.scrollTop / itemHeight())))];
      if (x !== picked.current) {
        picked.current = x;
        onChange(x);
      }
    }, m['press-ms']);
  };
  return (
    <div className="tu-wheel">
      <div className="tu-wheel__band" aria-hidden />
      <div
        ref={ref}
        className="tu-wheel__scroll"
        role="listbox"
        aria-label={label}
        tabIndex={0}
        onScroll={onScroll}
        onKeyDown={e => {
          if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return;
          e.preventDefault();
          to(indexOf(picked.current) + (e.key === 'ArrowDown' ? 1 : -1));
        }}
      >
        {QUARTERS.map((x, i) => (
          <div key={x} className="tu-wheel__item text-label-lg" role="option" aria-selected={x === minutes} onClick={() => to(i)}>
            {clockTime(tripDate(day, 0, x))}
          </div>
        ))}
      </div>
    </div>
  );
}
