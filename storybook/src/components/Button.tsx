import type { ButtonHTMLAttributes } from 'react';
import type { LucideIcon } from 'lucide-react';
import './Button.css';

export type ButtonVariant = 'soft' | 'primary';
export type ButtonSize = 'sm' | 'md' | 'lg';

export interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children'> {
  /** `soft`: grey glass button for everything secondary. `primary`: blue, the one main action on screen. */
  variant?: ButtonVariant;
  /** `sm` 40 inside cards and sheets · `md` 44 in the top bar · `lg` 56 in the action bar. */
  size?: ButtonSize;
  /** A Lucide icon component, e.g. `ArrowRight`. Always 16 px with a 2 px stroke. */
  icon: LucideIcon;
  /** Accessible name. Icon-only buttons have no visible text, so this is required. */
  label: string;
}

/** Round icon button. Every icon button in TripUp is this component. */
export function Button({ variant = 'soft', size = 'md', icon: Icon, label, className, ...rest }: ButtonProps) {
  return (
    <button type="button" aria-label={label} className={['tu-btn', `tu-btn--${variant}`, `tu-btn--${size}`, className].filter(Boolean).join(' ')} {...rest}>
      <Icon className="tu-btn__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
    </button>
  );
}
