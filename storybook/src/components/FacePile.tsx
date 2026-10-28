import { Sticker } from './Sticker';
import './FacePile.css';

/**
 * People as a little pile: everyone's sticker, up to five; past five, four of them and a "+N" bubble for the rest, so
 * it's never wider than five. On the map it's a group walking together (people closer than a sticker's width merge
 * into one pile); on a pin, who's already there.
 */
const MOST = 5;

export function FacePile({ faces, size = 'avatar', label }: { faces: string[]; size?: 'avatar' | 'chip'; label?: string }) {
  const shown = faces.length > MOST ? MOST - 1 : faces.length;
  const more = faces.length - shown;
  return (
    <span className="tu-pile" role="img" aria-label={label}>
      {faces.slice(0, shown).map(f => <Sticker key={f} name={f} size={size} />)}
      {more > 0 && <span className="tu-pile__more text-label-md weight-bold">+{more}</span>}
    </span>
  );
}
