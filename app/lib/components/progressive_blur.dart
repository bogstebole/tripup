import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A backdrop blur that is strongest at the top and fades out toward the bottom: full [sigma] down to
/// [solidUntil] (a fraction of the height), then less in each band. A masked blur doesn't render on iOS,
/// so it's built from bands, all reading one shared backdrop.
class ProgressiveBlur extends StatelessWidget {
  const ProgressiveBlur({super.key, required this.sigma, this.solidUntil = 0});
  final double sigma;
  final double solidUntil;

  /// Enough steps that no edge between them shows under a fade.
  static const _bands = 8;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight, start = solidUntil * h;
        Widget band(double top, double bottom, double s) => Positioned(
              left: 0,
              right: 0,
              top: top,
              height: bottom - top,
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
