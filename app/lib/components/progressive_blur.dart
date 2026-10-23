import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A backdrop blur that is strongest at the top (or the bottom, with [fromBottom]) and fades out toward the
/// other edge: full [sigma] for [solidUntil] of the height, then less in each band. A masked blur doesn't
/// render on iOS, so it's built from bands, all reading one shared backdrop.
class ProgressiveBlur extends StatelessWidget {
  const ProgressiveBlur({super.key, required this.sigma, this.solidUntil = 0, this.fromBottom = false, this.shared = false, this.solidHidden = false});
  final double sigma;
  final double solidUntil;
  final bool fromBottom;

  /// Reads the backdrop of a [BackdropGroup] above it instead of its own: blurs that don't overlap, like the top
  /// and bottom bars, then cost one read of the screen between them instead of one each.
  final bool shared;

  /// The solid part sits under something opaque, so it isn't blurred at all (no one would see it).
  final bool solidHidden;

  /// Enough steps that no edge between them shows under a fade.
  static const _bands = 8;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
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
          for (var j = 0; j < _bands; j++) band(start + (h - start) * j / _bands, start + (h - start) * (j + 1) / _bands, sigma * (1 - (j + 1) / (_bands + 1))),
        ]);
        return shared ? bands : BackdropGroup(child: bands);
      });
}
