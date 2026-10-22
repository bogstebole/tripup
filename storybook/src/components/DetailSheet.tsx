import { X } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useState } from 'react';
import tokens from '../../../design-system/tokens.json';
import { photoUrl, type Dish, type Person } from '../data';
import { Button } from './Button';
import { KnowRow, KnowSection } from './KnowSection';
import { RatingLine } from './RatingLine';
import { SegmentedTabs } from './SegmentedTabs';
import { Sticker } from './Sticker';
import './Surface.css';
import './DetailSheet.css';

export const DETAIL_TABS = ['Overview', 'Menu', 'People'] as const;
export type DetailTab = (typeof DETAIL_TABS)[number];

export interface DetailSheetProps {
  name: string;
  rating: string;
  cuisine: string;
  photos: string[];
  about: string;
  tips: string[];
  menu: Dish[];
  people: Person[];
  /** Sticker of each person, by id; used for who picked a dish. */
  faces: Record<string, string>;
  tab?: DetailTab;
  onTabChange?: (tab: DetailTab) => void;
  onClose?: () => void;
}

const fadeMs = tokens.motion['fade-ms'] / 1000;
const ease = tokens.motion['ease-out'] as [number, number, number, number];

/** The full view of a plan. Photos and name stay put; the body below switches with the tabs. */
export function DetailSheet(p: DetailSheetProps) {
  const [own, setOwn] = useState<DetailTab>('Overview');
  const tab = p.tab ?? own;
  const reduce = useReducedMotion();
  const index = DETAIL_TABS.indexOf(tab);
  const [prev, setPrev] = useState(index);
  const dir = index >= prev ? 1 : -1;
  const shift = reduce ? 0 : tokens.space.xs;   // tabs slide in from the side they come from
  const select = (t: DetailTab) => { setPrev(index); setOwn(t); p.onTabChange?.(t); };
  const going = p.people.filter(x => x.status !== 'Not going').length;
  const picked = new Set(p.menu.flatMap(d => d.pickedBy)).size;

  return (
    <article className="tu-sheet tu-surface tu-surface--sheet" aria-label={p.name}>
      <div className="tu-sheet__scroll">
        <div className="tu-sheet__photos" aria-hidden>
          {p.photos.map((ph, i) => (
            <img key={ph} src={photoUrl(ph)} alt="" className={`tu-sheet__photo tu-sheet__photo--${i === 0 ? 'start' : i === p.photos.length - 1 ? 'end' : 'main'}`} />
          ))}
        </div>
        <div className="tu-sheet__info">
          <h2 className="tu-sheet__name text-heading-md tu-ellipsis">{p.name}</h2>
          <RatingLine rating={p.rating} kind={p.cuisine} align="start" />
        </div>
        <AnimatePresence mode="popLayout" initial={false} custom={dir}>
          <motion.div
            key={tab}
            className="tu-sheet__body"
            initial={{ opacity: 0, x: dir * shift }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -dir * shift }}
            transition={{ duration: reduce ? 0 : fadeMs, ease }}
          >
            {tab === 'Overview' && (
              <>
                <p className="tu-sheet__about text-body-sm">{p.about}</p>
                <KnowSection title="Know before you go">
                  {p.tips.map(t => <KnowRow key={t}>{t}</KnowRow>)}
                </KnowSection>
              </>
            )}
            {tab === 'Menu' && (
              <>
                <p className="tu-sheet__about text-body-sm">Pick what you'll have. When the bill comes, scan it and each line goes to whoever picked it.</p>
                <KnowSection title="Menu picks" meta={`${picked} of ${p.people.length} picked`}>
                  {p.menu.map(d => (
                    <KnowRow
                      key={d.id}
                      leading={<Sticker name={d.sticker} size="row" />}
                      trailing={<span className="tu-sheet__faces">{d.pickedBy.map(id => <Sticker key={id} name={p.faces[id]} size="chip" />)}</span>}
                    >
                      <span className="tu-sheet__row-title">{d.name}</span>
                      <span className="tu-sheet__row-sub">{d.price}</span>
                    </KnowRow>
                  ))}
                </KnowSection>
              </>
            )}
            {tab === 'People' && (
              <KnowSection title="Who's coming" meta={`${going} of ${p.people.length} going`}>
                {p.people.map(x => (
                  <KnowRow key={x.id} leading={<Sticker name={x.sticker} size="avatar" />}>
                    <span className="tu-sheet__row-title">{x.name}</span>
                    <span className="tu-sheet__row-sub">{x.status}</span>
                  </KnowRow>
                ))}
              </KnowSection>
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
