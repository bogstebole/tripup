// The dinner poll: where to eat tonight, decided by the group (see the poll section of data.ts). The app has the same
// in lib/components/poll.dart.
import { Check, ChevronDown, ChevronUp } from 'lucide-react';
import { motion, useReducedMotion } from 'motion/react';
import type { CSSProperties, ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  clockTime, DINNER, DINNER_TABLE, dinnerChoice, personById, POLL_ASKED_BY, POLL_CLOSES, POLL_OPTIONS, pollClosed, pollCountdown,
  pollLeader, pollOpen, pollOptionById, pollScore, votersOf, votesIn, walkMinutes, type PollState,
} from '../data';
import { Button, TextButton } from './Button';
import { RatingLine } from './RatingLine';
import { Sticker } from './Sticker';
import { useTripNotice } from './Notice';
import { Slot, StaggerIn } from './TripSheet';
import './Surface.css';
import './Poll.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const names = (ids: string[]) => ids.map(id => personById(id).name).join(', ');
/** "5 PM · Maya asked". */
const asked = () => `${clockTime(DINNER)} · ${personById(POLL_ASKED_BY).name} asked`;

export interface PollProps {
  /** Now, in the trip. */
  now: Date;
  /** My vote, and whether the winner was undone and another picked by hand. */
  poll: PollState;
}

/** A small brand pill: "Won", "Tonight". */
export function PollTag({ label }: { label: string }) {
  return <span className="tu-poll-tag text-label-md weight-semibold">{label}</span>;
}

/** "Live": a red dot that slowly breathes while the poll is open (still, with reduced motion). */
export function LiveDot() {
  return <span className="tu-live-dot" aria-hidden />;
}

/**
 * A place's share of the table's votes, as a bar: grows as votes come in, in brand for the one ahead. The fill slides
 * in from the left inside the track (a transform, so the rounded end keeps its shape, enter-ms, ease-out); with
 * reduced motion it just jumps. `onMuted`: on a grey card (the poll's places), where the usual track wouldn't show.
 */
export function VoteBar({ votes, ahead, onMuted }: { votes: number; ahead: boolean; onMuted?: boolean }) {
  const share = votes / DINNER_TABLE.length;
  return (
    <span className={onMuted ? 'tu-vote-bar tu-vote-bar--on-muted' : 'tu-vote-bar'} aria-hidden>
      <span className="tu-vote-bar__fill" data-ahead={ahead || undefined} style={{ transform: `translateX(${(share - 1) * 100}%)` }} />
    </span>
  );
}

/** Everyone who voted for a place, every face, overlapped (five at most, so no "+N"). */
function Voters({ ids }: { ids: string[] }) {
  if (!ids.length) return null;
  return (
    <span className="tu-poll-voters" role="img" aria-label={names(ids)}>
      {ids.map(id => <Sticker key={id} name={personById(id).sticker} size="chip" />)}
    </span>
  );
}

/**
 * While the poll is open it stands where the Up next card would: a live sign and the countdown, the question, then
 * each place with everyone who voted for it and a bar of its votes (the one ahead in brand). Tapping it opens the
 * poll; the corner button folds it into a pill (see PollPill), so it needn't cover the map the whole time.
 */
export function PollCard({ now, poll, onOpen, onFold }: PollProps & { onOpen?: () => void; onFold?: () => void }) {
  const leader = pollLeader(now, poll), countdown = pollCountdown(now, poll), n = votesIn(now, poll);
  return (
    <div className="tu-poll-card tu-surface tu-surface--sheet">
      {/* The whole card opens the poll: one button under everything, so the fold button can sit over it (the app
          nests them; the web can't put a button inside a button) */}
      <button type="button" className="tu-poll-card__open" onClick={onOpen} aria-label={`Dinner poll: ${n} of ${DINNER_TABLE.length} voted, ${countdown}. Open`} />
      <span className="tu-poll-card__head">
        <LiveDot />
        <span className="text-label-md weight-bold tu-ellipsis tu-poll-card__label">Live poll · {countdown}</span>
        <Button size="sm" icon={ChevronUp} label="Fold the poll away" onClick={onFold} />
      </span>
      <span className="tu-poll-card__body">
        <span className="text-heading-sm tu-poll-card__question">Where for dinner tonight?</span>
        <span className="text-body-sm tu-poll-card__meta">{asked()} · {n} of {DINNER_TABLE.length} voted</span>
        <span className="tu-poll-card__rows">
          {POLL_OPTIONS.map(o => {
            const voters = votersOf(o.id, now, poll);
            return (
              <span key={o.id} className="tu-poll-card__row">
                <Slot size="avatar"><Sticker name={o.sticker} size="avatar" /></Slot>
                <span className="tu-poll-card__choice">
                  <span className="tu-poll-card__line">
                    <span className="text-label-md weight-semibold tu-ellipsis tu-poll-card__name">{o.name}</span>
                    <Voters ids={voters} />
                  </span>
                  <VoteBar votes={voters.length} ahead={o.id === leader} />
                </span>
              </span>
            );
          })}
        </span>
      </span>
    </div>
  );
}

/**
 * The poll folded away: a pill under the day filter that keeps it in sight (live sign, how many voted, the countdown;
 * one line, ellipsized). Tapping it unfolds the card.
 */
export function PollPill({ now, poll, onUnfold }: PollProps & { onUnfold?: () => void }) {
  const countdown = pollCountdown(now, poll), n = votesIn(now, poll);
  return (
    <button
      type="button"
      className="tu-poll-pill tu-surface tu-surface--pill"
      onClick={onUnfold}
      aria-label={`Dinner poll: ${n} of ${DINNER_TABLE.length} voted, ${countdown}. Unfold`}
    >
      <LiveDot />
      <span className="text-label-md weight-semibold tu-ellipsis tu-poll-pill__text">Dinner poll · {n} of {DINNER_TABLE.length} · {countdown}</span>
      <ChevronDown className="tu-poll-pill__chevron" strokeWidth={2} absoluteStrokeWidth aria-hidden />
    </button>
  );
}

/**
 * The poll on the map, card or pill, in its place (`style`). Key it by which one it holds inside AnimatePresence: they
 * swap in place, the new one fading in and growing from its top (morph-enter-scale, enter-ms, ease-out), the one
 * leaving shrinking a little into the top as it fades (fade-ms). It comes and goes the same way as the poll opens and
 * closes, or a pop-up covers it. Reduced motion: fades only.
 */
export function PollOnMap({ style, children }: { style?: CSSProperties; children: ReactNode }) {
  const reduce = useReducedMotion();
  const away = { opacity: 0, scale: reduce ? 1 : m['morph-enter-scale'] };
  return (
    <motion.div
      style={{ ...style, transformOrigin: 'top center' }}
      initial={away}
      animate={{ opacity: 1, scale: 1, transition: { duration: (reduce ? m['fade-ms'] : m['enter-ms']) / 1000, ease } }}
      exit={{ ...away, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      {children}
    </motion.div>
  );
}

/**
 * The poll pop-up's subtitle: "5 PM · Maya asked · closes in 18 mins"; once it has closed, "Closed · La Brasserie won,
 * 3 votes to 1"; after an Undo, "Closed · nothing added yet", then "Closed · Dote picked by hand".
 */
export const pollSubtitle = (now: Date, poll: PollState) => {
  if (!pollClosed(now, poll)) return `${asked()} · ${pollCountdown(now, poll)}`;
  if (poll.undone) return `Closed · ${poll.picked ? `${pollOptionById(poll.picked).short} picked by hand` : 'nothing added yet'}`;
  return `Closed · ${pollOptionById(pollLeader(now, poll)!).short} won, ${pollScore(now, poll)}`;
};

export interface PollPageProps extends PollProps {
  /** My vote, while it's open (it can change until it closes). */
  onVote?: (option: string) => void;
  /** After an Undo: put this place in tonight's slot by hand. */
  onPick?: (option: string) => void;
}

/**
 * The poll: a card per place (its sticker, rating, food, price and how far it is), a bar of its votes (on the white
 * track, since the card is grey), who voted for it, and Vote. Once
 * it has closed: which one won and went into tonight, the others dimmed (d-poll-lost-opacity); after an Undo, Add to
 * tonight on each place that isn't in it, and a note at the top of the screen when one goes in.
 */
export function PollPage({ now, poll, onVote, onPick }: PollPageProps) {
  const toast = useTripNotice();
  const open = pollOpen(now, poll), leader = pollLeader(now, poll), chosen = dinnerChoice(now, poll);
  return (
    <StaggerIn gap="sm">
      <p key="intro" className="text-body-sm tu-poll__intro">
        {open
          ? `${votesIn(now, poll)} of ${DINNER_TABLE.length} have voted. It closes at ${clockTime(POLL_CLOSES)}, or once everyone has voted; the winner goes into tonight by itself.`
          : poll.undone && !poll.picked
            ? "The winner was taken back out. Pick tonight's place yourself."
            : `It's in tonight, ${clockTime(DINNER)}: on everyone's map and itinerary.`}
      </p>
      {POLL_OPTIONS.map(o => {
        const voters = votersOf(o.id, now, poll);
        const mine = poll.mine?.option === o.id;
        const won = !open && o.id === chosen;
        const lost = !open && chosen != null && !won;
        return (
          <div key={o.id} className={lost ? 'tu-poll-place tu-poll-place--lost' : 'tu-poll-place'}>
            <div className="tu-poll-place__head">
              <Slot><Sticker name={o.sticker} size="row" /></Slot>
              <div className="tu-poll-place__text">
                <p className="text-label-lg tu-poll-place__name">{o.name}</p>
                <RatingLine rating={o.rating} kind={`${o.cuisine} · ${o.price}`} align="start" />
                <p className="text-body-sm tu-poll__muted">{walkMinutes(o.at)} min walk</p>
              </div>
            </div>
            <VoteBar votes={voters.length} ahead={o.id === leader} onMuted />
            <div className="tu-poll-place__votes">
              <Voters ids={voters} />
              <span className="text-body-sm tu-poll__muted">{voters.length ? `${voters.length} ${voters.length === 1 ? 'vote' : 'votes'}` : 'No votes yet'}</span>
              {won ? <PollTag label="Tonight" /> : !open && o.id === leader && <PollTag label="Won" />}
              {open ? (
                <TextButton
                  className="tu-poll-place__action"
                  variant={mine ? 'primary' : 'soft'}
                  icon={mine ? Check : undefined}
                  label={mine ? 'Your vote' : 'Vote'}
                  aria-label={mine ? `Your vote: ${o.name}` : `Vote for ${o.name}`}
                  onClick={() => onVote?.(o.id)}
                />
              ) : poll.undone && chosen !== o.id ? (
                <TextButton
                  className="tu-poll-place__action"
                  variant="soft"
                  label="Add to tonight"
                  aria-label={`Add ${o.name} to tonight`}
                  onClick={() => {
                    onPick?.(o.id);
                    toast(`${o.short} added for tonight, ${clockTime(DINNER)}`);
                  }}
                />
              ) : null}
            </div>
          </div>
        );
      })}
    </StaggerIn>
  );
}
