// A note for everyone on the trip, at the top of the screen: the app's `tripNotice`. Every note comes from here, from
// anywhere on the screen: Pay, Link copied, Added for…, a dish added on the Menu (with Undo), the poll.
import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import tokens from '../../../design-system/tokens.json';
import { Toast } from './Toast';

const m = tokens.motion;

/** What a note offers to do about itself ("Undo"). */
export type NoticeAction = { label: string; onTap: () => void };
export type Notice = { label: string; shown: boolean; action?: NoticeAction };
export type ShowNotice = (label: string, action?: NoticeAction) => void;
/** A screen's note as it stands, how to show one, and how to take it away at once (Undo does). */
export type NoticeState = readonly [Notice, ShowNotice, () => void];

/** Shows a note for toast-ms; one with an action (Undo) stays for toast-action-ms, so there's time to reach it. A new
 *  one replaces it. */
export function useNotice(): NoticeState {
  const [notice, setNotice] = useState<Notice>({ label: '', shown: false });
  const timer = useRef<number | undefined>(undefined);
  const show = useCallback<ShowNotice>((label, action) => {
    setNotice({ label, shown: true, action });
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setNotice(n => ({ ...n, shown: false })), action ? m['toast-action-ms'] : m['toast-ms']);
  }, []);
  const hide = useCallback(() => {
    window.clearTimeout(timer.current);
    setNotice(n => ({ ...n, shown: false }));
  }, []);
  useEffect(() => () => window.clearTimeout(timer.current), []);
  return [notice, show, hide] as const;
}

const ShowNoticeContext = createContext<ShowNotice>(() => {});

/** Shows a note at the top of the screen this is on, from any page on it. */
export const useTripNotice = () => useContext(ShowNoticeContext);

/**
 * A screen's note for everyone: whatever is inside shows one with `useTripNotice()`, and it slides down at the top of
 * the screen (put this inside the screen's positioned frame). Pass `state` to show notes from outside the screen too
 * (the others' payments, the poll closing); otherwise it keeps its own.
 */
export function NoticeLayer({ state, children }: { state?: NoticeState; children: ReactNode }) {
  const own = useNotice();
  const [notice, show] = state ?? own;
  return (
    <ShowNoticeContext.Provider value={show}>
      {children}
      <Toast label={notice.label} shown={notice.shown} actionLabel={notice.action?.label} onAction={notice.action?.onTap} />
    </ShowNoticeContext.Provider>
  );
}
