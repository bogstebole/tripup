import './Button.css';
import './DayFilter.css';

export interface TripDay {
  /** Day of the month. */
  day: number;
  /** "Tue 12": weekday and day. */
  label: string;
}

export interface DayFilterProps {
  days: TripDay[];
  /** The days that are on. Empty means All. */
  selected: number[];
  onChange?: (days: number[]) => void;
}

/**
 * Day filter under the top bar: All, then each day of the trip. The chips are toggles: flat when off,
 * primary glass when on (the same tactile blue as the buttons, so only what's picked stands out).
 * Days can be combined; with none picked, All is on.
 */
export function DayFilter({ days, selected, onChange }: DayFilterProps) {
  const toggle = (d: number) => onChange?.(selected.includes(d) ? selected.filter(x => x !== d) : [...selected, d]);
  return (
    <div className="tu-days" role="group" aria-label="Filter by day">
      <DayChip label="All" on={selected.length === 0} onClick={() => onChange?.([])} />
      {days.map(d => <DayChip key={d.day} label={d.label} on={selected.includes(d.day)} onClick={() => toggle(d.day)} />)}
    </div>
  );
}

/** One toggle in the day filter. */
export function DayChip({ label, on, onClick }: { label: string; on: boolean; onClick?: () => void }) {
  return (
    <button type="button" aria-pressed={on} className={`tu-day text-label-md ${on ? 'tu-btn--primary' : 'tu-day--off'}`} onClick={onClick}>
      {label}
    </button>
  );
}
