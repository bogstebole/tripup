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

/** The rest of a person's picks, as one more sticker on the pile: "+2". */
export function DishMore({ count, tilt = 0 }: { count: number; tilt?: number }) {
  return (
    <span className="tu-dish-sticker tu-dish-sticker--pick tu-dish-more" style={tilt ? { transform: `rotate(${tilt}deg)` } : undefined}>
      <span className="tu-dish-more__count text-label-md weight-bold">+{count}</span>
    </span>
  );
}
