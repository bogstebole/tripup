// The pages of the footer's three pop-ups: the itinerary, the group's money, and adding to the trip. Each goes inside
// a TripSheet, which scrolls it; their notes come down at the top of the screen (see Notice.tsx).
import { ArrowRight, Check, ChevronLeft, CircleCheck, Copy, MapPin, MapPinPlus, ScanLine, UserPlus } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useState, type ReactElement, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  balanceLeft, clockTime, dayName, DINNER, DINNER_ESTIMATE, DINNER_TABLE, dinnerChoice, euros, INVITE_LINK, isPaid, MY_ID, payLine, PEOPLE,
  personById, PLAN_IDEAS, planStart, plansWith, POLL_OPENS, pollClosed, pollOpen, PRE_DINNER, shareOf, SPENT_SO_FAR, squaredUp, timeUntil,
  TODAY, tripDate, TRIP_DAYS, TRIP_NOW, VISITED, votesIn, type Money, type Payment, type PollState,
} from '../data';
import { AddButton } from './AddButton';
import { TextButton } from './Button';
import { KnowRow } from './KnowSection';
import { Sticker } from './Sticker';
import { useTripNotice } from './Notice';
import { SegmentedTabs } from './SegmentedTabs';
import { Hairline, SheetRow, SheetSection, Slot, StaggerIn } from './TripSheet';
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
  /** Tapping a stop: show it on the map. */
  onPick?: (place: string) => void;
  /** The dinner poll, while it decides tonight's dinner (my vote, an Undo, a place picked by hand). Leave it out for
   *  the plans as they stand at the demo's start: the poll long closed, La Brasserie at 5 PM. */
  poll?: PollState;
  /** Opens the dinner poll, from tonight's slot while it isn't decided. */
  onPoll?: () => void;
  /** Now, in the trip (the demo's start, 3:56 PM, by default). */
  now?: Date;
  /** The days picked in its filter (the chips under its title); empty or left out means all of them. */
  days?: number[];
}

/**
 * Every day of the trip, in order, each in its own grey block (so what belongs to which day is plain): where we've
 * been, what's planned, and today marked. It opens on today. Its filter shows only the days picked. Tapping a stop
 * shows it on the map (the pop-up closes and the map flies there). While the dinner poll hasn't decided, today has a
 * Dinner slot at 5 PM instead of the place ("Poll open · 3 of 5 voted"), which opens the poll.
 */
export function ItineraryPage({ onPick, poll, onPoll, now = TRIP_NOW, days = [] }: ItineraryPageProps) {
  const dinner = poll && (dinnerChoice(now, poll) ?? null);
  const plans = plansWith(dinner);
  const next = plans.find(p => planStart(p) > now);
  return (
    <StaggerIn gap="sm">
      {TRIP_DAYS.map(({ day, label }, i) => {
        if (days.length && !days.includes(day)) return null;
        const rows = [
          ...VISITED.filter(v => v.day === day).map(v => (
            <SheetRow
              key={v.name}
              leading={<Slot><Sticker name={v.sticker} size="row" tilt={v.tilt} /></Slot>}
              title={v.name}
              subtitle="Been there"
              trailing={<Check className="tu-pages__check" strokeWidth={2} absoluteStrokeWidth aria-label="Visited" />}
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
              subtitle={p === next ? `Up next · ${timeUntil(planStart(p), now)}` : timeUntil(planStart(p), now)}
              tone={p === next ? 'brand' : undefined}
              trailing={<span className="text-label-md weight-semibold tu-pages__strong">{clockTime(planStart(p))}</span>}
              onClick={onPick && (() => onPick(p.name))}
            />
          )),
        ];
        return (
          <div key={day} className="tu-day-block" data-sheet-focus={day === TODAY || undefined}>
            <div className="tu-day">
              <h3 className={`text-heading-sm ${day < TODAY ? 'tu-pages__muted' : 'tu-pages__strong'}`}>{label}</h3>
              <span className="text-body-sm tu-pages__muted">Day {i + 1}</span>
              {day === TODAY && <span className="tu-tag text-label-md weight-semibold">Today</span>}
            </div>
            {rows.length
              ? <div className="tu-day-block__rows">{rows}</div>
              : <p className="text-body-sm tu-day__empty">Nothing planned yet</p>}
          </div>
        );
      })}
    </StaggerIn>
  );
}

// ---------- Money

/** "€726.00 spent so far · 3 expenses"; with the dinner in, "€954.80 spent so far · 4 expenses". */
export const moneySubtitle = (money: Money = PRE_DINNER) => `${euros(money.spent)} spent so far · ${money.expenses.length} expenses`;
export const MONEY_SUBTITLE = moneySubtitle();

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
  /** The dinner is on and its bill isn't in: instead of the estimate, a way to scan the bill. */
  dinnerOn?: boolean;
  onScan?: () => void;
  /** The tab it opens on (Settle up, by default). */
  tab?: MoneyTab;
}

/**
 * The group's money: what I owe (and paying it) on top, then one thing at a time in tabs (Settle up · Balances ·
 * Expenses): the fewest payments that square everyone up (each with a Why that opens), each person's balance after
 * the payments made so far, or the expenses (the list that grows all trip, so it never pushes the rest away). Each
 * tab's list has a short line on top. Picking a tab fades its list in (enter-ms) while the last one fades out with a
 * blur (fade-ms; no blur with reduced motion). Tonight's dinner is an estimate until it's on, then Scan the bill; once
 * the bill is in, it's an expense split by who had what. The top block: what I owe and Pay; "Everyone else has paid";
 * "You're square with Maya"; and, once everyone has paid, a green "Lisbon is squared up".
 */
export function MoneyPage({ money = PRE_DINNER, made: kept, onPay, dinnerOn, onScan, tab: firstTab = 'Settle up' }: MoneyPageProps) {
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
      {(mine || square) && (
        <div key="mine" className={square ? 'tu-owe tu-owe--square' : 'tu-owe'}>
          <div className="tu-owe__text">
            <p className="text-label-lg">{head}</p>
            {!done && mine && <p className="text-heading-lg">{euros(mine.amount)}</p>}
            {sub && <p className={`text-body-sm ${done ? 'tu-pages__success' : 'tu-pages__muted'}`}>{sub}</p>}
          </div>
          {done
            ? <CircleCheck className="tu-owe__done" strokeWidth={2} absoluteStrokeWidth aria-label="Paid" />
            : mine && <TextButton label="Pay" onClick={() => pay(mine)} />}
        </div>
      )}
      {/* Tonight's dinner: an estimate until it's on, then the way to bring its bill in */}
      {!money.bill && dinnerOn ? (
        <div key="dinner-on" className="tu-dinner-on">
          <p className="text-body-sm tu-pages__muted tu-dinner-on__text">Dinner is on. When the bill comes, scan it: it splits by who had what.</p>
          <TextButton label="Scan the bill" icon={ScanLine} onClick={onScan} />
        </div>
      ) : !money.bill && DINNER_ESTIMATE > 0 ? (
        <p key="estimate" className="text-body-sm tu-pages__note">
          Tonight's dinner isn't on it yet: about {euros(DINNER_ESTIMATE)}, from what everyone picked. It splits by who had what.
        </p>
      ) : null}
      <div key="tabs" className="tu-money-tabs">
        <SegmentedTabs tabs={[...MONEY_TABS]} value={tab} onChange={t => setTab(t as MoneyTab)} />
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
                <MoneyNote>{pays.length} payments square everyone, instead of {money.paymentsOneByOne}</MoneyNote>
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
                <MoneyNote>Who gets money back, and who owes</MoneyNote>
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
                <MoneyNote>{money.expenses.length} expenses · {euros(money.spent)} · newest first</MoneyNote>
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

/** A short line under Money's tabs, about the list. */
function MoneyNote({ children }: { children: ReactNode }) {
  return <p className="text-body-sm tu-money-note">{children}</p>;
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

export const ADD_SUBTITLE = 'A plan, or someone new';
export type AddStep = 'choose' | 'plan' | 'invite';

export interface AddPageProps {
  /** The step it opens on (the choice, by default). */
  start?: AddStep;
  /** Shows what someone invited will see on their phone (Invite's "See what they'll see"). */
  onPreview?: () => void;
}

/**
 * Adding to the trip: a plan (a place to go, put in a free slot on everyone's itinerary and map) or someone new (a
 * link: no account, and they only share costs from the day they join; Invite can show what they'll see). A step
 * replaces the page: the old one fades out with a blur while the new one's blocks arrive.
 */
export function AddPage({ start = 'choose', onPreview }: AddPageProps) {
  const [step, setStep] = useState<AddStep>(start);
  const reduce = useReducedMotion();
  return (
    <div className="tu-add-steps">
      <AnimatePresence initial={false}>
        <motion.div
          key={step}
          className="tu-add-steps__step"
          exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
        >
          {step === 'choose' && <ChooseStep onPick={setStep} />}
          {step === 'plan' && <PlanStep onBack={() => setStep('choose')} />}
          {step === 'invite' && <InviteStep onBack={() => setStep('choose')} onPreview={onPreview} />}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

function ChooseStep({ onPick }: { onPick: (s: AddStep) => void }) {
  return (
    <StaggerIn gap="xs">
      <KnowRow key="plan" leading={<MapPinPlus className="tu-pages__lead" strokeWidth={2} absoluteStrokeWidth aria-hidden />} subtitle="A place to eat, see or do. It goes on everyone's itinerary and map." onClick={() => onPick('plan')}>
        Plan something
      </KnowRow>
      <KnowRow key="invite" leading={<UserPlus className="tu-pages__lead" strokeWidth={2} absoluteStrokeWidth aria-hidden />} subtitle="They join with a link, no account. They only share costs from the day they join." onClick={() => onPick('invite')}>
        Invite someone
      </KnowRow>
    </StaggerIn>
  );
}

function Back({ onClick }: { onClick: () => void }) {
  return (
    <button type="button" className="tu-back text-label-md weight-semibold" onClick={onClick}>
      <ChevronLeft className="tu-back__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
      Back
    </button>
  );
}

function PlanStep({ onBack }: { onBack: () => void }) {
  const toast = useTripNotice();
  const [added, setAdded] = useState<string[]>([]);
  return (
    <StaggerIn>
      <Back key="back" onClick={onBack} />
      <SheetSection key="title" title="Ideas nearby" top="md" subtitle="Each one goes in a free slot. Everyone sees it on their map." />
      {withHairlines(PLAN_IDEAS, idea => {
        const on = added.includes(idea.id);
        const t = tripDate(idea.day, idea.hour);
        const slot = `${dayName(t)}, ${clockTime(t)}`;
        return (
          <SheetRow
            key={idea.id}
            leading={<Slot><Sticker name={idea.sticker} size="row" /></Slot>}
            title={idea.name}
            subtitle={`${idea.kind} · ${slot}`}
            trailing={
              <AddButton
                added={on}
                itemName={idea.name}
                onToggle={() => {
                  setAdded(a => (on ? a.filter(id => id !== idea.id) : [...a, idea.id]));
                  if (!on) toast(`Added for ${slot}`);
                }}
              />
            }
          />
        );
      })}
    </StaggerIn>
  );
}

function InviteStep({ onBack, onPreview }: { onBack: () => void; onPreview?: () => void }) {
  const toast = useTripNotice();
  const copy = () => {
    // The story's frame may not be allowed the clipboard; the note shows either way, as in the app
    navigator.clipboard?.writeText(`https://${INVITE_LINK}`).catch(() => {});
    toast('Link copied');
  };
  return (
    <StaggerIn>
      <Back key="back" onClick={onBack} />
      <SheetSection key="title" title="Invite someone" top="md" subtitle="Send them this link. They type their name and they're in." />
      <div key="link" className="tu-link">
        <span className="text-label-lg tu-ellipsis tu-link__text">{INVITE_LINK}</span>
        <TextButton label="Copy link" icon={Copy} onClick={copy} />
      </div>
      <p key="note" className="text-body-sm tu-pages__note">
        No account needed. They see the trip so far, and only costs from the day they join are theirs: Ren joined today, so the €{SPENT_SO_FAR.toFixed(0)} from before stays with the four of you.
      </p>
      {/* A look at their phone: what someone invited will see (see Join.tsx) */}
      {onPreview && (
        <div key="preview" className="tu-invite-preview">
          <TextButton variant="soft" label="See what they'll see" onClick={onPreview} />
        </div>
      )}
    </StaggerIn>
  );
}
