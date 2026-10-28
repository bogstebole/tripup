// The first screen: your trips (Figma 258:12058). The app has the same in lib/components/home.dart; going into the
// trip, the trip's screen opens out of the top of it (see HomeLayer).
import { Bell } from 'lucide-react';
import { animate, motion, useMotionValue, useReducedMotion, useTransform } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type ReactNode, type Ref } from 'react';
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
 *  (the app does the same; the demo's trip is one 26-letter word). */
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
  /** On the trip you're on (the top of the screen), so the trip can open out of it. */
  cardRef?: Ref<HTMLDivElement>;
}

/**
 * Your trips. The one you're on fills the top of the screen: its city's map, its name big in the middle, who's on it
 * and the way in (See trip details). Under it, on the brand blue rising over the map, the trip coming up and the ones
 * before, as soft cards. Tapping the trip goes into its map. The bell has nothing yet, and says so at the top.
 */
export function TripsHome({ onOpen, now = TRIP_NOW, scrolledToEnd, cardRef }: TripsHomeProps) {
  const list = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (scrolledToEnd && list.current) list.current.scrollTop = list.current.scrollHeight;
  }, [scrolledToEnd]);
  return (
    <div className="tu-home">
      <div ref={list} className="tu-home__list">
        <StaggerIn>
          {/* The trip you're on, over its map; the blue rises over the map's lower part under it */}
          <div key="hero" ref={cardRef} className="tu-home-hero">
            <HomeMapStill />
            <span className="tu-home-hero__ground" aria-hidden />
            <HomeHeroFace now={now} onOpen={onOpen} />
          </div>
          <Section key="coming" title="Coming up" trips={UPCOMING_TRIPS} />
          <Section key="past" title="Previous trips" trips={PAST_TRIPS} count={PAST_TRIPS.length} />
        </StaggerIn>
      </div>
      {/* The list fades into the blue at the bottom */}
      <div className="tu-home__fade" aria-hidden />
    </div>
  );
}

/** A heading in white (with a count, softer), then its cards. */
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
 *  dates, who's on it and See trip details. The whole of it goes in. Without `onOpen` (in the opening trip, where it
 *  fades away) nothing in it takes a press. */
export function HomeHeroFace({ now = TRIP_NOW, onOpen }: { now?: Date; onOpen?: () => void }) {
  const notice = useTripNotice();
  const crew = PEOPLE.filter(p => onTrip(p, now));
  return (
    <div className="tu-home-face" onClick={onOpen}>
      <div className="tu-home__head">
        <h1 className="text-heading-lg tu-ellipsis tu-home__title">Your trips</h1>
        <Button icon={Bell} label="Notifications" onClick={e => { e.stopPropagation(); if (onOpen) notice('No new notifications'); }} />
        {/* Me, in a soft glass circle the size of the bell */}
        <span className="tu-home__me" role="img" aria-label={MY_NAME}>
          <Sticker name={personById(MY_ID).sticker} size="avatar" />
        </span>
      </div>
      <div className="tu-home-face__middle">
        <div className="tu-home-face__titles">
          <TripName title={TRIP.title} />
          <span className="text-label-md">{TRIP.city} · {TRIP.dates}</span>
        </div>
        <div className="tu-home-face__way-in">
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

type Box = { left: number; top: number; width: number; height: number };
/** The screen's box, and the trip's place in it (the top of Your trips), taken as a transition starts. */
type Frame = { screen: Box; card?: Box };

/** 0 up to `a`, 1 from `b`, eased in and out between (the app's smoothstep). */
const smoothstep = (a: number, b: number, v: number) => {
  const x = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return x * x * (3 - 2 * x);
};
const mix = (a: number, b: number, k: number) => a + (b - a) * k;

/** A spring token as the app runs it (Flutter's SpringDescription.withDurationAndBounce: the duration is the perceived
 *  one), so the surface keeps time with the entrance's clock as it does on the phone. */
const physical = ({ duration, bounce }: { duration: number; bounce: number }) =>
  ({ type: 'spring' as const, mass: 1, stiffness: (2 * Math.PI / duration) ** 2, damping: (4 * Math.PI * (1 - bounce)) / duration, restDelta: 0.0005, restSpeed: 0.005 });

/** The screen's box, and the trip's place in it as laid out (as far as the list is scrolled). */
function measure(screen: HTMLElement | null, card: HTMLElement | null): Frame {
  const box = { left: 0, top: 0, width: screen?.offsetWidth ?? 0, height: screen?.offsetHeight ?? 0 };
  if (!screen || !card) return { screen: box };
  const s = screen.getBoundingClientRect(), c = card.getBoundingClientRect();
  const x = c.left + c.width / 2 - s.left, y = c.top + c.height / 2 - s.top;
  return { screen: box, card: { left: x - card.offsetWidth / 2, top: y - card.offsetHeight / 2, width: card.offsetWidth, height: card.offsetHeight } };
}

export interface HomeLayerProps extends Omit<TripsHomeProps, 'cardRef'> {
  /** In the trip; false is on your trips. */
  inTrip: boolean;
  /** The trip's screen, which opens out of the top of Your trips. */
  trip: ReactNode;
}

/**
 * Your trips, and the trip's screen over them (the app's home layer and its opening trip), with one spring between.
 * Going in, the trip opens out of the top of Your trips, where it sits over its map: your trips stay put and blur and
 * wash out (bg/default at 60% and the sheet's backdrop blur, over the first 60% of the way), and one surface grows from
 * the trip's part of the screen down to the whole of it, lifted by a shadow (elevation-overlay) while it grows. It
 * starts as that part: the map stays where it was and more of it shows as the surface grows, on the map's own grey
 * below (bg/canvas), and the trip's words (HomeHeroFace, where they were) leave over the first quarter. The live trip
 * fades in over 45–85% of the way, blurred a little while it and the still both show (up to crossfade-blur × 4 × live
 * × (1 − live)). Opening is on spring-open (no bounce: a full-screen container shouldn't wobble); the trip's Back runs
 * it in reverse, quicker (spring-collapse). Nothing takes taps while it moves. Reduced motion: the trip only fades
 * (fade-ms) while the list blurs and washes out. Whichever isn't showing isn't drawn, and keeps its place (the list its
 * scroll).
 *
 * The trip's entrance runs from the tap (see Entrance.tsx): its controls arrive one by one and Up next opens last. On
 * your trips its clock waits at 0, so the next way in starts it over; with reduced motion it's at 1 at once.
 */
export function HomeLayer({ inTrip, trip, ...home }: HomeLayerProps) {
  const reduce = !!useReducedMotion();
  // 1 on your trips, 0 in the trip
  const t = useMotionValue(inTrip ? 0 : 1);
  // The trip's entrance clock: 0 at the tap, 1 once every control is in
  const enter = useMotionValue(inTrip ? 1 : 0);
  const frame = useMotionValue<Frame>({ screen: { left: 0, top: 0, width: 0, height: 0 } });
  const [moving, setMoving] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null), cardRef = useRef<HTMLDivElement>(null);

  // In or back: the trip's place is taken first (before the first frame), then the spring runs from wherever it is
  useLayoutEffect(() => {
    const to = inTrip ? 0 : 1;
    if (t.get() === to && !t.isAnimating()) return;
    frame.set(measure(rootRef.current, cardRef.current));
    setMoving(true);
    const done = () => {
      setMoving(false);
      // Back on your trips, the entrance waits for the next way in (Up next small again, unseen)
      if (!inTrip) enter.jump(0);
    };
    if (reduce) animate(t, to, { duration: m['fade-ms'] / 1000, ease: 'linear', onComplete: done });
    else animate(t, to, { ...physical(inTrip ? m['spring-open'] : m['spring-collapse']), onComplete: done });
    // Going in, the entrance's clock runs from the tap; with reduced motion it's all in, and fades in with the trip
    if (inTrip && reduce) enter.jump(1);
    else if (inTrip) {
      enter.jump(0);
      animate(enter, 1, { duration: ENTER_MS / 1000, ease: 'linear' });
    }
  }, [inTrip, reduce, t, enter, frame]);
  useEffect(() => () => { t.stop(); enter.stop(); }, [t, enter]);

  const onHome = !moving && !inTrip, inTheTrip = !moving && inTrip;
  // 0 on the list, 1 in the trip
  const p = () => Math.min(1, Math.max(0, 1 - t.get()));
  // The surface is growing: not at rest in the trip, and not with reduced motion
  const air = !inTheTrip && !reduce;
  // The surface's box: from the trip's place (the screen's, if there's none) to the screen's
  const box = (): Box => {
    const { screen, card = screen } = frame.get(), k = p();
    if (!air) return screen;
    return { left: mix(card.left, screen.left, k), top: mix(card.top, screen.top, k), width: mix(card.width, screen.width, k), height: mix(card.height, screen.height, k) };
  };
  const left = useTransform(() => box().left), top = useTransform(() => box().top);
  const width = useTransform(() => box().width), height = useTransform(() => box().height);
  // What shows when: the trip's words leave first, the live trip arrives near full size
  const live = () => (inTheTrip ? 1 : reduce ? p() : smoothstep(0.45, 0.85, p()));
  const behind = () => (inTheTrip ? 0 : smoothstep(0, 0.6, p()));

  // Your trips: blurred and washed out behind the surface
  const washBlur = useTransform(() => (behind() > 0.01 ? `blur(calc(2.5px * ${behind()}))` : 'none'));
  const washOpacity = useTransform(behind);
  // The surface's lift
  const lift = useTransform(() => (air && p() < 1 ? 'var(--shadow-elevation-overlay)' : 'none'));
  // Everything on the surface is clipped to it; in the trip, none of it applies
  const clip = useTransform(() => {
    const { screen } = frame.get(), r = box();
    if (!air || p() >= 1) return 'none';
    return `inset(${r.top}px ${screen.width - r.left - r.width}px ${screen.height - r.top - r.height}px ${r.left}px)`;
  });
  const stillOpacity = useTransform(() => (air ? 1 : 0));
  const cardTop = useTransform(() => (frame.get().card ?? frame.get().screen).top);
  const wordsOpacity = useTransform(() => (air ? 1 - smoothstep(0, 0.25, p()) : 0));
  const cardWidth = useTransform(() => (frame.get().card ?? frame.get().screen).width);
  const cardHeight = useTransform(() => (frame.get().card ?? frame.get().screen).height);
  // The live trip, at its own size, scaled to the surface's width from its top
  const tripOpacity = useTransform(live);
  const tripFilter = useTransform(() => {
    const v = live(), seam = air ? m['crossfade-blur'] * 4 * v * (1 - v) : 0;
    return seam >= 0.05 ? `blur(${seam}px)` : 'none';
  });
  const tripTransform = useTransform(() => {
    const { screen } = frame.get(), r = box();
    if (!air || p() >= 1 || !screen.width) return 'none';
    const s = r.width / screen.width;
    return `translate(${r.left}px, ${r.top}px) scale(${s})`;
  });

  const surface = { position: 'absolute' as const, left, top, width, height, pointerEvents: 'none' as const };
  return (
    <div ref={rootRef} style={{ position: 'absolute', inset: 0 }}>
      {/* Your trips don't move */}
      <div style={{ position: 'absolute', inset: 0, visibility: inTheTrip ? 'hidden' : undefined, pointerEvents: moving ? 'none' : undefined }}>
        <TripsHome {...home} cardRef={cardRef} />
      </div>
      <div style={{ position: 'absolute', inset: 0, visibility: onHome || inTheTrip ? 'hidden' : undefined, pointerEvents: 'none' }}>
        <motion.div style={{ position: 'absolute', inset: 0, backdropFilter: washBlur, WebkitBackdropFilter: washBlur }}>
          <motion.div style={{ position: 'absolute', inset: 0, background: 'color-mix(in srgb, var(--color-bg-default) 60%, transparent)', opacity: washOpacity }} />
        </motion.div>
        <motion.div style={{ ...surface, boxShadow: lift }} />
      </div>
      <motion.div style={{ position: 'absolute', inset: 0, clipPath: clip, visibility: onHome ? 'hidden' : undefined, pointerEvents: inTheTrip ? undefined : 'none' }}>
        {/* The map where it was on Your trips, on the map's own grey, the surface showing more of it as it grows */}
        <motion.div style={{ ...surface, opacity: stillOpacity, background: 'var(--color-bg-canvas)' }} />
        <motion.div style={{ position: 'absolute', left: 0, right: 0, top: cardTop, opacity: stillOpacity }}><HomeMapStill /></motion.div>
        {/* The trip's words, where they were, leaving */}
        <motion.div style={{ ...surface, opacity: wordsOpacity }}>
          <motion.div style={{ position: 'absolute', left: 0, top: 0, width: cardWidth, height: cardHeight }}><HomeHeroFace now={home.now} /></motion.div>
        </motion.div>
        <motion.div style={{ position: 'absolute', inset: 0, opacity: tripOpacity, filter: tripFilter, transform: tripTransform, transformOrigin: '0 0' }}>
          <TripEntrance clock={enter}>{trip}</TripEntrance>
        </motion.div>
      </motion.div>
    </div>
  );
}
