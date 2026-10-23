// The small drawn shapes on the map. Geometry is traced from the Figma vectors;
// every color and shadow comes from tokens (see Storybook: Widget/Up next → Map marks).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

/// The rounded tail under a widget (Figma "Rectangle 5"), in its 35.28 × 24 frame.
Path _tailPath(Size s) {
  final sx = s.width / 35.28, sy = s.height / 24;
  return Path()
    ..moveTo(20.8721 * sx, 20.5675 * sy)
    ..lineTo(30.5049 * sx, 7.35669 * sy)
    ..cubicTo(32.4324 * sx, 4.71336 * sy, 30.5443 * sx, 1 * sy, 27.2729 * sx, 1 * sy)
    ..lineTo(8.00714 * sx, 1 * sy)
    ..cubicTo(4.73573 * sx, 1 * sy, 2.84768 * sx, 4.71336 * sy, 4.77511 * sx, 7.35669 * sy)
    ..lineTo(14.408 * sx, 20.5675 * sy)
    ..cubicTo(16.0057 * sx, 22.7586 * sy, 19.2744 * sx, 22.7586 * sy, 20.8721 * sx, 20.5675 * sy)
    ..close();
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.top, this.bottom, this.edge);
  final Color top, bottom, edge;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _tailPath(size);
    paintPathShadows(canvas, path, TokShadow.surface);
    canvas.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = TokDim.surfaceEdgeWidth
      ..color = edge);
  }

  @override
  bool shouldRepaint(_TailPainter o) => o.top != top || o.bottom != bottom || o.edge != edge;
}

/// The tail under a widget plus the blue dash that marks the exact spot. Its bottom is the map point.
class PinTail extends StatelessWidget {
  const PinTail({super.key, this.gap = TokSpace.xs});
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Column(mainAxisSize: MainAxisSize.min, spacing: gap, children: [
      CustomPaint(size: const Size(TokDim.pinTailWidth, TokDim.pinTailHeight), painter: _TailPainter(t.cSurfaceTop, t.cSurfaceBottom, t.cSurfaceEdge)),
      Container(
        width: TokDim.pinDashWidth,
        height: TokDim.pinDashHeight,
        decoration: BoxDecoration(color: t.cPinDash, borderRadius: BorderRadius.circular(TokRadius.control)),
      ),
    ]);
  }

  /// Total height, so a pin can put its bottom exactly on the map point.
  static double heightFor(double gap) => TokDim.pinTailHeight + gap + TokDim.pinDashHeight;
}

/// Blue rounded triangle pointing at something off-screen. [angle] in radians; 0 points right.
class EdgeArrow extends StatelessWidget {
  const EdgeArrow({super.key, required this.angle});
  final double angle;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(size: const Size.square(TokDim.widgetEdgeArrow), painter: _ArrowPainter(t.cEdgeArrowFrom, t.cEdgeArrowTo)),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.from, this.to);
  final Color from, to;

  @override
  void paint(Canvas canvas, Size size) {
    // Figma's arrow points down; draw it pointing right so `angle` reads as a heading.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 2);
    final s = size.width / 12.6;
    canvas.scale(s);
    canvas.translate(-9.5, -5.6);
    final path = Path()
      ..moveTo(11.1444, 9.47125)
      ..lineTo(15.2316, 3.86584)
      ..cubicTo(16.1954, 2.54418, 15.2513, 0.6875, 13.6156, 0.6875)
      ..lineTo(5.44107, 0.6875)
      ..cubicTo(3.80536, 0.6875, 2.86134, 2.54418, 3.82506, 3.86584)
      ..lineTo(7.91233, 9.47125)
      ..cubicTo(8.71117, 10.5668, 10.3455, 10.5668, 11.1444, 9.47125)
      ..close();
    paintPathShadows(canvas, path, TokShadow.slightlyRaised);
    canvas.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [from, to]).createShader(const Rect.fromLTWH(3, 0.5, 13, 10)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArrowPainter o) => o.from != from || o.to != to;
}

/// Glassy blue dot (my location), also used inside the recenter button. With [breathe], only the blue
/// scales; the white rim stays put.
class MeDot extends StatelessWidget {
  const MeDot({super.key, this.ring = false, this.breathe});
  final bool ring;
  final Animation<double>? breathe;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final r = BorderRadius.circular(TokRadius.pill);
    final blue = DecoratedBox(
      decoration: BoxDecoration(color: t.cMeDot, borderRadius: r),
      child: CustomPaint(painter: InsetShadowPainter(TokInset.buttonPrimary, r)),
    );
    // The rim is the white disc showing around the blue
    return Container(
      width: TokDim.meDot,
      height: TokDim.meDot,
      padding: const EdgeInsets.all(TokDim.surfaceEdgeWidth),
      decoration: BoxDecoration(
        color: t.cMeDotEdge,
        borderRadius: r,
        boxShadow: [
          if (ring) BoxShadow(color: t.cMeRing, spreadRadius: TokDim.meRing),
          ...TokShadow.meDot,
        ],
      ),
      child: breathe == null ? blue : ScaleTransition(scale: breathe!, child: blue),
    );
  }
}

/// My location with a soft cone toward where I'm facing. [heading] in radians, 0 = north.
/// The blue breathes slowly, as a live location does; it holds still with reduced motion. Mute it with
/// [TickerMode] while it can't be seen.
class MeMarker extends StatefulWidget {
  const MeMarker({super.key, required this.heading});
  final double heading;

  @override
  State<MeMarker> createState() => _MeMarkerState();
}

class _MeMarkerState extends State<MeMarker> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: TokMotion.pulse);
  late final _scale = Tween(begin: 1.0, end: TokDim.mePulseScale).animate(CurvedAnimation(parent: _pulse, curve: TokMotion.easeBreathe));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return SizedBox.square(
      dimension: TokDim.meCone * 2,
      child: Stack(alignment: Alignment.center, children: [
        Transform.rotate(angle: widget.heading, child: CustomPaint(size: const Size.square(TokDim.meCone * 2), painter: _ConePainter(t.cMeCone))),
        // Its own layer, so the breathing repaints only the dot
        RepaintBoundary(child: MeDot(breathe: _scale)),
      ]),
    );
  }
}

class _ConePainter extends CustomPainter {
  _ConePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    const spread = 0.42; // half-angle of the cone, from the Figma vector
    final path = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx + r * math.sin(-spread), c.dy - r * math.cos(-spread))
      ..lineTo(c.dx + r * math.sin(spread), c.dy - r * math.cos(spread))
      ..close();
    canvas.drawPath(path, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
  }

  @override
  bool shouldRepaint(_ConePainter o) => o.color != color;
}

/// On the screen edge when I'm off-screen: a glow pointing in and a blue capsule. [angle] radians, 0 = toward the right edge.
class MeEdge extends StatelessWidget {
  const MeEdge({super.key, required this.angle});
  final double angle;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final r = BorderRadius.circular(TokRadius.pill);
    return Transform.rotate(
      angle: angle,
      child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x3xs, children: [
        CustomPaint(size: const Size(TokDim.meGlowWidth, TokDim.meGlowHeight), painter: _GlowPainter(t.cMeCone)),
        Container(
          width: TokDim.meEdgeWidth,
          height: TokDim.meEdgeHeight,
          decoration: BoxDecoration(color: t.cMeDot, borderRadius: r, border: Border.all(color: t.cMeDotEdge, width: TokDim.surfaceEdgeWidth), boxShadow: TokShadow.meDot),
          child: CustomPaint(painter: InsetShadowPainter(TokInset.buttonPrimary, r)),
        ),
      ]),
    );
  }

  /// Width of the whole mark before rotation.
  static const double width = TokDim.meGlowWidth + TokSpace.x3xs + TokDim.meEdgeWidth;
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Traced from Figma: wide on the inside, narrowing toward the capsule
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, h * 0.27)
      ..lineTo(w, h * 0.73)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..shader = LinearGradient(colors: [color.withValues(alpha: 0), color]).createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(_GlowPainter o) => o.color != color;
}
