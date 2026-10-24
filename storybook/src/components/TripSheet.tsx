import { X } from 'lucide-react';
import { motion, useReducedMotion } from 'motion/react';
import { Children, isValidElement, useEffect, useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import { Button } from './Button';
import { easedFade } from './easedFade';
import './Surface.css';
import './TripSheet.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const space = tokens.space as Record<string, number>;
// A component token is a reference like "{space.xl}"; read the size it points at
const spaceOf = (ref: string) => space[ref.replace(/^\{space\.|\}$/g, '')];
const inset = spaceOf(tokens.component.dimension['sheet/inset']);
const topFade = spaceOf(tokens.component.dimension['sheet/top-fade']);
const rise = spaceOf(tokens.component.dimension['tab/enter-shift']);
const blur = `blur(${m['enter-blur']}px)`;

export interface TripSheetProps {
  title: string;
  subtitle: string;
  /** The page, top to bottom. The sheet scrolls it; a block marked `data-sheet-focus` opens scrolled to just under the header. */
  children: ReactNode;
  onClose?: () => void;
  /** Add's pop-up: only a few rows, so it stops at sheet/compact-height and sits at the bottom of its place. */
  compact?: boolean;
  /** Stays put at the bottom while the page scrolls above it (the scanned bill's totals and its button; Money's spent
   *  so far). */
  footer?: ReactNode;
  /** Stays put under the title while the page scrolls under it (the itinerary's day filter): one chip row high
   *  (toggle-chip-height), sm under the title, and the header grows by as much. */
  top?: ReactNode;
}

/**
 * One of the footer's pop-ups (itinerary, money, add): the full view's surface, a header with the title, subtitle
 * and close, and a page that scrolls up under the header. It rises from the bottom in the full view's place, from
 * just past the bottom edge (its own height plus the inset), and goes back down quicker than it came; with reduced
 * motion it only fades. Put it in AnimatePresence so it can leave. On the phone, a pull down on the header closes it too.
 * It has no notes of its own: its pages show them at the top of the screen (see Notice.tsx).
 */
export function TripSheet({ title, subtitle, children, onClose, compact, footer, top }: TripSheetProps) {
  const reduce = useReducedMotion();
  const scroll = useRef<HTMLDivElement>(null);
  // How far the page has scrolled under the header, 0–1 over the top fade's height
  const [under, setUnder] = useState(0);

  // Open on the marked block (today, in the itinerary): its top just under the header
  useLayoutEffect(() => {
    const el = scroll.current, at = el?.querySelector<HTMLElement>('[data-sheet-focus]');
    if (!el || !at) return;
    // Its layout position in the page (the blocks are still mid-stagger, so not their rects); each arriving block
    // has a transform, which makes it the offsetParent of what's inside, so add up the chain
    let y = 0;
    for (let n: HTMLElement | null = at; n && n !== el; n = n.offsetParent as HTMLElement | null) y += n.offsetTop;
    el.scrollTop = y - parseFloat(getComputedStyle(el).paddingTop);
    setUnder(Math.min(1, el.scrollTop / topFade));
  }, []);

  // Full transform strings, so Motion runs them on the compositor
  const away = `translate(0px, calc(100% + ${inset}px))`;
  const here = 'translate(0px, calc(0% + 0px))';

  return (
    <motion.article
      className={['tu-trip-sheet', 'tu-surface', 'tu-surface--sheet', compact && 'tu-trip-sheet--compact', footer != null && 'tu-trip-sheet--footer', top != null && 'tu-trip-sheet--top'].filter(Boolean).join(' ')}
      aria-label={title}
      initial={reduce ? { opacity: 0 } : { transform: away }}
      animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { transform: here, transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } } : { transform: away, transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      <div ref={scroll} className="tu-trip-sheet__scroll" onScroll={e => setUnder(Math.min(1, e.currentTarget.scrollTop / topFade))}>
        {children}
      </div>
      {/* The header's white shows once the page goes under it, so a page at rest isn't faded at the top */}
      <div className="tu-trip-sheet__top-fade" aria-hidden style={{ opacity: under, background: easedFade('var(--c-surface-top)', { from: 'var(--header)' }) }} />
      <div className="tu-trip-sheet__head">
        <div className="tu-trip-sheet__titles">
          <h2 className="text-heading-md tu-ellipsis">{title}</h2>
          <p className="text-body-sm tu-ellipsis tu-trip-sheet__subtitle">{subtitle}</p>
        </div>
        <Button icon={X} label="Close" size="sm" onClick={onClose} />
      </div>
      {top != null && <div className="tu-trip-sheet__top">{top}</div>}
      {footer != null && <div className="tu-trip-sheet__footer">{footer}</div>}
    </motion.article>
  );
}

/**
 * The page's blocks arrive one after another: each fades in, sharpens from a light blur and settles a few px up
 * (enter-ms, ease-out, stagger-ms apart; past stagger-max the rest come in with the last one, so a long list
 * doesn't drag). With reduced motion they only fade in. It runs once, as it's built (as in the app): a block that
 * comes later, like a day the itinerary's filter brings back, is simply there.
 */
export function StaggerIn({ children, gap }: { children: ReactNode; gap?: 'xs' | 'sm' | 'md' }) {
  const reduce = useReducedMotion();
  const [built, setBuilt] = useState(false);
  useEffect(() => setBuilt(true), []);
  return (
    <div className="tu-stagger" style={gap ? { gap: `var(--space-${gap})` } : undefined}>
      {Children.toArray(children).map((child, i) => (
        <motion.div
          key={isValidElement(child) && child.key != null ? child.key : i}
          initial={built ? false : reduce ? { opacity: 0 } : { opacity: 0, transform: `translate(0px, ${rise}px)`, filter: blur }}
          animate={reduce ? { opacity: 1 } : { opacity: 1, transform: 'translate(0px, 0px)', filter: 'blur(0px)' }}
          transition={reduce ? { duration: m['fade-ms'] / 1000, ease } : { duration: m['enter-ms'] / 1000, ease, delay: (Math.min(i, m['stagger-max'] - 1) * m['stagger-ms']) / 1000 }}
        >
          {child}
        </motion.div>
      ))}
    </div>
  );
}

/** A heading inside a pop-up's page, with an optional line under it. `top` is the room above it. */
export function SheetSection({ title, subtitle, top = 'xl' }: { title: string; subtitle?: string; top?: 'md' | 'lg' | 'xl' }) {
  return (
    <div className="tu-sheet-section" style={{ paddingTop: `var(--space-${top})` }}>
      <h3 className="text-heading-sm">{title}</h3>
      {subtitle && <p className="text-body-sm tu-sheet-section__sub">{subtitle}</p>}
    </div>
  );
}

export interface SheetRowProps {
  /** A sticker or faces, in a Slot so the names line up. */
  leading?: ReactNode;
  title: string;
  subtitle?: string;
  /** The line under the name in another tone: brand for what's up next, success once paid. Muted otherwise. */
  tone?: 'brand' | 'success';
  /** An amount, a time, a button. */
  trailing?: ReactNode;
  /** Makes the whole row a button (the itinerary's stops: show it on the map). */
  onClick?: () => void;
}

/** One line in a pop-up's list: something on the left, a name and a line under it, and whatever sits at the end. */
export function SheetRow({ leading, title, subtitle, tone, trailing, onClick }: SheetRowProps) {
  const body = (
    <>
      {leading}
      <span className="tu-sheet-row__text">
        <span className="text-label-lg tu-sheet-row__title">{title}</span>
        {subtitle && <span className={['text-body-sm', 'tu-sheet-row__sub', tone && `tu-sheet-row__sub--${tone}`].filter(Boolean).join(' ')}>{subtitle}</span>}
      </span>
      {trailing}
    </>
  );
  return onClick
    ? <button type="button" className="tu-sheet-row tu-sheet-row--tap" onClick={onClick}>{body}</button>
    : <div className="tu-sheet-row">{body}</div>;
}

/** A thin divider between rows, inset to the rows' text. */
export const Hairline = () => <div className="tu-hairline" />;

/** Stickers come in their own widths; a fixed slot keeps the names after them in one line. */
export function Slot({ children, size = 'row' }: { children: ReactNode; size?: 'row' | 'avatar' }) {
  return <span className="tu-slot" style={{ width: `var(--d-sticker-${size})` }}>{children}</span>;
}
