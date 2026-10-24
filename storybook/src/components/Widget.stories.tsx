import type { Meta, StoryObj } from '@storybook/react-vite';
import { useState } from 'react';
import { TODAY, tripDate, UP_NEXT, UP_NEXT_NOW, upNextChips } from '../data';
import { EdgeArrow, MeEdge, MeMarker, PinTail } from './MapShapes';
import { RecenterButton } from './Bars';
import { PollCard as PollCardView } from './Poll';
import { UpNextWidget, type WidgetState } from './UpNextWidget';

/** Halfway through the dinner poll: 2:41 PM and a half, Maya, Leo and Nic have voted. */
const MID_POLL = new Date(tripDate(TODAY, 14, 41).getTime() + 30 * 1000);


const meta = {
  title: 'Widget/Up next',
  component: UpNextWidget,
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: [
          'The next plan, pinned to its place on the map. One surface that morphs between three states, so every change reads as the same object growing or shrinking, never a swap.',
          '',
          '| State | When | Tap |',
          '|---|---|---|',
          '| **mid** | The trip opens and the place is on screen | Opens the full view |',
          '| **mini** | The map starts moving (pan or zoom), or any later plan | Grows back to mid |',
          '| **edge** | The place leaves the screen; the pin slides along the edge and the arrow points at it | Pans the map to the place |',
          '',
          'Motion: size, position and corner radius follow one spring (spring-morph: 0.45 s, bounce 0.12), and the card grows out of the tail (anchored at its bottom centre). Card ↔ mini is one object: the plan\'s sticker is the same picture in both states and travels from the mini\'s slot into the middle of the fan, growing; the name slides between its two places and crossfades between the two styles. Everything else hangs on those two: the other fan stickers open out from the shared one, the label and rating follow the name, the eta leaves with the mini name, and the chips rise in last (from morph-enter-scale 0.9). Who\'s coming is the card\'s first chip ("4 coming"); once people arrive it becomes their faces and "here", next to the price range. On the mini pin the same faces sit across its top-right corner instead, fading in once the card has mostly shrunk (enter-ms) and out quickly as it grows (fade-ms); the card itself has no corner pile. The tail is blue with a thin white edge just inside, so it reads on pale streets, blue water and the dark map alike. Fading parts blur while half there (enter-blur 4 px). While the map is being dragged, the pin follows the finger frame by frame. Haptics on the phone: light on buttons, medium when a pin gets focus. Reduced motion: instant state changes, crossfade only.',
        ].join('\n'),
      },
    },
  },
  args: { event: UP_NEXT, state: 'mid' },
} satisfies Meta<typeof UpNextWidget>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Mid: Story = { args: { state: 'mid' }, parameters: { docs: { description: { story: 'Maya is already there: her face and "here", then the price range, in two equal chips.' } } } };
export const MidNobodyThere: Story = {
  name: 'Mid · nobody there yet',
  args: { state: 'mid', event: { ...UP_NEXT, chips: upNextChips([]), here: [] } },
  parameters: { docs: { description: { story: 'Before anyone arrives, the first chip counts who\'s going: "5 coming".' } } },
};
export const MidFourThere: Story = {
  name: 'Mid · four there',
  args: { state: 'mid', event: { ...UP_NEXT, chips: upNextChips(['person-01', 'person-05', 'person-02', 'person-04']), here: ['person-01', 'person-05', 'person-02', 'person-04'] } },
  parameters: { docs: { description: { story: 'Four or more faces need the room, so the price chip shrinks to its text.' } } },
};
export const MidNow: Story = {
  name: 'Mid · now',
  args: { state: 'mid', event: UP_NEXT_NOW },
  parameters: { docs: { description: { story: 'The dinner is on: its time has come (from a quarter of an hour before) and someone is inside the geofence. Nobody presses anything for it. The label turns to a brand dot and "Now · You\'re here" once I\'m there too ("Now · 5 PM" until then), and the first chip has the four others who are there (the app leaves me out of "here"). Switch `state` to mini: it says "Now" instead of how soon.' } } },
};
export const Mini: Story = { args: { state: 'mini' }, parameters: { docs: { description: { story: 'Whoever is already there sits across the mini pin\'s top-right corner.' } } } };
export const Edge: Story = { args: { state: 'edge', edgeAngle: 90 } };

export const Morph: Story = {
  name: 'Morph between states',
  render: function Render(args) {
    const [state, setState] = useState<WidgetState>('mid');
    return (
      <div style={{ display: 'grid', gap: 'var(--space-xl)', justifyItems: 'center' }}>
        <div style={{ display: 'flex', gap: 'var(--space-xs)' }}>
          {(['mid', 'mini', 'edge'] as const).map(s => (
            <button key={s} className="text-label-md" style={{ padding: 'var(--space-xs) var(--space-sm)', borderRadius: 'var(--radius-pill)', background: s === state ? 'var(--color-bg-inverse)' : 'var(--color-bg-muted)', color: s === state ? 'var(--color-text-inverse)' : 'var(--color-text-default)' }} onClick={() => setState(s)}>{s}</button>
          ))}
        </div>
        <div style={{ height: 340, display: 'flex', alignItems: 'flex-end' }}>
          <UpNextWidget {...args} state={state} onTap={() => setState('mid')} onOpen={() => setState('mini')} />
        </div>
      </div>
    );
  },
};

export const Shapes: Story = {
  name: 'Map marks',
  parameters: { docs: { description: { story: 'Pin tail (under a widget: blue, a thin white edge just inside, and the dash on the exact spot), edge arrow (points at an off-screen pin), my location with the heading cone, my location off-screen (edge capsule), and the recenter button that appears when I am off-screen.' } } },
  render: () => (
    <div style={{ display: 'flex', gap: 'var(--space-2xl)', alignItems: 'center' }}>
      <PinTail />
      <EdgeArrow angle={90} />
      <MeMarker heading={-20} />
      <MeEdge />
      <RecenterButton />
    </div>
  ),
};

export const PollCard: Story = {
  name: 'Poll card',
  parameters: {
    controls: { disable: true },
    docs: { description: { story: 'While the dinner poll is open (2:30 to 3 PM, or until everyone has voted) this card stands where the Up next card would, under the day filter, with no pin. In brand blue, "Poll · closes in 19 mins"; the question; "5 PM · Maya asked · 3 of 5 voted"; then the three places, each with its sticker, its name (one line, ellipsized), Leading on the one ahead, and the faces of who voted for it. Here it\'s 2:41 PM: Maya and Nic for La Brasserie, Leo for Churrasqueira, nobody yet for Dote. Tapping it opens the poll (see Pop-ups › Poll · open, where it follows the votes live once the pop-up is closed). It fades in and grows from its top (morph-enter-scale, enter-ms, ease-out), and goes quicker (fade-ms) once the poll closes or a pop-up covers it. Reduced motion: fades only.' } },
  },
  render: () => <PollCardView now={MID_POLL} poll={{}} />,
};
