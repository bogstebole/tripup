// The dinner poll: where to eat tonight, decided by the group (see the poll section of data.ts). The app has the same
// in lib/components/poll.dart.
import { ArrowRight, Check, ChevronDown, ChevronUp } from 'lucide-react';
import { animate, motion, useMotionValue, useReducedMotion, useTransform } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
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
const morph = m['spring-morph'];
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

/** A place on the card: its sticker, name, voters and bar, and the round mark that is the vote. Tapping the row votes
 *  for it (or moves my vote to it). */
function VoteRow({ option: o, now, poll, ahead, onVote }: PollProps & { option: PollOption; ahead: boolean; onVote?: (option: string) => void }) {
  const voters = votersOf(o.id, now, poll), mine = poll.mine?.option === o.id;
  return (
    <button type="button" className="tu-vote-row" aria-label={mine ? `Your vote: ${o.name}` : `Vote for ${o.name}`} onClick={() => onVote?.(o.id)}>
      <Slot size="avatar"><Sticker name={o.sticker} size="avatar" /></Slot>
      <span className="tu-vote-row__choice">
        <span className="tu-vote-row__line">
          <span className="text-label-md weight-semibold tu-ellipsis tu-vote-row__name">{o.name}</span>
          <Voters ids={voters} />
        </span>
        <VoteBar votes={voters.length} ahead={ahead} />
      </span>
      <VoteMark on={mine} />
    </button>
  );
}

/**
 * The vote itself: an empty ring (poll-mark 24, ring poll-mark-ring 2), or filled in brand with a check once it's
 * mine. The fill comes in quickly with a small scale (from morph-enter-scale, press-ms, ease-out) and goes at fade-ms;
 * with reduced motion it only fades.
 */
export function VoteMark({ on }: { on: boolean }) {
  return (
    <span className="tu-vote-mark" data-on={on || undefined} aria-hidden>
      <span className="tu-vote-mark__fill"><Check className="tu-vote-mark__check" strokeWidth={2} absoluteStrokeWidth /></span>
    </span>
  );
}

export interface PollCardProps extends PollProps {
  /** "Ratings, prices and walks": opens the poll. */
  onOpen?: () => void;
  /** The corner button: folds it into the pill. */
  onFold?: () => void;
  /** A tap on a place: my vote, or my vote moved to it. */
  onVote?: (option: string) => void;
}

/**
 * The card's content (PollOnMap gives it its surface): a live sign and the countdown, with the fold button, in a row
 * as tall as the pill; the question; then each place with everyone who voted for it, a bar of its votes (the one
 * ahead in brand) and a ring that is the vote. Tapping a place votes for it, right there; the poll itself (ratings,
 * prices, walks) is the link at the bottom. The card is no longer one big button.
 */
export function PollCard({ now, poll, onOpen, onFold, onVote }: PollCardProps) {
  const leader = pollLeader(now, poll), countdown = pollCountdown(now, poll), n = votesIn(now, poll);
  return (
    <div className="tu-poll-card">
      {/* As tall as the pill, so the live dot and its line stay put as it folds */}
      <div className="tu-poll-card__head">
        <LiveDot />
        <span className="text-label-md weight-bold tu-ellipsis tu-poll-card__label">Live poll · {countdown}</span>
        <Button size="sm" icon={ChevronUp} label="Fold the poll away" onClick={onFold} />
      </div>
      <div className="tu-poll-card__body">
        <p className="text-heading-sm tu-poll-card__question">Where for dinner tonight?</p>
        <p className="text-body-sm tu-poll-card__meta">{asked()} · {n} of {DINNER_TABLE.length} voted</p>
      </div>
      {POLL_OPTIONS.map(o => <VoteRow key={o.id} option={o} now={now} poll={poll} ahead={o.id === leader} onVote={onVote} />)}
      {/* The places in full */}
      <button type="button" className="tu-poll-card__more" aria-label="See the places: ratings, prices and walks" onClick={onOpen}>
        <span className="text-label-md weight-semibold">Ratings, prices and walks</span>
        <ArrowRight className="tu-poll-card__more-icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
      </button>
    </div>
  );
}

/**
 * The pill's content (PollOnMap gives it its surface): the live sign, "Dinner poll · 3 of 5 · closes in 19 mins" (one
 * line, ellipsized) and a chevron down, as tall as the top bar's buttons. Tapping it unfolds the card.
 */
export function PollPill({ now, poll, onUnfold }: PollProps & { onUnfold?: () => void }) {
  const countdown = pollCountdown(now, poll), n = votesIn(now, poll);
  return (
    <button type="button" className="tu-poll-pill" onClick={onUnfold} aria-label={`Dinner poll: ${n} of ${DINNER_TABLE.length} voted, ${countdown}. Unfold`}>
      <LiveDot />
      <span className="text-label-md weight-semibold tu-ellipsis tu-poll-pill__text">Dinner poll · {n} of {DINNER_TABLE.length} · {countdown}</span>
      <ChevronDown className="tu-poll-pill__chevron" strokeWidth={2} absoluteStrokeWidth aria-hidden />
    </button>
  );
}

type Size = { width: number; height: number };
/** Its layout size (transforms, like a press or the poll arriving, don't count). */
const sizeOf = (el: HTMLElement): Size => ({ width: el.offsetWidth, height: el.offsetHeight });
const sameSize = (a: Size, b: Size) => a.width === b.width && a.height === b.height;
/** 0 up to `a`, 1 from `b`, eased in and out between (the app's smoothstep). */
const smoothstep = (a: number, b: number, v: number) => {
  const x = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return x * x * (3 - 2 * x);
};

export interface PollOnMapProps extends PollCardProps {
  /** Folded into the pill. */
  folded: boolean;
  /** A tap on the pill: unfold the card. */
  onUnfold?: () => void;
}

/**
 * The poll on the map, as one surface that folds between the card and the pill. Its box springs between their two
 * measured sizes (spring-morph) while one's content fades out and the other's fades in (the pill over 0.05–0.55 of
 * the way, the card over 0.3–0.8, eased in and out), slightly blurred where they overlap (crossfade-blur); both are
 * pinned to the box's top-left, so the live dot and the line beside it travel with it. It reads as the same thing
 * changing shape, not two things swapping. With reduced motion the box jumps and the contents only fade (fade-ms).
 * Coming and going on the map (the poll opening and closing, a pop-up covering it) is up to whoever places it.
 */
export function PollOnMap({ folded, now, poll, onFold, onUnfold, onOpen, onVote }: PollOnMapProps) {
  const reduce = !!useReducedMotion();
  // 0 = the pill, 1 = the card (a spring, so it can go a little past either)
  const t = useMotionValue(folded ? 0 : 1);
  const pillRef = useRef<HTMLDivElement>(null), cardRef = useRef<HTMLDivElement>(null);
  const [sizes, setSizes] = useState<{ pill: Size; card: Size }>();

  // Each content at its own size, whatever the box is doing: measured before the first paint, and again whenever it
  // changes (the pill's line follows the count and the countdown)
  useLayoutEffect(() => {
    const pill = pillRef.current, card = cardRef.current;
    if (!pill || !card) return;
    const measure = () => setSizes(s => {
      const next = { pill: sizeOf(pill), card: sizeOf(card) };
      return s && sameSize(s.pill, next.pill) && sameSize(s.card, next.card) ? s : next;
    });
    measure();
    const watch = new ResizeObserver(measure);
    watch.observe(pill);
    watch.observe(card);
    return () => watch.disconnect();
  }, []);

  // Fold or unfold: from wherever it is, so a tap mid-way turns it around
  useEffect(() => {
    const to = folded ? 0 : 1;
    if (t.get() !== to) animate(t, to, reduce ? { duration: m['fade-ms'] / 1000, ease } : { type: 'spring', duration: morph.duration, bounce: morph.bounce });
  }, [folded, reduce, t]);
  useEffect(() => () => t.stop(), [t]);

  const p = () => Math.min(1, Math.max(0, t.get()));
  const pillOpacity = useTransform(() => (reduce ? 1 - p() : 1 - smoothstep(0.05, 0.55, p())));
  const cardOpacity = useTransform(() => (reduce ? p() : smoothstep(0.3, 0.8, p())));
  // The seam: blurred most where both are half there
  const seam = useTransform(() => {
    const sigma = reduce ? 0 : m['crossfade-blur'] * 4 * pillOpacity.get() * cardOpacity.get();
    return sigma < 0.05 ? 'none' : `blur(${sigma}px)`;
  });
  const side = (k: keyof Size) => (!sizes ? 0 : reduce ? sizes[folded ? 'pill' : 'card'][k] : sizes.pill[k] + (sizes.card[k] - sizes.pill[k]) * t.get());
  const width = useTransform(() => side('width'));
  const height = useTransform(() => side('height'));

  return (
    // Until both are measured (before the first paint), it lays them out unseen
    <motion.div className="tu-poll-morph tu-surface tu-surface--sheet" style={{ width, height, visibility: sizes ? undefined : 'hidden' }}>
      <motion.div className="tu-poll-morph__seam" style={{ filter: seam }}>
        {/* Only the one it is takes taps (and focus) */}
        <motion.div ref={pillRef} className="tu-poll-morph__pill" style={{ opacity: pillOpacity }} inert={!folded}>
          <PollPill now={now} poll={poll} onUnfold={onUnfold} />
        </motion.div>
        <motion.div ref={cardRef} className="tu-poll-morph__card" style={{ opacity: cardOpacity }} inert={folded}>
          <PollCard now={now} poll={poll} onOpen={onOpen} onFold={onFold} onVote={onVote} />
        </motion.div>
      </motion.div>
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
