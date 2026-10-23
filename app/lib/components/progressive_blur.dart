import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A backdrop blur that is strongest at the top (or the bottom, with [fromBottom]) and fades out toward the
/// other edge: full [sigma] for [solidUntil] of the height, then less in each band. A masked blur doesn't
/// render on iOS, so it's built from bands, all reading one shared backdrop.
class ProgressiveBlur extends StatelessWidget {
  const ProgressiveBlur({super.key, required this.sigma, this.solidUntil = 0, this.fromBottom = false});
  final double sigma;
  final double solidUntil;
  final bool fromBottom;

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
        return BackdropGroup(
          child: Stack(children: [
            if (start > 0) band(0, start, sigma),
            for (var j = 0; j < _bands; j++) band(start + (h - start) * j / _bands, start + (h - start) * (j + 1) / _bands, sigma * (1 - (j + 1) / (_bands + 1))),
          ]),
        );
      });
}
