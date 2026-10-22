import type { ButtonHTMLAttributes } from 'react';
import { Sticker } from './Sticker';
import './PeopleButton.css';

export interface PeopleButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Sticker names of the first two people shown. */
  faces: [string, string];
  /** How many more people are on the trip. */
  more: number;
}

/** Soft pill in the top bar: two people stickers and a "+N" bubble. Opens the trip's people. */
export function PeopleButton({ faces, more, className, ...rest }: PeopleButtonProps) {
  return (
    <button type="button" aria-label={`${faces.length + more} people on this trip`} className={['tu-people', className].filter(Boolean).join(' ')} {...rest}>
      <span className="tu-people__faces">
        <Sticker name={faces[0]} size="avatar" />
        <Sticker name={faces[1]} size="avatar" />
      </span>
      <span className="tu-people__more text-label-md weight-bold">+{more}</span>
    </button>
  );
}
