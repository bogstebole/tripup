import type { Meta, StoryObj } from '@storybook/react-vite';
import { useState } from 'react';
import { EVENT, PEOPLE, TRIP, TRIP_DAYS } from '../data';
import { ActionBar, TopBar } from './Bars';
import { ToggleChips } from './ToggleChips';
import { DetailSheet, type DetailTab } from './DetailSheet';

const faces = Object.fromEntries(PEOPLE.map(p => [p.id, p.sticker]));
const phone = { width: 393, height: 852, position: 'relative' as const, overflow: 'hidden', borderRadius: 'var(--radius-sheet)', background: 'var(--color-bg-canvas)' };

const meta = { title: 'Screens/Trip', parameters: { layout: 'centered' } } satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Bars: Story = {
  name: 'Top bar and action bar',
  parameters: { docs: { description: { story: 'Top: back, the trip and its dates, the people, and the day filter, over a white that fades out down the map. Bottom: three 56 px glass buttons, each opening its pop-up (see Pop-ups): Itinerary (map pin, soft), Money (soft, with the whole group as a little pile of stickers) and Add (primary). md above them, 2xl below (the home indicator\'s inset on the phone when there is one). Behind them, white strongest at the bottom fades to clear at the top; no blur. Both fades ease in and out (a smoothstep), so their ends never show as a line.' } } },
  render: function Render() {
    const [days, setDays] = useState<number[]>([]);
    return (
      <div style={{ ...phone, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
        <TopBar title={TRIP.title} dates={TRIP.dates} filter={<ToggleChips label="Filter by day" options={TRIP_DAYS.map(d => ({ id: d.day, label: d.label }))} selected={days} onChange={setDays} />} />
        <ActionBar />
      </div>
    );
  },
};

function Sheet({ start }: { start: DetailTab }) {
  const [tab, setTab] = useState<DetailTab>(start);
  return (
    <div style={{ ...phone, padding: 'var(--d-sheet-inset)', paddingTop: 'calc(var(--space-xl) + var(--d-button-md))' }}>
      <DetailSheet {...EVENT} people={PEOPLE} faces={faces} tab={tab} onTabChange={setTab} />
    </div>
  );
}

export const Overview: Story = { name: 'Full view · Overview', render: () => <Sheet start="Overview" /> };
export const Menu: Story = { name: 'Full view · Menu', render: () => <Sheet start="Menu" /> };
export const Group: Story = { name: 'Full view · Group', render: () => <Sheet start="Group" /> };
