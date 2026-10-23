import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'glass.dart';

/// Day filter under the top bar: All, then each day of the trip. The chips are toggles: flat when off,
/// primary glass when on (the same tactile blue as the buttons, so only what's picked stands out).
/// Days can be combined; with none picked, All is on.
class DayFilter extends StatelessWidget {
  const DayFilter({super.key, required this.days, required this.selected, required this.onChanged, required this.labelOf});

  /// The trip's days, in order.
  final List<int> days;

  /// The days that are on. Empty means All.
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final String Function(int day) labelOf;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
      clipBehavior: Clip.none,
      child: Row(spacing: TokDim.dayChipGap, children: [
        DayChip(label: 'All', on: selected.isEmpty, onTap: () => onChanged(const {})),
        for (final d in days)
          DayChip(
            label: labelOf(d),
            on: selected.contains(d),
            onTap: () => onChanged(selected.contains(d) ? ({...selected}..remove(d)) : {...selected, d}),
          ),
      ]),
    );
  }
}

/// One toggle in the day filter.
class DayChip extends StatelessWidget {
  const DayChip({super.key, required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final text = Text(label, maxLines: 1, style: TokText.labelMd.copyWith(color: on ? t.cButtonPrimaryFg : t.cDayChipOffFg));
    const pad = EdgeInsets.symmetric(horizontal: TokDim.dayChipPaddingX);
    final radius = BorderRadius.circular(TokRadius.pill);
    return Semantics(
      selected: on,
      child: Pressable(
        onTap: () {
          onTap();
          // A chip half off the edge slides fully into view (nothing moves if it already is)
          for (final policy in [ScrollPositionAlignmentPolicy.keepVisibleAtEnd, ScrollPositionAlignmentPolicy.keepVisibleAtStart]) {
            Scrollable.ensureVisible(context, alignmentPolicy: policy, duration: TokMotion.enter, curve: TokMotion.easeOut);
          }
        },
        semanticLabel: label,
        child: AnimatedSwitcher(
          duration: TokMotion.fade,
          switchInCurve: TokMotion.easeOut,
          switchOutCurve: TokMotion.easeOut,
          layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
          transitionBuilder: (child, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: TokMotion.pressScale, end: 1.0).animate(a), child: child)),
          child: on
              ? Glass(key: const ValueKey(true), kind: GlassKind.primary, height: TokDim.dayChipHeight, radius: radius, padding: pad, child: Center(widthFactor: 1, child: text))
              : Container(
                  key: const ValueKey(false),
                  height: TokDim.dayChipHeight,
                  padding: pad,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.cDayChipOffBg, borderRadius: radius),
                  child: text,
                ),
        ),
      ),
    );
  }
}
