// The dinner poll: where to eat tonight, decided by the group (see the poll section of data.ts). The app has the same
// in lib/components/poll.dart.
import { Check, ChevronDown, Star } from 'lucide-react';
import { AnimatePresence, motion, useIsPresent, useReducedMotion } from 'motion/react';
import tokens from '../../../design-system/tokens.json';
import {
  clockTime, DINNER, DINNER_TABLE, dinnerChoice, personById, POLL_ASKED_BY, POLL_CLOSES, POLL_OPTIONS, pollClosed, pollCountdown,
  pollLeader, pollOpen, pollOptionById, pollScore, votersOf, votesIn, walkMinutes, type PollOption, type PollState,
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
const easeInOut = m['ease-in-out'] as [number, number, number, number];
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

/** Everyone at the table, small (poll/meta-face 16, overlapping poll/meta-face-overlap 5): the ones who have voted
 *  first, then the ones the poll is still waiting for, faded (poll/not-voted-opacity). */
function Table({ now, poll, hidden }: PollProps & { hidden: boolean }) {
  const voted = new Set(POLL_OPTIONS.flatMap(o => votersOf(o.id, now, poll)));
  const order = [...DINNER_TABLE.filter(id => voted.has(id)), ...DINNER_TABLE.filter(id => !voted.has(id))];
  return (
    <span className="tu-poll-table" data-hidden={hidden || undefined} aria-hidden>
      {order.map(id => <Sticker key={id} name={personById(id).sticker} className={voted.has(id) ? 'tu-poll-table__face' : 'tu-poll-table__face tu-poll-table__face--waiting'} />)}
    </span>
  );
}

/**
 * One place in the open poll, on bg-subtle (poll/place-radius 28, xs in, concentric with its vote): its name (body-md, medium, one line), a brand star
 * with its rating • food • price (label-md, muted; the dots label-sm), its sticker (poll/option-sticker 48); md under
 * them a bar of its share of the five votes (poll/bar-height 8, brand for every place here, on the white track); md
 * under that, Details (body-md, medium, muted; 44 high), everyone who voted for it (24, overlapping 10) and the vote: a
 * round check (Button sm, 40, xs from the corner), soft, or primary once it's mine. Tapping another place's check
 * moves my vote there.
 */
function Place({ option: o, now, poll, onDetails, onVote }: PollProps & { option: PollOption; onDetails?: (option: string) => void; onVote?: (option: string) => void }) {
  const voters = votersOf(o.id, now, poll), mine = poll.mine?.option === o.id;
  return (
    <div className="tu-poll-option">
      <div className="tu-poll-option__head">
        <div className="tu-poll-option__text">
          <p className="text-body-md weight-medium tu-ellipsis tu-poll-option__name">{o.name}</p>
          <p className="tu-poll-option__facts">
            <Star className="tu-poll-option__star" fill="currentColor" strokeWidth={2} absoluteStrokeWidth aria-hidden />
            <span className="text-label-md">{o.rating}</span>
            <span className="text-label-sm" aria-hidden>•</span>
            <span className="text-label-md tu-ellipsis tu-poll-option__kind">{o.cuisine}</span>
            <span className="text-label-sm" aria-hidden>•</span>
            <span className="text-label-md">{o.price}</span>
          </p>
        </div>
        <Sticker name={o.sticker} className="tu-poll-option__sticker" />
      </div>
      <div className="tu-poll-option__bar"><VoteBar votes={voters.length} ahead onMuted /></div>
      <div className="tu-poll-option__foot">
        <button type="button" className="text-body-md weight-medium tu-poll-option__details" aria-label={`Details: ${o.name}`} onClick={() => onDetails?.(o.id)}>Details</button>
        <Voters ids={voters} />
        <Button
          size="sm"
          variant={mine ? 'primary' : 'soft'}
          icon={Check}
          label={mine ? `Your vote: ${o.name}` : `Vote for ${o.name}`}
          onClick={() => onVote?.(o.id)}
        />
      </div>
    </div>
  );
}

export interface PollCardProps extends PollProps {
  /** Opened up, in place: each place under the head, to vote on. */
  expanded: boolean;
  /** A tap on the head: open it, or close it. */
  onToggle?: () => void;
  /** A place's Details: the poll's pop-up, with walking times. */
  onDetails?: (option: string) => void;
  /** A place's check: my vote, or my vote moved to it. */
  onVote?: (option: string) => void;
}

/**
 * The poll on the map (Bogdan's design, Figma 82:3), the screen less its margins wide (whoever places it gives the
 * width), its text left-aligned on the surface (md in at the top, xs on the other sides). Closed, it's a compact card
 * under the day filter: "Live poll • closes in 19 mins" (label-md, semibold, brand) with the red dot after it and a
 * chevron at the end, the question (heading-md), and "5 PM • Maya asked • 3 of 5 voted" (label-sm, muted) with everyone
 * at the table as tiny faces. The head (md in from the sides, sm between its lines) is one button: it opens the poll in
 * place, over a tinted map (PollScrim, the trip screen's). The same card grows down (its height, enter-ms, ease-in-out:
 * it moves on screen) while the places arrive under the head, sm apart, one after another; the chevron turns over
 * (enter-ms, ease-out) and the faces in the meta line fade out (fade-ms; each place shows its own voters). The head
 * again closes it: the places fade out with a blur first (fade-ms), then the card folds up after them, and the faces
 * come back (enter-ms). If the screen is too short for it, the places scroll. Reduced motion: the height jumps, the
 * places only fade. Leaving the map (the poll closing, a pop-up covering it), it takes no more taps.
 */
export function PollCard({ now, poll, expanded, onToggle, onDetails, onVote }: PollCardProps) {
  const reduce = !!useReducedMotion();
  const present = useIsPresent();
  const n = votesIn(now, poll), countdown = pollCountdown(now, poll);
  const blur = reduce ? 'none' : `blur(${m['enter-blur']}px)`;
  return (
    <section className="tu-poll-card tu-surface tu-surface--sheet" aria-label="Dinner poll" inert={!present}>
      {/* The head: tapping it opens the poll, or closes it */}
      <button
        type="button"
        className="tu-poll-card__head"
        aria-expanded={expanded}
        aria-label={`${expanded ? 'Close' : 'Open'} the dinner poll: ${n} of ${DINNER_TABLE.length} voted, ${countdown}`}
        onClick={onToggle}
      >
        <span className="tu-poll-card__live">
          <span className="text-label-md weight-semibold tu-ellipsis tu-poll-card__live-text">Live poll • {countdown}</span>
          <LiveDot />
          <ChevronDown className="tu-poll-card__chevron" data-open={expanded || undefined} strokeWidth={2} absoluteStrokeWidth aria-hidden />
        </span>
        <span className="tu-poll-card__text">
          <span className="text-heading-md tu-ellipsis tu-poll-card__question">Where for dinner tonight?</span>
          <span className="tu-poll-card__meta">
            <span className="text-label-sm tu-ellipsis tu-poll-card__meta-text">{clockTime(DINNER)} • {personById(POLL_ASKED_BY).name} asked • {n} of {DINNER_TABLE.length} voted</span>
            {/* Who has voted: the faces say it closed; open, each place shows its own */}
            <Table now={now} poll={poll} hidden={expanded} />
          </span>
        </span>
      </button>
      {/* The places, open: the card grows to hold them (an on-screen morph, so ease in and out), and they arrive one
          by one; closing, they fade away first and the card folds up after them */}
      <motion.div
        className="tu-poll-card__places"
        initial={false}
        animate={{ height: expanded ? 'auto' : 0 }}
        transition={reduce ? { duration: 0 } : { duration: m['enter-ms'] / 1000, ease: easeInOut, delay: expanded ? 0 : m['fade-ms'] / 1000 }}
      >
        <AnimatePresence initial={false}>
          {expanded && (
            <motion.div
              key="places"
              className="tu-poll-card__list"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
              exit={{ opacity: 0, filter: blur, transition: { duration: m['fade-ms'] / 1000, ease } }}
            >
              <StaggerIn gap="sm">
                {POLL_OPTIONS.map(o => <Place key={o.id} option={o} now={now} poll={poll} onDetails={onDetails} onVote={onVote} />)}
              </StaggerIn>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </section>
  );
}

/**
 * Behind the open poll, over the whole screen (the map and its bars): a blue tint (c-poll-scrim, blue 975 at 23%) and
 * a slight blur (d-poll-scrim-blur 2.5). It fades in as the poll opens (enter-ms, ease-out) and out quicker (fade-ms);
 * a tap on it closes the poll. Put it in AnimatePresence, under the card.
 */
export function PollScrim({ onClose }: { onClose?: () => void }) {
  return (
    <motion.div
      className="tu-poll-scrim"
      aria-hidden
      onClick={onClose}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={{ opacity: 0, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
    />
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
