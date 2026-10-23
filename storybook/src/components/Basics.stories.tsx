import type { Meta, StoryObj } from '@storybook/react-vite';
import { useState } from 'react';
import { EVENT, MENU, PEOPLE } from '../data';
import { AddButton } from './AddButton';
import { InfoChips } from './InfoChips';
import { KnowRow, KnowSection } from './KnowSection';
import { PeopleButton } from './PeopleButton';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { Sticker } from './Sticker';
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

export const People: Story = {
  name: 'PeopleButton',
  parameters: { docs: { description: { story: 'Soft pill in the top bar: the first two people as stickers plus a "+N" bubble. Opens the people on the trip.' } } },
  render: () => <PeopleButton faces={['person-04', 'person-01']} more={3} />,
};

export const Rating: Story = {
  name: 'RatingLine',
  parameters: { docs: { description: { story: 'Filled brand star, rating and review count, then the place type. Centered on the widget, start-aligned in the sheet.' } } },
  render: () => <div style={{ width: 'var(--d-widget-mid-width)' }}><RatingLine rating={EVENT.rating} kind={EVENT.cuisine} /></div>,
};

export const Chips: Story = {
  name: 'InfoChips',
  parameters: { docs: { description: { story: 'Joined facts about a plan: who is going, price level, time. Only the outer corners are rounded; the middle chip takes the spare width.' } } },
  render: () => (
    <div style={{ width: 201, display: 'flex' }}>
      <InfoChips items={[{ text: '+3', sticker: 'person-05', tilt: -6.22 }, { text: EVENT.price, grow: true }, { text: EVENT.when }]} />
    </div>
  ),
};

export const Tabs: Story = {
  name: 'SegmentedTabs',
  parameters: { docs: { description: { story: 'Pill tabs on a muted track. The selected pill is a Surface that springs to the tapped tab (spring-snap: 0.35 s, no bounce).' } } },
  render: function Render() {
    const [tab, setTab] = useState('Overview');
    return <SegmentedTabs tabs={['Overview', 'Menu', 'People']} value={tab} onChange={setTab} />;
  },
};

export const Know: Story = {
  name: 'KnowSection',
  parameters: { docs: { description: { story: 'A muted group with a brand heading and soft rows. The same component holds tips, menu picks and people.' } } },
  render: () => (
    <div style={{ width: 343, display: 'grid', gap: 'var(--space-md)' }}>
      <KnowSection title="Know before you go">{EVENT.tips.map(t => <KnowRow key={t}>{t}</KnowRow>)}</KnowSection>
      <KnowSection title="Menu picks" meta="4 of 5 picked">
        <KnowRow leading={<Sticker name={MENU[0].sticker} size="row" />}>{MENU[0].name}</KnowRow>
      </KnowSection>
      <KnowSection title="Who's coming" meta="4 of 5 going">
        <KnowRow leading={<Sticker name={PEOPLE[1].sticker} size="avatar" />}>{PEOPLE[1].name}</KnowRow>
      </KnowSection>
    </div>
  ),
};

export const Add: Story = {
  name: 'AddButton',
  parameters: { docs: { description: { story: 'Small pill on a menu row: "Add" in soft glass, "Added" in primary glass (blue-700). One tap toggles it; on the phone it also ticks a light haptic.' } } },
  render: function Render() {
    const [added, setAdded] = useState(false);
    return <div style={{ display: 'flex', gap: 'var(--space-md)' }}><AddButton added={added} itemName="Crème brûlée" onToggle={() => setAdded(a => !a)} /><AddButton added itemName="Fries" /></div>;
  },
};
