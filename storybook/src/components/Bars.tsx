import { ArrowLeft, Calendar, Euro, MapPin, Plus } from 'lucide-react';
import type { ReactNode } from 'react';
import { Button } from './Button';
import { PeopleButton } from './PeopleButton';
import './Bars.css';

export interface TopBarProps {
  title: string;
  dates: string;
  faces: [string, string];
  more: number;
  onBack?: () => void;
  onPeople?: () => void;
  /** Day filter, right under the title row (inside the bar's fade, so it reads over the map). */
  filter?: ReactNode;
}

/** Trip header over the map: back, trip name and dates, people, and the day filter. Fades the map out behind it. */
export function TopBar({ title, dates, faces, more, onBack, onPeople, filter }: TopBarProps) {
  return (
    <header className="tu-topbar">
      <div className="tu-topbar__row">
        <Button icon={ArrowLeft} label="Back to trips" size="md" onClick={onBack} />
        <div className="tu-topbar__title">
          <p className="text-heading-sm tu-ellipsis">{title}</p>
          <p className="text-label-md tu-topbar__dates">{dates}</p>
        </div>
        <PeopleButton faces={faces} more={more} onClick={onPeople} />
      </div>
      {filter}
    </header>
  );
}

export interface ActionBarProps {
  onCalendar?: () => void;
  onPlaces?: () => void;
  onMoney?: () => void;
  onAdd?: () => void;
}

/** The trip's four actions at the bottom: plan, places, money, and add (the one primary). Blurs and fades the map out behind it. In the app it slides down while the map is being moved and comes back once it settles. */
export function ActionBar({ onCalendar, onPlaces, onMoney, onAdd }: ActionBarProps) {
  return (
    <nav className="tu-actionbar" aria-label="Trip actions">
      <Button icon={Calendar} label="Plan" size="lg" onClick={onCalendar} />
      <Button icon={MapPin} label="Places" size="lg" onClick={onPlaces} />
      <Button icon={Euro} label="Money" size="lg" onClick={onMoney} />
      <Button icon={Plus} label="Add to the trip" size="lg" variant="primary" onClick={onAdd} />
    </nav>
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
