import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final IconData icon;
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
          child: Icon(icon, size: TokDim.buttonIcon, color: kind == GlassKind.soft ? t.cButtonSoftFg : t.cButtonPrimaryFg),
        ),
      ),
    );
  }
}

/// The Lucide icons used in the app, in one place.
abstract final class TuIcons {
  static const back = LucideIcons.arrowLeft;
  static const forward = LucideIcons.arrowRight;
  static const calendar = LucideIcons.calendar;
  static const places = LucideIcons.mapPin;
  static const money = LucideIcons.euro;
  static const add = LucideIcons.plus;
  static const close = LucideIcons.x;
  static const star = LucideIcons.star;
}
