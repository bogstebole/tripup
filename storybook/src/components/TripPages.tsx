// The pages of the footer's three pop-ups: the itinerary, the group's money, and adding to the trip. Each goes inside
// a TripSheet, which scrolls it; their notes come down at the top of the screen (see Notice.tsx).
import { ArrowRight, ChevronDown, ChevronRight, ChevronUp, Clock, MapPin, Search, X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type ReactElement, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  accountOf, atMinute, balanceLeft, spentAt, BANK_CONFIRM_MS, BANKS, clockTime, dayName, DINNER, DINNER_TABLE, dinnerChoice, euros, INVITE_LINK, isPaid, LISBON_PLACES, MARK_CONFIRM_MS, MY_ID, payLine, payReference, PEOPLE,
  personById, placeById, placeMatches, planEnd, planStart, plansWith, POLL_OPENS, pollClosed, pollOpen, PRE_DINNER, shareOf,
  timeUntil, TODAY, tripDate, TRIP_DAYS, TRIP_NOW, VISITED, votesIn, walkLabel, walkMinutes, type Visited, type Bank, type Money, type Paying, type Payment, type PlaceSpot,
  type Plan, type PollState,
} from '../data';
import { TextButton } from './Button';
import { Sticker } from './Sticker';
import { BankLayer } from './BankApp';
import { useTripNotice } from './Notice';
import { SegmentedTabs } from './SegmentedTabs';
import { ToggleChip } from './ToggleChips';
import { Hairline, RowThumb, SheetFooter, SheetRow, SheetSection, Slot, StaggerIn } from './TripSheet';
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
  /** Tapping a place we've been: what happened there, in the same pop-up (see VisitPage). */
  onVisit?: (place: Visited) => void;
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
 * the days picked. Tapping a place we've been opens what happened there, in the same pop-up (see VisitPage); tapping
 * a plan opens its details right there, in the pop-up's place. While the dinner poll hasn't decided, today has a Dinner
 * slot at 5 PM instead of the place ("Poll open · 3 of 5 voted"), which opens the poll. A plan with an end says until
 * when ("In 2 hrs · until 8 PM").
 */
export function ItineraryPage({ onVisit, onOpen, poll, onPoll, now = TRIP_NOW, days = [], added = [] }: ItineraryPageProps) {
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
              leading={<RowThumb sticker={v.sticker} tilt={v.tilt} />}
              title={v.name}
              subtitle={`Been there · ${clockTime(atMinute(v.day, v.arrived))}`}
              onClick={onVisit && (() => onVisit(v))}
            />
          )),
          // Tonight's slot, until the poll has picked a place
          ...(poll && day === TODAY && dinner === null
            ? [
                <SheetRow
                  key="dinner-slot"
                  leading={<RowThumb><MapPin className="tu-pages__lead" strokeWidth={2} absoluteStrokeWidth aria-hidden /></RowThumb>}
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
              leading={<RowThumb sticker={p.sticker} />}
              title={p.name}
              subtitle={[p === next && 'Up next', timeUntil(planStart(p), now), planEnd(p) && `until ${clockTime(planEnd(p)!)}`].filter(Boolean).join(' · ')}
              tone={p === next ? 'brand' : undefined}
              trailing={<span className="text-label-md weight-semibold tu-pages__strong">{clockTime(planStart(p))}</span>}
              onClick={onOpen && (() => onOpen(p))}
            />
          )),
        ];
        return (
          <div key={day} className="tu-day-block">
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

/** The itinerary's two steps, one at a time like Money's: the days, or a place we've been. The pop-up's header follows
 *  (see visitHeaderOf), with Back to the days; the old page fades out with a blur as the new one fades in. */
export function ItineraryFlow({ visit, list }: { visit?: Visited | null; list: ReactNode }) {
  const reduce = useReducedMotion();
  return (
    <div className="tu-add-steps">
      <AnimatePresence initial={false}>
        <motion.div
          key={visit?.name ?? 'days'}
          className="tu-add-steps__step"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
          exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
        >
          {visit ? <VisitPage visit={visit} /> : list}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

const lengthOf = (minutes: number) => (minutes < 60 ? `${minutes} min` : `${Math.floor(minutes / 60)} h${minutes % 60 ? ` ${minutes % 60} min` : ''}`);
const namesOf = (ids: string[]) => {
  const names = ids.map(name);
  return names.length < 2 ? names.join('') : `${names.slice(0, -1).join(', ')} and ${names[names.length - 1]}`;
};

/** A place's header: its name; the facts under it (what it is, the day, how long, what was spent). */
export const visitHeaderOf = (v: Visited) => {
  const spent = spentAt(v).reduce((sum, e) => sum + e.amount, 0);
  return {
    title: v.name,
    subtitle: [v.kind, `${atMinute(v.day, 0).toLocaleDateString('en-GB', { weekday: 'short' })} ${v.day} May`, lengthOf(v.left - v.arrived), spent ? `${euros(spent)} spent` : 'Nothing spent'].join(' · '),
  };
};

/** A place's footer: show it on the map (the pop-up closes and the map flies there). */
export const VisitFooter = ({ onMap }: { onMap?: () => void }) => (
  <SheetFooter>
    <TextButton label="Show on the map" variant="soft" size="lg" wide onClick={onMap} />
  </SheetFooter>
);

/**
 * A place we've been, as it went: the place big, on a muted block like Ren's catch-up tiles, then a timeline: when we
 * got there and who came, what was paid there (who paid, how it's split, my part), and when we left. A dot per moment
 * on a line that runs down to the next.
 */
export function VisitPage({ visit: v }: { visit: Visited }) {
  return (
    <StaggerIn>
      <div key="place" className="tu-visit__place">
        <Sticker name={v.sticker} tilt={v.tilt} className="tu-visit__sticker" />
      </div>
      <SheetSection key="what" title="What happened" top="lg" />
      <Moment key="in" at={atMinute(v.day, v.arrived)} title="Got there" subtitle={namesOf(v.who)}>
        <span className="tu-visit__faces">{v.who.map(id => <Sticker key={id} name={personById(id).sticker} size="chip" />)}</span>
      </Moment>
      {spentAt(v).map(e => (
        <Moment
          key={e.title}
          at={atMinute(v.day, e.minute!)}
          title={e.title}
          subtitle={`${e.paidBy === MY_ID ? 'You' : name(e.paidBy)} paid · split ${e.split.length} ways${shareOf(e, MY_ID) ? ` · yours ${euros(shareOf(e, MY_ID))}` : ''}`}
          trailing={<span className="text-label-lg tu-pages__strong">{euros(e.amount)}</span>}
        />
      ))}
      <Moment key="out" at={atMinute(v.day, v.left)} title="Left" subtitle={`${lengthOf(v.left - v.arrived)} there`} last />
    </StaggerIn>
  );
}

/** One moment on a visit's timeline: the time, a dot on a line down to the next moment, and what happened. */
function Moment({ at, title, subtitle, trailing, last, children }: { at: Date; title: string; subtitle?: string; trailing?: ReactNode; last?: boolean; children?: ReactNode }) {
  return (
    <div className={`tu-moment${last ? ' tu-moment--last' : ''}`}>
      <span className="text-label-md weight-semibold tu-pages__strong tu-moment__time">{clockTime(at)}</span>
      <span className="tu-moment__rail" aria-hidden><span className="tu-moment__dot" /></span>
      <span className="tu-moment__what">
        <span className="text-label-lg tu-pages__strong">{title}</span>
        {subtitle && <span className="text-body-sm tu-pages__muted">{subtitle}</span>}
        {children}
      </span>
      {trailing}
    </div>
  );
}

// ---------- Money

/** Money's tabs: one list at a time, Settle up first (it's the one with something to do). */
export const MONEY_TABS = ['Settle up', 'Balances', 'Expenses'] as const;
export type MoneyTab = (typeof MONEY_TABS)[number];

export interface MoneyPageProps {
  /** The money as it stands: before the dinner's bill (`PRE_DINNER`, the default) or with it in (`BILL_IN`). */
  money?: Money;
  /** The payments made so far (none by default). My Pay is in the footer (MoneyFooter, OwePill). */
  made?: Payment[];
  /** The tab it opens on (Settle up, by default), and a change of tab (so Pay and back keep it). */
  tab?: MoneyTab;
  onTab?: (tab: MoneyTab) => void;
  /** My payment on its way, if any: its row says so (Paying…, or Waiting for Maya to confirm). */
  paying?: Paying;
}

/**
 * The group's money, one thing at a time in tabs the width of the page (Settle up · Balances · Expenses): the fewest payments that square everyone up (each with a Why that opens), each
 * person's balance after the payments made so far, or the expenses (the list that grows all trip, so it never pushes
 * the rest away). Each tab's list starts with a section title and a line under it. Picking a tab fades its list in
 * (enter-ms) while the last one fades out with a blur (fade-ms; no blur with reduced motion). Tonight's dinner joins
 * once its bill is in, as an expense split by who had what. What I owe and Pay, what it has cost so far, and Scan the
 * bill are at the bottom, in the pop-up's footer (MoneyFooter), where the thumb reaches.
 */
export function MoneyPage({ money = PRE_DINNER, made = [], tab: firstTab = 'Settle up', onTab, paying }: MoneyPageProps) {
  const [tab, setTab] = useState<MoneyTab>(firstTab);
  // The payment whose "why" is open, if any
  const [why, setWhy] = useState<string | null>(null);
  const reduce = useReducedMotion();
  const pays = money.settleUp;
  const paid = (p: Payment) => isPaid(p, made);
  const joinedLate = (joined: number) => joined > TRIP_DAYS[0].day;
  const key = (p: Payment) => `${p.from}>${p.to}`;
  // Paid; mine on its way (from my bank, or marked and waiting for them to confirm); or not yet
  const state = (p: Payment) => paid(p) ? 'Paid'
    : paying && key(paying.pay) === key(p) ? (paying.via === 'bank' ? 'Paying…' : `Waiting for ${name(p.to)} to confirm`)
    : 'Pending';
  return (
    <StaggerIn>
      <div key="tabs" className="tu-money-tabs">
        <SegmentedTabs tabs={[...MONEY_TABS]} value={tab} onChange={t => { setTab(t as MoneyTab); onTab?.(t as MoneyTab); }} wide />
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
                      subtitle={`${state(p)} · ${why === key(p) ? 'Hide why' : 'Why'}`}
                      tone={paid(p) ? 'success' : undefined}
                      trailing={<span className="text-label-lg tu-pages__strong">{euros(p.amount)}</span>}
                      onClick={() => setWhy(w => (w === key(p) ? null : key(p)))}
                      expanded={why === key(p)}
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
  /** The payments made so far (none by default), my Pay (see OwePill), and my payment on its way. */
  made?: Payment[];
  onPay?: (p: Payment) => void;
  paying?: Paying;
}

/**
 * What I owe and Pay, as a rounded pill (xl in on the left, xs elsewhere), while I owe it: a muted "You owe Maya" ("·
 * Everyone else has paid" once they have) over the amount, and Pay, which opens the payment (see PayPage). While it's
 * on its way the line and the end change over: "Paying Maya · your bank is confirming" with a spinner, or "Waiting for
 * Maya to confirm" with a clock, as tall as Pay so the pill keeps its height. Once it's paid the pill goes, fading as
 * the footer closes up under it (the note at the top says it went through). Nothing if I owe nobody. At the top of
 * Money's footer, where the thumb reaches.
 */
export function OwePill({ money = PRE_DINNER, made = [], onPay, paying }: { money?: Money; made?: Payment[]; onPay?: (p: Payment) => void; paying?: Paying }) {
  const pays = money.settleUp;
  const mine = pays.find(p => p.from === MY_ID);
  const owing = mine && !isPaid(mine, made) ? mine : undefined;
  const othersPaid = pays.filter(p => p.from !== MY_ID).every(p => isPaid(p, made));
  const via = owing && paying && paying.pay.to === owing.to ? paying.via : undefined;
  return (
    <AnimatePresence initial={false}>
      {owing && (
        <motion.div
          key="owe"
          className="tu-owe"
          exit={{ opacity: 0, height: 0, marginBottom: 0, paddingTop: 0, paddingBottom: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
        >
          <AnimatePresence initial={false} mode="popLayout">
            <motion.div
              key={via ?? 'owe'}
              className="tu-owe__body"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
              exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
            >
              <div className="tu-owe__text">
                <p className="text-body-sm tu-ellipsis tu-pages__muted">
                  {via === 'bank' ? `Paying ${name(owing.to)} · your bank is confirming`
                    : via === 'marked' ? `Waiting for ${name(owing.to)} to confirm`
                    : `You owe ${name(owing.to)}${othersPaid && money.bill ? ' · Everyone else has paid' : ''}`}
                </p>
                <p className="text-heading-sm tu-ellipsis tu-pages__strong">{euros(owing.amount)}</p>
              </div>
              {via === 'bank' ? <span className="tu-owe__wait"><span className="tu-spinner" aria-label="Confirming" /></span>
                : via === 'marked' ? <span className="tu-owe__wait"><Clock className="tu-owe__clock" strokeWidth={2} absoluteStrokeWidth aria-hidden /></span>
                : <TextButton label="Pay" onClick={() => onPay?.(owing)} />}
            </motion.div>
          </AnimatePresence>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

/**
 * Money's bottom, in view while the lists scroll (the pop-up's footer): what I owe and Pay (OwePill, while I owe it), sm above the
 * hairline, where the thumb reaches; then, over it, what the trip has cost so far and my part of it, like the Menu's
 * total: "Spent so far", "3 expenses · yours €181.50", and the total, big. While the
 * dinner is on and its bill isn't in, Scan the bill under it, the width of the page and 56 px tall (TextButton lg, wide).
 */
export function MoneyFooter({ money = PRE_DINNER, dinnerOn, onScan, made, onPay, paying }: MoneyFooterProps) {
  const mine = money.expenses.reduce((sum, e) => sum + shareOf(e, MY_ID), 0);
  return (
    <>
    <OwePill money={money} made={made} onPay={onPay} paying={paying} />
    <SheetFooter>
      <div className="tu-money-footer__row">
        <div className="tu-money-footer__text">
          <p className="text-label-lg">Spent so far</p>
          <p className="text-body-sm tu-pages__muted">{money.expenses.length} expenses · yours {euros(mine)}</p>
        </div>
        <p className="text-heading-lg tu-pages__strong">{euros(money.spent)}</p>
      </div>
      {!money.bill && dinnerOn && <TextButton label="Scan the bill" size="lg" wide onClick={onScan} />}
    </SheetFooter>
    </>
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

// ---------- Paying

/** Where Money is: the group's money, paying what I owe, or picking my bank (the first time I pay). */
export type MoneyStep = 'list' | 'pay' | 'bank';

/** The pop-up's title and the line at the top of its page, for each step (the app's `MoneyFlow.headerOf`). */
export const moneyHeaderOf = (step: MoneyStep, pay?: Payment): { title: string; subtitle?: string } =>
  step === 'pay' && pay ? { title: `Pay ${name(pay.to)}`, subtitle: `It goes straight from your bank to ${name(pay.to)}'s. TripUp never holds the money.` }
  : step === 'bank' ? { title: 'Your bank', subtitle: "Pick it once and TripUp remembers it. You approve each payment in your bank's app; TripUp never sees your login." }
  : { title: 'Money' };

/**
 * Paying what I owe: who and how much, big (their sticker, the amount in display, "to Maya"); then what the transfer
 * will say, in a muted box inset like Why's (To, with their account; From, my bank once I've picked it, a tap to pick
 * another; the reference that tells them what it's for; Arrives in seconds); and Why that amount, which opens under
 * it. Pay with the bank and Mark as paid are in the footer (PayFooter).
 */
export function PayPage({ money = PRE_DINNER, pay, bank, onChangeBank }: { money?: Money; pay: Payment; bank?: Bank; onChangeBank?: () => void }) {
  const reduce = useReducedMotion();
  const [why, setWhy] = useState(false);
  const to = personById(pay.to);
  return (
    <StaggerIn>
      <div key="who" className="tu-pay-who">
        <Sticker name={to.sticker} className="tu-pay-who__face" />
        <p className="text-display tu-pages__strong">{euros(pay.amount)}</p>
        <p className="text-body-md tu-pages__muted">to {to.name}</p>
      </div>
      <div key="lines" className="tu-pay-lines">
        <PayLine label="To" value={`${to.name} · ${accountOf(to.id)}`} />
        {bank && <PayLine label="From" value={bank.name} onClick={onChangeBank} />}
        <PayLine label="Reference" value={payReference(pay)} />
        <PayLine label="Arrives" value="In seconds" />
      </div>
      <div key="why">
        <SheetRow
          title={`Why ${euros(pay.amount)}`}
          subtitle={why ? 'Hide why' : 'What you had, and what you paid'}
          onClick={() => setWhy(w => !w)}
          expanded={why}
        />
        <AnimatePresence initial={false}>
          {why && (
            <motion.div
              key="why"
              className="tu-why"
              initial={reduce ? { opacity: 0 } : { height: 0, opacity: 0 }}
              animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 'auto', opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
              exit={reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 0, opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
            >
              <Why money={money} p={pay} />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </StaggerIn>
  );
}

/** One line of what the transfer will say: what it is on the left (muted), the value on the right; an arrow when a
 *  tap changes it. */
function PayLine({ label, value, onClick }: { label: string; value: string; onClick?: () => void }) {
  const body = (
    <>
      <span className="text-body-sm tu-pages__muted">{label}</span>
      <span className="text-label-md tu-pages__strong tu-pay-line__value">{value}</span>
      {onClick && <ChevronRight className="tu-pay-line__arrow" strokeWidth={2} absoluteStrokeWidth aria-hidden />}
    </>
  );
  return onClick ? <button type="button" className="tu-pay-line tu-pay-line--tap" onClick={onClick}>{body}</button> : <div className="tu-pay-line">{body}</div>;
}

/** Paying's footer: Pay with my bank (named once TripUp knows it), and Mark as paid (soft) for money that went another
 *  way; under them, "Paid in cash or another way? Maya confirms it." */
export function PayFooter({ pay, bank, onBank, onMarked }: { pay: Payment; bank?: Bank; onBank?: () => void; onMarked?: () => void }) {
  return (
    <SheetFooter note={`Paid in cash or another way? ${name(pay.to)} confirms it.`}>
      <TextButton label={`Pay with ${bank?.name ?? 'your bank'}`} size="lg" wide onClick={onBank} />
      <TextButton label="Mark as paid" variant="soft" size="lg" wide onClick={onMarked} />
    </SheetFooter>
  );
}

/** The banks I can pay from, the first time I pay: each its mark, its name and an arrow; a tap picks it and opens it to
 *  approve. */
export function BankPage({ onPick }: { onPick?: (bank: Bank) => void }) {
  return (
    <StaggerIn>
      {withHairlines(BANKS, b => (
        <SheetRow
          key={b.id}
          leading={<BankLogo bank={b} />}
          title={b.name}
          onClick={onPick && (() => onPick(b))}
        />
      ))}
    </StaggerIn>
  );
}

/** A bank's mark in TripUp's lists: its first letter on a muted disc, space-2xl wide (the real app shows its logo). */
export function BankLogo({ bank }: { bank: Bank }) {
  return <span className="tu-bank-logo text-label-md weight-semibold" aria-hidden>{bank.name[0]}</span>;
}

/** Money's pop-up for a story: its header, page, footer and Back for the step it's on, and my bank's app over the
 *  screen while it's up (`overlay`). */
export type MoneySlot = { title: string; subtitle?: string; page: ReactNode; footer: ReactNode; onBack?: () => void; overlay: ReactNode; reset: () => void };

/**
 * The whole of Money, as in the app: the money; Pay on what I owe opens paying it (Back to the money); Pay with your
 * bank, the first time, picks the bank (Back to paying), then hands off to the bank's app, the transfer filled in.
 * Approved: back on the money, the pill waits for the bank (BANK_CONFIRM_MS), then "You paid Maya €11.82" and Paid.
 * Cancelled: back on paying, "Payment cancelled · nothing was sent". Mark as paid: back on the money, the pill waits
 * for Maya (MARK_CONFIRM_MS), then "Maya confirmed your €11.82". The step's page fades in (enter-ms) while the last
 * fades out with a blur (fade-ms); the footer comes in once the old one has mostly gone (swap-in-at).
 */
export function useMoneyFlow({ money = PRE_DINNER, made, onPaid, notify, dinnerOn, onScan, tab: firstTab = 'Settle up', step: firstStep = 'list', bank: knownBank, banking: bankFirst = false }: {
  money?: Money;
  /** The tab the money opens on. */
  tab?: MoneyTab;
  /** For a story: the step it starts on (paying what I owe, or the bank list), the bank TripUp already knows, and
   *  whether my bank's app is up from the start. */
  step?: MoneyStep;
  bank?: Bank;
  banking?: boolean;
  made: Payment[];
  onPaid: (p: Payment) => void;
  notify: (line: string) => void;
  dinnerOn?: boolean;
  onScan?: () => void;
}): MoneySlot {
  const reduce = useReducedMotion();
  const [step, setStep] = useState<MoneyStep>(firstStep);
  const [tab, setTab] = useState<MoneyTab>(firstTab);
  const [payFor, setPayFor] = useState<Payment | undefined>(() => (firstStep !== 'list' || bankFirst ? money.settleUp.find(p => p.from === MY_ID) : undefined));
  const [bank, setBank] = useState<Bank | undefined>(knownBank);
  const [banking, setBanking] = useState(bankFirst);
  const [paying, setPaying] = useState<Paying>();
  const timer = useRef<number | undefined>(undefined);
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const onTheWay = (p: Payment, via: Paying['via']) => {
    setPaying({ pay: p, via });
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => {
      setPaying(undefined);
      onPaid(p);
      notify(via === 'bank' ? payLine(p) : `${name(p.to)} confirmed your ${euros(p.amount)}`);
    }, via === 'bank' ? BANK_CONFIRM_MS : MARK_CONFIRM_MS);
  };
  const payWithBank = () => (bank ? setBanking(true) : setStep('bank'));
  const header = moneyHeaderOf(step, payFor);
  const swapIn = { duration: (m['enter-ms'] * (1 - m['swap-in-at'])) / 1000, delay: (m['enter-ms'] * m['swap-in-at']) / 1000, ease };
  return {
    ...header,
    page: (
      <div className="tu-add-steps">
        <AnimatePresence initial={false}>
          <motion.div
            key={step}
            className="tu-add-steps__step"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
            exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
          >
            {step === 'list' && <MoneyPage money={money} made={made} tab={tab} onTab={setTab} paying={paying} />}
            {step === 'pay' && payFor && <PayPage money={money} pay={payFor} bank={bank} onChangeBank={() => setStep('bank')} />}
            {step === 'bank' && <BankPage onPick={b => { setBank(b); setBanking(true); }} />}
          </motion.div>
        </AnimatePresence>
      </div>
    ),
    footer: (
      <div className="tu-money-footers">
        <AnimatePresence initial={false}>
          <motion.div
            key={step}
            className="tu-money-footers__one"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1, transition: swapIn }}
            exit={{ opacity: 0, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
          >
            {step === 'list' && <MoneyFooter money={money} dinnerOn={dinnerOn} onScan={onScan} made={made} paying={paying} onPay={p => { setPayFor(p); setStep('pay'); }} />}
            {step === 'pay' && payFor && <PayFooter pay={payFor} bank={bank} onBank={payWithBank} onMarked={() => { onTheWay(payFor, 'marked'); setStep('list'); }} />}
          </motion.div>
        </AnimatePresence>
      </div>
    ),
    onBack: step === 'list' ? undefined : () => setStep(s => (s === 'bank' ? 'pay' : 'list')),
    overlay: (
      <AnimatePresence>
        {banking && payFor && bank && (
          <BankLayer
            key="bank"
            pay={payFor}
            bank={bank}
            onApproved={() => { onTheWay(payFor, 'bank'); setBanking(false); setStep('list'); }}
            onCancel={() => { setBanking(false); setStep('pay'); notify('Payment cancelled · nothing was sent'); }}
          />
        )}
      </AnimatePresence>
    ),
    reset: () => setStep('list'),
  };
}

// ---------- Add

/** What Add to the trip shows: the two choices, or one of them. */
export type AddStep = 'choose' | 'plan' | 'invite';

/** The pop-up's title and the line at the top of its page, for each step (the app's `AddPage.headerOf`); Invite's page
 *  says it itself. */
export const addHeaderOf = (step: AddStep): { title: string; subtitle?: string } => ({
  choose: { title: 'Add to the trip' },
  plan: { title: 'Plan something' },
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
      <TextButton label="Copy link" size="lg" wide onClick={copy} />
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
          leading={<RowThumb sticker={s.sticker} />}
          title={s.name}
          subtitle={placeLine(s)}
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
 * A time wheel in 15-minute steps, 180 tall. The app's is Cupertino's (three wheels: hour, minute,
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
