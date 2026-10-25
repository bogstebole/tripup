import { ArrowRight } from 'lucide-react';
import { useId } from 'react';
import { AnimatePresence, LayoutGroup, motion, useReducedMotion, type Variants } from 'motion/react';
import tokens from '../../../design-system/tokens.json';
import { Button } from './Button';
import { InfoChips, type InfoChip } from './InfoChips';
import { FacePile } from './FacePile';
import { EdgeArrow, PinTail } from './MapShapes';
import { RatingLine } from './RatingLine';
import { Sticker } from './Sticker';
import './Surface.css';
import './UpNextWidget.css';

export type WidgetState = 'mid' | 'mini' | 'edge';

export interface UpNextEvent {
  /** "Up next · 5 PM"; once the dinner is on, "Now · You're here" (see `upNextAt` in data.ts). */
  label: string;
  name: string;
  rating: string;
  cuisine: string;
  /** How soon ("In 64 mins"), on the mini pin; "Now" once it's on. */
  eta: string;
  /** The plan is on: its time has come and someone is there. The label gets a brand dot before it. */
  now?: boolean;
  sticker: string;
  fan: { sticker: string; height: number; tilt: number }[];
  /** Who's coming or who's here, then the price range (see `upNextChips` in data.ts). */
  chips: InfoChip[];
  /** Stickers of whoever is already at the place: in the card's first chip, and across the mini pin's corner. */
  here?: string[];
}

export interface UpNextWidgetProps {
  event: UpNextEvent;
  /** `mid`: the card shown when the trip opens. `mini`: while the map moves. `edge`: the place is off-screen. */
  state: WidgetState;
  /** For `edge`: which way the arrow points, in degrees (0 down, 90 left, 180 up, 270 right). */
  edgeAngle?: number;
  /** Tap on the card or the arrow button: open the full view. */
  onOpen?: () => void;
  /** Tap on the mini pin or the edge pin. */
  onTap?: () => void;
}

const m = tokens.motion;
const morph = m['spring-morph'];
const ease = m['ease-out'] as [number, number, number, number];
const space = tokens.space as Record<string, number>;
const rise = space[(tokens.component.dimension['tab/enter-shift'] as string).replace(/^\{space\.|\}$/g, '')];

/** When the morph spring has covered [at] of its way, in s (the app starts the next content then: it watches the spring). */
function springAt(at: number) {
  const w = (2 * Math.PI) / morph.duration, z = 1 - morph.bounce, wd = w * Math.sqrt(Math.max(1 - z * z, 1e-6));
  for (let t = 0; t < 2; t += 0.001) {
    if (1 - Math.exp(-z * w * t) * (Math.cos(wd * t) + ((z * w) / wd) * Math.sin(wd * t)) >= at) return t;
  }
  return morph.duration;
}

/**
 * The next plan, pinned to its place on the map. One surface that morphs between three states,
 * so every change reads as the same object growing or shrinking.
 * Card ↔ mini, like the Dynamic Island: the old content fades out with a blur as the surface starts to spring, and
 * the new one comes in once the surface is nearly its new size: the card's parts one after another from the top
 * (label, name, rating, the fan, the chips), rising a little into place; the mini's all at once. They never overlap.
 * Whoever is already there is in the card's first chip; on the mini pin they sit across its top-right corner instead,
 * coming in with the mini's content. Gone at the edge.
 * Once the plan is on (`now`), the label starts with a brand dot: "Now · You're here", and the mini says "Now".
 */
export function UpNextWidget({ event, state, edgeAngle = 90, onOpen, onTap }: UpNextWidgetProps) {
  const reduce = useReducedMotion();
  const group = useId();
  const spring = reduce ? { duration: 0 } : { type: 'spring' as const, duration: morph.duration, bounce: morph.bounce };
  const fade = { duration: reduce ? 0 : m['fade-ms'] / 1000, ease };
  const blur = reduce ? 'none' : `blur(${m['enter-blur']}px)`;
  // Leaving: an even fade (the strong ease-out would make it a cut at this length)
  const leave = { opacity: 0, filter: blur, transition: { duration: reduce ? 0 : m['pin-out-ms'] / 1000, ease: 'linear' as const } };
  const cardAt = reduce ? 0 : springAt(m['pin-in-at']), miniAt = reduce ? 0 : springAt(1 - m['pin-mini-at']);
  // The card's parts, the i-th one a stagger later: fade, sharpen and rise into place
  const part: Variants = {
    out: { opacity: 0, filter: blur, y: reduce ? 0 : rise },
    in: (i: number) => ({ opacity: 1, filter: 'blur(0px)', y: 0, transition: { duration: reduce ? 0 : m['open-item-ms'] / 1000, ease, delay: cardAt + i * (m['open-stagger-ms'] / 1000) } }),
  };
  const miniIn = { opacity: 1, filter: 'blur(0px)', transition: { ...fade, delay: miniAt } };

  return (
    <LayoutGroup id={group}>
    <motion.div layout transition={spring} className={`tu-upnext tu-upnext--${state}`}>
      {state === 'edge' && (
        <motion.span layout transition={spring} className="tu-upnext__edge-arrow">
          <EdgeArrow angle={edgeAngle} />
        </motion.span>
      )}
      <motion.div
        layout
        transition={spring}
        className={`tu-upnext__card tu-surface ${state === 'edge' ? 'tu-surface--pill' : 'tu-surface--sheet'}`}
        role="button"
        tabIndex={0}
        aria-label={state === 'mid' ? `Open ${event.name}` : `${event.name}, ${event.eta}`}
        onClick={state === 'mid' ? onOpen : onTap}
      >
        <AnimatePresence mode="popLayout" initial={false}>
          {state === 'mid' && (
            <motion.div key="mid" layout transition={spring} className="tu-upnext__mid" exit={leave}>
              <div className="tu-upnext__head">
                <motion.p variants={part} initial="out" animate="in" custom={0} className="tu-upnext__label text-label-md weight-bold">
                  {event.now && <span className="tu-upnext__now-dot" aria-hidden />}
                  <span className="tu-ellipsis">{event.label}</span>
                </motion.p>
                <motion.p variants={part} initial="out" animate="in" custom={1} className="tu-upnext__name text-heading-sm tu-ellipsis">{event.name}</motion.p>
                <motion.div variants={part} initial="out" animate="in" custom={2}><RatingLine rating={event.rating} kind={event.cuisine} /></motion.div>
              </div>
              <motion.div variants={part} initial="out" animate="in" custom={3} className="tu-upnext__fan" aria-hidden>
                {event.fan.map(f => <span key={f.sticker} className="tu-upnext__fan-item"><Sticker name={f.sticker} size={f.height} tilt={f.tilt} /></span>)}
              </motion.div>
              <motion.div variants={part} initial="out" animate="in" custom={4} className="tu-upnext__actions">
                <InfoChips items={event.chips} />
                <Button variant="primary" size="sm" icon={ArrowRight} label={`Open ${event.name}`} onClick={e => { e.stopPropagation(); onOpen?.(); }} />
              </motion.div>
            </motion.div>
          )}
          {state === 'mini' && (
            <motion.div key="mini" layout transition={spring} className="tu-upnext__mini" initial={{ opacity: 0, filter: blur }} animate={miniIn} exit={leave}>
              <span className="tu-upnext__fan-item"><Sticker name={event.sticker} size="mini" /></span>
              <span className="tu-upnext__mini-text">
                <span className="tu-upnext__mini-name text-label-md weight-semibold tu-ellipsis">{event.name}</span>
                <span className="tu-upnext__mini-eta text-label-md tu-ellipsis">{event.eta}</span>
              </span>
            </motion.div>
          )}
          {state === 'edge' && (
            <motion.div key="edge" className="tu-upnext__edge" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={fade}>
              <Sticker name={event.sticker} size="edge" />
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
      {!!event.here?.length && (
        <motion.span layout="position" transition={spring} className="tu-upnext__here" aria-hidden>
          <motion.span
            className="tu-upnext__here-pile"
            initial={false}
            animate={state === 'mini' ? miniIn : leave}
          >
            <FacePile faces={event.here} size="chip" />
          </motion.span>
        </motion.span>
      )}
      {state !== 'edge' && (
        <motion.span layout transition={spring}>
          <PinTail gap={state === 'mid' ? 'xs' : '2xs'} />
        </motion.span>
      )}
    </motion.div>
    </LayoutGroup>
  );
}
