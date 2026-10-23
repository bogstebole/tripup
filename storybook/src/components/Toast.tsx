import { Check } from 'lucide-react';
import './Toast.css';

export interface ToastProps {
  /** The one line that matters, e.g. "Added for Today, 5 PM". */
  label: string;
  shown: boolean;
  actionLabel?: string;
  onAction?: () => void;
  /** `bottom` (the default): a pop-up's note, from past its bottom edge. `top`: a note for everyone on the trip
   *  ("Leo paid Maya €185.92"), sliding down at the top of the screen, where the top bar's buttons are. */
  place?: 'bottom' | 'top';
}

/**
 * A short note: a flat pill in the brand blue (not glass, so it doesn't read as a button), with a check, one line
 * and Undo (or just the line, e.g. "Link copied"). It comes up from past the bottom edge and goes back down the way it came; CSS transitions, so a new
 * one while it's up just retargets. At the top, it slides down from above the edge and goes back up.
 */
export function Toast({ label, shown, actionLabel, onAction, place = 'bottom' }: ToastProps) {
  return (
    <div className={['tu-toast', !actionLabel && 'tu-toast--plain', place === 'top' && 'tu-toast--top'].filter(Boolean).join(' ')} data-shown={shown || undefined} role="status" aria-live="polite" aria-hidden={!shown}>
      <Check className="tu-toast__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
      <span className="text-label-md">{label}</span>
      {actionLabel && (
        <button type="button" className="tu-toast__action text-label-md weight-bold" onClick={onAction} tabIndex={shown ? 0 : -1}>
          {actionLabel}
        </button>
      )}
    </div>
  );
}
