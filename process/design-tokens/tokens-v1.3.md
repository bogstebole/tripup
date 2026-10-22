# Design tokens v1.3 (Figma variables)

Figma file G13GoEmstoKyMr5nCh8eoQ → Local variables. Built 21 Oct 2026. v1.1: Display and Heading styles use IBM Plex Sans Condensed. v1.2 (22 Oct): clearer surface layers, two Elevation shadows. v1.3 (22 Oct): Body and Label in every weight.

| Collection | Modes | Variables | What's in it |
|---|---|---|---|
| Primitives | Value | 355 | Tailwind palette (22 × 50–950, white, black) plus zinc 150 / 750 / 850, `brand/*` → blue, `base/*` → zinc, spacing, radius, font size / line height / weight, `font/family/sans` = Geist, `display` = IBM Plex Sans Condensed, `mono` = Geist Mono. Hidden from pickers. |
| Color | Light, Dark | 38 | `bg/*`, `text/*`, `border/*`, `icon/*` |
| Layout | Mobile | 23 | `space/*`, `radius/*`, `size/*` |
| Typography | Value | 52 | size, line height, weight, family per text style, plus `font-weight/regular · medium · semibold · bold` |

Text styles (bound to Typography):
- IBM Plex Sans Condensed (`font/family/display`): Display 36/40 · Heading XL 30/36 · LG 24/32 · MD 20/28 · SM 18/28, all Bold. Tracking 0.
- Geist (`font/family/sans`): Body LG 18/28 · MD 16/24 · SM 14/20 · Label LG 16/24 · MD 14/20 · SM 12/16 · Caption 12/16 Regular.
- Weights (v1.3): every Body size as `Body/<size>/Regular · Medium · Semibold · Bold`, every Label size as `Label/<size>/Medium · Semibold · Bold`. 27 text styles in total.
  - The old `Body/MD` is now `Body/MD/Regular` and `Label/MD` is `Label/MD/Medium` (same for LG and SM). Same style ids, so text that uses them keeps working.
  - Variants share the size, line height and family variables of their base style; the weight binds to `font-weight/*`. In CSS that's the size utility plus a weight utility, e.g. `text-body-md font-semibold`.
  - Specimen: `type-weights-v1.3.png` (Figma, page Assets → "Type weights · tokens v1.3").

Effect styles: Elevation/Raised (0 1 2 6%, 0 4 12 8%) and Elevation/Overlay (0 2 6 8%, 0 16 40 16%).

Render check: `type-check-v1.1.png`, surfaces: `surfaces-v1.2.png` (Figma, page Assets → "Surfaces · tokens v1.2").

## Surfaces (v1.2)
v1.1 surfaces were nearly the same tone in light mode (white, base-50, base-100, white). v1.2 gives each layer its own step.

| Layer, back to front | Use | Light | Dark |
|---|---|---|---|
| bg/canvas (new) | App background, behind sheets and cards | base-100 #f4f4f5 | base-950 #09090b |
| bg/default | Sheets, cards, screens | white | base-900 #18181b (was 950) |
| bg/raised (was bg/surface) | Menus, popovers, dialogs, toasts, selected segment. Light: pair with an Elevation shadow | white | base-750 #333338 (was 900) |
| bg/subtle | Inside a card: section headers, hover, selected rows | base-150 #ececee (was 50) | base-850 #1f1f22 (was 900) |
| bg/muted | Wells: segmented track, chips, skeletons, image placeholders | base-200 #e4e4e7 (was 100) | base-800 #27272a |

- base-150, 750 and 850 are new in-between steps (midpoints of the zinc neighbours), so the light steps are even: white → 100 → 150 → 200.
- `bg/surface` was renamed to `bg/raised`; existing bindings keep working, the CSS name is now `--color-bg-raised`.
- `border/subtle` in dark is base-850 (was 900, the same as the new bg/default, so it disappeared).

## Color (Light / Dark)
| Token | Light | Dark |
|---|---|---|
| bg/canvas | base-100 | base-950 |
| bg/default | white | base-900 |
| bg/raised | white | base-750 |
| bg/subtle | base-150 | base-850 |
| bg/muted | base-200 | base-800 |
| bg/inverse | base-900 | base-50 |
| bg/brand · hover · subtle | brand-600 · 700 · 50 | brand-600 · 500 · 950 |
| bg/success · subtle | emerald-600 · 50 | emerald-600 · 950 |
| bg/warning · subtle | amber-500 · 50 | amber-400 · 950 |
| bg/danger · subtle | red-600 · 50 | red-600 · 950 |
| text/default · muted · subtle | base-950 · 500 · 400 | base-50 · 400 · 500 |
| text/inverse · on-brand | white · white | base-950 · white |
| text/brand · success · warning · danger | brand-600 · emerald-700 · amber-700 · red-600 | brand-400 · emerald-400 · amber-400 · red-400 |
| border/default · strong · subtle | base-200 · 300 · 100 | base-800 · 700 · 850 |
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
