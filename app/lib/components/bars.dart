import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'entrance.dart';
import 'glass.dart';
import 'map_shapes.dart';
import 'progressive_blur.dart';

/// Trip header over the map: back, trip name and dates, people. Fades the map out behind it.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, required this.dates, this.onBack, this.filter, this.trailing});
  final String title, dates;
  final VoidCallback? onBack;

  /// At the end of the title row (the demo's moment picker).
  final Widget? trailing;

  /// Day filter, right under the title row (inside the bar's fade, so it reads over the map).
  final Widget? filter;

  /// Height of the bar's content area below the status bar (used to keep pins out from under it).
  static const double contentHeight = TokSpace.xl + TokDim.buttonMd;

  /// The same with the day filter under it.
  static const double contentHeightWithFilter = contentHeight + TokSpace.md + TokSpace.x2xl;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final top = MediaQuery.paddingOf(context).top;
    // The map fades out under a see-through white running past the day filter, so the bar reads over any map
    return Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: easedFade(t.bgDefault.withValues(alpha: 0.7), from: TokDim.topBarFadeStart)))),
      Container(
      padding: EdgeInsets.fromLTRB(0, top + TokSpace.xl, 0, TokSpace.x2xl),
      child: Column(mainAxisSize: MainAxisSize.min, spacing: TokSpace.md, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
          child: Row(spacing: TokSpace.md, children: [
            EnterItem(index: EnterOrder.back, child: TuButton(icon: TuIcons.back, label: 'Back to trips', onTap: onBack)),
            Expanded(
              child: EnterItem(
                index: EnterOrder.title,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingSm.copyWith(color: t.textDefault)),
                  Text(dates, style: TokText.labelMd.copyWith(color: t.textMuted)),
                ]),
              ),
            ),
            if (trailing != null) EnterItem(index: EnterOrder.demo, child: trailing!),
          ]),
        ),
        ?filter,
      ]),
      ),
    ]);
  }
}

/// The trip's three actions: the itinerary, the group's money (the whole group as one little pile), and add (the
/// one primary). A white fade, strongest at the bottom, lifts them off the map.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, this.onItinerary, this.onMoney, this.onAdd});
  final VoidCallback? onItinerary, onMoney, onAdd;

  /// The buttons' row, side to side: pins pass beside it, never under it.
  static const double width = TokDim.buttonLg * 3 + TokSpace.xs * 2;

  /// The map's credit: one line of small text (OpenStreetMap's licence asks for it to be readable).
  static const creditStyle = TokText.bodySm;
  static final double creditHeight = creditStyle.fontSize! * creditStyle.height!;

  /// Under the buttons, where pins never go, sits the map's credit. On iOS it's inside the home indicator's inset, as
  /// designed. Android's system bar there is real UI (three buttons, or a gesture handle the credit ran into), so on
  /// Android the credit sits just above it, and the buttons above the credit.
  static bool get _android => defaultTargetPlatform == TargetPlatform.android;

  /// From the bottom of the screen to the bottom of the buttons.
  static double rowInset(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return _android ? math.max(bottom + creditHeight + TokSpace.x3xs * 2, TokSpace.x2xl) : math.max(bottom, TokSpace.x2xl);
  }

  /// From the bottom of the screen to the bottom of the map's credit.
  static double creditInset(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return _android ? bottom + TokSpace.x3xs : math.max(bottom, TokSpace.x2xl) - creditHeight - TokSpace.x3xs;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(TokSpace.md, TokSpace.md, TokSpace.md, _android ? rowInset(context) : (bottom > 0 ? bottom : TokSpace.x2xl)),
      decoration: BoxDecoration(gradient: easedFade(t.bgDefault, from: TokDim.actionBarFadeStart, up: true)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: TokSpace.xs, children: [
        EnterItem(index: EnterOrder.footer, child: TuButton(icon: TuIcons.places, label: 'Itinerary', size: TuButtonSize.lg, onTap: onItinerary)),
        EnterItem(index: EnterOrder.footer + 1, child: _CrewButton(onTap: onMoney)),
        EnterItem(index: EnterOrder.footer + 2, child: TuButton(icon: TuIcons.add, label: 'Add to the trip', size: TuButtonSize.lg, kind: GlassKind.primary, onTap: onAdd)),
      ]),
    );
  }
}

/// The money button: everyone on the trip, piled up, on a soft glass circle.
class _CrewButton extends StatelessWidget {
  const _CrewButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: 'Money: who paid and who owes',
        child: Glass(
          kind: GlassKind.soft,
          width: TokDim.buttonLg,
          height: TokDim.buttonLg,
          radius: BorderRadius.circular(TokRadius.pill),
          child: Center(
            child: SizedBox(
              width: crewPile.width,
              height: crewPile.height,
              child: Stack(clipBehavior: Clip.none, children: [
                for (final s in crewPile.stickers) Positioned(left: s.left, top: s.top, child: Sticker(s.sticker, height: s.height, tilt: s.tilt)),
              ]),
            ),
          ),
        ),
      );
}

/// Not part of the product: the demo's clock, and a way to jump between moments of the brief's story.
class DemoButton extends StatelessWidget {
  const DemoButton({super.key, required this.time, this.onTap});

  /// The demo's "now" ("3:56 PM").
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Demo, $time: jump to a moment in the story',
      child: Glass(
        kind: GlassKind.soft,
        height: TokDim.buttonMd,
        radius: BorderRadius.circular(TokRadius.pill),
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xs, children: [
          LucideIcon(TuIcons.hours, size: TokSize.iconSm, color: t.textMuted),
          Text('Demo · $time', style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
        ]),
      ),
    );
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
