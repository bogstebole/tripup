import { Sticker } from './Sticker';
import './InfoChips.css';

export type InfoChip = {
  text: string;
  sticker?: string;
  /** People's stickers, overlapped in front of the text ("here"); shown instead of `sticker`. */
  faces?: string[];
  tilt?: number;
  grow?: boolean;
};

export interface InfoChipsProps {
  /** Joined chips, read left to right. Only the outer corners are rounded. Chips marked `grow` share the spare width; the rest keep to their content. */
  items: InfoChip[];
}

/** A row of joined facts about a plan: who's coming (or who's already there), the price range. */
export function InfoChips({ items }: InfoChipsProps) {
  return (
    <div className="tu-chips">
      {items.map((c, i) => (
        <span key={i} className={['tu-chips__chip', 'text-body-sm', 'weight-semibold', c.grow && 'tu-chips__chip--grow', c.faces?.length && 'tu-chips__chip--faces'].filter(Boolean).join(' ')}>
          {c.faces?.length
            ? <span className="tu-chips__faces">{c.faces.map(f => <Sticker key={f} name={f} size="chip" />)}</span>
            : c.sticker && <Sticker name={c.sticker} size="chip" tilt={c.tilt} />}
          {c.text}
        </span>
      ))}
    </div>
  );
}
