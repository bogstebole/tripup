import type { Meta, StoryObj } from '@storybook/react-vite';
import { ArrowLeft, ArrowRight, Check, MapPin, Plus, X } from 'lucide-react';
import { CrewButton } from './Bars';
import { Button, TextButton } from './Button';

const icons = { ArrowLeft, ArrowRight, MapPin, Plus, X };

const meta = {
  title: 'Components/Button',
  component: Button,
  tags: ['autodocs'],
  parameters: {
    docs: {
      description: {
        component: [
          'Round icon button. Every icon button in TripUp is this one component, in two variants and three sizes.',
          '',
          '- **soft**: grey glass with a pressed-in edge. Secondary actions: back, close, the itinerary, money.',
          '- **primary**: blue glass. The one main action on a screen (add to the trip, open the plan). Never two primaries side by side.',
          '- **Sizes**: `sm` 40 inside cards and sheets, `md` 44 in the top bar (minimum touch target), `lg` 56 in the action bar.',
          '- Icons are Lucide, 16 px, 2 px stroke, in the button\'s foreground token.',
          '- Press: scales to 0.97 in 120 ms with the ease-out curve. Focus: 2 px focus ring.',
          '- **TextButton**: the same glass as a 44 px pill with a label (and an optional icon), for actions a bare icon can\'t say: Pay, Copy link. At `lg` it\'s 56 px, and `wide` fills the width it\'s given: the main action at the bottom of a page (Scan the bill, See who owes what).',
        ].join('\n'),
      },
    },
  },
  argTypes: {
    icon: { options: Object.keys(icons), mapping: icons, control: { type: 'select' } },
  },
  args: { icon: Plus, label: 'Add to the trip', variant: 'soft', size: 'md' },
} satisfies Meta<typeof Button>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Playground: Story = {};

export const Variants: Story = {
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-md)' }}>
      <Button icon={MapPin} label="Itinerary" size="lg" />
      <Button icon={Plus} label="Add to the trip" size="lg" variant="primary" />
    </div>
  ),
};

export const Sizes: Story = {
  render: () => (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, auto)', gap: 'var(--space-xl)', alignItems: 'center', justifyItems: 'center' }}>
      {(['sm', 'md', 'lg'] as const).map(s => <span key={s} className="text-label-md" style={{ color: 'var(--color-text-muted)' }}>{s}</span>)}
      {(['sm', 'md', 'lg'] as const).map(s => <Button key={'s' + s} icon={X} label="Close" size={s} />)}
      {(['sm', 'md', 'lg'] as const).map(s => <Button key={'p' + s} icon={ArrowRight} label="Open" size={s} variant="primary" />)}
    </div>
  ),
};

export const InContext: Story = {
  name: 'Where they are used',
  parameters: { docs: { description: { story: 'The footer: Itinerary (soft), Money (soft, the whole group as a little pile of stickers instead of an icon) and Add (the one primary).' } } },
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-xs)' }}>
      <Button icon={MapPin} label="Itinerary" size="lg" />
      <CrewButton />
      <Button icon={Plus} label="Add to the trip" size="lg" variant="primary" />
    </div>
  ),
};

export const Text: Story = {
  name: 'TextButton',
  parameters: { docs: { description: { story: 'A glass pill with a label, 44 px tall, for actions a bare icon can\'t say. Primary by default: Pay in the money pop-up. At `lg` (56 px) and `wide`, it\'s the main action in a footer: Copy link in the invite, Scan the bill and See who owes what in the full view\'s Group, the width of the page. No icons: the label says it. The one icon is a state mark, the check on Your vote in the poll.' } } },
  render: () => (
    <div style={{ display: 'grid', gap: 'var(--space-md)', width: 343 }}>
      <div style={{ display: 'flex', gap: 'var(--space-md)' }}>
        <TextButton label="Pay" />
        <TextButton label="Vote" variant="soft" />
        <TextButton label="Your vote" icon={Check} />
      </div>
      <TextButton label="Copy link" size="lg" wide />
      <TextButton label="Scan the bill" size="lg" wide />
      <TextButton label="See who owes what" variant="soft" size="lg" wide />
    </div>
  ),
};
