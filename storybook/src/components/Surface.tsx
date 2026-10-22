import type { HTMLAttributes } from 'react';
import './Surface.css';

export interface SurfaceProps extends HTMLAttributes<HTMLDivElement> {
  /** `sheet` 24 px corners for cards and the detail sheet, `pill` for round chips and the selected tab. */
  shape?: 'sheet' | 'pill';
}

/** The raised white glass every widget sits on: soft top-to-bottom fade, 1 px light edge, surface shadow. */
export function Surface({ shape = 'sheet', className, ...rest }: SurfaceProps) {
  return <div className={['tu-surface', `tu-surface--${shape}`, className].filter(Boolean).join(' ')} {...rest} />;
}
