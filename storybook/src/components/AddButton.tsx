import { Check, Plus } from 'lucide-react';
import './Button.css';
import './AddButton.css';

export interface AddButtonProps {
  added: boolean;
  /** The dish, for the accessible name. */
  itemName: string;
  onToggle?: () => void;
}

/** Small pill on a menu row: "Add" in soft glass, "Added" in primary glass. One tap toggles it. */
export function AddButton({ added, itemName, onToggle }: AddButtonProps) {
  const Icon = added ? Check : Plus;
  return (
    <button
      type="button"
      aria-pressed={added}
      aria-label={added ? `Remove ${itemName} from your picks` : `Add ${itemName} to your picks`}
      className={`tu-add ${added ? 'tu-btn--primary' : 'tu-btn--soft'}`}
      onClick={onToggle}
    >
      <Icon className="tu-add__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
      <span className="text-label-md">{added ? 'Added' : 'Add'}</span>
    </button>
  );
}
