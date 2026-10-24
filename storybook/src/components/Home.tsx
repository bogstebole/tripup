// The first screen: your trips. The app has the same in lib/components/home.dart; it sits over the trip's screen and
// zooms past as you go into the trip (see HomeLayer).
import { ArrowRight, ChevronUp } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  EVENT, euros, isActive, isPaid, MY_ID, onTrip, PAST_TRIPS, PEOPLE, personById, planStart, plansAhead, pollOpen, PRE_DINNER, startsAt,
  TRIP, TRIP_NOW, UPCOMING_TRIPS, VISITED, type Money, type Payment, type PollState, type TripSummary,
} from '../data';
import { Sticker } from './Sticker';
import { ITINERARY_SUBTITLE } from './TripPages';
import { Hairline, SheetRow, SheetSection, Slot, StaggerIn } from './TripSheet';
import './Button.css';
import './Surface.css';
import './Home.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
// Full transform strings, so Motion runs them on the compositor
const zoomed = `scale(${m['page-zoom-scale']})`, settled = 'scale(1)';

export interface TripsHomeProps {
  /** Into the trip you're on: its card (or the arrow on it). */
  onOpen?: () => void;
  /** Now, in the trip (the demo's start, 3:56 PM, by default): what's on, and who's on it. */
  now?: Date;
  /** The dinner poll as it stands (nobody has voted here by default). */
  poll?: PollState;
  /** The money, and the payments made so far: what I owe, until I've paid it. */
  money?: Money;
  made?: Payment[];
  /** Starts with the past trips unfolded (the app starts with them folded). */
  pastOpen?: boolean;
  /** The demo's clock and moments, top right (not part of the product; the stories leave it out). */
  demo?: ReactNode;
}

/**
 * Your trips. The one you're on sits on top, big: what's happening on it now, who's on it, and what you owe. The ones
 * coming up are under it; past ones are folded away (they're done and settled), and a tap on "Past trips" unfolds
 * them (enter-ms, ease-out; the chevron turns with it). Tapping the current one goes into its map.
 */
export function TripsHome({ onOpen, now = TRIP_NOW, poll = {}, money = PRE_DINNER, made = [], pastOpen: startOpen = false, demo }: TripsHomeProps) {
  const [pastOpen, setPastOpen] = useState(startOpen);
  const reduce = useReducedMotion();
  return (
    <div className="tu-home">
      <div className="tu-home__head">
        <h1 className="text-heading-lg tu-home__title">Your trips</h1>
        {demo}
      </div>
      <StaggerIn>
        <CurrentTrip key="current" now={now} poll={poll} money={money} made={made} onOpen={onOpen} />
        <SheetSection key="coming" title="Coming up" />
        {UPCOMING_TRIPS.map(trip => <TripRow key={trip.title} trip={trip} />)}
        {/* Past trips, folded away until asked for */}
        <button
          key="past"
          type="button"
          className="tu-home__past"
          aria-expanded={pastOpen}
          aria-label={pastOpen ? 'Hide past trips' : 'Show past trips'}
          onClick={() => setPastOpen(o => !o)}
        >
          <span className="text-heading-sm">Past trips</span>
          <span className="text-body-sm tu-home__muted">{PAST_TRIPS.length}</span>
          <ChevronUp className="tu-home__chevron" data-open={pastOpen || undefined} strokeWidth={2} absoluteStrokeWidth aria-hidden />
        </button>
        <AnimatePresence key="past-trips" initial={false}>
          {pastOpen && (
            <motion.div
              key="past-trips"
              className="tu-home__fold"
              initial={reduce ? { opacity: 0 } : { height: 0 }}
              animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 'auto', transition: { duration: m['enter-ms'] / 1000, ease } }}
              exit={reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 0, transition: { duration: m['enter-ms'] / 1000, ease } }}
            >
              {PAST_TRIPS.flatMap((trip, i) => (i ? [<Hairline key={`line-${i}`} />, <TripRow key={trip.title} trip={trip} />] : [<TripRow key={trip.title} trip={trip} />]))}
            </motion.div>
          )}
        </AnimatePresence>
      </StaggerIn>
    </div>
  );
}

/**
 * The trip you're on: where we've been (stickers), its name and where, the day it's on, what's on right now (brand),
 * who's on it (their faces) and what I owe ("N on this trip" once I've paid). The whole card goes in.
 */
function CurrentTrip({ now, poll, money, made, onOpen }: Required<Pick<TripsHomeProps, 'now' | 'poll' | 'money' | 'made'>> & { onOpen?: () => void }) {
  const next = plansAhead(now, poll)[0];
  // What's on right now, the way you'd say it
  const status = pollOpen(now, poll)
    ? 'Poll open: where for dinner tonight?'
    : isActive(now)
      ? `Now: dinner at ${EVENT.name.split(' - ')[0]}`
      : !next
        ? 'Nothing planned'
        : `Up next: ${next.name.split(' - ')[0]}, ${startsAt(planStart(next), now)}`;
  const crew = PEOPLE.filter(p => onTrip(p, now));
  const mine = money.settleUp.find(p => p.from === MY_ID && !isPaid(p, made));
  return (
    <button type="button" className="tu-home-card tu-surface tu-surface--sheet" aria-label={`Open ${TRIP.title}`} onClick={onOpen}>
      {/* Where we've been so far, as stickers */}
      <span className="tu-home-card__stickers">
        {VISITED.slice(0, 5).map(v => <Sticker key={v.name} name={v.sticker} size="row" tilt={v.tilt} />)}
      </span>
      <span className="tu-home-card__titles">
        <span className="text-heading-md tu-ellipsis tu-home-card__title">{TRIP.title}</span>
        <span className="text-body-sm tu-home__muted">Lisbon · {ITINERARY_SUBTITLE}</span>
      </span>
      <span className="text-label-md weight-semibold tu-home-card__status">{status}</span>
      <span className="tu-home-card__crew">
        <span className="tu-home__faces">{crew.map(p => <Sticker key={p.id} name={p.sticker} size="chip" />)}</span>
        <span className="text-body-sm tu-ellipsis tu-home__muted tu-home-card__owe">
          {mine ? `You owe ${personById(mine.to).name} ${euros(mine.amount)}` : `${crew.length} on this trip`}
        </span>
        {/* The app's forward button. The card is already the one button (no button inside a button), so here the arrow
            only shows where it goes, and a press on it presses the card */}
        <span className="tu-btn tu-btn--primary tu-btn--sm tu-home-card__go" aria-hidden>
          <ArrowRight className="tu-btn__icon" strokeWidth={2} absoluteStrokeWidth />
        </span>
      </span>
    </button>
  );
}

/** Another trip, as a line: its sticker, name, when, a word about it, and who. */
function TripRow({ trip }: { trip: TripSummary }) {
  return (
    <SheetRow
      leading={<Slot><Sticker name={trip.sticker} size="row" /></Slot>}
      title={trip.title}
      subtitle={`${trip.dates} · ${trip.note}`}
      trailing={<span className="tu-home__faces">{trip.faces.map(f => <Sticker key={f} name={f} size="chip" />)}</span>}
    />
  );
}

/**
 * Your trips over the trip's screen (the app's home layer), which is under them all along. Going into the trip they
 * zoom past you (to page-zoom-scale) and fade, quickly, as an exit (fade-ms, ease-out); the trip's Back brings them
 * back, settling from that same zoom (enter-ms, ease-out). Reduced motion: fades only. Put it in AnimatePresence
 * (`initial={false}`, so the screen opens on it).
 */
export function HomeLayer(props: TripsHomeProps) {
  const reduce = useReducedMotion();
  const away = reduce ? { opacity: 0 } : { opacity: 0, transform: zoomed };
  return (
    <motion.div
      style={{ position: 'absolute', inset: 0 }}
      initial={away}
      animate={{ ...(reduce ? { opacity: 1 } : { opacity: 1, transform: settled }), transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={{ ...away, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      <TripsHome {...props} />
    </motion.div>
  );
}
