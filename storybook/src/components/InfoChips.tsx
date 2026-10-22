import { Sticker } from './Sticker';
import './InfoChips.css';

export type InfoChip = { text: string; sticker?: string; tilt?: number; grow?: boolean };

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
          {c.sticker && <Sticker name={c.sticker} size="chip" tilt={c.tilt} />}
          {c.text}
        </span>
      ))}
    </div>
  );
}
