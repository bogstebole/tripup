// The app's `easedFade`: a fade from a color to clear that holds solid until `from` of the way, then eases in and
// out (a smoothstep, in 8 steps), so neither where it starts nor where it ends shows as a line the way a straight
// fade does. Used by the bars and the pop-ups' header.

const STEPS = 8;
const smoothstep = (x: number) => x * x * (3 - 2 * x);

/** A CSS gradient from `color` (a token, e.g. `var(--color-bg-default)`) to clear. `from` is a percentage or a
 *  CSS length; `to` is the direction the fade runs toward. */
export function easedFade(color: string, { from = '0%', to = 'bottom' }: { from?: string; to?: 'top' | 'bottom' } = {}) {
  const stops = Array.from({ length: STEPS + 1 }, (_, i) => {
    const alpha = (1 - smoothstep(i / STEPS)) * 100;
    // from + (1 - from) · i/steps, as a share of the whole
    const at = `calc(${from} + (100% - ${from}) * ${i / STEPS})`;
    return `color-mix(in srgb, ${color} ${alpha}%, transparent) ${at}`;
  });
  return `linear-gradient(to ${to}, ${stops.join(', ')})`;
}
