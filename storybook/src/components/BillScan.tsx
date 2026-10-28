// Scanning the dinner's bill: the camera finds the paper, reads it, and every line lands on whoever had it.
import { Check, ChevronDown, ChevronUp, UserPlus, X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type Ref } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  billShares, billTotal, BRASSERIE_BILL, DINNER_TABLE, euros, lineTotal, menuItemNamed, MY_ID, personById, scannedBill, unclaimedOf, type Bill, type BillLine,
} from '../data';
import { Button, TextButton } from './Button';
import { Sticker } from './Sticker';
import { Hairline, Slot, StaggerIn, TripSheet } from './TripSheet';
import './Surface.css';
import './BillScan.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const space = tokens.space as Record<string, number>;
const cornerLength = space.xl;

type Phase = 'aim' | 'lock' | 'read' | 'review';
type Box = { left: number; top: number; width: number; height: number };
/** An element's box in the camera's own frame (its offsets, so a transform above the camera doesn't skew it). */
const boxOf = (el: HTMLElement, grow = 0): Box => ({ left: el.offsetLeft - grow, top: el.offsetTop - grow, width: el.offsetWidth + grow * 2, height: el.offsetHeight + grow * 2 });
const who = (id: string) => (id === MY_ID ? 'You' : personById(id).name);

export interface BillScanProps {
  /** The bill as checked (who had each line, who paid), to add to the trip's money. */
  onAdd?: (bill: Bill) => void;
  onClose?: () => void;
}

/**
 * The camera over the screen: it fades in like any modal (enter-ms) and leaves with a blur (fade-ms), so the bill
 * melts into the page under it (Group or Money, in the same place on the same background). Reduced motion: fades.
 * Put it in AnimatePresence.
 */
export function Camera({ onAdd, onClose }: BillScanProps) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      style={{ position: 'absolute', inset: 0 }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={{ opacity: 0, filter: reduce ? 'none' : ['blur(0px)', `blur(${m['enter-blur']}px)`], transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      <BillScan onAdd={onAdd} onClose={onClose} />
    </motion.div>
  );
}

/**
 * Full screen, over everything: the camera's view of the bill, on one plain colour (zinc 900). A moment to find the
 * paper (scan-find-ms), then the frame closes in from the screen's edges onto it (enter-ms, ease-out) and turns blue, a
 * line reads it top to bottom at an even pace (scan-read-ms, linear), and the bill rises with every line on the faces
 * of whoever had it. Then the colour fades out (enter-ms) and the paper with it (fade-ms), so the bill sits on what's
 * behind: the same backdrop as the full view, in the same place. Reduced motion: straight to the bill, which fades in.
 * In the prototype the camera shows a prepared bill (there's no real camera or OCR).
 */
export function BillScan({ onAdd, onClose }: BillScanProps) {
  const reduce = useReducedMotion();
  const [phase, setPhase] = useState<Phase>('aim');
  const root = useRef<HTMLDivElement>(null);
  const aim = useRef<HTMLDivElement>(null);
  const paper = useRef<HTMLDivElement>(null);
  // Where the payer menu sits, while it's open: its bottom-left corner xs above the trigger's top-left. It goes over
  // everything in the camera (so nothing clips it), with a tap anywhere else closing it.
  const [menu, setMenu] = useState<{ left: number; bottom: number } | null>(null);
  const openMenu = (trigger: HTMLElement) => {
    const t = trigger.getBoundingClientRect(), r = root.current?.getBoundingClientRect();
    if (r) setMenu({ left: t.left - r.left, bottom: r.bottom - t.top + tokens.space.xs });
  };
  // Where the frame starts (the screen's edges) and where the paper is, once it's found
  const [from, setFrom] = useState<Box | null>(null);
  const [to, setTo] = useState<Box | null>(null);
  const [bill, setBill] = useState<Bill>(scannedBill);

  useLayoutEffect(() => {
    if (aim.current) setFrom(boxOf(aim.current));
  }, []);
  // A moment to "find" the paper, as a camera would
  useEffect(() => {
    const t = window.setTimeout(() => {
      if (paper.current) setTo(boxOf(paper.current, tokens.space.xs));
      setPhase(reduce ? 'review' : 'lock');
    }, m['scan-find-ms']);
    return () => window.clearTimeout(t);
  }, [reduce]);

  const review = phase === 'review';
  const frame = phase === 'aim' ? from : to ?? from;
  return (
    <div ref={root} className="tu-scan" data-phase={phase}>
      {/* The camera's view: one plain colour with the bill on it, both fading once the bill is up */}
      <div className="tu-scan__bg" aria-hidden />
      <div className="tu-scan__middle">
        <Paper ref={paper} />
      </div>
      <div ref={aim} className="tu-scan__aim" aria-hidden />
      {/* The frame: from the edges of the screen onto the paper, turning blue once it has it */}
      {!review && frame && (
        <div className={phase === 'read' ? 'tu-scan__frame tu-scan__frame--locked' : 'tu-scan__frame'} aria-hidden>
          {/* Each mark is a corner-sized box at its corner of the rect, the corner point on the rect's corner */}
          {([[0, 0], [1, 0], [0, 1], [1, 1]] as const).map(([x, y]) => (
            <motion.svg
              key={`${x}${y}`}
              className="tu-scan__corner"
              width={cornerLength}
              height={cornerLength}
              initial={false}
              animate={{ transform: `translate(${frame.left + x * (frame.width - cornerLength)}px, ${frame.top + y * (frame.height - cornerLength)}px)` }}
              transition={{ duration: m['enter-ms'] / 1000, ease }}
              onAnimationComplete={x + y === 0 ? () => setPhase(p => (p === 'lock' ? 'read' : p)) : undefined}
            >
              <path d={`M ${x * cornerLength} ${(1 - y) * cornerLength} L ${x * cornerLength} ${y * cornerLength} L ${(1 - x) * cornerLength} ${y * cornerLength}`} />
            </motion.svg>
          ))}
        </div>
      )}
      {/* The reading line, top to bottom over the paper at an even pace */}
      {phase === 'read' && to && (
        <motion.span
          className="tu-scan__line"
          style={{ left: to.left, top: to.top, width: to.width }}
          initial={{ transform: 'translate(0px, 0px)' }}
          animate={{ transform: `translate(0px, ${to.height}px)` }}
          transition={{ duration: m['scan-read-ms'] / 1000, ease: 'linear' }}
          onAnimationComplete={() => setPhase('review')}
          aria-hidden
        />
      )}
      {/* The camera's own close and title (the bill has its own once it's up) */}
      {!review && (
        <>
          <div className="tu-scan__bar">
            <Button icon={X} label="Close the camera" size="sm" onClick={onClose} />
            <p className="text-label-lg tu-scan__title">Scan the bill</p>
            <span className="tu-scan__bar-end" aria-hidden />
          </div>
          <p className="text-label-md tu-scan__hint" role="status">{phase === 'aim' ? 'Hold the bill inside the frame' : 'Reading the bill…'}</p>
        </>
      )}
      {/* The bill, rising over the camera once it's read, in the full view's place */}
      {review && (
        <div className="tu-scan__place">
          <BillReview bill={bill} payerMenuOpen={!!menu} onPayer={openMenu} onChange={setBill} onAdd={() => onAdd?.(bill)} onClose={onClose} />
        </div>
      )}
      {menu && <div className="tu-payer__outside" onClick={() => setMenu(null)} aria-hidden />}
      <AnimatePresence>
        {menu && (
          <PayerMenu
            key="payer"
            at={menu}
            payer={bill.paidBy}
            table={DINNER_TABLE}
            onPick={id => {
              setBill(b => ({ ...b, paidBy: id }));
              setMenu(null);
            }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

/** "you", "Maya and you", "Maya, Leo and you". */
const names = (ids: string[]) => {
  const n = ids.map(id => (id === MY_ID ? 'you' : personById(id).name));
  return n.length < 2 ? n.join('') : `${n.slice(0, -1).join(', ')} and ${n[n.length - 1]}`;
};

/**
 * The bill as read: the total, big, then every line with what it is on the menu, how many at what price, its amount
 * and every face of whoever had it. Under it, what each person had to the cent (scrolling sideways once they don't
 * fit), who paid, and Add to the trip's money.
 */
function BillReview({ bill, payerMenuOpen, onPayer, onChange, onAdd, onClose }: {
  bill: Bill;
  payerMenuOpen: boolean;
  /** Opens the payer menu over its trigger. */
  onPayer: (trigger: HTMLElement) => void;
  onChange: (b: Bill) => void;
  onAdd: () => void;
  onClose?: () => void;
}) {
  const reduce = useReducedMotion();
  const table = DINNER_TABLE, shares = billShares(bill);
  // The line whose faces are open for changing, if any, and each line's place (to bring an opened one into view)
  const [editing, setEditing] = useState<number | null>(null);
  const lines = useRef<(HTMLDivElement | null)[]>([]);
  const scrollTimer = useRef<number | undefined>(undefined);
  useEffect(() => () => window.clearTimeout(scrollTimer.current), []);

  const edit = (i: number) => {
    const opening = editing !== i;
    setEditing(opening ? i : null);
    window.clearTimeout(scrollTimer.current);
    if (!opening) return;
    // Once its faces have grown in, scroll so the whole line shows, in the middle of the page
    scrollTimer.current = window.setTimeout(() => {
      const el = lines.current[i], page = el?.closest<HTMLElement>('.tu-trip-sheet__scroll');
      if (!el || !page) return;
      const at = el.getBoundingClientRect().top - page.getBoundingClientRect().top + page.scrollTop;
      page.scrollTo({ top: at - (page.clientHeight - el.offsetHeight) / 2, behavior: reduce ? 'auto' : 'smooth' });
    }, OPENING_MS);
  };
  const toggle = (line: number, id: string) => {
    const had = bill.who[line].includes(id) ? bill.who[line].filter(x => x !== id) : [...bill.who[line], id];
    onChange({ ...bill, who: bill.who.map((w, i) => (i === line ? had : w)) });
  };
  const unclaimed = unclaimedOf(bill);

  return (
    <TripSheet
      title="The bill"
      subtitle={`La Brasserie de L'Entrecôte · ${bill.lines.length} lines${unclaimed.length ? ` · ${unclaimed.length} nobody has yet` : ''}`}
      onClose={onClose}
      footer={
        <div className="tu-bill__footer">
          {/* The summary in a grey block of its own: everyone's share, then the total. It sets itself apart from the
              lines above, so the footer needs no edge */}
          <div className="tu-bill__summary">
            {/* What each person had, to the cent: side by side while they fit, scrolling sideways once they don't */}
            <div className="tu-bill__shares">
              {table.map(id => (
                <span key={id} className="tu-bill__share">
                  <Sticker name={personById(id).sticker} size="avatar" />
                  <span className="text-label-md weight-semibold">{euros(shares[id] ?? 0)}</span>
                </span>
              ))}
            </div>
            <div className="tu-bill__rule" />
            {/* The total, big: it's the number everyone checks first, and it stays in view under the lines */}
            <div className="tu-bill__total">
              <span className="text-label-lg tu-bill__total-label">Total</span>
              <span className="text-heading-lg">{euros(billTotal(bill))}</span>
            </div>
          </div>
          <div className="tu-bill__actions">
            <PayerTrigger payer={bill.paidBy} open={payerMenuOpen} onOpen={onPayer} />
            <TextButton label="Add to the trip's money" size="lg" onClick={onAdd} />
          </div>
        </div>
      }
    >
      <StaggerIn>
        {bill.lines.flatMap((line, i) => {
          const block = (
            <BillLineRow
              key={`line-${i}`}
              refEl={el => { lines.current[i] = el; }}
              line={line}
              had={bill.who[i]}
              table={table}
              open={editing === i}
              onOpen={() => edit(i)}
              onToggle={id => toggle(i, id)}
            />
          );
          return i ? [<Hairline key={`hairline-${i}`} />, block] : [block];
        })}
      </StaggerIn>
    </TripSheet>
  );
}

// The opening's steps, as in the app (a quick move people make many times over a bill)
const FACE_OUT_MS = 100, FACE_STAGGER_MS = 25, BLOCK_AT_MS = 60, PEOPLE_AT_MS = 60, PEOPLE_STAGGER_MS = 30;
const OPENING_MS = BLOCK_AT_MS + PEOPLE_AT_MS + PEOPLE_STAGGER_MS * (DINNER_TABLE.length - 1) + m['fade-ms'];
const s_ = (ms: number) => ms / 1000;

/**
 * One line of the bill (Figma 262:12632): the dish, then what it comes to (and how many at what price), and at the end
 * who had it: their faces on a soft pill with a chevron, or a round add-a-person button for a line nobody has yet.
 * Either opens the line: everyone at the table in a grey block, the ones who had it with a red minus, the others faded
 * with a plus; a tap on a person adds or takes them off. Opening is one move: the pill's faces leave one after another
 * (100 ms each, 25 apart), the pill gives way to a round chevron (up), a little blurred while both show, the block
 * grows (enter-ms) and the people come in one after another (fade-ms each, 30 apart), about 420 ms in all; closing runs
 * back, quicker. Reduced motion: it only fades.
 */
function BillLineRow({ line, had, table, open, onOpen, onToggle, refEl }: {
  line: BillLine; had: string[]; table: string[]; open: boolean; onOpen: () => void; onToggle: (id: string) => void; refEl: (el: HTMLDivElement | null) => void;
}) {
  const reduce = useReducedMotion();
  const lastFace = FACE_STAGGER_MS * Math.max(0, had.length - 1);
  const swap = { duration: s_(FACE_OUT_MS), delay: open && !reduce ? s_(lastFace) : 0, ease };
  const blur = (on: boolean) => (reduce ? 'none' : on ? 'blur(0px)' : `blur(${m['enter-blur']}px)`);
  return (
    <div ref={refEl}>
      <button type="button" className="tu-bill__line" aria-expanded={open} onClick={onOpen}>
        <span className="text-label-lg">{menuItemNamed(line.item)?.name ?? line.printed}</span>
        <span className="tu-bill__meta">
          <span className="tu-bill__sums">
            <span className="text-body-lg weight-semibold">{euros(lineTotal(line))}</span>
            <span className="text-body-sm tu-bill__qty">{`${line.qty} × ${euros(line.unit)}`}</span>
          </span>
          <span className="tu-bill__control">
            {/* Who had it, or a way to say who did; it gives way to a round chevron while the line is open */}
            <motion.span
              className={had.length ? 'tu-btn tu-btn--soft tu-btn--text tu-btn--text-sm tu-bill__pill' : 'tu-btn tu-btn--soft tu-btn--sm tu-bill__pill'}
              animate={{ opacity: open ? 0 : 1, filter: blur(!open) }}
              transition={swap}
              aria-label={had.length ? names(had) : 'Nobody yet: say who had it'}
            >
              {had.length ? (
                <>
                  <span className="tu-bill__pile">
                    {had.map((id, k) => (
                      <motion.span
                        key={id}
                        animate={{ opacity: open ? 0 : 1, transform: open && !reduce ? `scale(${m['morph-enter-scale']})` : 'scale(1)' }}
                        transition={{ duration: s_(FACE_OUT_MS), delay: open && !reduce ? s_(FACE_STAGGER_MS * k) : 0, ease }}
                      >
                        <Sticker name={personById(id).sticker} size="chip" />
                      </motion.span>
                    ))}
                  </span>
                  <ChevronDown className="tu-btn__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
                </>
              ) : (
                <UserPlus className="tu-btn__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
              )}
            </motion.span>
            <motion.span className="tu-btn tu-btn--soft tu-btn--sm tu-bill__round" initial={false} animate={{ opacity: open ? 1 : 0, filter: blur(open) }} transition={swap} aria-hidden>
              <ChevronUp className="tu-btn__icon" strokeWidth={2} absoluteStrokeWidth />
            </motion.span>
          </span>
        </span>
      </button>
      {/* Everyone at the table, in a grey block that grows under the line */}
      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            key="who"
            className="tu-bill__who"
            initial={reduce ? { opacity: 0 } : { height: 0 }}
            animate={reduce ? { opacity: 1, transition: { duration: s_(m['fade-ms']) } } : { height: 'auto', transition: { delay: s_(BLOCK_AT_MS), duration: s_(m['enter-ms']), ease } }}
            exit={reduce ? { opacity: 0, transition: { duration: s_(m['fade-ms']) } } : { height: 0, transition: { duration: s_(m['enter-ms'] * 0.75), ease } }}
          >
            <div className="tu-bill__faces">
              {table.map((id, j) => {
                const on = had.includes(id);
                return (
                  <motion.button
                    key={id}
                    type="button"
                    className="tu-bill__face"
                    aria-pressed={on}
                    aria-label={`${personById(id).name}: ${on ? 'had it, tap to take off' : "didn't have it, tap to add"}`}
                    onClick={() => onToggle(id)}
                    initial={{ opacity: 0, transform: reduce ? 'none' : `translateY(${tokens.space.xs}px)` }}
                    animate={{ opacity: 1, transform: 'translateY(0px)', transition: { delay: reduce ? 0 : s_(BLOCK_AT_MS + PEOPLE_AT_MS + PEOPLE_STAGGER_MS * j), duration: s_(m['fade-ms']), ease } }}
                    exit={{ opacity: 0, transition: { duration: s_(m['fade-ms'] * 0.75), ease } }}
                  >
                    <span className="tu-bill__face-pic">
                      <span className={on ? undefined : 'tu-bill__off'}><Sticker name={personById(id).sticker} size="avatar" /></span>
                      <AddRemove on={on} />
                    </span>
                    <span className={on ? 'text-label-md' : 'text-label-md tu-bill__off'}>{personById(id).name}</span>
                  </motion.button>
                );
              })}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

/** The small add/remove mark on a person: the sm button's glass at 0.4 (16 of 40, its edge and shadow shrinking with
 *  it), soft with a plus for someone who didn't have it, red with a minus for someone who did. It turns from one into
 *  the other on the spot: the glass fades from soft to red and the plus's upright bar folds away into the minus
 *  (fade-ms, ease-out). */
function AddRemove({ on }: { on: boolean }) {
  return (
    <span className="tu-mark" data-on={on || undefined} aria-hidden>
      <span className="tu-mark__scaled">
        <span className="tu-btn tu-btn--soft tu-btn--sm tu-mark__glass" />
        <span className="tu-btn tu-btn--danger tu-btn--sm tu-mark__glass tu-mark__glass--on" />
        <span className="tu-mark__bar" />
        <span className="tu-mark__bar tu-mark__bar--up" />
      </span>
    </span>
  );
}

/** Who paid: the payer's face, "You paid" and a chevron up, where the payer menu opens. */
function PayerTrigger({ payer, open, onOpen }: { payer: string; open: boolean; onOpen: (trigger: HTMLElement) => void }) {
  return (
    <button
      type="button"
      className="tu-payer"
      aria-haspopup="menu"
      aria-expanded={open}
      aria-label={`${who(payer)} paid. Change who paid`}
      onClick={e => onOpen(e.currentTarget)}
    >
      <Sticker name={personById(payer).sticker} size="chip" />
      <span className="text-label-md weight-semibold tu-ellipsis">{who(payer)} paid</span>
      <ChevronUp className="tu-payer__chevron" strokeWidth={2} absoluteStrokeWidth aria-hidden />
    </button>
  );
}

/**
 * The payer menu: a small surface opening upward from the trigger (it sits at the bottom of the screen), everyone at
 * the table, the payer checked; picking one changes who paid and closes it. It grows from the trigger's corner and
 * fades: fade-ms in, press-ms out, from press-scale. Reduced motion: fades only. Put it in AnimatePresence.
 */
function PayerMenu({ at, payer, table, onPick }: { at: { left: number; bottom: number }; payer: string; table: string[]; onPick: (id: string) => void }) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      role="menu"
      aria-label="Who paid"
      className="tu-payer__menu tu-surface"
      style={{ left: at.left, bottom: at.bottom, originX: 0, originY: 1 }}
      initial={{ opacity: 0, scale: reduce ? 1 : m['press-scale'] }}
      animate={{ opacity: 1, scale: 1, transition: { duration: m['fade-ms'] / 1000, ease } }}
      exit={{ opacity: 0, scale: reduce ? 1 : m['press-scale'], pointerEvents: 'none', transition: { duration: m['press-ms'] / 1000, ease } }}
    >
      {table.map(id => (
        <button
          key={id}
          type="button"
          role="menuitemradio"
          aria-checked={id === payer}
          aria-label={`${who(id)} paid`}
          className="tu-payer__option"
          onClick={() => onPick(id)}
        >
          <Slot size="avatar"><Sticker name={personById(id).sticker} size="avatar" /></Slot>
          <span className="text-label-lg tu-payer__name">{who(id)}</span>
          {id === payer && <Check className="tu-payer__check" strokeWidth={2} absoluteStrokeWidth aria-hidden />}
        </button>
      ))}
    </motion.div>
  );
}

/** The paper bill on the table, as the camera sees it. */
function Paper({ ref }: { ref: Ref<HTMLDivElement> }) {
  const line = (left: string, right: string) => (
    <p key={left} className="tu-paper__line">
      <span className="tu-paper__item">{left}</span>
      <span>{right}</span>
    </p>
  );
  return (
    <div ref={ref} className="tu-paper text-body-sm" aria-label="The bill on the table">
      <p className="tu-paper__centre weight-bold">LA BRASSERIE DE L'ENTRECÔTE</p>
      <p className="tu-paper__centre">AV. DA IGREJA 12B · LISBOA</p>
      <p className="tu-paper__centre">14/05/2026  19:24  MESA 12</p>
      <span className="tu-paper__rule" />
      {BRASSERIE_BILL.map(l => line(`${l.qty} ${l.printed}`, lineTotal(l).toFixed(2)))}
      <span className="tu-paper__rule" />
      {line('TOTAL EUR', BRASSERIE_BILL.reduce((sum, l) => sum + lineTotal(l), 0).toFixed(2))}
      <p className="tu-paper__centre">IVA INCLUÍDO · OBRIGADO</p>
    </div>
  );
}
