import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Provides the current mode's token colors. Read them with `context.tok`.
class Tok extends InheritedWidget {
  const Tok({super.key, required this.colors, required super.child});
  final TokColors colors;

  @override
  bool updateShouldNotify(Tok oldWidget) => oldWidget.colors != colors;
}

extension TokContext on BuildContext {
  TokColors get tok => dependOnInheritedWidgetOfExactType<Tok>()!.colors;
}

/// An Apple-style spring token as a Flutter spring.
SpringDescription springOf(TokSpring s) => SpringDescription.withDurationAndBounce(
      duration: Duration(milliseconds: (s.duration * 1000).round()),
      bounce: s.bounce,
    );

/// Animates [c] to [target] on [spring], keeping the current velocity so a change of mind mid-way stays smooth.
TickerFuture springTo(AnimationController c, double target, TokSpring spring, {double? velocity}) {
  final sim = SpringSimulation(springOf(spring), c.value, target, velocity ?? c.velocity, tolerance: const Tolerance(distance: 0.0005, velocity: 0.005));
  return c.animateWith(sim);
}

/// Soft shapes (blurred shadows) drawn once into an image at the screen's pixel density and reused, instead of being
/// blurred again on the GPU every frame. A blur has no hard edge, so the image looks the same wherever it lands.
abstract final class SoftImage {
  static final _images = <Object, ui.Image>{};

  /// Draws what [paint] draws within [bounds] (in the canvas's units), from the image made the first time this [key]
  /// came up. [scale] is any scale the canvas already has on top of the screen's density.
  static void draw(Canvas canvas, Object key, Rect bounds, void Function(Canvas canvas) paint, {double scale = 1}) {
    final density = (WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ?? 1) * scale;
    if (_images.length > 256) {
      // Sizes are few in practice; if they ever pile up, start over
      for (final image in _images.values) {
        image.dispose();
      }
      _images.clear();
    }
    final image = _images[(key, bounds, density)] ??= () {
      final recorder = ui.PictureRecorder();
      paint(Canvas(recorder)
        ..scale(density)
        ..translate(-bounds.left, -bounds.top));
      final picture = recorder.endRecording();
      try {
        return picture.toImageSync((bounds.width * density).ceil(), (bounds.height * density).ceil());
      } finally {
        picture.dispose();
      }
    }();
    canvas.drawImageRect(image, Offset.zero & bounds.size * density, bounds, Paint()..filterQuality = FilterQuality.low);
  }
}

/// Paints inner shadows inside a rounded rect, like CSS `box-shadow: inset ...`.
class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter(this.shadows, this.radius);
  final List<InsetShadow> shadows;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    final outer = Rect.fromLTWH(-size.width, -size.height, size.width * 3, size.height * 3);
    canvas.save();
    canvas.clipRRect(rrect);
    // The same blurred rings for every glass of this size and shape: blurred once, then reused (the clip stays sharp)
    SoftImage.draw(canvas, (shadows, radius), Offset.zero & size, (canvas) {
      for (final s in shadows) {
        final hole = rrect.shift(s.offset).deflate(s.spread);
        final ring = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(outer)
          ..addRRect(hole);
        canvas.drawPath(ring, Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(s.blur)));
      }
    });
    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetShadowPainter old) => old.shadows != shadows || old.radius != radius;
}

/// Draws drop shadows for any path (shapes that aren't boxes: the pin tail, the edge arrow). They're blurred once per
/// [shape] (a key for the path, which is the same every time for it) and reused; [scale] is any scale the canvas has.
void paintPathShadows(Canvas canvas, Path path, List<BoxShadow> shadows, {required Object shape, double scale = 1}) {
  // Room for the farthest-reaching shadow: its offset, spread and blur (3 sigma is all a Gaussian shows)
  final reach = shadows.fold(0.0, (r, s) => math.max(r, s.offset.distance + s.spreadRadius + 3 * Shadow.convertRadiusToSigma(s.blurRadius) + 1));
  SoftImage.draw(canvas, (shape, shadows), path.getBounds().inflate(reach), (canvas) {
    for (final s in shadows) {
      canvas.drawPath(
        path.shift(s.offset),
        Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(s.blurRadius)),
      );
    }
  }, scale: scale);
}

/// Scales to the press token while held, like the CSS `:active` rule, and ticks a light haptic on the tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel, this.button = true});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool button;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      button: widget.button,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          HapticFeedback.lightImpact();   // same frame as the press, one per tap
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _down && !reduce ? TokMotion.pressScale : 1,
          duration: TokMotion.press,
          curve: TokMotion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
