import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useState } from 'react';
import tokens from '../../../design-system/tokens.json';
import { TRIP } from '../data';
import { ActionBar, TopBar } from './Bars';
import { ADD_SUBTITLE, AddPage, ITINERARY_SUBTITLE, ItineraryPage, MONEY_SUBTITLE, MoneyPage } from './TripPages';
import { TripSheet } from './TripSheet';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const phone = { width: 393, height: 852, position: 'relative' as const, overflow: 'hidden', borderRadius: 'var(--radius-sheet)', background: 'var(--color-bg-canvas)' };
// The full view's place: under the top bar's buttons, the sheet inset from the other edges. The pop-up lines up at
// its bottom, so Add's shorter one sits low.
const place = {
  position: 'absolute' as const,
  top: 'calc(var(--space-xl) + var(--d-button-md))',
  left: 'var(--d-sheet-inset)',
  right: 'var(--d-sheet-inset)',
  bottom: 'var(--d-sheet-inset)',
  display: 'flex',
  flexDirection: 'column' as const,
  justifyContent: 'flex-end',
  pointerEvents: 'none' as const,
};
// The map and the bars blur away behind it, under a light scrim
const backdrop = { position: 'absolute' as const, inset: 0, background: 'var(--c-sheet-scrim)', backdropFilter: 'blur(var(--d-sheet-backdrop-blur))', WebkitBackdropFilter: 'blur(var(--d-sheet-backdrop-blur))' };

type Which = 'itinerary' | 'money' | 'add';

/** The trip screen with one footer pop-up open. The footer's buttons open the others once it's closed. */
function Screen({ start }: { start: Which }) {
  const [open, setOpen] = useState<Which | null>(start);
  const reduce = useReducedMotion();
  const close = () => setOpen(null);
  const sheet = {
    itinerary: { title: 'Itinerary', subtitle: ITINERARY_SUBTITLE, page: <ItineraryPage onPick={close} /> },
    money: { title: 'Money', subtitle: MONEY_SUBTITLE, page: <MoneyPage /> },
    add: { title: 'Add to the trip', subtitle: ADD_SUBTITLE, page: <AddPage /> },
  };
  return (
    <div style={phone}>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
        <TopBar title={TRIP.title} dates={TRIP.dates} />
        <ActionBar onItinerary={() => setOpen('itinerary')} onMoney={() => setOpen('money')} onAdd={() => setOpen('add')} />
      </div>
      <AnimatePresence>
        {open && (
          <motion.div
            key="backdrop"
            style={backdrop}
            onClick={close}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1, transition: { duration: (reduce ? m['fade-ms'] : m['enter-ms']) / 1000, ease } }}
            exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
          />
        )}
      </AnimatePresence>
      <div style={place}>
        <AnimatePresence>
          {open && (
            <TripSheet key={open} title={sheet[open].title} subtitle={sheet[open].subtitle} compact={open === 'add'} onClose={close}>
              {sheet[open].page}
            </TripSheet>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

const meta = {
  title: 'Pop-ups',
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: [
          'The footer\'s three pop-ups: Itinerary, Money and Add. They look the same so they read as one family: the full view\'s surface, in the full view\'s place, with a header holding the title, a one-line subtitle and close. The page scrolls up under the header, which picks up the surface\'s white as the page goes under it.',
          '',
          'Motion: the pop-up rises from just past the bottom edge (enter-ms, ease-out) while the map and bars blur away under a light scrim, and goes back down quicker (fade-ms). The page\'s blocks arrive one after another (fade, light blur, a few px up, stagger-ms apart). They close with the ×, a tap outside, or (on the phone) a pull down on the header. Reduced motion: fades only.',
          '',
          'Add is shorter (sheet/compact-height) since it has only a few rows. Notes ("Link copied", "Paid Maya €181.50") come up at the bottom of the pop-up for toast-ms.',
        ].join('\n'),
      },
    },
  },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Itinerary: Story = {
  parameters: { docs: { description: { story: 'Every day of the trip, in order: where we\'ve been (a check), what\'s planned (its time), and today marked. It opens on today, just under the header. The next plan says "Up next" in brand blue. Tapping a stop closes the pop-up and shows it on the map.' } } },
  render: () => <Screen start="itinerary" />,
};

export const Money: Story = {
  parameters: { docs: { description: { story: 'What I owe and Pay, tonight\'s dinner as an estimate until the bill comes, the fewest payments that square everyone (3 instead of 9, one expense at a time), each person\'s balance in plain words, and the expenses. Pay flips the block to "You\'re square with Maya" and shows a note; my payment row turns to Paid and the balances follow. Costs from before someone joined stay with the people who were there (Ren joined today).' } } },
  render: () => <Screen start="money" />,
};

export const Add: Story = {
  parameters: { docs: { description: { story: 'Two choices: plan something, or invite someone. Plan shows ideas nearby, each with the free slot it would go in, and an Add button (a note confirms the slot). Invite shows the link with Copy link (a note confirms) and says what joining costs. Back returns to the choice; a step fades out with a blur while the next one arrives.' } } },
  render: () => <Screen start="add" />,
};
