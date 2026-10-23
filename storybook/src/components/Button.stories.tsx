import type { Meta, StoryObj } from '@storybook/react-vite';
import { ArrowLeft, ArrowRight, Calendar, Euro, MapPin, Plus, X } from 'lucide-react';
import { Button } from './Button';

const icons = { ArrowLeft, ArrowRight, Calendar, Euro, MapPin, Plus, X };

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
          '- **soft**: grey glass with a pressed-in edge. Secondary actions: back, close, calendar, places, money.',
          '- **primary**: blue glass. The one main action on a screen (add to the trip, open the plan). Never two primaries side by side.',
          '- **Sizes**: `sm` 40 inside cards and sheets, `md` 44 in the top bar (minimum touch target), `lg` 56 in the action bar.',
          '- Icons are Lucide, 16 px, 2 px stroke, in the button\'s foreground token.',
          '- Press: scales to 0.97 in 120 ms with the ease-out curve. Focus: 2 px focus ring.',
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
      <Button icon={MapPin} label="Places" size="lg" />
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
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-xs)' }}>
      <Button icon={Calendar} label="Plan" size="lg" />
      <Button icon={MapPin} label="Places" size="lg" />
      <Button icon={Euro} label="Money" size="lg" />
      <Button icon={Plus} label="Add to the trip" size="lg" variant="primary" />
    </div>
  ),
};
