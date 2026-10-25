import { ArrowLeft, X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion, type Variants } from 'motion/react';
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
  /** A line on what the pop-up is for, at the top of its page (not in the header, so the header stays one line). */
  subtitle?: string;
  /** The page, top to bottom. The sheet scrolls it; a block marked `data-sheet-focus` opens scrolled to just under the header. */
  children: ReactNode;
  onClose?: () => void;
  /** Add's choice and its invite: only a few rows, so it stops at sheet/compact-height and sits at the bottom of its
   *  place. Planning takes the whole height; a change between the two eases in and out (enter-ms, ease-in-out). */
  compact?: boolean;
  /** A step back inside the pop-up (Add's Plan or Invite back to its choice): a back button before the title. */
  onBack?: () => void;
  /** The page sits in the middle of the sheet when it's shorter than it (Invite's link). */
  centered?: boolean;
  /** Stays put at the bottom while the page scrolls above it: the page's actions (see SheetFooter). */
  footer?: ReactNode;
  /** Stays put under the title while the page scrolls under it (the itinerary's day filter): one chip row high
   *  (toggle-chip-height), sm under the title, and the header grows by as much. */
  top?: ReactNode;
}

/**
 * One of the footer's pop-ups (itinerary, money, add): the full view's surface, a header with Back (for a step inside
 * it), the title and Close on one line, a page that scrolls up under the header (the pop-up's line on what it's for at
 * its top), and a footer with the page's actions. Every pop-up is built the same way: going back and closing in the
 * header, doing things in the footer. It rises from the bottom in the full view's place, from
 * just past the bottom edge (its own height plus the inset), and goes back down quicker than it came; with reduced
 * motion it only fades. Put it in AnimatePresence so it can leave; with `custom` true on that AnimatePresence it goes at
 * once instead (a plan's details opened from the itinerary take its place: the same surface, in the same place). On the
 * phone, a pull down on the header closes it too.
 * It has no notes of its own: its pages show them at the top of the screen (see Notice.tsx). A step inside it (Add's)
 * shows in the header: a back button slides in before the title (enter-ms, ease-out), and a new title fades in as the
 * old one fades out (enter-ms in, fade-ms out).
 */
export function TripSheet({ title, subtitle, children, onClose, compact, footer, top, onBack, centered }: TripSheetProps) {
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
  // Leaving: back down, quicker than it came; or at once, when what takes its place is already there
  const leave: Variants = {
    leave: (atOnce?: boolean) =>
      atOnce ? { opacity: 0, transition: { duration: 0 } }
      : reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }
      : { transform: away, transition: { duration: m['fade-ms'] / 1000, ease } },
  };

  return (
    <motion.article
      className={['tu-trip-sheet', 'tu-surface', 'tu-surface--sheet', compact && 'tu-trip-sheet--compact', footer != null && 'tu-trip-sheet--footer', top != null && 'tu-trip-sheet--top'].filter(Boolean).join(' ')}
      aria-label={title}
      initial={reduce ? { opacity: 0 } : { transform: away }}
      animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { transform: here, transition: { duration: m['enter-ms'] / 1000, ease } }}
      variants={leave}
      exit="leave"
    >
      <div ref={scroll} className={centered ? 'tu-trip-sheet__scroll tu-trip-sheet__scroll--centered' : 'tu-trip-sheet__scroll'} onScroll={e => setUnder(Math.min(1, e.currentTarget.scrollTop / topFade))}>
        {subtitle && <p className="text-body-sm tu-trip-sheet__intro">{subtitle}</p>}
        {children}
      </div>
      {/* The header's white shows once the page goes under it, so a page at rest isn't faded at the top */}
      <div className="tu-trip-sheet__top-fade" aria-hidden style={{ opacity: under, background: easedFade('var(--c-surface-top)', { from: 'var(--header)' }) }} />
      <div className="tu-trip-sheet__head">
        {/* A step back slides in before the title (and out again), the title moving over for it */}
        <AnimatePresence initial={false}>
          {onBack && (
            <motion.div
              key="back"
              className="tu-trip-sheet__back"
              initial={{ width: 0 }}
              animate={{ width: 'auto', transition: { duration: m['enter-ms'] / 1000, ease } }}
              exit={{ width: 0, transition: { duration: m['enter-ms'] / 1000, ease } }}
            >
              <Button icon={ArrowLeft} label="Back" size="sm" onClick={onBack} />
            </motion.div>
          )}
        </AnimatePresence>
        {/* A new title fades in once the old one has mostly gone (a step inside the pop-up: swap-in-at of enter-ms),
            so they never read over each other */}
        <div className="tu-trip-sheet__titles">
          <AnimatePresence initial={false}>
            <motion.div
              key={title}
              className="tu-trip-sheet__title"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1, transition: { duration: (m['enter-ms'] * (1 - m['swap-in-at'])) / 1000, delay: (m['enter-ms'] * m['swap-in-at']) / 1000, ease } }}
              exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
            >
              <h2 className="text-heading-md tu-ellipsis">{title}</h2>
            </motion.div>
          </AnimatePresence>
        </div>
        <Button icon={X} label="Close" size="sm" onClick={onClose} />
      </div>
      {top != null && <div className="tu-trip-sheet__top">{top}</div>}
      {footer != null && <div className="tu-trip-sheet__footer">{footer}</div>}
    </motion.article>
  );
}

/**
 * A pop-up's bottom, in view while its page scrolls: what to do there, as buttons (one wide, or several stacked), with
 * what they need above them (Money's total) or a line under them (`note`). Every pop-up's actions are here; going back
 * and closing are in the header. Padding sm on top and md at the bottom, xs at the sides, over a hairline.
 */
export function SheetFooter({ children, note }: { children: ReactNode; note?: string }) {
  return (
    <div className="tu-sheet-footer">
      {children}
      {note && <p className="text-body-sm tu-sheet-footer__note">{note}</p>}
    </div>
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
