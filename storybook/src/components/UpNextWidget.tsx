import { ArrowRight } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
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

const morph = tokens.motion['spring-morph'];
const fadeMs = tokens.motion['fade-ms'] / 1000;

/**
 * The next plan, pinned to its place on the map. One surface that morphs between three states,
 * so every change reads as the same object growing or shrinking, never a swap.
 */
export function UpNextWidget({ event, state, edgeAngle = 90, onOpen, onTap }: UpNextWidgetProps) {
  const reduce = useReducedMotion();
  const spring = reduce ? { duration: 0 } : { type: 'spring' as const, duration: morph.duration, bounce: morph.bounce };
  const fade = { duration: reduce ? 0 : fadeMs, ease: tokens.motion['ease-out'] as [number, number, number, number] };

  return (
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
            <motion.div key="mid" className="tu-upnext__mid" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={fade}>
              <div className="tu-upnext__head">
                <p className="tu-upnext__label text-label-sm weight-bold tu-ellipsis">{event.label}</p>
                <p className="tu-upnext__name text-heading-sm tu-ellipsis">{event.name}</p>
                <RatingLine rating={event.rating} kind={event.cuisine} />
              </div>
              <div className="tu-upnext__fan" aria-hidden>
                {event.fan.map(f => <Sticker key={f.sticker} name={f.sticker} size={f.height} tilt={f.tilt} />)}
              </div>
              <div className="tu-upnext__actions">
                <InfoChips items={event.chips} />
                <Button variant="primary" size="sm" icon={ArrowRight} label={`Open ${event.name}`} onClick={e => { e.stopPropagation(); onOpen?.(); }} />
              </div>
            </motion.div>
          )}
          {state === 'mini' && (
            <motion.div key="mini" className="tu-upnext__mini" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={fade}>
              <Sticker name={event.sticker} size="mini" />
              <span className="tu-upnext__mini-text">
                <span className="tu-upnext__mini-name text-label-sm weight-semibold tu-ellipsis">{event.name}</span>
                <span className="tu-upnext__mini-eta text-label-sm tu-ellipsis">{event.eta}</span>
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
  );
}
