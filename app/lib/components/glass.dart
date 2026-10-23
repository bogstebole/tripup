import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/lucide.dart';
import '../design/theme.dart';
import '../design/tokens.dart';

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
