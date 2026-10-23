import { Banknote, Calendar, Check, Clock, Globe, MapPin, Phone, Truck, X, type LucideIcon } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion, type Variants } from 'motion/react';
import { createContext, useContext, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import realMenu from '../../../app/assets/data/brasserie-menu.json';
import { euros, eurosIn, type Person, type PlaceDetail } from '../data';
import { AddButton } from './AddButton';
import { Button } from './Button';
import { DishMore, DishSticker } from './DishSticker';
import { KnowRow, KnowSection } from './KnowSection';
import { PhotoCarousel } from './PhotoCarousel';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { Toast } from './Toast';
import { ToggleChips } from './ToggleChips';
import { Sticker } from './Sticker';
import './Surface.css';
import './DetailSheet.css';

export const DETAIL_TABS = ['Overview', 'Menu', 'Group'] as const;
export type DetailTab = (typeof DETAIL_TABS)[number];

type MenuItem = { name: string; price: string; note?: string; photo?: string; pickedBy?: string[] };
type MenuSection = { title: string; course?: string; note?: string; items: MenuItem[] };

/** What the menu can be narrowed to: what anyone has picked, or a course. */
const MENU_FILTERS = [
  { id: 'picked', label: 'Picked' },
  { id: 'starters', label: 'Starters' },
  { id: 'mains', label: 'Mains' },
  { id: 'desserts', label: 'Desserts' },
  { id: 'drinks', label: 'Drinks' },
];
const SECTIONS = (realMenu as { sections: MenuSection[] }).sections;

export interface DetailSheetProps {
  name: string;
  rating: string;
  cuisine: string;
  photos: string[];
  about: string;
  tips: string[];
  /** Service options and facts, as on the place's Google Maps card. */
  services?: string[];
  details?: PlaceDetail[];
  /** "Today, 5 PM". */
  whenLong?: string;
  people: Person[];
  /** Sticker of each person, by id; shows who picked a dish. */
  faces: Record<string, string>;
  tab?: DetailTab;
  onTabChange?: (tab: DetailTab) => void;
  onClose?: () => void;
}

const m = tokens.motion;
const space = tokens.space as Record<string, number>;
// A component token is a reference like "{space.xl}"; read the size it points at
const spaceOf = (ref: string) => space[ref.replace(/^\{space\.|\}$/g, '')];
const slide = spaceOf(tokens.component.dimension['tab/slide'] as string);
const rise = spaceOf(tokens.component.dimension['tab/enter-shift'] as string);

/** The page's stagger, handed to every block (a component made inside the sheet would remount on each render). */
const Stagger = createContext<Variants>({});
function Block({ i, children, className }: { i: number; children: ReactNode; className?: string }) {
  return <motion.div custom={i} variants={useContext(Stagger)} className={className}>{children}</motion.div>;
}
const tilt = tokens.component.dimension['menu/photo-tilt'];
const FACT_ICON: Record<PlaceDetail['kind'], LucideIcon> = { address: MapPin, hours: Clock, price: Banknote, booking: Calendar, order: Truck, website: Globe, phone: Phone };
const ease = m['ease-out'] as [number, number, number, number];

/**
 * The full view of a plan. The tabs and close sit in a header at the top, and each tab replaces the whole page
 * under it, which scrolls up under the header: the new page's blocks arrive one after
 * another (fade, light blur, a few px up), the old page fades out with a blur. Menu is the restaurant's real menu.
 */
export function DetailSheet(p: DetailSheetProps) {
  const [own, setOwn] = useState<DetailTab>('Overview');
  const tab = p.tab ?? own;
  // How far the page has scrolled under the top edge, 0–1 over the top fade's height
  const [under, setUnder] = useState(0);
  // Which way the last tab change went: 1 to the right, -1 to the left, 0 for the page the sheet opened on
  const [dir, setDir] = useState(0);
  const select = (t: DetailTab) => { setDir(Math.sign(DETAIL_TABS.indexOf(t) - DETAIL_TABS.indexOf(tab))); setOwn(t); setUnder(0); setFiltered(false); p.onTabChange?.(t); };
  const reduce = useReducedMotion();
  const [added, setAdded] = useState<Set<string>>(() => new Set(SECTIONS.flatMap(s => s.items).filter(i => i.pickedBy?.includes('ari')).map(i => i.name)));
  // The menu's filter (empty means everything); once it changes, the list under it swaps on its own
  const [filter, setFilter] = useState<string[]>([]);
  const [filtered, setFiltered] = useState(false);
  // The "added" toast: shown for toast-ms, Undo takes the dish back off
  const [toast, setToast] = useState<{ name: string; shown: boolean } | null>(null);
  const timer = useRef<number | undefined>(undefined);
  const hideToast = () => { window.clearTimeout(timer.current); setToast(t => (t ? { ...t, shown: false } : t)); };
  const toggle = (name: string) => {
    const adding = !added.has(name);
    setAdded(a => { const n = new Set(a); adding ? n.add(name) : n.delete(name); return n; });
    if (adding) {
      setToast({ name, shown: true });
      window.clearTimeout(timer.current);
      timer.current = window.setTimeout(hideToast, m['toast-ms']);
    } else if (toast?.name === name) hideToast();
  };
  const undo = () => { if (toast) setAdded(a => { const n = new Set(a); n.delete(toast.name); return n; }); hideToast(); };

  // The new page comes in from the side the tab is on, once the old one has mostly gone; the first page rises.
  // Each block waits its turn (capped so a long list doesn't drag), then sharpens into place. Full transform
  // strings, so Motion runs them on the compositor.
  const blur = reduce ? 'none' : `blur(${m['enter-blur']}px)`;
  const from = reduce ? 'none' : dir ? `translate(${dir * slide}px, 0px)` : `translate(0px, ${rise}px)`;
  const block: Variants = {
    hidden: { opacity: 0, transform: from, filter: blur },
    shown: (i: number) => ({
      opacity: 1, transform: reduce ? 'none' : 'translate(0px, 0px)', filter: 'blur(0px)',
      transition: { duration: reduce ? 0 : m['enter-ms'] / 1000, ease, delay: reduce ? 0 : ((dir ? m['page-enter-delay-ms'] : 0) + Math.min(i, m['stagger-max'] - 1) * m['stagger-ms']) / 1000 },
    }),
  };
  // A new filter's list rises in on its own, once the old one has gone
  const listBlock: Variants = {
    hidden: { opacity: 0, transform: reduce ? 'none' : `translate(0px, ${rise}px)`, filter: blur },
    shown: (i: number) => ({
      opacity: 1, transform: reduce ? 'none' : 'translate(0px, 0px)', filter: 'blur(0px)',
      transition: { duration: reduce ? 0 : m['enter-ms'] / 1000, ease, delay: reduce ? 0 : (Math.min(i, m['stagger-max'] - 1) * m['stagger-ms']) / 1000 },
    }),
  };
  // The old page leaves toward the side away from the new tab, quicker than the new one arrives
  const page: Variants = {
    leave: (d: number) => ({ opacity: 0, transform: reduce || !d ? 'none' : `translate(${-d * slide}px, 0px)`, filter: blur, transition: { duration: reduce ? 0 : m['fade-ms'] / 1000, ease } }),
  };

  const dishes = SECTIONS.flatMap(s => s.items);
  const pickers = new Set([...dishes.flatMap(i => (i.pickedBy ?? []).filter(id => id !== 'ari')), ...(added.size ? ['ari'] : [])]);
  const picksOf = (id: string) => dishes.filter(d => (id === 'ari' ? added.has(d.name) : d.pickedBy?.includes(id)));
  // Roughly what each person's picks come to, and all of them together
  const costOf = (id: string) => picksOf(id).reduce((sum, d) => sum + (eurosIn(d.price) ?? 0), 0);
  const total = p.people.reduce((sum, x) => sum + costOf(x.id), 0);
  const going = p.people.filter(x => x.status !== 'Not going').length;

  return (
    <article className="tu-sheet tu-surface tu-surface--sheet" aria-label={p.name}>
      <div className="tu-sheet__bar">
        <SegmentedTabs tabs={[...DETAIL_TABS]} value={tab} onChange={t => select(t as DetailTab)} />
        <Button icon={X} label="Close" size="sm" onClick={p.onClose} />
      </div>
      <div className="tu-sheet__pages">
        <Stagger.Provider value={block}>
        <AnimatePresence initial={false} custom={dir}>
          <motion.div
            key={tab}
            custom={dir}
            variants={page}
            className="tu-sheet__scroll"
            onScroll={e => setUnder(Math.min(1, e.currentTarget.scrollTop / parseFloat(getComputedStyle(e.currentTarget).getPropertyValue('--d-sheet-top-fade'))))}
            initial="hidden"
            animate="shown"
            exit="leave"
          >
            {tab === 'Overview' && (
              <>
                <Block i={0} className="tu-sheet__info">
                  <h2 className="tu-sheet__name text-heading-md tu-ellipsis">{p.name}</h2>
                  <RatingLine rating={p.rating} kind={p.cuisine} align="start" />
                </Block>
                <Block i={1}><PhotoCarousel photos={p.photos} /></Block>
                <Block i={2}><p className="tu-sheet__about text-body-sm">{p.about}</p></Block>
                {/* The one highlighted block: worth knowing before going */}
                <Block i={3}><KnowSection title="Know before you go">{p.tips.map(t => <KnowRow key={t}>{t}</KnowRow>)}</KnowSection></Block>
                {!!(p.services?.length || p.details?.length) && (
                  <Block i={4} className="tu-facts">
                    <h3 className="tu-sheet__title text-heading-sm tu-sheet__pad">Details</h3>
                    <div>
                      {p.services && p.services.length > 0 && (
                        <div className="tu-facts__row">
                          <span className="tu-facts__services">
                            {p.services.map(sv => <span key={sv} className="tu-facts__service text-label-md"><Check className="tu-facts__check" strokeWidth={2} absoluteStrokeWidth aria-hidden />{sv}</span>)}
                          </span>
                        </div>
                      )}
                      {p.details?.map(d => {
                        const Icon = FACT_ICON[d.kind];
                        return (
                          <div key={d.kind} className="tu-facts__row">
                            <Icon className="tu-facts__icon" strokeWidth={2} absoluteStrokeWidth aria-hidden />
                            <div className="tu-sheet__row-text">
                              <p className="text-label-md">{d.status && <span className="tu-facts__status">{d.status} · </span>}{d.text}</p>
                              {d.sub && <p className="text-body-sm tu-sheet__muted">{d.sub}</p>}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </Block>
                )}
              </>
            )}
            {tab === 'Menu' && (
              <>
                <Block i={0} className="tu-sheet__info">
                  <h2 className="tu-sheet__name text-heading-md tu-ellipsis">Menu</h2>
                  <p className="text-body-sm tu-sheet__muted">{pickers.size} of {p.people.length} have picked. Add what you'll have, and the bill splits itself.</p>
                </Block>
                <Block i={1}>
                  <ToggleChips label="Filter the menu" options={MENU_FILTERS} selected={filter} onChange={f => { setFilter(f); setFiltered(true); }} />
                </Block>
                {/* A new filter swaps the list: the old one fades out, then the new one cascades in */}
                <Stagger.Provider value={filtered ? listBlock : block}>
                  <AnimatePresence mode="wait">
                    <motion.div key={filter.join('|') || 'all'} className="tu-sheet__list" initial="hidden" animate="shown" exit={{ opacity: 0, filter: blur, transition: { duration: reduce ? 0 : m['fade-ms'] / 1000, ease } }}>
                      {(() => {
                        // One block per title and per dish, so the list cascades in rather than arriving in lumps
                        const shows = (s: MenuSection, i: MenuItem) => !filter.length || filter.some(f => (f === 'picked' ? (i.pickedBy ?? []).some(id => id !== 'ari') || added.has(i.name) : f === s.course));
                        let k = filtered ? 0 : 2;
                        return SECTIONS.map(s => ({ s, items: s.items.filter(i => shows(s, i)) })).filter(x => x.items.length).map(({ s, items }) => (
                          <div key={s.title} className="tu-sheet__section">
                            <Block i={k++} className="tu-sheet__section-head">
                              <h3 className="tu-sheet__title text-heading-sm">{s.title}</h3>
                              {s.note && <p className="text-body-sm tu-sheet__muted">{s.note}</p>}
                            </Block>
                            <div className="tu-sheet__cards">
                              {items.map((item, i) => {
                                const others = (item.pickedBy ?? []).filter(id => id !== 'ari');
                                const mine = added.has(item.name);
                                return (
                                  <Block key={item.name} i={k++} className="tu-dish">
                                    <div className="tu-dish__top">
                                      {item.photo && <DishSticker photo={item.photo} size="menu" tilt={i % 2 ? tilt : -tilt} />}
                                      <div className="tu-dish__text">
                                        <p className="text-label-md">{item.name}</p>
                                        {item.note && <p className="text-body-sm tu-sheet__muted">{item.note}</p>}
                                      </div>
                                    </div>
                                    <div className="tu-dish__foot">
                                      <p className="text-label-md weight-semibold tu-dish__price">{item.price}</p>
                                      {/* Who picked it, and me at the end once I add it, coming in from Add's side */}
                                      <span className="tu-sheet__faces">
                                        {others.map(id => <Sticker key={id} name={p.faces[id]} size="chip" />)}
                                        <AnimatePresence initial={false}>
                                          {mine && (
                                            <motion.span
                                              key="me"
                                              className="tu-sheet__me"
                                              initial={{ opacity: 0, transform: reduce ? 'none' : `translate(${tokens.space.xs}px, 0px) scale(${m['morph-enter-scale']})`, filter: blur }}
                                              animate={{ opacity: 1, transform: 'translate(0px, 0px) scale(1)', filter: 'blur(0px)', transition: { duration: reduce ? 0 : m['enter-ms'] / 1000, ease } }}
                                              exit={{ opacity: 0, transform: reduce ? 'none' : `translate(${tokens.space.xs}px, 0px) scale(${m['morph-enter-scale']})`, filter: blur, transition: { duration: reduce ? 0 : m['fade-ms'] / 1000, ease } }}
                                            >
                                              <Sticker name={p.faces.ari} size="chip" />
                                            </motion.span>
                                          )}
                                        </AnimatePresence>
                                      </span>
                                      <AddButton added={mine} itemName={item.name} onToggle={() => toggle(item.name)} />
                                    </div>
                                  </Block>
                                );
                              })}
                            </div>
                          </div>
                        ));
                      })()}
                      <Block i={m['stagger-max']}><p className="text-body-sm tu-sheet__subtle tu-sheet__pad">Prices with VAT. From the restaurant's own menu. Entrecôte photos are the restaurant's; other dish photos are illustrative, from Wikimedia Commons.</p></Block>
                    </motion.div>
                  </AnimatePresence>
                </Stagger.Provider>
              </>
            )}
            {tab === 'Group' && (
              <>
                <Block i={0} className="tu-sheet__info">
                  <h2 className="tu-sheet__name text-heading-md tu-ellipsis">Who's coming</h2>
                  <p className="text-body-sm tu-sheet__muted">{going} of {p.people.length} going{p.whenLong ? ` · ${p.whenLong}` : ''}</p>
                </Block>
                <div>
                  {p.people.map((x, xi) => (
                    <Block key={x.id} i={1 + xi} className="tu-sheet__row">
                      <span className="tu-sheet__face"><Sticker name={x.sticker} size="avatar" /></span>
                      <div className="tu-sheet__row-text">
                        <p className="text-label-md">{x.name}</p>
                        <p className={`text-body-sm ${x.status === 'Not going' ? 'tu-sheet__subtle' : 'tu-sheet__muted'}`}>{x.status}</p>
                      </div>
                      {/* What they'll have, as a little pile of stickers: at a glance, who has already picked */}
                      {(() => {
                        const picks = picksOf(x.id);
                        // Two in the pile, the priciest (the mains, usually); the rest are counted on one more sticker
                        const shown = picks.filter(d => d.photo).sort((a, b) => (eurosIn(b.price) ?? 0) - (eurosIn(a.price) ?? 0)).slice(0, 2);
                        const more = picks.length - shown.length;
                        if (picks.length) return (
                          <span className="tu-sheet__picks" aria-label={`${x.name} picked ${picks.map(d => d.name).join(', ')}`}>
                            {shown.map((d, i) => <DishSticker key={d.name} photo={d.photo!} size="pick" tilt={i % 2 ? -tilt : tilt} />)}
                            {more > 0 && <DishMore count={more} tilt={shown.length % 2 ? -tilt : tilt} />}
                          </span>
                        );
                        return x.status !== 'Not going' ? <span className="text-body-sm tu-sheet__subtle">No picks yet</span> : null;
                      })()}
                      {costOf(x.id) > 0 && <span className="text-label-md weight-semibold tu-sheet__cost">≈ {euros(costOf(x.id))}</span>}
                    </Block>
                  ))}
                </div>
              </>
            )}
          </motion.div>
        </AnimatePresence>
        </Stagger.Provider>
        {/* Content scrolling up passes under a blur and the surface's white instead of being cut at the edge */}
        <div className="tu-sheet__top-fade" aria-hidden style={{ '--under': under } as CSSProperties} />
      </div>
      {/* Group: the total stays put at the bottom while the list scrolls above it */}
      {tab === 'Group' && total > 0 && (
        <motion.div className="tu-sheet__footer" variants={block} custom={1} initial="hidden" animate="shown">
          <p className="text-label-lg tu-sheet__total-label">Estimated total</p>
          <p className="text-heading-lg tu-sheet__cost">≈ {euros(total)}</p>
        </motion.div>
      )}
      {/* What I just added, with Undo, centred at the bottom; it comes up from past the edge and goes back down */}
      <Toast label={`Added for ${p.whenLong ?? 'later'}`} shown={!!toast?.shown} actionLabel="Undo" onAction={undo} />
    </article>
  );
}
