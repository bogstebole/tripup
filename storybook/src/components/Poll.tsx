// The dinner poll: where to eat tonight, decided by the group (see the poll section of data.ts). The app has the same
// in lib/components/poll.dart.
import { Check } from 'lucide-react';
import {
  clockTime, DINNER, DINNER_TABLE, dinnerChoice, personById, POLL_ASKED_BY, POLL_CLOSES, POLL_OPTIONS, pollClosed, pollCountdown,
  pollLeader, pollOpen, pollOptionById, pollScore, votersOf, votesIn, walkMinutes, type PollState,
} from '../data';
import { TextButton } from './Button';
import { FacePile } from './FacePile';
import { RatingLine } from './RatingLine';
import { Sticker } from './Sticker';
import { useTripNotice } from './Notice';
import { Slot, StaggerIn } from './TripSheet';
import './Surface.css';
import './Poll.css';

const faces = (ids: string[]) => ids.map(id => personById(id).sticker);
const names = (ids: string[]) => ids.map(id => personById(id).name).join(', ');
/** "5 PM · Maya asked". */
const asked = () => `${clockTime(DINNER)} · ${personById(POLL_ASKED_BY).name} asked`;

export interface PollProps {
  /** Now, in the trip. */
  now: Date;
  /** My vote, and whether the winner was undone and another picked by hand. */
  poll: PollState;
}

/** A small brand pill: "Leading", "Won", "Tonight". */
export function PollTag({ label }: { label: string }) {
  return <span className="tu-poll-tag text-label-md weight-semibold">{label}</span>;
}

/**
 * While the poll is open it stands where the Up next card would: the question, the three places with who voted for
 * each, the leading one marked, and the countdown. Tapping it opens the poll.
 */
export function PollCard({ now, poll, onOpen }: PollProps & { onOpen?: () => void }) {
  const leader = pollLeader(now, poll), countdown = pollCountdown(now, poll), n = votesIn(now, poll);
  return (
    <button
      type="button"
      className="tu-poll-card tu-surface tu-surface--sheet"
      onClick={onOpen}
      aria-label={`Dinner poll: ${n} of ${DINNER_TABLE.length} voted, ${countdown}. Open`}
    >
      <span className="text-label-md weight-bold tu-poll-card__label">Poll · {countdown}</span>
      <span className="text-heading-sm tu-poll-card__question">Where for dinner tonight?</span>
      <span className="text-body-sm tu-poll-card__meta">{asked()} · {n} of {DINNER_TABLE.length} voted</span>
      <span className="tu-poll-card__rows">
        {POLL_OPTIONS.map(o => {
          const voters = votersOf(o.id, now, poll);
          return (
            <span key={o.id} className="tu-poll-card__row">
              <Slot size="avatar"><Sticker name={o.sticker} size="avatar" /></Slot>
              <span className="text-label-md weight-semibold tu-ellipsis tu-poll-card__name">{o.name}</span>
              {o.id === leader && <PollTag label="Leading" />}
              {voters.length > 0 && <FacePile faces={faces(voters)} size="chip" label={names(voters)} />}
            </span>
          );
        })}
      </span>
    </button>
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
 * The poll: a card per place (its sticker, rating, food, price and how far it is), who voted for it, and Vote. Once
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
            <div className="tu-poll-place__votes">
              {voters.length > 0 && <FacePile faces={faces(voters)} size="chip" label={names(voters)} />}
              <span className="text-body-sm tu-poll__muted">{voters.length ? `${voters.length} ${voters.length === 1 ? 'vote' : 'votes'}` : 'No votes yet'}</span>
              {won ? <PollTag label="Tonight" /> : o.id === leader && <PollTag label={open ? 'Leading' : 'Won'} />}
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
