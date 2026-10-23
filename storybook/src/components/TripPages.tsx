// The pages of the footer's three pop-ups: the itinerary, the group's money, and adding to the trip. Each goes inside
// a TripSheet, which scrolls it and shows its toasts.
import { ArrowRight, Check, ChevronLeft, CircleCheck, Copy, MapPinPlus, UserPlus } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useState, type ReactElement } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  balanceOf, clockTime, dayName, DINNER_ESTIMATE, euros, EXPENSES, INVITE_LINK, MY_ID, PAYMENTS_ONE_BY_ONE, PEOPLE, personById,
  PLAN_IDEAS, planStart, PLANS, SETTLE_UP, shareOf, SPENT_SO_FAR, timeUntil, TODAY, tripDate, TRIP_DAYS, TRIP_NOW, VISITED,
} from '../data';
import { AddButton } from './AddButton';
import { TextButton } from './Button';
import { KnowRow } from './KnowSection';
import { Sticker } from './Sticker';
import { Hairline, SheetRow, SheetSection, Slot, StaggerIn, useSheetToast } from './TripSheet';
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

/**
 * Every day of the trip, in order: where we've been, what's planned, and today marked. It opens on today. Tapping a
 * stop shows it on the map (the pop-up closes and the map flies there).
 */
export function ItineraryPage({ onPick }: { onPick?: (place: string) => void }) {
  const next = PLANS.find(p => planStart(p) > TRIP_NOW);
  return (
    <StaggerIn>
      {TRIP_DAYS.map(({ day, label }, i) => {
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
          ...PLANS.filter(p => p.day === day).map(p => (
            <SheetRow
              key={p.id}
              leading={<Slot><Sticker name={p.sticker} size="row" /></Slot>}
              title={p.name}
              subtitle={p === next ? `Up next · ${timeUntil(planStart(p))}` : timeUntil(planStart(p))}
              tone={p === next ? 'brand' : undefined}
              trailing={<span className="text-label-md weight-semibold tu-pages__strong">{clockTime(planStart(p))}</span>}
              onClick={onPick && (() => onPick(p.name))}
            />
          )),
        ];
        return (
          <div key={day} data-sheet-focus={day === TODAY || undefined}>
            <div className={i ? 'tu-day' : 'tu-day tu-day--first'}>
              <h3 className={`text-heading-sm ${day < TODAY ? 'tu-pages__muted' : 'tu-pages__strong'}`}>{label}</h3>
              <span className="text-body-sm tu-pages__muted">Day {i + 1}</span>
              {day === TODAY && <span className="tu-tag text-label-md weight-semibold">Today</span>}
            </div>
            {rows.length ? rows.flatMap((r, j) => (j ? [<Hairline key={`line-${j}`} />, r] : [r])) : <p className="text-body-sm tu-day__empty">Nothing planned yet</p>}
          </div>
        );
      })}
    </StaggerIn>
  );
}

// ---------- Money

/** "€726.00 spent so far · 3 expenses". */
export const MONEY_SUBTITLE = `${euros(SPENT_SO_FAR)} spent so far · ${EXPENSES.length} expenses`;

/**
 * The group's money: what I owe (and paying it), what's been spent, the fewest payments that square everyone up,
 * each person's balance, and the expenses. Tonight's dinner joins once the bill comes; until then it's an estimate.
 * In the prototype only my payment can be made from here.
 */
export function MoneyPage() {
  const toast = useSheetToast();
  const [paid, setPaid] = useState(false);
  const mine = SETTLE_UP.find(p => p.from === MY_ID);
  const balance = (id: string) => balanceOf(id) + (paid && mine ? (id === MY_ID ? mine.amount : id === mine.to ? -mine.amount : 0) : 0);
  const joinedLate = (joined: number) => joined > TRIP_DAYS[0].day;
  return (
    <StaggerIn>
      {mine && (
        <div key="mine" className="tu-owe">
          <div className="tu-owe__text">
            <p className="text-label-lg">{paid ? `You're square with ${name(mine.to)}` : `You owe ${name(mine.to)}`}</p>
            <p className={paid ? 'text-body-sm tu-pages__success' : 'text-heading-lg'}>{paid ? `Paid ${euros(mine.amount)}` : euros(mine.amount)}</p>
          </div>
          {paid
            ? <CircleCheck className="tu-owe__done" strokeWidth={2} absoluteStrokeWidth aria-label="Paid" />
            : <TextButton label="Pay" onClick={() => { setPaid(true); toast(`Paid ${name(mine.to)} ${euros(mine.amount)}`); }} />}
        </div>
      )}
      {DINNER_ESTIMATE > 0 && (
        <p key="estimate" className="text-body-sm tu-pages__note">
          Tonight's dinner isn't on it yet: about {euros(DINNER_ESTIMATE)}, from what everyone picked. It splits by who had what.
        </p>
      )}
      <SheetSection key="settle" title="Settle up" subtitle={`${SETTLE_UP.length} payments square everyone, instead of ${PAYMENTS_ONE_BY_ONE}`} />
      {withHairlines(SETTLE_UP, p => (
        <SheetRow
          key={`pay-${p.from}`}
          leading={<span className="tu-pay">{face(p.from)}<ArrowRight className="tu-pay__arrow" strokeWidth={2} absoluteStrokeWidth aria-hidden />{face(p.to)}</span>}
          title={p.from === MY_ID ? `You pay ${name(p.to)}` : `${name(p.from)} pays ${name(p.to)}`}
          subtitle={p === mine && paid ? 'Paid' : 'Pending'}
          tone={p === mine && paid ? 'success' : undefined}
          trailing={<span className="text-label-lg tu-pages__strong">{euros(p.amount)}</span>}
        />
      ))}
      <SheetSection key="balances" title="Balances" />
      {withHairlines(PEOPLE, x => {
        const b = balance(x.id);
        return (
          <SheetRow
            key={`balance-${x.id}`}
            leading={face(x.id)}
            title={x.name}
            subtitle={b > 0.005 ? 'Gets back'
              : b < -0.005 ? (x.id === MY_ID ? 'You owe' : 'Owes')
              : joinedLate(x.joined) ? `Joined ${dayName(tripDate(x.joined)).toLowerCase()} · shares costs from then on`
              : 'Square'}
            trailing={Math.abs(b) > 0.005 ? <span className={`text-label-lg ${b > 0 ? 'tu-pages__success' : 'tu-pages__strong'}`}>{euros(Math.abs(b))}</span> : undefined}
          />
        );
      })}
      <SheetSection key="expenses" title="Expenses" subtitle="Newest first" />
      {withHairlines(EXPENSES, e => (
        <SheetRow
          key={`expense-${e.title}`}
          leading={face(e.paidBy)}
          title={e.title}
          subtitle={`${e.paidBy === MY_ID ? 'You' : name(e.paidBy)} paid · ${dayName(tripDate(e.day))} · ${e.split.length} people`}
          trailing={
            <span className="tu-amount">
              <span className="text-label-lg tu-pages__strong">{euros(e.amount)}</span>
              {e.split.includes(MY_ID) && <span className="text-body-sm tu-pages__muted">yours {euros(shareOf(e, MY_ID))}</span>}
            </span>
          }
        />
      ))}
    </StaggerIn>
  );
}

// ---------- Add

export const ADD_SUBTITLE = 'A plan, or someone new';
export type AddStep = 'choose' | 'plan' | 'invite';

/**
 * Adding to the trip: a plan (a place to go, put in a free slot on everyone's itinerary and map) or someone new (a
 * link: no account, and they only share costs from the day they join). A step replaces the page: the old one fades
 * out with a blur while the new one's blocks arrive.
 */
export function AddPage({ start = 'choose' }: { start?: AddStep }) {
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
          {step === 'invite' && <InviteStep onBack={() => setStep('choose')} />}
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
  const toast = useSheetToast();
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

function InviteStep({ onBack }: { onBack: () => void }) {
  const toast = useSheetToast();
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
    </StaggerIn>
  );
}
