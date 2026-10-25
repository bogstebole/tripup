// Approving a payment in my bank's app: the step TripUp hands off to, and gets back from.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'glass.dart';

/// My bank's app, with the transfer TripUp started already filled in: to whom, their account, how much, the reference,
/// from which of my accounts. I check it and approve it with Face ID (or cancel), and the bank sends me back to TripUp.
/// In the real app iOS opens the bank's own app; in the prototype this stands in for it, in a plain look of its own
/// rather than TripUp's, so it reads as another app. "TripUp" at the top goes back, as iOS's back-to-app link does.
class BankApp extends StatefulWidget {
  const BankApp({super.key, required this.pay, required this.bank, required this.onApproved, required this.onCancel});
  final Payment pay;
  final Bank bank;

  /// Approved: back to TripUp, where the bank's answer follows in a moment.
  final VoidCallback onApproved;

  /// Cancelled: back to TripUp, nothing sent.
  final VoidCallback onCancel;

  @override
  State<BankApp> createState() => _BankAppState();
}

enum _Phase { review, scanning, approved }

class _BankAppState extends State<BankApp> {
  var _phase = _Phase.review;
  final _timers = <Timer>[];

  void _approve() {
    if (_phase != _Phase.review) return;
    HapticFeedback.selectionClick();
    setState(() => _phase = _Phase.scanning);
    _timers.add(Timer(TokMotion.faceId, () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();   // Face ID matched
      setState(() => _phase = _Phase.approved);
      _timers.add(Timer(TokMotion.approved, () {
        if (mounted) widget.onApproved();
      }));
    }));
  }

  void _cancel() {
    if (_phase != _Phase.review) return;
    HapticFeedback.selectionClick();
    widget.onCancel();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    final p = widget.pay, to = personById(p.to);
    final muted = TokText.bodySm.copyWith(color: t.cBankMuted);
    return ColoredBox(
      color: t.cBankBg,
      child: Stack(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(TokSpace.screenX, pad.top + TokSpace.x2xs, TokSpace.screenX, pad.bottom + TokSpace.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // iOS's way back to the app that opened this one
            Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                onTap: _cancel,
                semanticLabel: 'Back to TripUp',
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  LucideIcon(TuIcons.backSmall, size: TokSize.iconSm, color: t.cBankMuted),
                  Text('TripUp', style: TokText.labelSm.copyWith(color: t.cBankMuted)),
                ]),
              ),
            ),
            const SizedBox(height: TokSpace.lg),
            // The bank's own bar
            Row(spacing: TokSpace.xs, children: [
              Container(
                width: TokDim.bankLogo,
                height: TokDim.bankLogo,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.cBankLogoBg, borderRadius: BorderRadius.circular(TokDim.bankRadius)),
                child: LucideIcon(TuIcons.bank, size: TokSize.iconSm, color: t.cBankLogoFg),
              ),
              Expanded(child: Text(widget.bank.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelLg.copyWith(fontWeight: TokWeight.semibold, color: t.cBankFg))),
              LucideIcon(TuIcons.secure, size: TokSize.iconSm, color: t.cBankMuted),
            ]),
            const SizedBox(height: TokSpace.x2xl),
            Text('Approve payment', style: TokText.headingLg.copyWith(color: t.cBankFg)),
            const SizedBox(height: TokSpace.x2xs),
            Text('TripUp asked to send this from your account.', style: muted),
            const SizedBox(height: TokSpace.lg),
            // The transfer, as TripUp filled it in; nothing here can be changed
            Container(
              padding: const EdgeInsets.all(TokSpace.md),
              decoration: BoxDecoration(
                color: t.cBankCard,
                borderRadius: BorderRadius.circular(TokDim.bankRadius),
                border: Border.all(color: t.cBankLine, width: TokDim.surfaceEdgeWidth),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(euros(p.amount), style: TokText.headingXl.copyWith(color: t.cBankFg)),
                Text('SEPA Instant · arrives in seconds', style: muted),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: TokSpace.sm),
                  child: SizedBox(height: TokDim.surfaceEdgeWidth, child: ColoredBox(color: t.cBankLine)),
                ),
                _line(context, 'To', to.name),
                _line(context, 'IBAN', accountOf(to.id)),
                _line(context, 'Reference', payReference(p)),
                _line(context, 'From', 'Current account · ${accountOf(myId)}'),
              ]),
            ),
            const Spacer(),
            Pressable(
              onTap: _approve,
              semanticLabel: 'Approve with Face ID',
              child: Container(
                height: TokDim.bankButton,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.cBankAccent, borderRadius: BorderRadius.circular(TokDim.bankRadius)),
                child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
                  LucideIcon(TuIcons.faceId, size: TokSize.iconMd, color: t.cBankAccentFg),
                  Text('Approve with Face ID', style: TokText.labelLg.copyWith(fontWeight: TokWeight.semibold, color: t.cBankAccentFg)),
                ]),
              ),
            ),
            Pressable(
              onTap: _cancel,
              semanticLabel: 'Cancel',
              child: SizedBox(
                height: TokSize.touchTarget,
                child: Center(child: Text('Cancel', style: TokText.labelLg.copyWith(color: t.cBankMuted))),
              ),
            ),
          ]),
        ),
        // Face ID, then the check: the system's square in the middle of the screen
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _phase == _Phase.review,
            child: Center(
              child: AnimatedOpacity(
                opacity: _phase == _Phase.review ? 0 : 1,
                duration: TokMotion.fade,
                curve: TokMotion.easeOut,
                child: AnimatedScale(
                  scale: _phase == _Phase.review ? TokMotion.morphEnterScale : 1,
                  duration: TokMotion.enter,
                  curve: TokMotion.easeOut,
                  child: Container(
                    width: TokDim.bankHud,
                    height: TokDim.bankHud,
                    decoration: BoxDecoration(color: t.cBankHudBg, borderRadius: BorderRadius.circular(TokRadius.sheet)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: TokSpace.sm, children: [
                      AnimatedSwitcher(
                        duration: TokMotion.enter,
                        reverseDuration: TokMotion.fade,
                        switchInCurve: TokMotion.easeOut,
                        switchOutCurve: TokMotion.easeOut,
                        transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: TokMotion.morphEnterScale, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
                        child: _phase == _Phase.approved
                            ? LucideIcon(TuIcons.done, key: const ValueKey('ok'), size: TokDim.bankHudIcon, color: t.cBankOk)
                            : LucideIcon(TuIcons.faceId, key: const ValueKey('face'), size: TokDim.bankHudIcon, color: t.cBankHudFg),
                      ),
                      Text(_phase == _Phase.approved ? 'Approved' : 'Face ID', style: TokText.labelMd.copyWith(color: t.cBankHudFg)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final t = context.tok;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokSpace.x2xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.sm, children: [
        Text(label, style: TokText.bodySm.copyWith(color: t.cBankMuted)),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: TokText.labelMd.copyWith(color: t.cBankFg))),
      ]),
    );
  }
}
