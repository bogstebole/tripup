import { Banknote, Calendar, Check, Clock, Globe, MapPin, Phone, Truck, X, type LucideIcon } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion, type Variants } from 'motion/react';
import { useState, type CSSProperties, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import realMenu from '../../../app/assets/data/brasserie-menu.json';
import { photoUrl, type Person, type PlaceDetail } from '../data';
import { AddButton } from './AddButton';
import { Button } from './Button';
import { DishSticker } from './DishSticker';
import { KnowRow, KnowSection } from './KnowSection';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { Sticker } from './Sticker';
import './Surface.css';
import './DetailSheet.css';

export const DETAIL_TABS = ['Overview', 'Menu', 'People'] as const;
export type DetailTab = (typeof DETAIL_TABS)[number];

type MenuItem = { name: string; price: string; note?: string; photo?: string; pickedBy?: string[] };
type MenuSection = { title: string; note?: string; items: MenuItem[] };
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
  people: Person[];
  /** Sticker of each person, by id; shows who picked a dish. */
  faces: Record<string, string>;
  tab?: DetailTab;
  onTabChange?: (tab: DetailTab) => void;
  onClose?: () => void;
}

const m = tokens.motion;
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
  const select = (t: DetailTab) => { setOwn(t); setUnder(0); p.onTabChange?.(t); };
  const reduce = useReducedMotion();
  const [added, setAdded] = useState<Set<string>>(() => new Set(SECTIONS.flatMap(s => s.items).filter(i => i.pickedBy?.includes('ari')).map(i => i.name)));
  const toggle = (name: string) => setAdded(a => { const n = new Set(a); n.has(name) ? n.delete(name) : n.add(name); return n; });

  // Stagger: each block waits its turn (capped so a long list doesn't drag), then sharpens into place
  const block: Variants = {
    hidden: { opacity: 0, y: reduce ? 0 : tokens.space.xs, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)` },
    shown: (i: number) => ({
      opacity: 1, y: 0, filter: 'blur(0px)',
      transition: { duration: reduce ? 0 : m['enter-ms'] / 1000, ease, delay: reduce ? 0 : (Math.min(i, m['stagger-max'] - 1) * m['stagger-ms']) / 1000 },
    }),
  };
  const Block = ({ i, children, className }: { i: number; children: ReactNode; className?: string }) => (
    <motion.div custom={i} variants={block} className={className}>{children}</motion.div>
  );

  const dishes = SECTIONS.flatMap(s => s.items);
  const pickers = new Set([...dishes.flatMap(i => (i.pickedBy ?? []).filter(id => id !== 'ari')), ...(added.size ? ['ari'] : [])]);
  const picksOf = (id: string) => dishes.filter(d => (id === 'ari' ? added.has(d.name) : d.pickedBy?.includes(id)));
  const going = p.people.filter(x => x.status !== 'Not going').length;

  return (
    <article className="tu-sheet tu-surface tu-surface--sheet" aria-label={p.name}>
      <div className="tu-sheet__bar">
        <SegmentedTabs tabs={[...DETAIL_TABS]} value={tab} onChange={t => select(t as DetailTab)} />
        <Button icon={X} label="Close" size="sm" onClick={p.onClose} />
      </div>
      <div className="tu-sheet__pages">
        <AnimatePresence initial={false}>
          <motion.div
            key={tab}
            className="tu-sheet__scroll"
            onScroll={e => setUnder(Math.min(1, e.currentTarget.scrollTop / parseFloat(getComputedStyle(e.currentTarget).getPropertyValue('--d-sheet-top-fade'))))}
            initial="hidden"
            animate="shown"
            exit={{ opacity: 0, filter: reduce ? 'none' : `blur(${m['enter-blur']}px)`, transition: { duration: reduce ? 0 : m['fade-ms'] / 1000, ease } }}
          >
            {tab === 'Overview' && (
              <>
                <Block i={0} className="tu-sheet__photos">
                  {p.photos.map((ph, i) => (
                    <img key={ph} src={photoUrl(ph)} alt="" className={`tu-sheet__photo tu-sheet__photo--${i === 0 ? 'start' : i === p.photos.length - 1 ? 'end' : 'main'}`} />
                  ))}
                </Block>
                <Block i={1} className="tu-sheet__info">
                  <h2 className="tu-sheet__name text-heading-md tu-ellipsis">{p.name}</h2>
                  <RatingLine rating={p.rating} kind={p.cuisine} align="start" />
                </Block>
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
                <Block i={0} className="tu-sheet__head">
                  <h2 className="tu-sheet__title text-heading-lg">Menu</h2>
                  <p className="text-body-sm tu-sheet__muted">{pickers.size} of {p.people.length} have picked. Add what you'll have, and the bill splits itself.</p>
                </Block>
                {SECTIONS.map((s, si) => (
                  <Block key={s.title} i={si + 1} className="tu-sheet__section">
                    <div className="tu-sheet__section-head">
                      <h3 className="tu-sheet__title text-heading-sm">{s.title}</h3>
                      {s.note && <p className="text-body-sm tu-sheet__muted">{s.note}</p>}
                    </div>
                    <div className="tu-sheet__cards">
                      {s.items.map((item, i) => {
                        const others = (item.pickedBy ?? []).filter(id => id !== 'ari');
                        return (
                          <div key={item.name} className="tu-dish">
                            <div className="tu-dish__top">
                              {item.photo && <DishSticker photo={item.photo} size="menu" tilt={i % 2 ? tilt : -tilt} />}
                              <div className="tu-dish__text">
                                <p className="text-label-md">{item.name}</p>
                                {item.note && <p className="text-body-sm tu-sheet__muted">{item.note}</p>}
                              </div>
                            </div>
                            <div className="tu-dish__foot">
                              <p className="text-label-md weight-semibold tu-dish__price">{item.price}</p>
                              {others.length > 0 && <span className="tu-sheet__faces">{others.map(id => <Sticker key={id} name={p.faces[id]} size="chip" />)}</span>}
                              <AddButton added={added.has(item.name)} itemName={item.name} onToggle={() => toggle(item.name)} />
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </Block>
                ))}
                <Block i={SECTIONS.length + 1}><p className="text-body-sm tu-sheet__subtle tu-sheet__pad">Prices with VAT. From the restaurant's own menu. Entrecôte photos are the restaurant's; other dish photos are illustrative, from Wikimedia Commons.</p></Block>
              </>
            )}
            {tab === 'People' && (
              <>
                <Block i={0} className="tu-sheet__head">
                  <h2 className="tu-sheet__title text-heading-lg">Who's coming</h2>
                  <p className="text-body-sm tu-sheet__muted">{going} of {p.people.length} going · 5 PM today</p>
                </Block>
                <Block i={1}>
                  {p.people.map(x => (
                    <div key={x.id} className="tu-sheet__row">
                      <span className="tu-sheet__face"><Sticker name={x.sticker} size="avatar" /></span>
                      <div className="tu-sheet__row-text">
                        <p className="text-label-md">{x.name}</p>
                        <p className={`text-body-sm ${x.status === 'Not going' ? 'tu-sheet__subtle' : 'tu-sheet__muted'}`}>{x.status}</p>
                      </div>
                      {/* What they'll have, as a little pile of stickers: at a glance, who has already picked */}
                      {(() => {
                        const picks = picksOf(x.id).filter(d => d.photo);
                        if (picks.length) return <span className="tu-sheet__picks" aria-label={`${x.name} picked ${picks.map(d => d.name).join(', ')}`}>{picks.map((d, i) => <DishSticker key={d.name} photo={d.photo!} size="pick" tilt={i % 2 ? -tilt : tilt} />)}</span>;
                        return x.status !== 'Not going' ? <span className="text-body-sm tu-sheet__subtle">No picks yet</span> : null;
                      })()}
                    </div>
                  ))}
                </Block>
              </>
            )}
          </motion.div>
        </AnimatePresence>
        {/* Content scrolling up passes under a blur and the surface's white instead of being cut at the edge */}
        <div className="tu-sheet__top-fade" aria-hidden style={{ '--under': under } as CSSProperties} />
      </div>
    </article>
  );
}
