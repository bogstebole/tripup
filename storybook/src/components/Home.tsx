// The first screen: your trips (Figma 258:12058). The app has the same in lib/components/home.dart; going into the
// trip, the trip's screen opens out of the top of it (see HomeLayer).
import { Bell } from 'lucide-react';
import { animate, motion, useMotionValue, useReducedMotion, useTransform } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  HOME_MAP_IMAGE, HOME_MAP_RECT, HOME_MAP_WIDTH, MY_ID, MY_NAME, onTrip, PAST_TRIPS, PEOPLE, personById, TRIP, TRIP_NOW, UPCOMING_TRIPS,
  type TripSummary,
} from '../data';
import { Button } from './Button';
import { useTripNotice } from './Notice';
import { ENTER_MS, TripEntrance } from './Entrance';
import { Sticker } from './Sticker';
import { StaggerIn } from './TripSheet';
import './Button.css';
import './Home.css';

const m = tokens.motion;

/** The trip's name, big, on up to two lines. A single word too long for a line shrinks to fit it instead of breaking
 *  (the app does the same). */
function TripName({ title }: { title: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const fit = () => {
      el.style.fontSize = '';
      const over = el.scrollWidth / el.clientWidth;
      if (over > 1) el.style.fontSize = `${parseFloat(getComputedStyle(el).fontSize) / over}px`;
    };
    fit();
    const watch = new ResizeObserver(fit);
    watch.observe(el.parentElement ?? el);
    return () => watch.disconnect();
  }, [title]);
  return <span ref={ref} className="text-display tu-home-face__title">{title}</span>;
}

export interface TripsHomeProps {
  /** Into the trip you're on: the top of the screen, or See trip details. */
  onOpen?: () => void;
  /** Now, in the trip (the demo's start, 3:56 PM, by default): who's on it. */
  now?: Date;
  /** Opens scrolled to the end, where the list fades into the blue (the app opens at the top). */
  scrolledToEnd?: boolean;
}

/** Your trips' parts, in the order they leave (and come back): each fades and moves a little on its own, stagger-ms
 *  apart. The blue leaves last and comes back first. */
const PART = { header: 0, title: 1, wayIn: 2, comingUp: 3, previous: 4, blue: 5 } as const;
const part = (i: number) => ({ className: 'tu-home-part', style: { '--i': i } as CSSProperties });

/**
 * Your trips, an overlay on the trip you're on: its map shows through the top (in the app the live map, with none of
 * the trip's pins, people or controls; here the still of it, see HomeLayer), with its name big in the middle, who's on
 * it and the way in (See trip details). Under it, on the brand blue rising over the map, the trip coming up and the
 * ones before, as soft cards. Tapping the trip goes into its map. The bell has nothing yet, and says so at the top.
 */
export function TripsHome({ onOpen, now = TRIP_NOW, scrolledToEnd }: TripsHomeProps) {
  const list = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (scrolledToEnd && list.current) list.current.scrollTop = list.current.scrollHeight;
  }, [scrolledToEnd]);
  return (
    <div className="tu-home">
      <div ref={list} className="tu-home__list">
        <StaggerIn>
          {/* The trip you're on, over its map; the blue rises over the map's lower part under it */}
          <div key="hero" className="tu-home-hero">
            <span {...part(PART.blue)} aria-hidden><span className="tu-home-hero__ground" /></span>
            <HomeHeroFace now={now} onOpen={onOpen} />
          </div>
          <div key="trips" className="tu-home__trips">
            <span {...part(PART.blue)} aria-hidden><span className="tu-home__blue" /></span>
            <Section part={PART.comingUp} title="Coming up" trips={UPCOMING_TRIPS} />
            <Section part={PART.previous} title="Previous trips" trips={PAST_TRIPS} count={PAST_TRIPS.length} />
          </div>
        </StaggerIn>
      </div>
      {/* The list fades into the blue at the bottom */}
      <span {...part(PART.blue)} aria-hidden><span className="tu-home__fade" /></span>
    </div>
  );
}

/** A heading in white (with a count, softer), then its cards. */
function Section({ title, trips, count, part: i }: { title: string; trips: TripSummary[]; count?: number; part: number }) {
  const p = part(i);
  return (
    <section className={`tu-home__section ${p.className}`} style={p.style}>
      <h2 className="text-heading-sm tu-home__heading">
        {title}
        {count != null && <span className="tu-home__count"> {count}</span>}
      </h2>
      {trips.map(trip => <TripRow key={trip.title} trip={trip} />)}
    </section>
  );
}

/** The map behind the top of Your trips: the still of Lisbon at the design's scale, centred, from the top of the screen
 *  down to where the blue covers it. Also what the trip opens out of, at the same place. */
export function HomeMapStill() {
  const r = HOME_MAP_RECT;
  return (
    <span className="tu-home-map" style={{ width: HOME_MAP_WIDTH, height: r.top + r.height }} aria-hidden>
      <img src={HOME_MAP_IMAGE} alt="" draggable={false} style={{ left: r.left, top: r.top, width: r.width, height: r.height }} />
    </span>
  );
}

/** The trip you're on, over its map: the header (Your trips, the bell and me), then in the middle its name, the city and
 *  dates, who's on it and See trip details. The whole of it goes in. */
function HomeHeroFace({ now = TRIP_NOW, onOpen }: { now?: Date; onOpen?: () => void }) {
  const notice = useTripNotice();
  const crew = PEOPLE.filter(p => onTrip(p, now));
  return (
    <div className="tu-home-face" onClick={onOpen}>
      <div className={`tu-home__head ${part(PART.header).className}`} style={part(PART.header).style}>
        <h1 className="text-heading-lg tu-ellipsis tu-home__title">Your trips</h1>
        <Button icon={Bell} label="Notifications" onClick={e => { e.stopPropagation(); if (onOpen) notice('No new notifications'); }} />
        {/* Me, in a soft glass circle the size of the bell */}
        <span className="tu-home__me" role="img" aria-label={MY_NAME}>
          <Sticker name={personById(MY_ID).sticker} size="avatar" />
        </span>
      </div>
      <div className="tu-home-face__middle">
        <div className={`tu-home-face__titles ${part(PART.title).className}`} style={part(PART.title).style}>
          <TripName title={TRIP.title} />
          <span className="text-label-md">{TRIP.city} · {TRIP.dates}</span>
        </div>
        <div className={`tu-home-face__way-in ${part(PART.wayIn).className}`} style={part(PART.wayIn).style}>
          {/* Everyone on it, standing on the button */}
          <span className="tu-home-face__faces">{crew.map(p => <Sticker key={p.id} name={p.sticker} className="tu-home-face__face" />)}</span>
          <button type="button" className="tu-btn tu-btn--primary tu-btn--text tu-btn--text-lg" onClick={e => { e.stopPropagation(); onOpen?.(); }}>
            <span className="tu-home-now__dot" />
            <span className="text-label-md weight-semibold">See trip details</span>
          </button>
        </div>
      </div>
    </div>
  );
}

/** Another trip, as a soft glass card on the blue: its sticker, name, dates, and who's going (or went). */
function TripRow({ trip }: { trip: TripSummary }) {
  return (
    <div className="tu-home-row">
      <span className="tu-home-row__sticker"><Sticker name={trip.sticker} /></span>
      <span className="tu-home-row__titles">
        <span className="text-body-lg weight-medium tu-ellipsis tu-home-row__title">{trip.title}</span>
        <span className="text-body-sm tu-ellipsis tu-home-row__dates">{trip.dates}</span>
      </span>
      <span className="tu-home-row__faces">
        {trip.faces.map(f => <Sticker key={f} name={f} size="avatar" />)}
      </span>
    </div>
  );
}

export interface HomeLayerProps extends TripsHomeProps {
  /** In the trip; false is on your trips. */
  inTrip: boolean;
  /** The trip's screen, under Your trips. */
  trip: ReactNode;
}

/**
 * Your trips as an overlay on the trip (the app's home layer). The trip's map is under it all the time; here it's the
 * still of Lisbon, since Storybook's trip screen has no map. Going in (See trip details), Your trips' parts leave
 * gently, top to bottom, fade-ms each, stagger-ms apart, rising a little; the blue last. At the same moment the map
 * zooms in on the trip (spring-open) and the trip's entrance runs (see Entrance.tsx): its controls arrive one by one
 * and Up next opens last; the still fades once the trip's own page is in (Storybook only). Back: the trip's controls go
 * at once (fade-ms), the map zooms back out (spring-collapse), and the parts come back top to bottom, the blue first.
 * Nothing takes taps while it moves. Reduced motion: the parts and the trip only fade.
 */
export function HomeLayer({ inTrip, trip, ...home }: HomeLayerProps) {
  const reduce = !!useReducedMotion();
  // The map's zoom: 0 framed for Your trips, 1 on the trip
  const zoom = useMotionValue(inTrip ? 1 : 0);
  // The trip's entrance clock: 0 on Your trips, 1 once every control is in
  const enter = useMotionValue(inTrip ? 1 : 0);
  const [moving, setMoving] = useState(false);
  const [back, setBack] = useState(false);
  const first = useRef(true);

  useLayoutEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    setMoving(true);
    setBack(!inTrip);
    const settle = window.setTimeout(() => setMoving(false), (inTrip ? ENTER_MS : m['fade-ms'] + m['stagger-ms'] * 5) + 60);
    if (reduce) {
      zoom.jump(inTrip ? 1 : 0);
      animate(enter, inTrip ? 1 : 0, { duration: m['fade-ms'] / 1000, ease: 'linear' });
    } else if (inTrip) {
      animate(zoom, 1, physical(m['spring-open']));
      enter.jump(0);
      animate(enter, 1, { duration: ENTER_MS / 1000, ease: 'linear' });
    } else {
      animate(zoom, 0, physical(m['spring-collapse']));
      animate(enter, 0, { duration: m['fade-ms'] / 1000, ease: 'linear' });
    }
    return () => window.clearTimeout(settle);
  }, [inTrip, reduce, zoom, enter]);
  useEffect(() => () => { zoom.stop(); enter.stop(); }, [zoom, enter]);

  // The still zooms in on the trip (twice as close: one zoom level, as in the app) and gives way to the trip's page
  // once its controls are in
  const stillTransform = useTransform(() => `scale(${1 + zoom.get()})`);
  const stillOpacity = useTransform(() => 1 - Math.min(1, Math.max(0, (enter.get() - 0.5) / 0.5)));
  return (
    <div style={{ position: 'absolute', inset: 0, background: 'var(--color-bg-canvas)', overflow: 'hidden' }}>
      <motion.div className="tu-home-layer__map" style={{ transform: stillTransform, opacity: stillOpacity }}>
        <HomeMapStill />
      </motion.div>
      <div style={{ position: 'absolute', inset: 0, pointerEvents: inTrip && !moving ? undefined : 'none' }}>
        <TripEntrance clock={enter}>{trip}</TripEntrance>
      </div>
      <div
        className="tu-home-layer__home"
        data-gone={inTrip || undefined}
        data-back={back || undefined}
        style={{ visibility: inTrip && !moving ? 'hidden' : undefined, pointerEvents: inTrip || moving ? 'none' : undefined }}
      >
        <TripsHome {...home} />
      </div>
    </div>
  );
}

/** A spring token as the app runs it (Flutter's SpringDescription.withDurationAndBounce: the duration is the perceived
 *  one), so the map keeps time with the entrance's clock as it does on the phone. */
const physical = ({ duration, bounce }: { duration: number; bounce: number }) =>
  ({ type: 'spring' as const, mass: 1, stiffness: (2 * Math.PI / duration) ** 2, damping: (4 * Math.PI * (1 - bounce)) / duration, restDelta: 0.0005, restSpeed: 0.005 });
