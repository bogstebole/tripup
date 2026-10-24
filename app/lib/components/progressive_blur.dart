import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../design/theme.dart';

/// A backdrop blur that is strongest at the top (or the bottom, with [fromBottom]) and fades out toward the
/// other edge: full [sigma] for [solidUntil] of the height, then less in each band, easing off to nothing so
/// its far edge never shows as a line. A masked blur doesn't render on iOS, so it's built from bands, all
/// reading one shared backdrop.
class ProgressiveBlur extends StatelessWidget {
  const ProgressiveBlur({super.key, required this.sigma, this.solidUntil = 0, this.fromBottom = false, this.solidHidden = false});
  final double sigma;
  final double solidUntil;
  final bool fromBottom;

  /// The solid part sits under something opaque, so it isn't blurred at all (no one would see it).
  final bool solidHidden;

  /// Enough steps that no edge between them shows under a fade.
  static const _bands = 8;

  /// Below this a band's blur can't be seen.
  static const _least = 0.25;

  @override
  Widget build(BuildContext context) => lightEffects ? const SizedBox.shrink() : LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight, start = solidUntil * h;
        // [near] and [far] are distances from the strong edge
        Widget band(double near, double far, double s) => Positioned(
              left: 0,
              right: 0,
              top: fromBottom ? h - far : near,
              height: far - near,
              child: ClipRect(child: BackdropFilter.grouped(filter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s), child: const SizedBox.expand())),
            );
        final bands = Stack(children: [
          if (start > 0 && !solidHidden) band(0, start, sigma),
          for (var j = 0; j < _bands; j++)
            // Falls off as the square of the distance left, so the last steps are too small to see; bands that
            // would barely blur are left out
            if (sigma * math.pow(1 - (j + 0.5) / _bands, 2) case final s when s >= _least)
              band(start + (h - start) * j / _bands, start + (h - start) * (j + 1) / _bands, s),
        ]);
        return BackdropGroup(child: bands);
      });
}

/// A fade from [color] to clear: solid until [from] of the way, then easing in and out (a smoothstep), so
/// neither where it starts nor where it ends shows as a line the way a straight fade does. [up] runs it
/// from the bottom.
LinearGradient easedFade(Color color, {double from = 0, bool up = false}) {
  const steps = 8;
  double ease(double x) => x * x * (3 - 2 * x);
  return LinearGradient(
    begin: up ? Alignment.bottomCenter : Alignment.topCenter,
    end: up ? Alignment.topCenter : Alignment.bottomCenter,
    colors: [for (var i = 0; i <= steps; i++) color.withValues(alpha: color.a * (1 - ease(i / steps)))],
    stops: [for (var i = 0; i <= steps; i++) from + (1 - from) * i / steps],
  );
}
