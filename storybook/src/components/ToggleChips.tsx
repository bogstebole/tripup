import './Button.css';
import './ToggleChips.css';

export interface ToggleOption<T> {
  id: T;
  label: string;
}

export interface ToggleChipsProps<T> {
  options: ToggleOption<T>[];
  /** The options that are on. Empty means All. */
  selected: T[];
  onChange?: (selected: T[]) => void;
  allLabel?: string;
  /** Accessible name of the group, e.g. "Filter by day". */
  label: string;
  /** Room before the first chip and after the last: md under the top bar (the default), xs in a pop-up, which has
   *  its own xs inside its edge, so the chips line up with its title. */
  inset?: 'xs' | 'md';
}

/**
 * A row of toggles: All, then one per option. Flat when off, primary glass when on (the same tactile blue as the
 * buttons, so only what's picked stands out). Options combine; with none picked, All is on. Scrolls sideways.
 * Used for the trip's days under the top bar and in the itinerary, and for courses in the menu.
 */
export function ToggleChips<T extends string | number>({ options, selected, onChange, allLabel = 'All', label, inset }: ToggleChipsProps<T>) {
  const toggle = (id: T) => onChange?.(selected.includes(id) ? selected.filter(x => x !== id) : [...selected, id]);
  return (
    <div className="tu-toggles" role="group" aria-label={label} style={inset ? { paddingInline: `var(--space-${inset})` } : undefined}>
      <ToggleChip label={allLabel} on={selected.length === 0} onClick={() => onChange?.([])} />
      {options.map(o => <ToggleChip key={o.id} label={o.label} on={selected.includes(o.id)} onClick={() => toggle(o.id)} />)}
    </div>
  );
}

/** One toggle in a ToggleChips row. */
export function ToggleChip({ label, on, onClick }: { label: string; on: boolean; onClick?: () => void }) {
  return (
    <button
      type="button"
      aria-pressed={on}
      className={`tu-toggle text-label-md ${on ? 'tu-btn--primary' : 'tu-toggle--off'}`}
      // A chip half off the edge slides fully into view (nothing moves if it already is)
      onClick={e => { onClick?.(); e.currentTarget.scrollIntoView({ inline: 'nearest', block: 'nearest', behavior: 'smooth' }); }}
    >
      {label}
    </button>
  );
}
