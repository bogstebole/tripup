# Design tokens v1 (Figma variables)

Figma file G13GoEmstoKyMr5nCh8eoQ → Local variables. Built 21 Oct 2026.

| Collection | Modes | Variables | What's in it |
|---|---|---|---|
| Primitives | Value | 348 | Tailwind palette (22 × 50–950, white, black), `brand/*` → blue, `base/*` → zinc, spacing, radius, font size / line height / weight, `font/family/sans` = Geist, `mono` = Geist Mono. Hidden from pickers. |
| Color | Light, Dark | 37 | `bg/*`, `text/*`, `border/*`, `icon/*` |
| Layout | Mobile | 23 | `space/*`, `radius/*`, `size/*` |
| Typography | Value | 48 | size, line height, weight, family per text style |

Text styles (Geist, bound to Typography): Display 36/40 Bold · Heading XL 30/36 Bold · LG 24/32 · MD 20/28 · SM 18/28 SemiBold · Body LG 18/28 · MD 16/24 · SM 14/20 Regular · Label LG 16/24 · MD 14/20 · SM 12/16 Medium · Caption 12/16 Regular. Headings have −0.5% to −2% tracking.

## Color (Light / Dark)
| Token | Light | Dark |
|---|---|---|
| bg/default | white | base-950 |
| bg/subtle | base-50 | base-900 |
| bg/muted | base-100 | base-800 |
| bg/surface | white | base-900 |
| bg/inverse | base-900 | base-50 |
| bg/brand · hover · subtle | brand-600 · 700 · 50 | brand-600 · 500 · 950 |
| bg/success · subtle | emerald-600 · 50 | emerald-600 · 950 |
| bg/warning · subtle | amber-500 · 50 | amber-400 · 950 |
| bg/danger · subtle | red-600 · 50 | red-600 · 950 |
| text/default · muted · subtle | base-950 · 500 · 400 | base-50 · 400 · 500 |
| text/inverse · on-brand | white · white | base-950 · white |
| text/brand · success · warning · danger | brand-600 · emerald-700 · amber-700 · red-600 | brand-400 · emerald-400 · amber-400 · red-400 |
| border/default · strong · subtle | base-200 · 300 · 100 | base-800 · 700 · 900 |
| border/brand · focus · danger | brand-600 · brand-500 · red-500 | brand-500 · brand-400 · red-400 |
| icon/default · muted · inverse | base-900 · 500 · white | base-100 · 400 · base-950 |
| icon/brand · on-brand | brand-600 · white | brand-400 · white |
| icon/success · warning · danger | emerald-600 · amber-500 · red-600 | emerald-400 · amber-400 · red-400 |

## Layout
- space: none 0 · 3xs 2 · 2xs 4 · xs 8 · sm 12 · md 16 · lg 20 · xl 24 · 2xl 32 · 3xl 40 · 4xl 48 · 5xl 64 · screen-x 20
- radius: none 0 · sm 4 · control 12 · card 16 · sheet 24 · pill full
- size: icon-sm 16 · icon-md 20 · icon-lg 24 · touch-target 44

## Notes
- Brand is a placeholder (blue). To change it, re-point the 11 `color/brand/*` aliases in Primitives. Same for the neutral: `color/base/*` (zinc).
- Palette hex is Tailwind v3.4.17 (sRGB). Names and CSS variables follow Tailwind v4 (`--color-zinc-50`, `--text-sm`, `--radius-xl`, `--font-sans`); v4's oklch colors look nearly the same.
- Figma doesn't allow "." in variable names, so `spacing/0.5` is `spacing/0_5` (also 1_5, 2_5, 3_5).
