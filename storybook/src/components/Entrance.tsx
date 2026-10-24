// The trip screen's entrance (the app's lib/components/entrance.dart): as a trip opens out of its card, its controls
// arrive one by one, and Up next opens last. HomeLayer runs the clock; the bars and the day chips read it.
import { cubicBezier, motion, motionValue, useMotionValueEvent, useReducedMotion, useTransform, type MotionValue } from 'motion/react';
import { createContext, useContext, useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import './Entrance.css';

const m = tokens.motion;
const easeOut = cubicBezier(...(m['ease-out'] as [number, number, number, number]));

/** The order the controls arrive in: the top bar's three, then the day chips (only as many as show on a phone; the
 *  rest arrive with the last one), then the footer's. Up next comes after all of them. Storybook's top bar has no Demo
 *  button, so its turn passes empty; the timing is the app's. */
export const ENTER_ORDER = { back: 0, title: 1, demo: 2, firstChip: 3, chipsShown: 6, footer: 9, count: 12 } as const;

/** How long the whole entrance takes, from the tap (ms): the wait while the surface grows, one step per control, and
 *  the last one's own time (220 + 11 × 30 + 200 = 750). */
export const ENTER_MS = m['open-delay-ms'] + m['open-stagger-ms'] * (ENTER_ORDER.count - 1) + m['open-item-ms'];

/** Where on the clock (0–1) the control at `index` starts. */
const startOf = (index: number) => (m['open-delay-ms'] + m['open-stagger-ms'] * Math.min(Math.max(index, 0), ENTER_ORDER.count - 1)) / ENTER_MS;

/** When the last control starts (550 ms in): Up next opens then. */
export const ENTER_LAST = startOf(ENTER_ORDER.count - 1);

/** How far in the control at `index` is, 0–1, eased out, at `clock`. */
const shown = (index: number, clock: number) => {
  const from = startOf(index), to = Math.min(1, from + m['open-item-ms'] / ENTER_MS);
  return easeOut(Math.min(1, Math.max(0, (clock - from) / (to - from))));
};

const Clock = createContext<MotionValue<number> | null>(null);
/** A clock that stays at the end, for useEnteredLast outside a TripEntrance (a hook can't be skipped). */
const FULL = motionValue(1);

/** Carries the entrance's clock (0 at the tap, 1 once the last control has landed) down to the controls. In the trip
 *  at rest it's 1, so everything simply shows; while you're on your trips it waits at 0 (unseen). */
export function TripEntrance({ clock, children }: { clock: MotionValue<number>; children: ReactNode }) {
  return <Clock.Provider value={clock}>{children}</Clock.Provider>;
}

/**
 * One control arriving on its own: it fades in and rises space-xs, at its place in ENTER_ORDER (from open-delay-ms,
 * open-stagger-ms apart, over open-item-ms, ease-out). With reduced motion it doesn't rise (the clock is already at 1:
 * it fades in with the trip). Outside a TripEntrance it's just the control. The same wrapper holds it either way, so
 * nothing is built anew when the entrance ends. `className` gives the wrapper the control's place in its row.
 */
export function EnterItem({ index, className = 'tu-enter', children }: { index: number; className?: string; children: ReactNode }) {
  const clock = useContext(Clock);
  const reduce = useReducedMotion();
  const v = useTransform(() => (clock ? shown(index, clock.get()) : 1));
  const transform = useTransform(() => (reduce || v.get() >= 1 ? 'none' : `translate(0px, ${(1 - v.get()) * tokens.space.xs}px)`));
  return <motion.div className={className} style={{ opacity: v, transform }}>{children}</motion.div>;
}

/** Whether the entrance has reached its end, where Up next opens (or the poll's card shows): from when the last control
 *  starts. Always, outside a TripEntrance. */
export function useEnteredLast() {
  const clock = useContext(Clock);
  const [last, setLast] = useState(() => !clock || clock.get() >= ENTER_LAST);
  useMotionValueEvent(clock ?? FULL, 'change', v => setLast(v >= ENTER_LAST));
  return last;
}
