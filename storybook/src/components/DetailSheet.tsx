import { ArrowLeft, Banknote, Calendar, Check, Clock, Globe, MapPin, Phone, Truck, X, type LucideIcon } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion, type MotionValue, type Variants } from 'motion/react';
import { createContext, useContext, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import realMenu from '../../../app/assets/data/brasserie-menu.json';
import { billShares, billTotal, euros, eurosIn, isHere, MY_ID, personById, TRIP_NOW, walkLabel, type Bill, type LatLng, type Person, type PlaceDetail } from '../data';
import { AddButton } from './AddButton';
import { Button, TextButton } from './Button';
import { DishMore, DishSticker } from './DishSticker';
import { KnowSection, KnowTip } from './KnowSection';
import { useTripNotice } from './Notice';
import { PhotoCarousel } from './PhotoCarousel';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { ToggleChips } from './ToggleChips';
import { Sticker } from './Sticker';
import { PlaceMap } from './TripPages';
import './Surface.css';
import './DetailSheet.css';

/** The full view's pages, always in this order. */
export const DETAIL_TABS = ['Overview', 'Menu', 'Group'] as const;
export type DetailTab = (typeof DETAIL_TABS)[number];
/** The page the sheet opens on: Group while the plan is on (the group and the bill matter more than the place's
 *  details then), Overview otherwise (the app's `DetailPage.openingFor`). */
export const openingTab = (active?: boolean): DetailTab => (active ? 'Group' : 'Overview');

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
  /** Left empty for a plain plan (Tram 28, an added one): the line under the name says when and how far instead. */
  rating: string;
  cuisine: string;
  /** None for a plain plan: a small map of it stands in (see `at`). */
  photos: string[];
  about: string;
  tips: string[];
  /** It has a menu (La Brasserie's, the real one): only then is there a Menu tab. */
  menu?: boolean;
  /** Where it is, and its sticker: a plan without photos shows a small map of it, and without a rating, how far it is. */
  at?: LatLng;
  sticker?: string;
  /** Service options and facts, as on the place's Google Maps card. */
  services?: string[];
  details?: PlaceDetail[];
  /** "Today, 5 PM". */
  whenLong?: string;
  people: Person[];
  /** Now, in the trip (the demo's start by default): who's here, while the plan is on. */
  now?: Date;
  /** Sticker of each person, by id; shows who picked a dish. */
  faces: Record<string, string>;
  tab?: DetailTab;
  onTabChange?: (tab: DetailTab) => void;
  onClose?: () => void;
  /** Back to where the details were opened from (the itinerary), in the same sheet; leave it out when they grew out of
   *  Up next. */
  onBack?: () => void;
  /** The plan is on (its time has come and someone is there): it opens on Group (the tabs keep their order), Group
   *  says who's here, and its footer offers Scan the bill. */
  active?: boolean;
  /** Tonight's bill, once it's scanned: Group shows what each person had, exactly, and the bill's total. */
  bill?: Bill;
  onScan?: () => void;
  /** Once the bill is in: who owes what (in the app, the full view closes and Money opens). */
  onSettle?: () => void;
  /** Opened in place of a pop-up (a plan from the itinerary): the surface is already there, so only what's on it
   *  shows by this much, 0–1. */
  contentOpacity?: MotionValue<number>;
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
 * another (fade, light blur, a few px up), the old page fades out with a blur. Menu is the restaurant's real menu, and
 * a tab only for a place with one. A plain plan (no rating, no photos: Tram 28, an added one) shows when and how far
 * under its name ("Tomorrow, 10 AM · 4.3 km away") and a small map of it; whatever else it lacks (about, tips, facts)
 * is left out.
 */
export function DetailSheet(p: DetailSheetProps) {
  const tabs = DETAIL_TABS.filter(t => t !== 'Menu' || p.menu);
  const [own, setOwn] = useState<DetailTab>(openingTab(p.active));
  const tab = p.tab ?? own;
  // How far the page has scrolled under the top edge, 0–1 over the top fade's height
  const [under, setUnder] = useState(0);
  // Which way the last tab change went: 1 to the right, -1 to the left, 0 for the page the sheet opened on
  const [dir, setDir] = useState(0);
  const select = (t: DetailTab) => { setDir(Math.sign(tabs.indexOf(t) - tabs.indexOf(tab))); setOwn(t); setUnder(0); setFiltered(false); p.onTabChange?.(t); };
  const reduce = useReducedMotion();
  const [added, setAdded] = useState<Set<string>>(() => new Set(SECTIONS.flatMap(s => s.items).filter(i => i.pickedBy?.includes('ari')).map(i => i.name)));
  // The menu's filter (empty means everything); once it changes, the list under it swaps on its own
  const [filter, setFilter] = useState<string[]>([]);
  const [filtered, setFiltered] = useState(false);
  // Adding a dish says so at the top of the screen, like every other note, with Undo (for toast-action-ms), which
  // takes it back off
  const notice = useTripNotice();
  const remove = (name: string) => setAdded(a => { if (!a.has(name)) return a; const n = new Set(a); n.delete(name); return n; });
  const toggle = (name: string) => {
    const adding = !added.has(name);
    if (!adding) return remove(name);
    setAdded(a => new Set(a).add(name));
    notice(`Added for ${p.whenLong ?? 'later'}`, { label: 'Undo', onTap: () => remove(name) });
  };

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

  // Whether the tabs fit between Back and Close: measured against the bar's width (a narrow phone, large text)
  const barRef = useRef<HTMLDivElement>(null);
  const tabsRef = useRef<HTMLSpanElement>(null);
  const [stacked, setStacked] = useState(false);
  useLayoutEffect(() => {
    const bar = barRef.current;
    if (!bar) return;
    const check = () => {
      // The tab bar's own width (its row may be the bar's full width once stacked)
      const tabs = tabsRef.current?.firstElementChild as HTMLElement | null;
      if (!tabs) return;
      const css = getComputedStyle(bar), px = (v: string) => parseFloat(css.getPropertyValue(v));
      const buttons = (px('--d-button-sm') + px('--space-xs')) * (p.onBack ? 2 : 1);
      setStacked(tabs.offsetWidth + buttons > bar.clientWidth);
    };
    check();
    const ro = new ResizeObserver(check);
    ro.observe(bar);
    return () => ro.disconnect();
  }, [p.onBack, tabs.length]);
  const dishes = SECTIONS.flatMap(s => s.items);
  const pickers = new Set([...dishes.flatMap(i => (i.pickedBy ?? []).filter(id => id !== 'ari')), ...(added.size ? ['ari'] : [])]);
  const picksOf = (id: string) => dishes.filter(d => (id === 'ari' ? added.has(d.name) : d.pickedBy?.includes(id)));
  // Roughly what each person's picks come to, and all of them together, until the bill is in; then what they had
  const shares = p.bill && billShares(p.bill);
  const costOf = (id: string) => (shares ? shares[id] ?? 0 : picksOf(id).reduce((sum, d) => sum + (eurosIn(d.price) ?? 0), 0));
  const total = p.bill ? billTotal(p.bill) : p.people.reduce((sum, x) => sum + costOf(x.id), 0);
  const going = p.people.filter(x => x.going).length;
  const here = p.people.filter(x => isHere(x, p.now ?? TRIP_NOW)).length;
  const site = p.details?.find(d => d.kind === 'website');

  const tabBar = <span ref={tabsRef} className="tu-sheet__tabs"><SegmentedTabs tabs={tabs} value={tab} onChange={t => select(t as DetailTab)} /></span>;
  return (
    <article className={stacked ? 'tu-sheet tu-sheet--stacked tu-surface tu-surface--sheet' : 'tu-sheet tu-surface tu-surface--sheet'} aria-label={p.name}>
      <motion.div ref={barRef} className="tu-sheet__bar" style={{ opacity: p.contentOpacity }}>
        <span className="tu-sheet__lead">
          {p.onBack && <Button icon={ArrowLeft} label="Back" size="sm" onClick={p.onBack} />}
          {!stacked && tabBar}
        </span>
        <Button icon={X} label="Close" size="sm" onClick={p.onClose} />
        {/* Tabs that don't fit between Back and Close go on a row of their own under them */}
        {stacked && tabBar}
      </motion.div>
      <motion.div className="tu-sheet__pages" style={{ opacity: p.contentOpacity }}>
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
                  {p.rating
                    ? <RatingLine rating={p.rating} kind={p.cuisine} align="start" />
                    // A plain plan (added, or with nothing more known): when, and how far
                    : <p className="text-label-md tu-sheet__muted">{[p.whenLong, p.at && walkLabel(p.at)].filter(Boolean).join(' · ')}</p>}
                </Block>
                {p.photos.length
                  ? <Block i={1}><PhotoCarousel photos={p.photos} /></Block>
                  : p.at && p.sticker && <Block i={1} className="tu-sheet__pad"><PlaceMap sticker={p.sticker} /></Block>}
                {p.about && <Block i={2}><p className="tu-sheet__about text-body-sm">{p.about}</p></Block>}
                {/* The one highlighted block: worth knowing before going */}
                {p.tips.length > 0 && <Block i={3}><KnowSection title="Know before you go">{p.tips.map(t => <KnowTip key={t}>{t}</KnowTip>)}</KnowSection></Block>}
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
                                        <p className="text-label-lg">{item.name}</p>
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
                {/* Once the plan is on, it's who has got there, not who's coming */}
                <Block i={0} className="tu-sheet__info">
                  <h2 className="tu-sheet__name text-heading-md tu-ellipsis">{p.active ? "Who's here" : "Who's coming"}</h2>
                  <p className="text-body-sm tu-sheet__muted">
                    {p.active ? `${here} of ${going} here · Now` : `${going} of ${p.people.length} going${p.whenLong ? ` · ${p.whenLong}` : ''}`}
                  </p>
                </Block>
                <div>
                  {p.people.map((x, xi) => (
                    <Block key={x.id} i={1 + xi} className="tu-sheet__row">
                      <span className="tu-sheet__face"><Sticker name={x.sticker} size="avatar" /></span>
                      <div className="tu-sheet__row-text">
                        <p className="text-label-lg">{x.name}</p>
                        <p className={`text-body-sm ${x.going ? 'tu-sheet__muted' : 'tu-sheet__subtle'}`}>{x.status}</p>
                      </div>
                      {/* What they'll have, as a little pile of stickers: at a glance, who has already picked */}
                      {(() => {
                        const picks = picksOf(x.id);
                        // Two in the pile, the priciest (the mains, usually); the rest are counted on one more sticker
                        const shown = picks.filter(d => d.photo).sort((a, b) => (eurosIn(b.price) ?? 0) - (eurosIn(a.price) ?? 0)).slice(0, 2);
                        const more = picks.length - shown.length;
                        return picks.length ? (
                          <span className="tu-sheet__picks" aria-label={`${x.name} picked ${picks.map(d => d.name).join(', ')}`}>
                            {shown.map((d, i) => <DishSticker key={d.name} photo={d.photo!} size="pick" tilt={i % 2 ? -tilt : tilt} />)}
                            {more > 0 && <DishMore count={more} tilt={shown.length % 2 ? -tilt : tilt} />}
                          </span>
                        ) : null;
                      })()}
                      {/* Roughly what their picks come to; exactly what they had once the bill is in */}
                      {costOf(x.id) > 0
                        ? <span className="text-label-md weight-semibold tu-sheet__cost">{shares ? euros(costOf(x.id)) : `≈ ${euros(costOf(x.id))}`}</span>
                        : x.going && <span className="text-body-sm tu-sheet__subtle">No picks yet</span>}
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
      </motion.div>
      {/* Overview: Website and Directions stay at the bottom while it scrolls; Directions opens the maps app */}
      {tab === 'Overview' && p.at && (
        <motion.div className="tu-sheet__footer-wrap" style={{ opacity: p.contentOpacity }}>
        <motion.div className="tu-sheet__footer tu-sheet__actions" variants={block} custom={1} initial="hidden" animate="shown">
          {site && <TextButton variant="soft" label="Website" size="lg" wide onClick={() => openWebsite(site.text)} />}
          <TextButton label="Directions" size="lg" wide onClick={() => openDirections(p.at!)} />
        </motion.div>
        </motion.div>
      )}
      {/* Group: the bottom stays put while the list scrolls above it: the estimate, then (while the plan is on) Scan
          the bill; once it's in, the bill's total and who owes what */}
      {tab === 'Group' && total > 0 && (
        <motion.div className="tu-sheet__footer-wrap" style={{ opacity: p.contentOpacity }}>
        <motion.div className="tu-sheet__footer" variants={block} custom={1} initial="hidden" animate="shown">
          <div className="tu-sheet__footer-row">
            <div className="tu-sheet__footer-text">
              <p className="text-label-lg">{p.bill ? 'Bill' : 'Estimated total'}</p>
              {p.bill
                ? <p className="text-body-sm tu-sheet__muted">{p.bill.paidBy === MY_ID ? 'You' : personById(p.bill.paidBy).name} paid · split by who had what</p>
                : p.active && <p className="text-body-sm tu-sheet__muted">The bill splits itself once scanned</p>}
            </div>
            <p className="text-heading-lg tu-sheet__cost">{p.bill ? euros(total) : `≈ ${euros(total)}`}</p>
          </div>
          {p.bill
            ? <TextButton variant="soft" label="See who owes what" size="lg" wide onClick={p.onSettle} />
            : p.active && <TextButton label="Scan the bill" size="lg" wide onClick={p.onScan} />}
        </motion.div>
        </motion.div>
      )}
    </article>
  );
}

/** The place's site, in a new tab. */
const openWebsite = (host: string) => window.open(host.startsWith('http') ? host : `https://${host}`, '_blank', 'noopener');

/** Walking directions to the place in the maps app (Google Maps on the web; the app uses Apple Maps on iPhone). */
const openDirections = (at: LatLng) =>
  window.open(`https://www.google.com/maps/dir/?api=1&destination=${at[0]},${at[1]}&travelmode=walking`, '_blank', 'noopener');
