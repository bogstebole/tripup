import { ArrowRight } from 'lucide-react';
import type { ReactNode } from 'react';
import './KnowSection.css';

export interface KnowRowProps {
  children: ReactNode;
  onClick?: () => void;
  /** Shown on the left of the text, e.g. a dish sticker. */
  leading?: ReactNode;
  /** Shown before the arrow, e.g. avatars of who picked it. */
  trailing?: ReactNode;
}

/** A tappable row inside a section: soft glass row, brand text, arrow. */
export function KnowRow({ children, onClick, leading, trailing }: KnowRowProps) {
  return (
    <button type="button" className="tu-know-row" onClick={onClick}>
      {leading}
      <span className="tu-know-row__text text-label-sm">{children}</span>
      {trailing}
      <ArrowRight className="tu-know-row__arrow" strokeWidth={2} absoluteStrokeWidth aria-hidden />
    </button>
  );
}

export interface KnowSectionProps {
  title: string;
  /** Short text on the right of the title, e.g. "5 of 5 picked". */
  meta?: string;
  children: ReactNode;
}

/** A muted, rounded group with a brand heading and rows. Used for "Know before you go", menu picks and people. */
export function KnowSection({ title, meta, children }: KnowSectionProps) {
  return (
    <section className="tu-know">
      <div className="tu-know__head">
        <h3 className="tu-know__title text-heading-sm">{title}</h3>
        {meta && <span className="text-label-sm tu-know__meta">{meta}</span>}
      </div>
      <div className="tu-know__rows">{children}</div>
    </section>
  );
}
