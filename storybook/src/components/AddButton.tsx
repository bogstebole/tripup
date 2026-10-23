import { Check, Plus } from 'lucide-react';
import './Button.css';
import './AddButton.css';

export interface AddButtonProps {
  added: boolean;
  /** The dish, for the accessible name. */
  itemName: string;
  onToggle?: () => void;
}

/** Small round button on a menu row: a plus in soft glass, a check in primary glass once added. One tap toggles it. */
export function AddButton({ added, itemName, onToggle }: AddButtonProps) {
  const Icon = added ? Check : Plus;
  return (
    <button
      type="button"
      aria-pressed={added}
      aria-label={added ? `Remove ${itemName} from your picks` : `Add ${itemName} to your picks`}
      className="tu-add"
      onClick={onToggle}
    >
      <span className={`tu-add__circle ${added ? 'tu-btn--primary' : 'tu-btn--soft'}`}>
        <Icon key={String(added)} className="tu-add__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
      </span>
    </button>
  );
}
