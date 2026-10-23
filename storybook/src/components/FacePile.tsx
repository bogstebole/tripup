import { Sticker } from './Sticker';
import './FacePile.css';

/**
 * People as a little pile: up to two of their stickers, then a "+N" bubble for the rest. On the map it's a group
 * walking together (people closer than a sticker's width merge into one pile); on a pin, who's already there.
 */
export function FacePile({ faces, size = 'avatar', label }: { faces: string[]; size?: 'avatar' | 'chip'; label?: string }) {
  const more = faces.length - 2;
  return (
    <span className="tu-pile" role="img" aria-label={label}>
      {faces.slice(0, 2).map(f => <Sticker key={f} name={f} size={size} />)}
      {more > 0 && <span className="tu-pile__more text-label-md weight-bold">+{more}</span>}
    </span>
  );
}
