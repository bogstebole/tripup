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

export const ComponentColors: Story = {
  name: 'Component colors',
  render: () => (
    <Table head={['Token', 'Points at', 'Swatch']} rows={Object.entries(tokens.component.color).map(([k, v]) => [<code>c/{k}</code>, <span style={label}>{v}</span>, swatch(`var(--c-${kebab(k)})`)])} />
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
          <span style={{ width: 'var(--space-5xl)', height: 'var(--space-5xl)', borderRadius: 'var(--radius-pill)', background: `var(--c-${k}-bg)`, boxShadow: `var(--inset-${k}), var(--shadow-slightly-raised)` }} />
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
        ['spring-snap', `${tokens.motion['spring-snap'].duration} s, bounce ${tokens.motion['spring-snap'].bounce}`, 'Tab pill, map recenter'],
        ['crossfade-blur', `${tokens.motion['crossfade-blur']} px`, 'Blur on the seam while two states overlap (never a blank frame)'],
        ['press-scale / press-ms', `${tokens.motion['press-scale']} / ${tokens.motion['press-ms']} ms`, 'Every button press'],
        ['fade-ms', `${tokens.motion['fade-ms']} ms, ease-out`, 'Content crossfades'],
        ['ease-out', tokens.motion['ease-out'].join(', '), 'Entering, fades'],
        ['ease-in-out', tokens.motion['ease-in-out'].join(', '), 'Moving on screen'],
      ].map(([a, b, c]) => [<code>{a}</code>, b, c])}
    />
  ),
};
