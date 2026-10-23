import { Star } from 'lucide-react';
import './RatingLine.css';

export interface RatingLineProps {
  rating: string;
  /** Cuisine or place type, e.g. "French". */
  kind: string;
  align?: 'center' | 'start';
}

/** Filled brand star, rating with review count, then the place type. */
export function RatingLine({ rating, kind, align = 'center' }: RatingLineProps) {
  return (
    <div className={`tu-rating tu-rating--${align}`}>
      <span className="tu-rating__score">
        <Star className="tu-rating__star" fill="currentColor" strokeWidth={2} absoluteStrokeWidth aria-hidden />
        <span className="text-label-md">{rating}</span>
      </span>
      <span className="text-label-md" aria-hidden>-</span>
      <span className="text-label-md">{kind}</span>
    </div>
  );
}
