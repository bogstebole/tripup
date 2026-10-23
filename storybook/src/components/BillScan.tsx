// Scanning the dinner's bill: the camera finds the paper, reads it, and every line lands on whoever had it.
import { X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type Ref } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  billShares, billTotal, BRASSERIE_BILL, DINNER_TABLE, euros, lineTotal, menuItemNamed, MY_ID, personById, photoUrl, scannedBill,
  type Bill,
} from '../data';
import { Button, TextButton } from './Button';
import { FacePile } from './FacePile';
import { Sticker } from './Sticker';
import { Hairline, SheetRow, StaggerIn, TripSheet } from './TripSheet';
import './BillScan.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const space = tokens.space as Record<string, number>;
// A component token is a reference like "{space.xl}"; read the size it points at
const spaceOf = (ref: string) => space[ref.replace(/^\{space\.|\}$/g, '')];
const cornerLength = spaceOf(tokens.component.dimension['scan/corner'] as string);

type Phase = 'aim' | 'lock' | 'read' | 'review';
type Box = { left: number; top: number; width: number; height: number };
/** An element's box in the camera's own frame (its offsets, so a transform above the camera doesn't skew it). */
const boxOf = (el: HTMLElement, grow = 0): Box => ({ left: el.offsetLeft - grow, top: el.offsetTop - grow, width: el.offsetWidth + grow * 2, height: el.offsetHeight + grow * 2 });

export interface BillScanProps {
  /** The bill as checked (who had each line, who paid), to add to the trip's money. */
  onAdd?: (bill: Bill) => void;
  onClose?: () => void;
}

/**
 * Full screen, over everything: the camera's view of the bill on the table. A moment to find the paper
 * (scan-find-ms), then the frame closes in from the screen's edges onto it (enter-ms, ease-out) and turns blue, a line
 * reads it top to bottom at an even pace (scan-read-ms, linear), and the bill rises with every line on the faces of
 * whoever had it. Tap a line to change who had it; tap "Change" to change who paid. Reduced motion: straight to the
 * bill, which fades in. In the prototype the camera shows a prepared bill (there's no real camera or OCR).
 */
export function BillScan({ onAdd, onClose }: BillScanProps) {
  const reduce = useReducedMotion();
  const [phase, setPhase] = useState<Phase>('aim');
  const root = useRef<HTMLDivElement>(null);
  const aim = useRef<HTMLDivElement>(null);
  const paper = useRef<HTMLDivElement>(null);
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
      {/* The camera's view: the restaurant, dim, with the bill on the table */}
      <img className="tu-scan__photo" src={photoUrl('brasserie-1')} alt="" draggable={false} />
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
      {/* The bill, rising over the camera once it's read */}
      {review && (
        <div className="tu-scan__place">
          <BillReview bill={bill} onChange={setBill} onAdd={() => onAdd?.(bill)} onClose={onClose} />
        </div>
      )}
    </div>
  );
}

/** "you", "Maya and you", "Maya, Leo and you". */
const names = (ids: string[]) => {
  const n = ids.map(id => (id === MY_ID ? 'you' : personById(id).name));
  return n.length < 2 ? n.join('') : `${n.slice(0, -1).join(', ')} and ${n[n.length - 1]}`;
};

/**
 * The bill as read: every line with what it is on the menu, how many at what price, who had it (their faces) and its
 * amount. Under it, what each person had to the cent, who paid, and Add to the trip's money.
 */
function BillReview({ bill, onChange, onAdd, onClose }: { bill: Bill; onChange: (b: Bill) => void; onAdd: () => void; onClose?: () => void }) {
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
    }, m['enter-ms']);
  };
  const toggle = (line: number, id: string) => {
    const who = bill.who[line].includes(id) ? bill.who[line].filter(x => x !== id) : [...bill.who[line], id];
    if (!who.length) return; // someone always has it
    onChange({ ...bill, who: bill.who.map((w, i) => (i === line ? who : w)) });
  };
  const nextPayer = () => onChange({ ...bill, paidBy: table[(table.indexOf(bill.paidBy) + 1) % table.length] });
  const payer = bill.paidBy === MY_ID ? 'You' : personById(bill.paidBy).name;

  return (
    <TripSheet
      title="The bill"
      subtitle={`La Brasserie de L'Entrecôte · ${euros(billTotal(bill))}`}
      onClose={onClose}
      footer={
        <div className="tu-bill__footer">
          {/* What each person had, to the cent */}
          <div className="tu-bill__shares">
            {table.map(id => (
              <span key={id} className="tu-bill__share">
                <Sticker name={personById(id).sticker} size="avatar" />
                <span className="text-label-md weight-semibold">{euros(shares[id] ?? 0)}</span>
              </span>
            ))}
          </div>
          <div className="tu-bill__actions">
            <button type="button" className="tu-bill__payer text-body-sm" aria-label={`Who paid: ${payer === 'You' ? 'you' : payer}. Change`} onClick={nextPayer}>
              {payer} paid · <span className="weight-semibold tu-bill__change">Change</span>
            </button>
            <TextButton label="Add to the trip's money" onClick={onAdd} />
          </div>
        </div>
      }
    >
      <StaggerIn>
        <p key="intro" className="text-body-sm tu-bill__intro">
          Each line goes to whoever picked it on the menu; anything nobody picked goes to everyone. Tap a line to change who had it.
        </p>
        {bill.lines.flatMap((line, i) => {
          const who = bill.who[i];
          const block = (
            <div key={`line-${i}`} ref={el => { lines.current[i] = el; }}>
              <SheetRow
                title={menuItemNamed(line.item)?.name ?? line.printed}
                subtitle={`${line.qty} × ${euros(line.unit)} · ${who.length === table.length ? 'Everyone' : names(who)}`}
                trailing={
                  <span className="tu-bill__amount">
                    <span className="text-label-lg">{euros(lineTotal(line))}</span>
                    <FacePile faces={who.map(id => personById(id).sticker)} size="chip" label={names(who)} />
                  </span>
                }
                onClick={() => edit(i)}
              />
              {/* Who had it: everyone at the table, the ones who had it full, the others faded; tap to change */}
              <AnimatePresence initial={false}>
                {editing === i && (
                  <motion.div
                    key="who"
                    className="tu-bill__who"
                    initial={reduce ? { opacity: 0 } : { height: 0, opacity: 0 }}
                    animate={reduce ? { opacity: 1, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 'auto', opacity: 1, transition: { duration: m['enter-ms'] / 1000, ease } }}
                    exit={reduce ? { opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } } : { height: 0, opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
                  >
                    <div className="tu-bill__faces">
                      {table.map(id => {
                        const had = who.includes(id);
                        return (
                          <button
                            key={id}
                            type="button"
                            className={had ? 'tu-bill__face' : 'tu-bill__face tu-bill__face--off'}
                            aria-pressed={had}
                            aria-label={`${personById(id).name}: ${had ? 'had it' : "didn't have it"}`}
                            onClick={() => toggle(i, id)}
                          >
                            <Sticker name={personById(id).sticker} size="avatar" />
                            <span className="text-label-md">{personById(id).name}</span>
                          </button>
                        );
                      })}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
          return i ? [<Hairline key={`hairline-${i}`} />, block] : [block];
        })}
      </StaggerIn>
    </TripSheet>
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
