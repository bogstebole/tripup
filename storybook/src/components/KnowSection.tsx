import type { ReactNode } from 'react';
import './KnowSection.css';

/** A tip inside a section (Bogdan's Overview, Figma 62:4828): a short line in brand on a muted block. Read, not
 *  tapped, so no arrow and no glass. */
export function KnowTip({ children }: { children: ReactNode }) {
  return <p className="tu-know-tip text-label-md">{children}</p>;
}

export interface KnowSectionProps {
  title: string;
  /** Short text on the right of the title, e.g. "5 of 5 picked". */
  meta?: string;
  children: ReactNode;
}

/** A subtle, rounded group with a brand heading and rows: the place's tips ("Know before you go"). */
export function KnowSection({ title, meta, children }: KnowSectionProps) {
  return (
    <section className="tu-know">
      <div className="tu-know__head">
        <h3 className="tu-know__title text-heading-sm">{title}</h3>
        {meta && <span className="text-label-md tu-know__meta">{meta}</span>}
      </div>
      <div className="tu-know__rows">{children}</div>
    </section>
  );
}
