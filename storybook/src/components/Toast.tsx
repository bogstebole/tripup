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
 * and Undo (or just the line, e.g. "Link copied"). A line too long for the width ends in an ellipsis; Undo always
 * shows. Every note comes from the top of the screen, where the top bar's buttons are: it slides down from above the
 * edge and goes back up the way it came, a little quicker; CSS transitions, so a new one while it's up just
 * retargets. Its place is the screen's (see NoticeLayer).
 */
export function Toast({ label, shown, actionLabel, onAction }: ToastProps) {
  return (
    <div className={actionLabel ? 'tu-toast' : 'tu-toast tu-toast--plain'} data-shown={shown || undefined} role="status" aria-live="polite" aria-hidden={!shown}>
      <Check className="tu-toast__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
      <span className="text-label-md tu-toast__label">{label}</span>
      {actionLabel && (
        <button type="button" className="tu-toast__action text-label-md weight-bold" onClick={onAction} tabIndex={shown ? 0 : -1}>
          {actionLabel}
        </button>
      )}
    </div>
  );
}
