import { ArrowLeft, MapPin, Plus } from 'lucide-react';
import type { ReactNode } from 'react';
import { CREW_PILE } from '../data';
import { Button } from './Button';
import { Sticker } from './Sticker';
import { easedFade } from './easedFade';
import './Bars.css';

export interface TopBarProps {
  title: string;
  dates: string;
  onBack?: () => void;
  /** Day filter, right under the title row (inside the bar's fade, so it reads over the map). */
  filter?: ReactNode;
}

/** Trip header over the map: back, trip name and dates, and the day filter. Fades the map out behind it. (The group
 *  lives on the footer's Money button now.) */
export function TopBar({ title, dates, onBack, filter }: TopBarProps) {
  return (
    <header className="tu-topbar" style={{ background: easedFade('var(--c-top-bar-bg)', { from: 'calc(var(--d-top-bar-fade-start) * 100%)' }) }}>
      <div className="tu-topbar__row">
        <Button icon={ArrowLeft} label="Back to trips" size="md" onClick={onBack} />
        <div className="tu-topbar__title">
          <p className="text-heading-sm tu-ellipsis">{title}</p>
          <p className="text-label-md tu-topbar__dates">{dates}</p>
        </div>
      </div>
      {filter}
    </header>
  );
}

export interface ActionBarProps {
  onItinerary?: () => void;
  onMoney?: () => void;
  onAdd?: () => void;
}

/**
 * The trip's three actions at the bottom: the itinerary, the group's money (the whole group as one little pile), and
 * add (the one primary). Each opens its pop-up. A white fade, strongest at the bottom, lifts them off the map; no blur.
 * In the app it slides down while the map is being moved and comes back once it settles.
 */
export function ActionBar({ onItinerary, onMoney, onAdd }: ActionBarProps) {
  return (
    <nav className="tu-actionbar" aria-label="Trip actions" style={{ background: easedFade('var(--c-action-bar-bg)', { from: 'calc(var(--d-action-bar-fade-start) * 100%)', to: 'top' }) }}>
      <Button icon={MapPin} label="Itinerary" size="lg" onClick={onItinerary} />
      <CrewButton onClick={onMoney} />
      <Button icon={Plus} label="Add to the trip" size="lg" variant="primary" onClick={onAdd} />
    </nav>
  );
}

/** The money button: everyone on the trip, piled up as they were placed in Figma, on a soft glass circle. */
export function CrewButton({ onClick }: { onClick?: () => void }) {
  return (
    <button type="button" aria-label="Money: who paid and who owes" className="tu-btn tu-btn--soft tu-btn--lg" onClick={onClick}>
      <span className="tu-crew" style={{ width: CREW_PILE.width, height: CREW_PILE.height }} aria-hidden>
        {CREW_PILE.stickers.map(s => <Sticker key={s.sticker} name={s.sticker} size={s.height} tilt={s.tilt} className="tu-crew__face" style={{ left: s.left, top: s.top }} />)}
      </span>
    </button>
  );
}

/** Brings the map back to my location. Shows only when I'm off-screen. */
export function RecenterButton({ onClick }: { onClick?: () => void }) {
  return (
    <button type="button" aria-label="Show my location" className="tu-btn tu-btn--soft tu-btn--sm" onClick={onClick}>
      <span className="tu-recenter__dot" />
    </button>
  );
}
