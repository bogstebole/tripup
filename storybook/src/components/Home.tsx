// The first screen: your trips (Figma 75:5927). The app has the same in lib/components/home.dart; it sits over the
// trip's screen and zooms past as you go into the trip (see HomeLayer).
import { ArrowRight, Bell } from 'lucide-react';
import { motion, useReducedMotion } from 'motion/react';
import { useLayoutEffect, useRef, type CSSProperties } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  HOME_MAP_FRAME, HOME_MAP_IMAGE, HOME_MAP_IMAGE_RECT, HOME_MAP_STICKERS, MY_ID, MY_NAME, onTrip, PAST_TRIPS, PEOPLE, personById, TRIP,
  TRIP_NOW, UPCOMING_TRIPS, type TripSummary,
} from '../data';
import { Button } from './Button';
import { useTripNotice } from './Notice';
import { Sticker } from './Sticker';
import { StaggerIn } from './TripSheet';
import './Button.css';
import './Home.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
// Full transform strings, so Motion runs them on the compositor
const zoomed = `scale(${m['page-zoom-scale']})`, settled = 'scale(1)';

export interface TripsHomeProps {
  /** Into the trip you're on: its card (or the arrow on it). */
  onOpen?: () => void;
  /** Now, in the trip (the demo's start, 3:56 PM, by default): who's on it. */
  now?: Date;
  /** Opens scrolled to the end, where the list fades into the blue (the app opens at the top). */
  scrolledToEnd?: boolean;
}

/**
 * Your trips, on the brand blue. The one you're on is a big card: a still of the city with places you've been as
 * stickers, "Happening now", its name and dates, who's on it, and the way in. Under it, the trip coming up and the
 * ones before, as rows. Tapping the current one goes into its map. The bell has nothing yet, and says so at the top.
 */
export function TripsHome({ onOpen, now = TRIP_NOW, scrolledToEnd }: TripsHomeProps) {
  const notice = useTripNotice();
  const list = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (scrolledToEnd && list.current) list.current.scrollTop = list.current.scrollHeight;
  }, [scrolledToEnd]);
  return (
    <div className="tu-home">
      <div ref={list} className="tu-home__list">
        <StaggerIn>
          <div key="top" className="tu-home__top">
            <div className="tu-home__head">
              <h1 className="text-heading-lg tu-ellipsis tu-home__title">Your trips</h1>
              <Button icon={Bell} label="Notifications" onClick={() => notice('No new notifications')} />
              {/* Me, in a soft glass circle the size of the bell */}
              <span className="tu-home__me" role="img" aria-label={MY_NAME}>
                <Sticker name={personById(MY_ID).sticker} size="avatar" />
              </span>
            </div>
            <CurrentTrip now={now} onOpen={onOpen} />
          </div>
          {/* xl between the card and the rows (a step of the stagger too, as in the app) */}
          <div key="gap" className="tu-home__gap" />
          <Section key="coming" title="Coming up" trips={UPCOMING_TRIPS} />
          <Section key="past" title="Previous trips" trips={PAST_TRIPS} count={PAST_TRIPS.length} />
        </StaggerIn>
      </div>
      {/* The list fades into the blue at the bottom */}
      <div className="tu-home__fade" aria-hidden />
    </div>
  );
}

/** A heading in white (with a count, softer), then its rows. */
function Section({ title, trips, count }: { title: string; trips: TripSummary[]; count?: number }) {
  return (
    <section className="tu-home__section">
      <h2 className="text-heading-sm tu-home__heading">
        {title}
        {count != null && <span className="tu-home__count"> {count}</span>}
      </h2>
      {trips.map(trip => <TripRow key={trip.title} trip={trip} />)}
    </section>
  );
}

/**
 * The trip you're on: the city's still with stickers, fading to white at the bottom, where its name, dates, who's on
 * it and the way in sit. The whole card goes in, the arrow too.
 */
function CurrentTrip({ now, onOpen }: { now: Date; onOpen?: () => void }) {
  const crew = PEOPLE.filter(p => onTrip(p, now));
  return (
    <button type="button" className="tu-home-card" aria-label={`Open ${TRIP.title}`} onClick={onOpen}>
      {/* The city, scaled to fill the card, then white rising from the bottom so the text reads */}
      <HomeMap />
      <span className="tu-home-card__fade" />
      <span className="tu-home-card__body">
        <span className="tu-home-card__now"><HappeningNow /></span>
        <span className="tu-home-card__titles">
          <span className="text-heading-xl tu-ellipsis tu-home-card__title">{TRIP.title}</span>
          <span className="text-label-md tu-home-card__dates">{TRIP.city} · {TRIP.dates}</span>
        </span>
        <span className="tu-home-card__crew">
          <span className="tu-home-card__faces">{crew.map(p => <Sticker key={p.id} name={p.sticker} className="tu-home-card__face" />)}</span>
          {/* The app's forward button. The card is already the one button (no button inside a button), so here the arrow
              only shows where it goes, and a press on it presses the card */}
          <span className="tu-btn tu-btn--primary tu-btn--md tu-home-card__go" aria-hidden>
            <ArrowRight className="tu-btn__icon" strokeWidth={2} absoluteStrokeWidth />
          </span>
        </span>
      </span>
    </button>
  );
}

/** A length in the design's frame as a share of the frame, so everything on it scales with it. */
const share = (v: number, of: number) => `${(v / of) * 100}%`;

/** The still of the city with its stickers, in the design's frame (HOME_MAP_FRAME); the card scales the frame to cover
 *  it from the top, like the app's FittedBox (cover, top centre). */
function HomeMap() {
  const { width: w, height: h } = HOME_MAP_FRAME;
  const r = HOME_MAP_IMAGE_RECT;
  return (
    <span className="tu-home-card__map" style={{ '--frame-w': w, '--frame-h': h } as CSSProperties}>
      <img
        className="tu-home-card__city"
        src={HOME_MAP_IMAGE}
        alt=""
        draggable={false}
        style={{ left: share(r.left, w), top: share(r.top, h), width: share(r.width, w), height: share(r.height, h) }}
      />
      {/* Each place on its centre */}
      {HOME_MAP_STICKERS.map(s => (
        <Sticker
          key={s.sticker}
          name={s.sticker}
          tilt={s.tilt}
          className="tu-home-card__place"
          style={{ left: share(s.x, w), top: share(s.y, h), height: share(s.height, h) }}
        />
      ))}
    </span>
  );
}

/** "Happening now": the trip is on. A small soft glass pill with a green bead. */
function HappeningNow() {
  return (
    <span className="tu-home-now">
      <span className="tu-home-now__dot" />
      <span className="text-label-md">Happening now</span>
    </span>
  );
}

/** Another trip, as a light row on the blue: its sticker, name, dates, and who's going (or went). */
function TripRow({ trip }: { trip: TripSummary }) {
  return (
    <div className="tu-home-row">
      <span className="tu-home-row__sticker"><Sticker name={trip.sticker} /></span>
      <span className="tu-home-row__titles">
        <span className="text-body-lg weight-medium tu-ellipsis tu-home-row__title">{trip.title}</span>
        <span className="text-body-sm tu-ellipsis tu-home-row__dates">{trip.dates}</span>
      </span>
      {/* The faces sit on the row's bottom edge */}
      <span className="tu-home-row__faces">
        {trip.faces.map((f, i) => <Sticker key={f} name={f} size="avatar" tilt={trip.faceTilts?.[i] ?? 0} />)}
      </span>
    </div>
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
