// Scanning the dinner's bill: the camera finds the paper, reads it, and every line lands on whoever had it.
import { Check, ChevronUp, X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useEffect, useLayoutEffect, useRef, useState, type Ref } from 'react';
import tokens from '../../../design-system/tokens.json';
import {
  billShares, billTotal, BRASSERIE_BILL, DINNER_TABLE, euros, lineTotal, menuItemNamed, MY_ID, personById, scannedBill, type Bill,
} from '../data';
import { Button, TextButton } from './Button';
import { Sticker } from './Sticker';
import { Hairline, SheetRow, Slot, StaggerIn, TripSheet } from './TripSheet';
import './Surface.css';
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
 * Full screen, over everything: the camera's view of the bill, on one plain colour (c-scan-bg). A moment to find the
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
    }, m['enter-ms']);
  };
  const toggle = (line: number, id: string) => {
    const had = bill.who[line].includes(id) ? bill.who[line].filter(x => x !== id) : [...bill.who[line], id];
    if (!had.length) return; // someone always has it
    onChange({ ...bill, who: bill.who.map((w, i) => (i === line ? had : w)) });
  };

  return (
    <TripSheet
      title="The bill"
      subtitle={`La Brasserie de L'Entrecôte · ${bill.lines.length} lines`}
      onClose={onClose}
      footer={
        <div className="tu-bill__footer">
          {/* What each person had, to the cent: side by side while they fit, scrolling sideways once they don't */}
          <div className="tu-bill__shares">
            {table.map(id => (
              <span key={id} className="tu-bill__share">
                <Sticker name={personById(id).sticker} size="avatar" />
                <span className="text-label-md weight-semibold">{euros(shares[id] ?? 0)}</span>
              </span>
            ))}
          </div>
          <div className="tu-bill__actions">
            <PayerTrigger payer={bill.paidBy} open={payerMenuOpen} onOpen={onPayer} />
            <TextButton label="Add to the trip's money" onClick={onAdd} />
          </div>
        </div>
      }
    >
      <StaggerIn>
        {/* The total, big: it's the number everyone checks first */}
        <div key="total" className="tu-bill__total">
          <span className="text-label-lg tu-bill__total-label">Total</span>
          <span className="text-heading-lg">{euros(billTotal(bill))}</span>
        </div>
        <p key="intro" className="text-body-sm tu-bill__intro">
          Each line goes to whoever picked it on the menu; anything nobody picked goes to everyone. Tap a line to change who had it.
        </p>
        {bill.lines.flatMap((line, i) => {
          const had = bill.who[i];
          const block = (
            <div key={`line-${i}`} ref={el => { lines.current[i] = el; }}>
              <SheetRow
                title={menuItemNamed(line.item)?.name ?? line.printed}
                subtitle={`${line.qty} × ${euros(line.unit)} · ${had.length === table.length ? 'Everyone' : names(had)}`}
                trailing={
                  <span className="tu-bill__amount">
                    <span className="text-label-lg">{euros(lineTotal(line))}</span>
                    {/* Every face, overlapped (there's room for the whole table) */}
                    <span className="tu-bill__pile" role="img" aria-label={names(had)}>
                      {had.map(id => <Sticker key={id} name={personById(id).sticker} size="chip" />)}
                    </span>
                  </span>
                }
                onClick={() => edit(i)}
              />
              {/* Who had it: everyone at the table in a grey block, the ones who had it full, the others faded; tap to change */}
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
                        const on = had.includes(id);
                        return (
                          <button
                            key={id}
                            type="button"
                            className={on ? 'tu-bill__face' : 'tu-bill__face tu-bill__face--off'}
                            aria-pressed={on}
                            aria-label={`${personById(id).name}: ${on ? 'had it' : "didn't have it"}`}
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
