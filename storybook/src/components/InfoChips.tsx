import { Sticker } from './Sticker';
import './InfoChips.css';

/** `faces`: people's stickers, piled (for "2 here"); shown instead of `sticker`. */
export type InfoChip = { text: string; sticker?: string; faces?: string[]; tilt?: number; grow?: boolean };

export interface InfoChipsProps {
  /** Joined chips, read left to right. Only the outer corners are rounded. Mark one chip `grow` to take the spare width. */
  items: InfoChip[];
}

/** A row of joined facts about a plan: who's going, price level, time. */
export function InfoChips({ items }: InfoChipsProps) {
  return (
    <div className="tu-chips">
      {items.map((c, i) => (
        <span key={i} className={['tu-chips__chip', 'text-body-sm', 'weight-semibold', c.grow && 'tu-chips__chip--grow'].filter(Boolean).join(' ')}>
          {c.faces?.length ? (
            <span className="tu-chips__faces">{c.faces.slice(0, 2).map(f => <Sticker key={f} name={f} size="chip" />)}</span>
          ) : (
            c.sticker && <Sticker name={c.sticker} size="chip" tilt={c.tilt} />
          )}
          {c.text}
        </span>
      ))}
    </div>
  );
}
