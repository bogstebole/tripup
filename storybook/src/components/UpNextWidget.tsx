import { ArrowRight } from 'lucide-react';
import { useId } from 'react';
import { AnimatePresence, LayoutGroup, motion, useReducedMotion, type Variants } from 'motion/react';
import tokens from '../../../design-system/tokens.json';
import { Button } from './Button';
import { InfoChips, type InfoChip } from './InfoChips';
import { EdgeArrow, PinTail } from './MapShapes';
import { RatingLine } from './RatingLine';
import { Sticker } from './Sticker';
import './Surface.css';
import './UpNextWidget.css';

export type WidgetState = 'mid' | 'mini' | 'edge';

export interface UpNextEvent {
  label: string;
  name: string;
  rating: string;
  cuisine: string;
  eta: string;
  sticker: string;
  fan: { sticker: string; height: number; tilt: number }[];
  chips: InfoChip[];
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

/**
 * The next plan, pinned to its place on the map. One surface that morphs between three states,
 * so every change reads as the same object growing or shrinking, never a swap.
 * Card ↔ mini: the plan's sticker and the name are shared (layoutId) and travel between their two places;
 * the fan opens out from the sticker, the label and rating follow the name, the chips rise in last.
 */
export function UpNextWidget({ event, state, edgeAngle = 90, onOpen, onTap }: UpNextWidgetProps) {
  const reduce = useReducedMotion();
  const group = useId();
  const spring = reduce ? { duration: 0 } : { type: 'spring' as const, duration: morph.duration, bounce: morph.bounce };
  const fade = { duration: reduce ? 0 : m['fade-ms'] / 1000, ease };
  const blur = reduce ? 'none' : `blur(${m['enter-blur']}px)`;
  // Parts that arrive after the shared ones: fade, sharpen and grow into place, the i-th one a stagger later
  const rise: Variants = {
    out: { opacity: 0, filter: blur, scale: reduce ? 1 : m['morph-enter-scale'], transition: fade },
    in: (i: number) => ({ opacity: 1, filter: 'blur(0px)', scale: 1, transition: { ...fade, delay: reduce ? 0 : (morph.duration / 2) + i * (m['stagger-ms'] / 1000) } }),
  };
  const hub = event.fan.findIndex(f => f.sticker === event.sticker);
  // The other fan stickers start tucked toward the shared one and open out
  const fanOut = (i: number): Variants => ({
    out: { opacity: 0, filter: blur, scale: reduce ? 1 : m['morph-enter-scale'], x: reduce || hub < 0 ? 0 : Math.sign(hub - i) * tokens.space.lg, transition: fade },
    in: { opacity: 1, filter: 'blur(0px)', scale: 1, x: 0, transition: { ...spring, delay: reduce ? 0 : m['stagger-ms'] / 1000 } },
  });
  const shared = (key: string) => ({ layoutId: `${group}-${key}`, transition: spring });

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
            <motion.div key="mid" layout transition={spring} className="tu-upnext__mid" initial="out" animate="in" exit={{ opacity: 0, transition: fade }}>
              <div className="tu-upnext__head">
                <motion.p variants={rise} custom={0} className="tu-upnext__label text-label-md weight-bold tu-ellipsis">{event.label}</motion.p>
                <motion.p {...shared('name')} layout="position" className="tu-upnext__name text-heading-sm tu-ellipsis">{event.name}</motion.p>
                <motion.div variants={rise} custom={1}><RatingLine rating={event.rating} kind={event.cuisine} /></motion.div>
              </div>
              <div className="tu-upnext__fan" aria-hidden>
                {event.fan.map((f, i) => i === hub
                  ? <motion.span key={f.sticker} {...shared('sticker')} className="tu-upnext__fan-item"><Sticker name={f.sticker} size={f.height} tilt={f.tilt} /></motion.span>
                  : <motion.span key={f.sticker} variants={fanOut(i)} className="tu-upnext__fan-item"><Sticker name={f.sticker} size={f.height} tilt={f.tilt} /></motion.span>)}
              </div>
              <motion.div variants={rise} custom={2} className="tu-upnext__actions" style={{ transformOrigin: 'bottom' }}>
                <InfoChips items={event.chips} />
                <Button variant="primary" size="sm" icon={ArrowRight} label={`Open ${event.name}`} onClick={e => { e.stopPropagation(); onOpen?.(); }} />
              </motion.div>
            </motion.div>
          )}
          {state === 'mini' && (
            <motion.div key="mini" layout transition={spring} className="tu-upnext__mini" initial="out" animate="in" exit={{ opacity: 0, transition: fade }}>
              <motion.span {...shared('sticker')} className="tu-upnext__fan-item"><Sticker name={event.sticker} size="mini" /></motion.span>
              <span className="tu-upnext__mini-text">
                <motion.span {...shared('name')} layout="position" className="tu-upnext__mini-name text-label-md weight-semibold tu-ellipsis">{event.name}</motion.span>
                <motion.span variants={rise} custom={0} className="tu-upnext__mini-eta text-label-md tu-ellipsis">{event.eta}</motion.span>
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
      {state !== 'edge' && (
        <motion.span layout transition={spring}>
          <PinTail gap={state === 'mid' ? 'xs' : '2xs'} />
        </motion.span>
      )}
    </motion.div>
    </LayoutGroup>
  );
}
