// The small drawn shapes on the map: the pin tail under a widget, the edge arrow, and my location.
// Geometry is traced from the Figma vectors; every color and shadow comes from tokens.
import { useId } from 'react';
import './MapShapes.css';

/** The rounded tail under a widget plus the blue dash that marks the exact spot on the map. */
export function PinTail({ gap = 'xs' }: { gap?: 'xs' | '2xs' }) {
  const id = useId();
  return (
    <span className="tu-tail" style={{ gap: `var(--space-${gap})` }} aria-hidden>
      <svg className="tu-tail__shape" viewBox="0 0 35.28 24">
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" style={{ stopColor: 'var(--c-surface-top)' }} />
            <stop offset="1" style={{ stopColor: 'var(--c-surface-bottom)' }} />
          </linearGradient>
        </defs>
        <path
          d="M20.8721 20.5675L30.5049 7.35669C32.4324 4.71336 30.5443 1 27.2729 1H8.00714C4.73573 1 2.84768 4.71336 4.77511 7.35669L14.408 20.5675C16.0057 22.7586 19.2744 22.7586 20.8721 20.5675Z"
          fill={`url(#${id})`}
          style={{ stroke: 'var(--c-surface-edge)', strokeWidth: 'var(--d-surface-edge-width)' }}
        />
      </svg>
      <span className="tu-tail__dash" />
    </span>
  );
}

/** Blue rounded triangle pointing toward something off-screen. `angle` 0 points down, 90 left. */
export function EdgeArrow({ angle = 90 }: { angle?: number }) {
  const id = useId();
  return (
    <svg className="tu-edge-arrow" viewBox="3.2 0.5 12.6 10.2" style={{ transform: `rotate(${angle}deg)` }} aria-hidden>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" style={{ stopColor: 'var(--c-edge-arrow-from)' }} />
          <stop offset="1" style={{ stopColor: 'var(--c-edge-arrow-to)' }} />
        </linearGradient>
      </defs>
      <path d="M11.1444 9.47125L15.2316 3.86584C16.1954 2.54418 15.2513 0.6875 13.6156 0.6875H5.44107C3.80536 0.6875 2.86134 2.54418 3.82506 3.86584L7.91233 9.47125C8.71117 10.5668 10.3455 10.5668 11.1444 9.47125Z" fill={`url(#${id})`} />
    </svg>
  );
}

/** My location: blue dot with a white edge, and a soft cone showing which way I'm facing. */
export function MeMarker({ heading = 0 }: { heading?: number }) {
  return (
    <span className="tu-me" aria-label="Your location">
      <span className="tu-me__cone" style={{ transform: `rotate(${heading}deg)` }} />
      <span className="tu-me__dot" />
    </span>
  );
}

/** Shown on the screen edge when I'm off-screen: a glow pointing in, and a blue capsule. `angle` 0 = right edge. */
export function MeEdge({ angle = 0 }: { angle?: number }) {
  return (
    <span className="tu-me-edge" style={{ transform: `rotate(${angle}deg)` }} aria-label="Your location is this way">
      <span className="tu-me-edge__glow" />
      <span className="tu-me-edge__capsule" />
    </span>
  );
}
