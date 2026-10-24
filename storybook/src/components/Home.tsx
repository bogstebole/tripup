// The first screen: your trips (Figma 75:5927). The app has the same in lib/components/home.dart; going into the trip,
// the trip's screen opens out of the trip card over it (see HomeLayer).
import { ArrowRight, Bell } from 'lucide-react';
import { animate, motion, useMotionValue, useReducedMotion, useTransform } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode, type Ref } from 'react';
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

export interface TripsHomeProps {
  /** Into the trip you're on: its card (or the arrow on it). */
  onOpen?: () => void;
  /** Now, in the trip (the demo's start, 3:56 PM, by default): who's on it. */
  now?: Date;
  /** Opens scrolled to the end, where the list fades into the blue (the app opens at the top). */
  scrolledToEnd?: boolean;
  /** On the current trip's card, so the trip can open out of it. */
  cardRef?: Ref<HTMLButtonElement>;
}

/**
 * Your trips, on the brand blue. The one you're on is a big card: a still of the city with places you've been as
 * stickers, "Happening now", its name and dates, who's on it, and the way in. Under it, the trip coming up and the
 * ones before, as rows. Tapping the current one goes into its map. The bell has nothing yet, and says so at the top.
 */
export function TripsHome({ onOpen, now = TRIP_NOW, scrolledToEnd, cardRef }: TripsHomeProps) {
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
            <CurrentTrip now={now} onOpen={onOpen} cardRef={cardRef} />
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
function CurrentTrip({ now, onOpen, cardRef }: { now: Date; onOpen?: () => void; cardRef?: Ref<HTMLButtonElement> }) {
  const crew = PEOPLE.filter(p => onTrip(p, now));
  return (
    <button ref={cardRef} type="button" className="tu-home-card" aria-label={`Open ${TRIP.title}`} onClick={onOpen}>
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

type Box = { left: number; top: number; width: number; height: number };
/** The screen's box, and the trip card's place in it, taken as a transition starts. */
type Frame = { screen: Box; card?: Box };

/** 0 up to `a`, 1 from `b`, eased in and out between (the app's smoothstep). */
const smoothstep = (a: number, b: number, v: number) => {
  const x = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return x * x * (3 - 2 * x);
};
const mix = (a: number, b: number, k: number) => a + (b - a) * k;

/**
 * The screen's box, and the card's place in it as laid out: without the list's lean (the scale on `home`, whose box is
 * the screen's) or the card's press (a scale about its centre).
 */
function measure(screen: HTMLElement | null, home: HTMLElement | null, card: HTMLElement | null): Frame {
  const box = { left: 0, top: 0, width: screen?.offsetWidth ?? 0, height: screen?.offsetHeight ?? 0 };
  if (!home || !card) return { screen: box };
  const h = home.getBoundingClientRect(), c = card.getBoundingClientRect();
  const lean = h.width / home.offsetWidth || 1;
  const x = (c.left + c.width / 2 - h.left) / lean, y = (c.top + c.height / 2 - h.top) / lean;
  return { screen: box, card: { left: x - card.offsetWidth / 2, top: y - card.offsetHeight / 2, width: card.offsetWidth, height: card.offsetHeight } };
}

export interface HomeLayerProps extends Omit<TripsHomeProps, 'cardRef'> {
  /** In the trip; false is on your trips. */
  inTrip: boolean;
  /** The trip's screen, which opens out of the trip card. */
  trip: ReactNode;
}

/**
 * Your trips, and the trip's screen over them (the app's home layer and its opening trip), with one spring between.
 * Going in, the trip card opens into the trip: the whole trip screen grows out of the card's place, scaled to the
 * card's width and clipped to its rounded rect (the card's corners, d-surface-radius, easing to none), both growing
 * to the whole screen (spring-expand). It fades in over the first 30% of the way, so the card's still of the city
 * gives way to the trip. Behind it your trips fade (over 20–90%) and lean in toward the card (to page-zoom-scale,
 * about the card's centre). The trip's Back closes it into the card again (spring-collapse). Nothing takes taps
 * while it moves. Reduced motion: fades only (fade-ms). Whichever isn't showing isn't drawn, and keeps its place (the
 * list its scroll).
 */
export function HomeLayer({ inTrip, trip, ...home }: HomeLayerProps) {
  const reduce = !!useReducedMotion();
  // 1 on your trips, 0 in the trip (a spring, so it can go a little past either)
  const t = useMotionValue(inTrip ? 0 : 1);
  const frame = useMotionValue<Frame>({ screen: { left: 0, top: 0, width: 0, height: 0 } });
  const [moving, setMoving] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null), homeRef = useRef<HTMLDivElement>(null), cardRef = useRef<HTMLButtonElement>(null);

  // In or back: the card's place is taken first (before the first frame), then the spring runs from wherever it is
  useLayoutEffect(() => {
    const to = inTrip ? 0 : 1;
    if (t.get() === to && !t.isAnimating()) return;
    frame.set(measure(rootRef.current, homeRef.current, cardRef.current));
    setMoving(true);
    const done = () => setMoving(false);
    const spring = inTrip ? m['spring-expand'] : m['spring-collapse'];
    if (reduce) animate(t, to, { duration: m['fade-ms'] / 1000, ease: 'linear', onComplete: done });
    else animate(t, to, { type: 'spring', duration: spring.duration, bounce: spring.bounce, onComplete: done });
  }, [inTrip, reduce, t, frame]);
  useEffect(() => () => t.stop(), [t]);

  // 0 on the list, 1 in the trip
  const p = () => Math.min(1, Math.max(0, 1 - t.get()));
  // Your trips: fading, and leaning in toward the card
  const homeOpacity = useTransform(() => 1 - smoothstep(0.2, 0.9, p()));
  const homeTransform = useTransform(() => (reduce || p() <= 0 ? 'none' : `scale(${1 + p() * (m['page-zoom-scale'] - 1)})`));
  const homeOrigin = useTransform(() => {
    const c = frame.get().card;
    return c ? `${c.left + c.width / 2}px ${c.top + c.height / 2}px` : '0px 0px';
  });
  // The trip: its box goes from the card's (the screen's, if there's no card) to the screen's; the trip is scaled to
  // the box's width, centred on it, and clipped to it. In the trip, none of it applies.
  const tripBox = (): Box => {
    const { screen, card = screen } = frame.get(), k = p();
    return { left: mix(card.left, screen.left, k), top: mix(card.top, screen.top, k), width: mix(card.width, screen.width, k), height: mix(card.height, screen.height, k) };
  };
  const tripClip = useTransform(() => {
    const { screen } = frame.get(), r = tripBox(), k = p();
    if (reduce || k >= 1) return 'none';
    return `inset(${r.top}px ${screen.width - r.left - r.width}px ${screen.height - r.top - r.height}px ${r.left}px round calc(var(--d-surface-radius) * ${1 - k}))`;
  });
  const tripTransform = useTransform(() => {
    const { screen } = frame.get(), r = tripBox();
    if (reduce || p() >= 1 || !screen.width) return 'none';
    const s = r.width / screen.width;
    return `translate(${r.left + r.width / 2 - (screen.width / 2) * s}px, ${r.top + r.height / 2 - (screen.height / 2) * s}px) scale(${s})`;
  });
  const tripOpacity = useTransform(() => (reduce ? p() : smoothstep(0, 0.3, p())));

  const onHome = !moving && !inTrip, inTheTrip = !moving && inTrip;
  return (
    <div ref={rootRef} style={{ position: 'absolute', inset: 0 }}>
      <motion.div
        ref={homeRef}
        style={{
          position: 'absolute',
          inset: 0,
          opacity: homeOpacity,
          transform: homeTransform,
          transformOrigin: homeOrigin,
          visibility: inTheTrip ? 'hidden' : undefined,
          pointerEvents: moving ? 'none' : undefined,
        }}
      >
        <TripsHome {...home} cardRef={cardRef} />
      </motion.div>
      <motion.div style={{ position: 'absolute', inset: 0, clipPath: tripClip, visibility: onHome ? 'hidden' : undefined, pointerEvents: inTheTrip ? undefined : 'none' }}>
        <motion.div style={{ position: 'absolute', inset: 0, opacity: tripOpacity, transform: tripTransform, transformOrigin: '0 0' }}>
          {trip}
        </motion.div>
      </motion.div>
    </div>
  );
}
