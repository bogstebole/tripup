import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/lucide.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'stagger.dart';

enum GlassKind { soft, primary }

/// The glass body shared by buttons, the people pill and tappable rows: fill, pressed-in edge, slight lift.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.kind, required this.radius, this.padding, this.child, this.width, this.height});
  final GlassKind kind;
  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final soft = kind == GlassKind.soft;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: soft ? t.cButtonSoftBg : t.cButtonPrimaryBg,
        borderRadius: radius,
        boxShadow: TokShadow.slightlyRaised,
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(soft ? TokInset.buttonSoft : TokInset.buttonPrimary, radius),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

enum TuButtonSize { sm, md, lg }

/// Round icon button. Every icon button in TripUp is this component (see Storybook: Components/Button).
class TuButton extends StatelessWidget {
  const TuButton({super.key, required this.icon, required this.label, this.kind = GlassKind.soft, this.size = TuButtonSize.md, this.onTap});
  final String icon;
  final String label;
  final GlassKind kind;
  final TuButtonSize size;
  final VoidCallback? onTap;

  static double sizeOf(TuButtonSize s) => switch (s) {
        TuButtonSize.sm => TokDim.buttonSm,
        TuButtonSize.md => TokDim.buttonMd,
        TuButtonSize.lg => TokDim.buttonLg,
      };

  @override
  Widget build(BuildContext context) {
    final d = sizeOf(size);
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Glass(
        kind: kind,
        width: d,
        height: d,
        radius: BorderRadius.circular(TokRadius.pill),
        child: Center(
          child: LucideIcon(icon, size: TokDim.buttonIcon, color: kind == GlassKind.soft ? t.cButtonSoftFg : t.cButtonPrimaryFg),
        ),
      ),
    );
  }
}

/// The Lucide icons used in the app, in one place.
abstract final class TuIcons {
  static const back = Lucide.arrowLeft;
  static const forward = Lucide.arrowRight;
  static const calendar = Lucide.calendar;
  static const places = Lucide.mapPin;
  static const money = Lucide.euro;
  static const add = Lucide.plus;
  static const close = Lucide.x;
  static const star = Lucide.star;
  static const check = Lucide.check;
  static const hours = Lucide.clock;
  static const price = Lucide.banknote;
  static const delivery = Lucide.truck;
  static const website = Lucide.globe;
  static const phone = Lucide.phone;
}

/// A Lucide icon with a 2 px stroke at any size (like lucide-react's `absoluteStrokeWidth` in Storybook).
class LucideIcon extends StatelessWidget {
  const LucideIcon(this.body, {super.key, required this.size, required this.color, this.filled = false});
  final String body;
  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final stroke = TokDim.iconStroke * 24 / size;   // the view box is 24 wide
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? '#000' : 'none'}" stroke="#000" '
        'stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">$body</svg>';
    return SvgPicture.string(svg, width: size, height: size, colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
  }
}

/// Small round button on a menu row: a plus in soft glass, a check in primary glass once added. One tap toggles it.
class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.added, required this.onTap, required this.itemName});
  final bool added;
  final VoidCallback onTap;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: added ? 'Remove $itemName from your picks' : 'Add $itemName to your picks',
      // A small circle, with a full touch target around it. Plus and check swap like an icon swap should:
      // the new one grows in from a little smaller, sharpening from a blur, while the old one blurs away
      child: SizedBox.square(
        dimension: TokSize.touchTarget,
        child: Center(
          child: AnimatedSwitcher(
            duration: TokMotion.enter,
            reverseDuration: TokMotion.fade,
            switchInCurve: TokMotion.easeOut,
            switchOutCurve: TokMotion.easeOut,
            transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: TokMotion.morphEnterScale, end: 1.0).animate(a), child: fadeBlurOut(a, child)),
            child: Glass(
              key: ValueKey(added),
              kind: added ? GlassKind.primary : GlassKind.soft,
              width: TokDim.buttonPillHeight,
              height: TokDim.buttonPillHeight,
              radius: BorderRadius.circular(TokRadius.pill),
              child: Center(child: LucideIcon(added ? TuIcons.check : TuIcons.add, size: TokSize.iconSm, color: added ? t.cButtonPrimaryFg : t.cButtonSoftFg)),
            ),
          ),
        ),
      ),
    );
  }
}
