import { useLayoutEffect, useRef, useState } from 'react';
import tokens from '../../../design-system/tokens.json';
import { photoUrl } from '../data';
import './PhotoCarousel.css';

const dim = tokens.component.dimension;
const gap = tokens.space.xs;
// Small and medium keep the design's peek widths; large takes the rest
const small = dim['photos/peek-start'] as number;
const medium = dim['photos/peek-end'] as number;

type Slot = { x: number; w: number };
const lerp = (a: Slot, b: Slot, t: number): Slot => ({ x: a.x + (b.x - a.x) * t, w: a.w + (b.w - a.w) * t });

/**
 * The place's photos as a Material 3 multi-browse carousel: a large photo first, then a medium and a small one.
 * Each photo is a mask that grows or shrinks as it moves between those places (the picture inside stays full
 * size, so it reveals rather than squashes), and scrolling snaps to whole photos. Same as Flutter's
 * CarouselView.weighted in the app.
 */
export function PhotoCarousel({ photos }: { photos: string[] }) {
  const ref = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(0);
  const [scroll, setScroll] = useState(0);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setWidth(el.clientWidth));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const large = Math.max(0, width - medium - small - gap * 2);
  const step = large + gap;
  // Where a photo sits at each place: just gone past the start, large, medium, small, not yet in
  const places: Slot[] = [
    { x: -small - gap, w: small },
    { x: 0, w: large },
    { x: large + gap, w: medium },
    { x: large + medium + gap * 2, w: small },
    { x: width + gap, w: small },
  ];
  const at = (i: number): Slot => {
    const v = Math.min(places.length - 1, Math.max(0, i - (step ? scroll / step : 0) + 1));
    const k = Math.min(places.length - 2, Math.floor(v));
    return lerp(places[k], places[k + 1], v - k);
  };

  return (
    <div ref={ref} className="tu-carousel" onScroll={e => setScroll(e.currentTarget.scrollLeft)} role="group" aria-label="Photos">
      <div className="tu-carousel__stage" style={{ width }}>
        {photos.map((ph, i) => {
          const s = at(i);
          return (
            <span key={ph} className="tu-carousel__item" style={{ transform: `translateX(${s.x}px)`, width: s.w }}>
              <img src={photoUrl(ph)} alt="" style={{ width: large }} />
            </span>
          );
        })}
      </div>
      {/* One snap point per photo, so scrolling settles on whole photos */}
      <div className="tu-carousel__track" style={{ width: step * (photos.length - 1) + width }}>
        {photos.map(ph => <span key={ph} className="tu-carousel__snap" style={{ width: step }} />)}
      </div>
    </div>
  );
}
