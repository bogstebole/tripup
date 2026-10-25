// Approving a payment in my bank's app: the step TripUp hands off to, and gets back from (the app's bank_app.dart).
import { ChevronLeft, CircleCheck, Landmark, Lock, ScanFace } from 'lucide-react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { useEffect, useRef, useState } from 'react';
import tokens from '../../../design-system/tokens.json';
import { accountOf, euros, MY_ID, payReference, personById, type Bank, type Payment } from '../data';
import './BankApp.css';

const m = tokens.motion;
const ease = m['ease-out'] as [number, number, number, number];
const icon = { strokeWidth: 2, absoluteStrokeWidth: true, 'aria-hidden': true } as const;

export interface BankAppProps {
  pay: Payment;
  bank: Bank;
  /** Approved: back to TripUp, where the bank's answer follows in a moment. */
  onApproved: () => void;
  /** Cancelled: back to TripUp, nothing sent. */
  onCancel: () => void;
}

/**
 * My bank's app, with the transfer TripUp started already filled in: the amount (heading-xl) and "SEPA Instant ·
 * arrives in seconds", then To, IBAN, Reference and From, none of which can be changed. Approve with Face ID: the
 * system's square comes up in the middle (Face ID, face-id-ms), turns to a green check and Approved (approved-ms), and
 * the bank sends me back. Cancel, or "TripUp" at the top (iOS's back-to-app link), goes back with nothing sent. In the
 * real app iOS opens the bank's own app; here it stands in for it, in a plain look of its own (the c-bank colours,
 * square-ish corners, a dark button) so it reads as another app.
 */
export function BankApp({ pay, bank, onApproved, onCancel }: BankAppProps) {
  const [phase, setPhase] = useState<'review' | 'scanning' | 'approved'>('review');
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach(t => window.clearTimeout(t)), []);
  const to = personById(pay.to);
  const approve = () => {
    if (phase !== 'review') return;
    setPhase('scanning');
    timers.current.push(window.setTimeout(() => {
      setPhase('approved');
      timers.current.push(window.setTimeout(onApproved, m['approved-ms']));
    }, m['face-id-ms']));
  };
  const cancel = () => phase === 'review' && onCancel();
  return (
    <div className="tu-bank">
      <button type="button" className="text-label-sm tu-bank__back" onClick={cancel}>
        <ChevronLeft className="tu-bank__back-icon" {...icon} />TripUp
      </button>
      <div className="tu-bank__bar">
        <span className="tu-bank__logo"><Landmark className="tu-bank__logo-icon" {...icon} /></span>
        <span className="text-label-lg weight-semibold tu-bank__name">{bank.name}</span>
        <Lock className="tu-bank__lock" {...icon} />
      </div>
      <h2 className="text-heading-lg tu-bank__title">Approve payment</h2>
      <p className="text-body-sm tu-bank__muted">TripUp asked to send this from your account.</p>
      <div className="tu-bank__card">
        <p className="text-heading-xl">{euros(pay.amount)}</p>
        <p className="text-body-sm tu-bank__muted">SEPA Instant · arrives in seconds</p>
        <div className="tu-bank__line" />
        {([['To', to.name], ['IBAN', accountOf(to.id)], ['Reference', payReference(pay)], ['From', `Current account · ${accountOf(MY_ID)}`]] as const).map(([label, value]) => (
          <p key={label} className="tu-bank__row"><span className="text-body-sm tu-bank__muted">{label}</span><span className="text-label-md">{value}</span></p>
        ))}
      </div>
      <div className="tu-bank__actions">
        <button type="button" className="text-label-lg weight-semibold tu-bank__approve" onClick={approve}>
          <ScanFace className="tu-bank__approve-icon" {...icon} />Approve with Face ID
        </button>
        <button type="button" className="text-label-lg tu-bank__cancel" onClick={cancel}>Cancel</button>
      </div>
      {/* Face ID, then the check: the system's square in the middle of the screen */}
      <AnimatePresence>
        {phase !== 'review' && (
          <motion.div
            key="hud"
            className="tu-bank__hud"
            initial={{ opacity: 0, transform: `scale(${m['morph-enter-scale']})` }}
            animate={{ opacity: 1, transform: 'scale(1)', transition: { duration: m['enter-ms'] / 1000, ease } }}
          >
            <AnimatePresence initial={false} mode="popLayout">
              <motion.span
                key={phase}
                className="tu-bank__hud-mark"
                initial={{ opacity: 0, transform: `scale(${m['morph-enter-scale']})` }}
                animate={{ opacity: 1, transform: 'scale(1)', transition: { duration: m['enter-ms'] / 1000, ease } }}
                exit={{ opacity: 0, transition: { duration: m['fade-ms'] / 1000, ease } }}
              >
                {phase === 'approved' ? <CircleCheck className="tu-bank__hud-icon tu-bank__hud-icon--ok" {...icon} /> : <ScanFace className="tu-bank__hud-icon" {...icon} />}
              </motion.span>
            </AnimatePresence>
            <span className="text-label-md">{phase === 'approved' ? 'Approved' : 'Face ID'}</span>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

/**
 * The bank's app over TripUp: it comes in like another phone screen, from a slight zoom (page-zoom-scale to 1,
 * enter-ms, ease-out), and fades away quicker (fade-ms). Reduced motion: fades only. Put it in AnimatePresence.
 */
export function BankLayer(props: BankAppProps) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      style={{ position: 'absolute', inset: 0, zIndex: 1 }}
      initial={reduce ? { opacity: 0 } : { opacity: 0, transform: `scale(${m['page-zoom-scale']})` }}
      animate={{ ...(reduce ? { opacity: 1 } : { opacity: 1, transform: 'scale(1)' }), transition: { duration: m['enter-ms'] / 1000, ease } }}
      exit={{ opacity: 0, pointerEvents: 'none', transition: { duration: m['fade-ms'] / 1000, ease } }}
    >
      <BankApp {...props} />
    </motion.div>
  );
}
