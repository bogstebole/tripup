import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'glass.dart';

/// A row of toggles: All, then one per option. Flat when off, primary glass when on (the same tactile blue as
/// the buttons, so only what's picked stands out). Options combine; with none picked, All is on. Scrolls
/// sideways. Used for the trip's days under the top bar and for courses in the menu.
class ToggleChips<T> extends StatelessWidget {
  const ToggleChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.allLabel = 'All',
    this.padding = const EdgeInsets.symmetric(horizontal: TokSpace.md),
  });
  final List<T> options;

  /// The options that are on. Empty means All.
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T option) labelOf;
  final String allLabel;

  /// Inset of the first and last chip from the row's edges.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      clipBehavior: Clip.none,
      child: Row(spacing: TokDim.toggleChipGap, children: [
        ToggleChip(label: allLabel, on: selected.isEmpty, onTap: () => onChanged(<T>{})),
        for (final o in options)
          ToggleChip(
            label: labelOf(o),
            on: selected.contains(o),
            onTap: () => onChanged(selected.contains(o) ? ({...selected}..remove(o)) : {...selected, o}),
          ),
      ]),
    );
  }
}

/// One toggle in a [ToggleChips] row.
class ToggleChip extends StatelessWidget {
  const ToggleChip({super.key, required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final text = Text(label, maxLines: 1, style: TokText.labelMd.copyWith(color: on ? t.cButtonPrimaryFg : t.cToggleChipOffFg));
    const pad = EdgeInsets.symmetric(horizontal: TokDim.toggleChipPaddingX);
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
              ? Glass(key: const ValueKey(true), kind: GlassKind.primary, height: TokDim.toggleChipHeight, radius: radius, padding: pad, child: Center(widthFactor: 1, child: text))
              : Container(
                  key: const ValueKey(false),
                  height: TokDim.toggleChipHeight,
                  padding: pad,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.cToggleChipOffBg, borderRadius: radius),
                  child: text,
                ),
        ),
      ),
    );
  }
}
