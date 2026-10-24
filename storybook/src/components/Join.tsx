// Joining a trip mid-way, from the invite link: what the new person sees on their own phone. The app has the same in
// lib/components/join.dart.
import { BedDouble, Vote, X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useRef, useState } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  clockTime, DINNER, dinnerChoice, euros, MY_NAME, onTrip, PEOPLE, personById, planStart, plansAhead, POLL_OPENS, pollOpen, SPENT_SO_FAR,
  startsAt, TRIP, TRIP_DAYS, TRIP_NOW, VISITED, type PollState,
} from '../data';
import { Button, TextButton } from './Button';
import { easedFade } from './easedFade';
import { Sticker } from './Sticker';
import { SheetRow, SheetSection, Slot, StaggerIn } from './TripSheet';
import './Join.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
// Full transform strings, so Motion runs them on the compositor
const zoomed = `scale(${m['page-zoom-scale']})`, settled = 'scale(1)';

/** Who joins, in the story. */
const REN = 'ren';
const NUMBERS: Record<number, string> = { 2: 'two', 3: 'three', 4: 'four', 5: 'five', 6: 'six' };
const firstDay = TRIP_DAYS[0].day, lastDay = TRIP_DAYS[TRIP_DAYS.length - 1].day;

export type JoinStep = 'invite' | 'recap';

export interface JoinFlowProps {
  /** Only a look, from Invite, at what someone you invite will see (nobody joins): "What they'll see", no name yet. */
  preview?: boolean;
  /** Where it starts: the invite, or the trip so far (as just after Join). */
  start?: JoinStep;
  /** Now, in the trip (the demo's start, 3:56 PM, by default): who's there, and what's coming. */
  now?: Date;
  /** The dinner poll as it stands (nobody has voted here by default). */
  poll?: PollState;
  /** He joined and opens the trip (the preview just closes). */
  onJoined?: () => void;
  /** The × at the top: back to Ari's phone, or out of the preview. */
  onClose?: () => void;
}

/**
 * What Ren sees after opening the link: the trip and who invited him, then his name (no account, no password), then
 * the trip so far: where they're staying, where they've been, what's coming (an open poll included) and the rule for
 * money. It's the other person's phone, so the top says so, in a pill over an eased fade. Join swaps the page: the
 * invite fades out with a blur (fade-ms) while the trip so far fades in (enter-ms) and its blocks arrive.
 */
export function JoinFlow({ preview = false, start = 'invite', now = TRIP_NOW, poll = {}, onJoined, onClose }: JoinFlowProps) {
  const [step, setStep] = useState<JoinStep>(start);
  const [name, setName] = useState(preview ? '' : personById(REN).name);
  const reduce = useReducedMotion();
  return (
    <div className="tu-join">
      <AnimatePresence initial={false}>
        <motion.div
          key={step}
          className={step === 'invite' ? 'tu-join__page tu-join__page--invite' : 'tu-join__page'}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
          exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
        >
          {step === 'invite'
            ? <Invite preview={preview} now={now} name={name} onName={setName} onJoin={() => setStep('recap')} />
            : <Recap preview={preview} now={now} poll={poll} name={name} onJoined={onJoined} />}
        </motion.div>
      </AnimatePresence>
      {/* The page fades out under the top, so the pill reads over whatever scrolls by */}
      <div className="tu-join__fade" aria-hidden style={{ background: easedFade('var(--color-bg-canvas)', { from: 'calc(var(--d-top-bar-fade-start) * 100%)' }) }} />
      {/* Whose phone this is (the demo switches to Ren's), and a way back */}
      <div className="tu-join__top">
        <span className="text-label-md weight-semibold tu-join__pill">{preview ? "What they'll see" : `${personById(REN).name}'s phone`}</span>
        <Button icon={X} label={preview ? 'Close the preview' : `Back to ${MY_NAME}'s phone`} size="sm" onClick={onClose} />
      </div>
    </div>
  );
}

/** The invite: who's there, who invited you to what, then the one thing to do: your name, and Join. */
function Invite({ preview, now, name, onName, onJoin }: { preview: boolean; now: Date; name: string; onName: (name: string) => void; onJoin: () => void }) {
  const field = useRef<HTMLInputElement>(null);
  const crew = PEOPLE.filter(p => onTrip(p, now) && (preview || p.id !== REN));
  const join = () => {
    // Without a name yet, it goes to the name field instead
    if (!name.trim()) {
      field.current?.focus();
      return;
    }
    field.current?.blur();
    onJoin();
  };
  return (
    <StaggerIn gap="md">
      <span key="faces" className="tu-join__faces">{crew.map(p => <Sticker key={p.id} name={p.sticker} size="row" />)}</span>
      <div key="titles" className="tu-join__titles">
        <p className="text-body-md tu-join__muted">{MY_NAME} invited you to</p>
        <h1 className="text-heading-lg tu-join__trip">{TRIP.title}</h1>
        <p className="text-body-sm tu-join__muted">Lisbon · {firstDay}–{lastDay} May · {crew.length} friends are there</p>
      </div>
      <input
        key="name"
        ref={field}
        className="text-label-lg tu-join__name"
        value={name}
        onChange={e => onName(e.target.value)}
        placeholder="Your name"
        aria-label="Your name"
        autoCapitalize="words"
        autoComplete="given-name"
      />
      <p key="note" className="text-body-sm tu-join__muted tu-join__center">No account and no password: your name is all it takes.</p>
      <TextButton key="join" label="Join the trip" size="lg" wide onClick={join} />
    </StaggerIn>
  );
}

/** The trip so far, for someone arriving in the middle of it. */
function Recap({ preview, now, poll, name, onJoined }: { preview: boolean; now: Date; poll: PollState; name: string; onJoined?: () => void }) {
  const days = new Set(VISITED.map(v => v.day)).size;
  const next = plansAhead(now, poll).slice(0, 3);
  const undecided = dinnerChoice(now, poll) == null;
  const crew = PEOPLE.filter(p => onTrip(p, now) && p.id !== REN);
  return (
    <StaggerIn>
      <div key="welcome" className="tu-join__welcome">
        <h1 className="text-heading-lg">Welcome, {name.trim()}</h1>
        <p className="text-body-sm tu-join__muted">Here's the trip so far, so you're caught up.</p>
      </div>
      <SheetSection key="stay" title="Where you're staying" />
      <SheetRow
        key="flat"
        leading={<Slot><BedDouble className="tu-join__lead" strokeWidth={2} absoluteStrokeWidth aria-hidden /></Slot>}
        title="Alfama flat"
        subtitle={`Airbnb · until ${lastDay} May · ${personById('maya').name} booked it`}
      />
      <SheetSection key="been" title="Been so far" subtitle={`${VISITED.length} places in ${days} days`} />
      <span key="stickers" className="tu-join__stickers">{VISITED.map(v => <Sticker key={v.name} name={v.sticker} size="row" tilt={v.tilt} />)}</span>
      <SheetSection key="coming" title="Coming up" />
      {/* Tonight's dinner, while the poll hasn't decided it: his vote counts too */}
      {undecided && (
        <SheetRow
          key="poll"
          leading={<Slot><Vote className="tu-join__lead" strokeWidth={2} absoluteStrokeWidth aria-hidden /></Slot>}
          title={`Dinner tonight, ${clockTime(DINNER)}`}
          subtitle={pollOpen(now, poll) ? 'Poll open: where? Your vote counts too' : `A poll opens at ${clockTime(POLL_OPENS)}: you can vote`}
          tone="brand"
        />
      )}
      {next.map(p => (
        <SheetRow key={p.id} leading={<Slot><Sticker name={p.sticker} size="row" /></Slot>} title={p.name} subtitle={startsAt(planStart(p), now)} />
      ))}
      <SheetSection key="money" title="Money" />
      <p key="rule" className="text-body-sm tu-join__rule">
        You share costs from today on. The {euros(SPENT_SO_FAR)} spent before you joined stays with the {NUMBERS[crew.length] ?? crew.length} of them.
      </p>
      <TextButton key="open" className="tu-join__open" label={preview ? 'Close the preview' : 'Open the trip'} size="lg" wide onClick={onJoined} />
    </StaggerIn>
  );
}

/**
 * Ren's phone over Ari's (or, from Invite, what anyone invited would see): it fades in from a slight zoom
 * (page-zoom-scale to 1, enter-ms, ease-out), the way your trips settle back, and fades away quicker (fade-ms).
 * Reduced motion: fades only. Put it in AnimatePresence.
 */
export function JoinLayer(props: JoinFlowProps) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      style={{ position: 'absolute', inset: 0 }}
      initial={reduce ? { opacity: 0 } : { opacity: 0, transform: zoomed }}
      animate={{ ...(reduce ? { opacity: 1 } : { opacity: 1, transform: settled }), transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={{ opacity: 0, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      <JoinFlow {...props} />
    </motion.div>
  );
}
