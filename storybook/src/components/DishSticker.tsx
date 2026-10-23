import { dishUrl } from '../data';
import './DishSticker.css';

export interface DishStickerProps {
  /** File name in app/assets/photos/menu, without .jpg. */
  photo: string;
  /** `menu`: on a menu card. `pick`: in a person's pile of picks. */
  size: 'menu' | 'pick';
  /** Degrees. */
  tilt?: number;
}

/** A dish photo dressed as one of the app's die-cut stickers: white edge, soft shadow, a slight tilt. */
export function DishSticker({ photo, size, tilt = 0 }: DishStickerProps) {
  return (
    <span className={`tu-dish-sticker tu-dish-sticker--${size}`} style={tilt ? { transform: `rotate(${tilt}deg)` } : undefined}>
      <img src={dishUrl(photo)} alt="" loading="lazy" />
    </span>
  );
}
