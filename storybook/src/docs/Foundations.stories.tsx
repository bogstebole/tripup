import type { Meta, StoryObj } from '@storybook/react-vite';
import tokens from '../../../design-system/tokens.json';

const meta = { title: 'Foundations', parameters: { layout: 'padded' } } satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

const label = { color: 'var(--color-text-muted)' };
const cell = { padding: 'var(--space-xs) var(--space-sm)', borderBottom: '1px solid var(--color-border-default)', textAlign: 'left' as const, verticalAlign: 'middle' as const };
const kebab = (s: string) => s.replace(/[/.]/g, '-');

function Table({ head, rows }: { head: string[]; rows: React.ReactNode[][] }) {
  return (
    <table className="text-body-sm" style={{ borderCollapse: 'collapse', width: '100%', maxWidth: 880 }}>
      <thead><tr>{head.map(h => <th key={h} className="text-label-sm" style={{ ...cell, ...label }}>{h}</th>)}</tr></thead>
      <tbody>{rows.map((r, i) => <tr key={i}>{r.map((c, j) => <td key={j} style={cell}>{c}</td>)}</tr>)}</tbody>
    </table>
  );
}
const swatch = (v: string) => <span style={{ display: 'inline-block', width: 'var(--space-3xl)', height: 'var(--space-xl)', borderRadius: 'var(--radius-sm)', background: v, boxShadow: 'inset 0 0 0 1px var(--color-border-default)' }} />;

export const Colors: Story = {
  render: () => (
    <Table
      head={['Token', 'Value', 'Light', 'Dark']}
      rows={Object.keys(tokens.color.light).map(k => [
        <code>{k}</code>,
        <span style={label}>{(tokens.color.light as Record<string, string>)[k]} · {(tokens.color.dark as Record<string, string>)[k]}</span>,
        swatch(`var(--color-${kebab(k)})`),
        <span data-theme="dark" style={{ display: 'inline-block', padding: 'var(--space-2xs)', background: 'var(--color-bg-canvas)', borderRadius: 'var(--radius-sm)' }}>{swatch(`var(--color-${kebab(k)})`)}</span>,
      ])}
    />
  ),
};

// The primitives components may use as they are: colors that stay the same in light and dark (t.primitive.code)
const paletteVars = () => [...document.styleSheets].flatMap(sheet => {
  try { return [...sheet.cssRules]; } catch { return []; }
}).flatMap(rule => rule instanceof CSSStyleRule && rule.selectorText === ':root' ? [...rule.style].filter(p => p.startsWith('--palette-')) : []);

export const Palette: Story = {
  name: 'Palette (code)',
  render: () => (
    <Table head={['Token', 'Value', 'Swatch']} rows={[...new Set(paletteVars())].map(v => [<code>{v.slice(2)}</code>, <span style={label}>{getComputedStyle(document.documentElement).getPropertyValue(v)}</span>, swatch(`var(${v})`)])} />
  ),
};

// What a few component sizes are for, where the name doesn't say
const DIMENSION_NOTES: Record<string, string> = {
  'chip/face-overlap': 'How far the faces overlap in a chip (Up next, the poll, the bill)',
  'pin/tail-width': 'The blue pin tail under a widget',
  'action-bar/fade-start': 'Where the footer\'s white starts fading (0 = at the bottom)',
};
// Why each one is a token: everything else is a semantic token or a component's own number
const SHARED_WITH_WIDGET = ['poll/lost-opacity', 'poll/live-dot', 'sticker/mini'];
const dimEntries = Object.entries(tokens.component.dimension) as [string, string | number][];
const isDerived = (v: string | number) => typeof v === 'string' && /[-+*/]/.test(v.replace(/\{[^}]+\}/g, ''));
const why = (k: string, v: string | number) =>
  isDerived(v) ? 'Derived from the tokens it names'
    : dimEntries.some(([, o]) => isDerived(o) && String(o).includes(`{${k}}`)) ? 'A derived token is made from it'
      : SHARED_WITH_WIDGET.includes(k) ? 'Shared with the Live Activity'
        : 'Used by several components';
const unitless = (k: string) => /(fade-start|scale|tilt|opacity)$/.test(k);
// A size token is a number or a reference like "{space.xl}"; read the px it points at
const px = (v: string | number) => {
  if (typeof v === 'number') return v;
  const [, group, key] = /^\{(\w+)\.(.+)\}$/.exec(v) ?? [];
  return (tokens as unknown as Record<string, Record<string, number>>)[group]?.[key];
};
// A computed one ("{space.md} + {button/lg} / 2", or another component dimension) is read from the built CSS
const value = (k: string, v: string | number) =>
  px(v) ?? parseFloat(getComputedStyle(document.documentElement).getPropertyValue(`--d-${kebab(k)}`));

export const ComponentDimensions: Story = {
  name: 'Component dimensions',
  render: () => (
    <Table
      head={['Token', 'Points at', 'Value', '', 'Why a token', 'Used for']}
      rows={dimEntries.filter(([k]) => !k.startsWith('$')).map(([k, v]) => [
        <code>d/{k}</code>,
        <span style={label}>{typeof v === 'string' ? v : ''}</span>,
        unitless(k) ? value(k, v) : `${value(k, v)} px`,
        unitless(k) ? '' : <span style={{ display: 'inline-block', height: 'var(--space-xs)', width: `min(var(--d-${kebab(k)}), var(--space-5xl) * 2)`, background: 'var(--color-bg-brand)', borderRadius: 'var(--radius-sm)' }} />,
        <span style={label}>{why(k, v)}</span>,
        <span style={label}>{DIMENSION_NOTES[k] ?? ''}</span>,
      ])}
    />
  ),
};

export const Typography: Story = {
  render: () => (
    <Table
      head={['Style', 'Font · size / line · weight', 'Sample']}
      rows={Object.entries(tokens.text).map(([k, v]) => [
        <code>{k}</code>,
        <span style={label}>{v.font} · {v.size}/{v.line} · {v.weight}</span>,
        <span className={`text-${k}`}>La Brasserie de L'Entrecôte</span>,
      ])}
    />
  ),
};

export const SpaceAndRadius: Story = {
  name: 'Space and radius',
  render: () => (
    <div style={{ display: 'grid', gap: 'var(--space-2xl)' }}>
      <Table head={['Space', 'px', '']} rows={Object.entries(tokens.space).map(([k, v]) => [<code>space/{k}</code>, v, <span style={{ display: 'inline-block', height: 'var(--space-xs)', width: `var(--space-${k})`, background: 'var(--color-bg-brand)', borderRadius: 'var(--radius-sm)' }} />])} />
      <Table head={['Radius', 'px', '']} rows={Object.entries(tokens.radius).map(([k, v]) => [<code>radius/{k}</code>, v, <span style={{ display: 'inline-block', width: 'var(--space-4xl)', height: 'var(--space-2xl)', background: 'var(--color-bg-muted)', borderRadius: `var(--radius-${k})` }} />])} />
    </div>
  ),
};

const INSET_BG: Record<string, string> = { 'button-soft': 'var(--color-bg-muted)', 'button-primary': 'var(--palette-blue-700)', 'button-danger': 'var(--color-bg-danger)' };

export const Shadows: Story = {
  render: () => (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-2xl)', padding: 'var(--space-2xl)', background: 'var(--color-bg-canvas)' }}>
      {Object.keys(tokens.shadow).filter(k => !k.startsWith('$')).map(k => (
        <div key={k} style={{ display: 'grid', gap: 'var(--space-xs)', justifyItems: 'center' }}>
          <span style={{ width: 'var(--space-5xl)', height: 'var(--space-5xl)', borderRadius: 'var(--radius-card)', background: 'var(--color-bg-default)', boxShadow: `var(--shadow-${k})` }} />
          <code className="text-caption">{k}</code>
        </div>
      ))}
      {Object.keys(tokens.inset).filter(k => !k.startsWith('$')).map(k => (
        <div key={k} style={{ display: 'grid', gap: 'var(--space-xs)', justifyItems: 'center' }}>
          <span style={{ width: 'var(--space-5xl)', height: 'var(--space-5xl)', borderRadius: 'var(--radius-pill)', background: INSET_BG[k], boxShadow: `var(--inset-${k}), var(--shadow-slightly-raised)` }} />
          <code className="text-caption">inset/{k}</code>
        </div>
      ))}
    </div>
  ),
};

export const Motion: Story = {
  render: () => (
    <Table
      head={['Token', 'Value', 'Used for']}
      rows={[
        ['spring-morph', `${tokens.motion['spring-morph'].duration} s, bounce ${tokens.motion['spring-morph'].bounce}`, 'Widget mid ↔ mini ↔ edge'],
        ['spring-expand', `${tokens.motion['spring-expand'].duration} s, bounce ${tokens.motion['spring-expand'].bounce}`, 'Widget → full view and back'],
        ['spring-collapse', `${tokens.motion['spring-collapse'].duration} s, bounce ${tokens.motion['spring-collapse'].bounce}`, 'Full view → card: quicker than opening, no bounce'],
        ['spring-open', `${tokens.motion['spring-open'].duration} s, bounce ${tokens.motion['spring-open'].bounce}`, 'Your trips → the trip opening out of its card: a full-screen container, so no bounce'],
        ['spring-snap', `${tokens.motion['spring-snap'].duration} s, bounce ${tokens.motion['spring-snap'].bounce}`, 'Tab pill, map recenter'],
        ['crossfade-blur', `${tokens.motion['crossfade-blur']} px`, 'Blur on the seam while two states overlap (never a blank frame)'],
        ['enter-blur', `${tokens.motion['enter-blur']} px`, 'Blur on a part while it is half faded in or out (tab pages, widget parts)'],
        ['morph-enter-scale', `${tokens.motion['morph-enter-scale']}`, 'Scale a widget part grows from as it arrives (fan stickers, chips)'],
        ['press-scale / press-ms', `${tokens.motion['press-scale']} / ${tokens.motion['press-ms']} ms`, 'Every button press'],
        ['fade-ms', `${tokens.motion['fade-ms']} ms, ease-out`, 'Content crossfades; a pop-up going back down'],
        ['open-delay-ms / open-stagger-ms / open-item-ms', `${tokens.motion['open-delay-ms']} / ${tokens.motion['open-stagger-ms']} / ${tokens.motion['open-item-ms']} ms`, 'The trip\'s entrance: each control in on its own as the trip opens, Up next last'],
        ['enter-ms / stagger-ms', `${tokens.motion['enter-ms']} ms / ${tokens.motion['stagger-ms']} ms`, 'A pop-up rising from the bottom; blocks arriving one after another (up to stagger-max ' + tokens.motion['stagger-max'] + ')'],
        ['toast-ms', `${tokens.motion['toast-ms']} ms`, 'How long a note stays up ("Link copied")'],
        ['ease-out', tokens.motion['ease-out'].join(', '), 'Entering, fades'],
        ['ease-in-out', tokens.motion['ease-in-out'].join(', '), 'Moving on screen'],
        ['settle-ms', `${tokens.motion['settle-ms']} ms`, 'How long the map must be still before the bottom actions come back'],
        ['pulse-ms / ease-breathe', `${tokens.motion['pulse-ms']} ms each way / ${tokens.motion['ease-breathe'].join(', ')}`, 'My location breathing (only the blue, down to me/pulse-scale); still with reduced motion'],
      ].map(([a, b, c]) => [<code>{a}</code>, b, c])}
    />
  ),
};
