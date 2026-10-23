import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'map_shapes.dart';
import 'progressive_blur.dart';

/// Trip header over the map: back, trip name and dates, people. Fades the map out behind it.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, required this.dates, required this.faces, required this.more, this.onBack, this.onPeople, this.filter});
  final String title, dates;
  final List<String> faces;
  final int more;
  final VoidCallback? onBack, onPeople;

  /// Day filter, right under the title row (inside the bar's fade, so it reads over the map).
  final Widget? filter;

  /// Height of the bar's content area below the status bar (used to keep pins out from under it).
  static const double contentHeight = TokSpace.xl + TokDim.buttonMd;

  /// The same with the day filter under it.
  static const double contentHeightWithFilter = contentHeight + TokSpace.md + TokDim.toggleChipHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final top = MediaQuery.paddingOf(context).top;
    // The map blurs more toward the top under a white fade, both running past the day filter, so the bar reads over any map
    return Stack(children: [
      const Positioned.fill(child: ProgressiveBlur(sigma: TokDim.topBarBlur, solidUntil: TokDim.topBarFadeStart, shared: true)),
      // See-through white: the blurred map still shows through it
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: easedFade(t.cTopBarBg, from: TokDim.topBarFadeStart)))),
      Container(
      padding: EdgeInsets.fromLTRB(0, top + TokSpace.xl, 0, TokSpace.x2xl),
      child: Column(mainAxisSize: MainAxisSize.min, spacing: TokSpace.md, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
          child: Row(spacing: TokSpace.md, children: [
            TuButton(icon: TuIcons.back, label: 'Back to trips', onTap: onBack),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingSm.copyWith(color: t.textDefault)),
                Text(dates, style: TokText.labelMd.copyWith(color: t.textMuted)),
              ]),
            ),
            PeopleButton(faces: faces, more: more, onTap: onPeople),
          ]),
        ),
        ?filter,
      ]),
      ),
    ]);
  }
}

/// The trip's four actions: plan, places, money, and add (the one primary). Blurs and fades the map out behind it.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, this.onCalendar, this.onPlaces, this.onMoney, this.onAdd});
  final VoidCallback? onCalendar, onPlaces, onMoney, onAdd;

  static const double contentHeight = TokDim.buttonLg + TokSpace.x2xl;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // The same treatment as the top bar, upside down: a light blur of the map, strongest at the bottom,
    // under a see-through white that fades out a little above the buttons
    return Stack(children: [
      const Positioned.fill(child: ProgressiveBlur(sigma: TokDim.actionBarBlur, solidUntil: TokDim.actionBarFadeStart, fromBottom: true, shared: true)),
      Container(
      padding: EdgeInsets.fromLTRB(TokSpace.md, TokSpace.x2xl, TokSpace.md, bottom > 0 ? bottom : TokSpace.x2xl),
      decoration: BoxDecoration(gradient: easedFade(t.cActionBarBg, from: TokDim.actionBarFadeStart, up: true)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: TokSpace.xs, children: [
        TuButton(icon: TuIcons.calendar, label: 'Plan', size: TuButtonSize.lg, onTap: onCalendar),
        TuButton(icon: TuIcons.places, label: 'Places', size: TuButtonSize.lg, onTap: onPlaces),
        TuButton(icon: TuIcons.money, label: 'Money', size: TuButtonSize.lg, onTap: onMoney),
        TuButton(icon: TuIcons.add, label: 'Add to the trip', size: TuButtonSize.lg, kind: GlassKind.primary, onTap: onAdd),
      ]),
      ),
    ]);
  }
}

/// Brings the map back to my location. Shown only while I'm off-screen.
class RecenterButton extends StatelessWidget {
  const RecenterButton({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: 'Show my location',
        child: Glass(
          kind: GlassKind.soft,
          width: TokDim.buttonSm,
          height: TokDim.buttonSm,
          radius: BorderRadius.circular(TokRadius.pill),
          child: const Center(child: MeDot(ring: true)),
        ),
      );
}
