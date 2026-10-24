import type { Meta, StoryObj } from '@storybook/react-vite';
import { useState } from 'react';
import { EVENT, TRIP_DAYS, upNextChips } from '../data';
import { AddButton } from './AddButton';
import { Toast } from './Toast';
import { ToggleChips } from './ToggleChips';
import { DishSticker } from './DishSticker';
import { FacePile } from './FacePile';
import { InfoChips } from './InfoChips';
import { KnowSection, KnowTip } from './KnowSection';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { Surface } from './Surface';

const meta = { title: 'Components/Basics', parameters: { layout: 'centered' } } satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const SurfaceCard: Story = {
  name: 'Surface',
  parameters: { docs: { description: { story: 'The raised glass every widget sits on: bg/default → bg/subtle fade, 1 px edge, surface shadow, 24 px corners (`pill` for chips and the selected tab).' } } },
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-xl)', alignItems: 'center' }}>
      <Surface style={{ width: 'var(--d-widget-mid-width)', height: 'var(--d-photos-height)' }} />
      <Surface shape="pill" style={{ width: 'var(--d-widget-edge-size)', height: 'var(--d-widget-edge-size)' }} />
    </div>
  ),
};

export const Rating: Story = {
  name: 'RatingLine',
  parameters: { docs: { description: { story: 'Filled brand star, rating and review count, then the place type. Centered on the widget, start-aligned in the sheet.' } } },
  render: () => <div style={{ width: 'var(--d-widget-mid-width)' }}><RatingLine rating={EVENT.rating} kind={EVENT.cuisine} /></div>,
};

export const Chips: Story = {
  name: 'InfoChips',
  parameters: { docs: { description: { story: 'Joined facts about a plan, as on the Up next card. Only the outer corners are rounded. The first chip says how many are coming; once people arrive, it becomes every arrived face, overlapped (chip/face-overlap), then "here". The second is the price range. The two share the width equally until four or more faces need the room; then the price shrinks to its text.' } } },
  render: () => (
    // As wide as on the card: its width less the padding, the gap and the open button
    <div style={{ width: 'calc(var(--d-widget-mid-width) - var(--space-xs) * 2 - var(--space-md) - var(--d-button-sm))', display: 'grid', gap: 'var(--space-md)' }}>
      {[[], ['person-01'], ['person-01', 'person-05', 'person-02', 'person-04']].map(here => (
        <div key={here.length} style={{ display: 'flex' }}><InfoChips items={upNextChips(here)} /></div>
      ))}
    </div>
  ),
};

export const Tabs: Story = {
  name: 'SegmentedTabs',
  parameters: { docs: { description: { story: 'Pill tabs on a muted track. The selected pill is a Surface that springs to the tapped tab (spring-snap: 0.35 s, no bounce). As wide as its labels; `wide` fills the width it\'s given, the tabs sharing it equally (Money\'s tabs, see Pop-ups › Money).' } } },
  render: function Render() {
    const [tab, setTab] = useState('Overview');
    return <SegmentedTabs tabs={['Overview', 'Menu', 'Group']} value={tab} onChange={setTab} />;
  },
};

export const Know: Story = {
  name: 'KnowSection',
  parameters: { docs: { description: { story: 'Know before you go, on a place\'s Overview (Bogdan\'s block, Figma 62:4828): a subtle group (bg-subtle, radius-sheet; md in at the top, xs on the other sides) with a brand heading (heading-sm), then each tip, xs apart, as a plain line in brand (label-sm) on a muted block (bg-muted, radius-card, at least know-row/height 56 tall, sm in from the sides and xs from the top and bottom, the line centred in it top to bottom). Tips are read, not tapped: no arrow, no glass, no press.' } } },
  render: () => (
    <div style={{ width: 343 }}>
      <KnowSection title="Know before you go">{EVENT.tips.map(t => <KnowTip key={t}>{t}</KnowTip>)}</KnowSection>
    </div>
  ),
};

export const Add: Story = {
  name: 'AddButton',
  parameters: { docs: { description: { story: 'Small round button on a menu row, icon only: a plus in soft glass, a check in primary glass (blue-700) once added. The circle is 32 px; the touch target around it is 44 px. One tap toggles it; on the phone it also ticks a light haptic.' } } },
  render: function Render() {
    const [added, setAdded] = useState(false);
    return <div style={{ display: 'flex', gap: 'var(--space-md)' }}><AddButton added={added} itemName="Crème brûlée" onToggle={() => setAdded(a => !a)} /><AddButton added itemName="Fries" /></div>;
  },
};

export const Days: Story = {
  name: 'ToggleChips',
  parameters: { docs: { description: { story: 'A row of toggles, used for the days under the top bar ("Tue 12") and the courses in the menu. Flat (muted fill, no shadow) when off, primary glass when on, so only the picked ones stand out. Days combine; with none picked, All is on. On the map, other days\' pins and places fade out and the map frames what is left; All brings back the opening view. Scrolls sideways.' } } },
  render: function Render() {
    const [days, setDays] = useState<number[]>([]);
    return <div style={{ width: 393 }}><ToggleChips label="Filter by day" options={TRIP_DAYS.map(d => ({ id: d.day, label: d.label }))} selected={days} onChange={setDays} /></div>;
  },
};

export const Dish: Story = {
  name: 'DishSticker',
  parameters: { docs: { description: { story: 'A dish photo dressed as one of the app\'s die-cut stickers: white edge, soft shadow, a slight tilt that alternates down a list. `menu` (64 px, 4 px edge) sits on a menu card; `pick` (32 px, 2 px edge) piles up next to a person to show what they\'ll have.' } } },
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-xl)', alignItems: 'center' }}>
      <DishSticker photo="entrecote" size="menu" tilt={-3} />
      <DishSticker photo="creme-brulee" size="menu" tilt={3} />
      <span style={{ display: 'flex', gap: 'var(--space-3xs)' }}><DishSticker photo="entrecote" size="pick" tilt={3} /><DishSticker photo="fondant" size="pick" tilt={-3} /></span>
    </div>
  ),
};

export const Note: Story = {
  name: 'Toast',
  parameters: { docs: { description: { story: 'A flat pill in the brand blue (not glass, so it does not read as a button): a check, the one line that matters, and Undo. Every note comes from the top of the screen, where the top bar\'s buttons are: it slides down from above the edge, stays for toast-ms (3 s), or toast-action-ms (6 s) with Undo, so there\'s time to reach it, and goes back up the way it came, a little quicker. A line too long for the screen ends in an ellipsis; Undo always shows. CSS transitions, so a new one while it is up just retargets.' } } },
  render: function Render() {
    const [shown, setShown] = useState(true);
    return (
      <div style={{ position: 'relative', width: 343, height: 140, overflow: 'hidden', borderRadius: 'var(--radius-card)', background: 'var(--color-bg-default)', display: 'flex', alignItems: 'flex-end' }}>
        <button type="button" className="text-label-md" style={{ margin: 'var(--space-md)' }} onClick={() => setShown(s => !s)}>{shown ? 'Hide' : 'Show'}</button>
        <Toast label="Added for Today, 5 PM" shown={shown} actionLabel="Undo" onAction={() => setShown(false)} />
      </div>
    );
  },
};

export const Pile: Story = {
  name: 'FacePile',
  parameters: { docs: { description: { story: 'People as a little pile: up to two stickers, then "+N". On the map, people closer than a sticker\'s width merge into one pile, so a group walking together never turns into a heap. Whoever has arrived leaves the map and shows on the place\'s pin instead: a chip-size pile across the mini pin\'s corner, and their faces with "here" in the card\'s first chip. Locations are shared live and passively, from 90 minutes before the event.' } } },
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-xl)', alignItems: 'center' }}>
      <FacePile faces={['person-05']} label="Nic" />
      <FacePile faces={['person-05', 'person-02']} label="Nic and Leo" />
      <FacePile faces={['person-05', 'person-02', 'person-01', 'person-03']} label="Four people" />
      <FacePile faces={['person-01']} size="chip" label="Maya is here" />
    </div>
  ),
};
