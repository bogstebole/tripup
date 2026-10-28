import type { CSSProperties } from 'react';
import { stickerUrl } from '../data';

export type StickerSize = 'avatar' | 'chip' | 'mini' | 'edge' | 'row' | 'map';

/** Each sticker size's height. Only mini is its own token (the Live Activity shares it); the rest are the scale's sizes. */
export const stickerHeight: Record<StickerSize, string> = {
  avatar: 'var(--space-2xl)',
  chip: 'var(--size-icon-lg)',
  mini: 'var(--d-sticker-mini)',
  edge: 'var(--size-icon-md)',
  row: 'var(--space-3xl)',
  map: 'var(--size-touch-target)',
};

export interface StickerProps {
  /** File name in app/assets/stickers, without .png. */
  name: string;
  /** A sticker size token (height; width follows the image), or an exact height for hand-placed compositions. Left out,
   *  its height comes from `className` or `style`: a component's own size token, or a share of a frame that scales. */
  size?: StickerSize | number;
  /** Tilt in degrees; stickers look hand-placed, not aligned. */
  tilt?: number;
  className?: string;
  style?: CSSProperties;
}

/** A die-cut photo sticker (white outline baked into the image). */
export function Sticker({ name, size, tilt = 0, className, style }: StickerProps) {
  const height = typeof size === 'number' || size === undefined ? size : stickerHeight[size];
  return (
    <img
      src={stickerUrl(name)}
      alt=""
      className={className}
      style={{ height, width: 'auto', flex: 'none', transform: tilt ? `rotate(${tilt}deg)` : undefined, ...style }}
      draggable={false}
    />
  );
}
