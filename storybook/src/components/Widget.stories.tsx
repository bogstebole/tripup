import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnimatePresence } from 'motion/react';
import { useState } from 'react';
import { TODAY, tripDate, UP_NEXT, UP_NEXT_NOW, upNextChips, type PollState } from '../data';
import { EdgeArrow, MeEdge, MeMarker, PinTail } from './MapShapes';
import { RecenterButton } from './Bars';
import { PollCard, PollScrim } from './Poll';
import { UpNextWidget, type WidgetState } from './UpNextWidget';

/** Halfway through the dinner poll: 2:41 PM and a half, Maya, Leo and Nic have voted. */
const MID_POLL = new Date(tripDate(TODAY, 14, 41).getTime() + 30 * 1000);

/** A phone's screen, the map not drawn: the poll's card sits md under its top and md in from its sides. */
const screen = { width: 393, height: 852, position: 'relative' as const, overflow: 'hidden', borderRadius: 'var(--radius-sheet)', background: 'var(--color-bg-canvas)' };
const pollPlace = { position: 'absolute' as const, top: 'var(--space-md)', bottom: 'var(--space-md)', left: 'var(--space-md)', right: 'var(--space-md)', display: 'flex', flexDirection: 'column' as const, pointerEvents: 'none' as const };

/** The poll on the map at MID_POLL: compact, or (`open`) opened up over the scrim. Its head opens and closes it, and a
 *  tap on the scrim closes it; a place's check votes, or moves my vote (`mine`: where it starts). Details would open
 *  the poll's pop-up (here it only closes the card, as the app does first). */
function PollStory({ open = false, mine }: { open?: boolean; mine?: string }) {
  const [expanded, setExpanded] = useState(open);
  const [poll, setPoll] = useState<PollState>(mine ? { mine: { option: mine, at: MID_POLL } } : {});
  return (
    <div style={screen}>
      <AnimatePresence>{expanded && <PollScrim key="scrim" onClose={() => setExpanded(false)} />}</AnimatePresence>
      <div style={pollPlace}>
        <PollCard
          expanded={expanded}
          now={MID_POLL}
          poll={poll}
          onToggle={() => setExpanded(e => !e)}
          onDetails={() => setExpanded(false)}
          onVote={option => setPoll({ mine: { option, at: MID_POLL } })}
        />
      </div>
    </div>
  );
}

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

export const PollCompact: Story = {
  name: 'Poll · compact',
  parameters: {
    controls: { disable: true },
    docs: { description: { story: 'While the dinner poll is open (2:30 to 3 PM, or until everyone has voted) this card stands where the Up next card would, under the day filter (xs clear of it), with no pin: Bogdan\'s widget (Figma 82:3). It\'s the screen less its margins wide (md each side), on the surface (md in at the top, xs on the other sides), its text left-aligned. The head, md in from the sides with sm between its lines, is one button: "Live poll • closes in 19 mins" (label-md, semibold, brand), then the red dot (poll/live-dot 9) breathing (opacity 1 to poll/live-dim-opacity 0.35 and back, pulse-ms, ease-breathe; still with reduced motion), and a chevron down at the end (icon-sm, icon-default); the question, "Where for dinner tonight?" (heading-md, one line); 2xs under it "5 PM • Maya asked • 3 of 5 voted" (label-sm, muted, one line) and, 2xs after it, everyone at the table as tiny faces (poll/meta-face 16, overlapping poll/meta-face-overlap 5): the ones who have voted first (Maya, Nic, Leo), then the ones the poll is still waiting for (me, Ren), faded (poll/not-voted-opacity 0.4), each group in the table\'s order. Tapping it opens it in place (see Poll · open). On the map it fades in and grows from its top (morph-enter-scale, enter-ms, ease-out), and goes quicker (fade-ms) once the poll closes or a pop-up covers it, taking no taps while it goes. Reduced motion: fades only. Here it\'s 2:41 PM: Maya and Nic for La Brasserie, Leo for Churrasqueira, nobody yet for Dote.' } },
  },
  render: () => <PollStory />,
};

export const PollOpen: Story = {
  name: 'Poll · open',
  parameters: {
    controls: { disable: true },
    docs: { description: { story: 'Opened in place: behind it, the whole screen (the map and its bars) tints blue and blurs a little (c-poll-scrim, blue 975 at 23%; d-poll-scrim-blur 2.5), fading in (enter-ms, ease-out) and out quicker (fade-ms). The same card grows down (its height, enter-ms, ease-in-out: it moves on screen) and each place arrives under the head in turn, sm apart (fade, light blur, a few px up, stagger-ms apart). The chevron turns over (enter-ms, ease-out) and the faces in the meta line fade out (fade-ms): each place shows its own. A place is a grey card (bg-subtle, radius-card, xs in): its name (body-md, medium, one line), a brand star and "4.2 (173) • French • €20–40" (label-md, muted; the dots label-sm), and its sticker (poll/option-sticker 48) on the right; md under them a bar of its share of the five votes (poll/bar-height 8, every place in brand here, on the white track; it slides out from the left as votes come in); md under that, Details (body-md, medium, muted, 44 high), everyone who voted for it (24, overlapping 10) and the vote, a round check (Button sm, 40): soft, or primary once it\'s mine. Tap a check to vote, or another to move the vote there (a light haptic on the phone). Details opens the poll\'s pop-up, with walking times (see Pop-ups › Poll · open; here it closes the card). The head again, or a tap on the scrim, closes it: the places fade out with a blur first (fade-ms), then the card folds up after them and the faces come back (enter-ms). If the screen is too short, the places scroll under the head. Reduced motion: the height jumps and the places only fade.' } },
  },
  render: () => <PollStory open />,
};

export const PollVoted: Story = {
  name: 'Poll · open · your vote',
  parameters: {
    controls: { disable: true },
    docs: { description: { story: 'I voted for Dote: its check is primary (blue, icon-on-brand), my face joins its voters and its bar has one of the five votes; the meta line says "4 of 5 voted", and closed, my face joins the ones who have voted, unfaded. Tap another place\'s check to move the vote there: one check goes back to soft as the other turns blue, and the bars and faces follow at once. It\'s the same vote as in the poll\'s pop-up.' } },
  },
  render: () => <PollStory open mine="dote" />,
};
