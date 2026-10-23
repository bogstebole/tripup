import { X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion, type Variants } from 'motion/react';
import { useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import realMenu from '../../../app/assets/data/brasserie-menu.json';
import { photoUrl, type Person } from '../data';
import { AddButton } from './AddButton';
import { Button } from './Button';
import { KnowRow, KnowSection } from './KnowSection';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { Sticker } from './Sticker';
import './Surface.css';
import './DetailSheet.css';

export const DETAIL_TABS = ['Overview', 'Menu', 'People'] as const;
export type DetailTab = (typeof DETAIL_TABS)[number];

type MenuItem = { name: string; price: string; note?: string; pickedBy?: string[] };
type MenuSection = { title: string; note?: string; items: MenuItem[] };
const SECTIONS = (realMenu as { sections: MenuSection[] }).sections;

export interface DetailSheetProps {
  name: string;
  rating: string;
  cuisine: string;
  photos: string[];
  about: string;
  tips: string[];
  people: Person[];
  /** Sticker of each person, by id; shows who picked a dish. */
  faces: Record<string, string>;
  tab?: DetailTab;
  onTabChange?: (tab: DetailTab) => void;
  onClose?: () => void;
}

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];

/**
 * The full view of a plan. Each tab replaces everything above the tabs: the new page's blocks arrive one after
 * another (fade, light blur, a few px up), the old page fades out with a blur. Menu is the restaurant's real menu.
 */
export function DetailSheet(p: DetailSheetProps) {
  const [own, setOwn] = useState<DetailTab>('Overview');
  const tab = p.tab ?? own;
  const select = (t: DetailTab) => { setOwn(t); p.onTabChange?.(t); };
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

  const pickers = new Set(SECTIONS.flatMap(s => s.items.flatMap(i => i.pickedBy ?? [])));
  const going = p.people.filter(x => x.status !== 'Not going').length;

  return (
    <article className="tu-sheet tu-surface tu-surface--sheet" aria-label={p.name}>
      <div className="tu-sheet__pages">
        <AnimatePresence initial={false}>
          <motion.div
            key={tab}
            className="tu-sheet__scroll"
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
                    {s.items.map(item => {
                      const others = (item.pickedBy ?? []).filter(id => id !== 'ari');
                      return (
                        <div key={item.name} className="tu-sheet__row">
                          <div className="tu-sheet__row-text">
                            <p className="text-label-md">{item.name}</p>
                            {item.note && <p className="text-body-sm tu-sheet__muted">{item.note}</p>}
                            <p className="text-label-md weight-semibold">{item.price}</p>
                          </div>
                          {others.length > 0 && <span className="tu-sheet__faces">{others.map(id => <Sticker key={id} name={p.faces[id]} size="chip" />)}</span>}
                          <AddButton added={added.has(item.name)} itemName={item.name} onToggle={() => toggle(item.name)} />
                        </div>
                      );
                    })}
                  </Block>
                ))}
                <Block i={SECTIONS.length + 1}><p className="text-body-sm tu-sheet__subtle tu-sheet__pad">Prices with VAT. From the restaurant's own menu.</p></Block>
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
                    </div>
                  ))}
                </Block>
              </>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
      <div className="tu-sheet__bar">
        <SegmentedTabs tabs={[...DETAIL_TABS]} value={tab} onChange={t => select(t as DetailTab)} />
        <Button icon={X} label="Close" size="sm" onClick={p.onClose} />
      </div>
    </article>
  );
}
