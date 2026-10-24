import { useId } from 'react';
import { motion, useReducedMotion } from 'motion/react';
import tokens from '../../../design-system/tokens.json';
import './SegmentedTabs.css';

export interface SegmentedTabsProps {
  tabs: string[];
  value: string;
  onChange?: (tab: string) => void;
  /** Fills the width, the tabs sharing it equally (Money's tabs); otherwise as wide as the labels. */
  wide?: boolean;
}

const { duration, bounce } = tokens.motion['spring-snap'];

/** Pill tabs on a muted track. The selected pill is a Surface that slides to the tapped tab. */
export function SegmentedTabs({ tabs, value, onChange, wide }: SegmentedTabsProps) {
  const id = useId();
  const reduce = useReducedMotion();
  return (
    <div className={wide ? 'tu-tabs tu-tabs--wide' : 'tu-tabs'} role="tablist">
      {tabs.map(tab => {
        const on = tab === value;
        return (
          <button key={tab} type="button" role="tab" aria-selected={on} className={`tu-tabs__tab text-body-sm ${on ? 'weight-medium tu-tabs__tab--on' : ''}`} onClick={() => onChange?.(tab)}>
            {on && (
              <motion.span
                layoutId={`${id}-pill`}
                className="tu-tabs__pill tu-surface tu-surface--pill"
                transition={reduce ? { duration: 0 } : { type: 'spring', duration, bounce }}
              />
            )}
            <span className="tu-tabs__label" data-label={tab}>{tab}</span>
          </button>
        );
      })}
    </div>
  );
}
