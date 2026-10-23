import { Check } from 'lucide-react';
import './Toast.css';

export interface ToastProps {
  /** The one line that matters, e.g. "Added for Today, 5 PM". */
  label: string;
  shown: boolean;
  actionLabel?: string;
  onAction?: () => void;
}

/**
 * A short note: a flat pill in the brand blue (not glass, so it doesn't read as a button), with a check, one line
 * and Undo (or just the line, e.g. "Link copied"). It comes up from past the bottom edge and goes back down the way it came; CSS transitions, so a new
 * one while it's up just retargets.
 */
export function Toast({ label, shown, actionLabel, onAction }: ToastProps) {
  return (
    <div className={actionLabel ? 'tu-toast' : 'tu-toast tu-toast--plain'} data-shown={shown || undefined} role="status" aria-live="polite" aria-hidden={!shown}>
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
