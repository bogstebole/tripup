import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'glass.dart';
import 'stagger.dart';

/// A short note: a flat pill in the brand blue (not glass, so it doesn't read as a button), with a check,
/// the one line that matters, and Undo.
class Toast extends StatelessWidget {
  const Toast({super.key, required this.label, this.actionLabel, this.onAction});
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final fg = t.cToastFg;
    return Semantics(
      liveRegion: true,
      child: Container(
        height: TokDim.buttonMd,
        padding: const EdgeInsets.only(left: TokSpace.md),
        decoration: BoxDecoration(color: t.cToastBg, borderRadius: BorderRadius.circular(TokRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
          LucideIcon(TuIcons.check, size: TokSize.iconSm, color: fg),
          Text(label, maxLines: 1, style: TokText.labelMd.copyWith(color: fg)),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              semanticLabel: actionLabel,
              child: SizedBox(
                height: TokDim.buttonMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
                  child: Center(widthFactor: 1, child: Text(actionLabel!, style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: fg))),
                ),
              ),
            )
          else
            const SizedBox(width: TokSpace.x2xs),
        ]),
      ),
    );
  }
}

/// Slides a toast up from past the bottom edge as [animation] runs to 1, and back down the way it came as it
/// runs back to 0 (with reduced motion, it only fades). A new toast while one is up swaps in place, blurring across.
class ToastSlot extends StatelessWidget {
  const ToastSlot({super.key, required this.animation, required this.child});

  /// 0 hidden, 1 shown. Give it ease-out both ways (quick to start when leaving too).
  final Animation<double> animation;

  /// Key it by what it says, so a new one crossfades instead of jumping.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: animation,
      child: AnimatedSwitcher(
        duration: TokMotion.fade,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
        transitionBuilder: (c, a) => fadeBlurOut(a, c),
        child: child,
      ),
      builder: (context, child) {
        final v = animation.value;
        if (v <= 0) return const SizedBox.shrink();
        final away = reduce ? 0.0 : 1 - v;
        return IgnorePointer(
          ignoring: v < 0.5,
          child: Opacity(
            opacity: v.clamp(0.0, 1.0),
            // Its own height, plus the gap under it, so it starts fully out of view
            child: Transform.translate(
              offset: Offset(0, TokSpace.md * away),
              child: FractionalTranslation(translation: Offset(0, away), child: child),
            ),
          ),
        );
      },
    );
  }
}
