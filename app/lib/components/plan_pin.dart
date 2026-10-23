import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'map_shapes.dart';

/// The Up next card's content (mid state). Also drawn by the full-view morph as its starting picture.
class UpNextMid extends StatelessWidget {
  const UpNextMid({super.key, required this.plan, this.onOpen});
  final Plan plan;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return SizedBox(
      width: TokDim.widgetMidWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.md, TokSpace.xs, TokSpace.xs),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, spacing: TokSpace.md, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
            child: Column(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xs, children: [
              SizedBox(width: double.infinity, child: Text('Up next', textAlign: TextAlign.center, maxLines: 1, style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.textBrand))),
              SizedBox(width: double.infinity, child: Text(plan.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingSm.copyWith(color: t.textDefault))),
              RatingLine(rating: plan.rating, kind: plan.cuisine),
            ]),
          ),
          SizedBox(
            width: double.infinity,
            child: Center(child: Overlapped(overlap: TokDim.stickerOverlap, children: [for (final f in plan.fan) Sticker(f.sticker, height: f.height, tilt: f.tilt)])),
          ),
          Row(spacing: TokSpace.md, children: [
            Expanded(child: InfoChips(items: plan.chips)),
            TuButton(icon: TuIcons.forward, label: 'Open ${plan.name}', kind: GlassKind.primary, size: TuButtonSize.sm, onTap: onOpen),
          ]),
        ]),
      ),
    );
  }
}

/// The mini state's content: sticker, name, when.
class _MiniContent extends StatelessWidget {
  const _MiniContent({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return SizedBox(
      width: TokDim.widgetMiniWidth,
      child: Padding(
        padding: const EdgeInsets.all(TokSpace.xs),
        child: Row(spacing: TokSpace.x2xs, children: [
          Sticker(plan.sticker, size: StickerSize.mini),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(plan.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand)),
              Text(plan.eta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(color: t.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A plan pinned to its place on the map. One surface that morphs between mid, mini and edge with springs,
/// so every change reads as the same object growing or shrinking (see Storybook: Widget/Up next).
class PlanPin extends StatefulWidget {
  const PlanPin({
    super.key,
    required this.plan,
    required this.anchor,
    required this.safe,
    required this.wantMid,
    this.cardKey,
    this.hidden = false,
    this.onOpen,
    this.onTap,
    this.onEdgeChanged,
    this.onMidHeight,
  });

  final Plan plan;

  /// The plan's place on screen, in the map's coordinates. Changes every frame while the map moves.
  final Offset anchor;

  /// Where pins may sit (the map minus the bars). Outside it the pin goes to the edge.
  final Rect safe;

  /// Show the big card (only for Up next, and only until the map moves).
  final bool wantMid;
  final GlobalKey? cardKey;

  /// Hidden while the full view, which grew out of this card, is open.
  final bool hidden;
  final VoidCallback? onOpen;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onEdgeChanged;

  /// The card's full height plus its tail, once measured (the screen uses it to make room above the place).
  final ValueChanged<double>? onMidHeight;

  @override
  State<PlanPin> createState() => _PlanPinState();
}

class _PlanPinState extends State<PlanPin> with TickerProviderStateMixin {
  late final _mid = AnimationController.unbounded(vsync: this);
  late final _edge = AnimationController.unbounded(vsync: this);
  Size? _midSize, _miniSize;
  bool _atEdge = false;

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  double _midTarget = 0;

  @override
  void initState() {
    super.initState();
    _atEdge = _isOutside(widget.anchor, 0);
    _edge.value = _atEdge ? 1 : 0;
  }

  @override
  void didUpdateWidget(PlanPin old) {
    super.didUpdateWidget(old);
    // Hysteresis: once at the edge, come back only when the place is a little way inside
    final outside = _isOutside(widget.anchor, _atEdge ? TokSpace.md : 0);
    if (outside != _atEdge) {
      _atEdge = outside;
      _go(_edge, outside ? 1 : 0);
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.onEdgeChanged?.call(outside));
    }
    if (_midSize != null) _syncMid();
  }

  void _syncMid() {
    final target = widget.wantMid && !_atEdge ? 1.0 : 0.0;
    if (target != _midTarget) {
      _midTarget = target;
      _go(_mid, target);
    }
  }

  bool _isOutside(Offset p, double inset) => !widget.safe.deflate(inset).contains(p);

  void _go(AnimationController c, double target) {
    if (_reduce) {
      c.value = target;
    } else {
      springTo(c, target, TokMotion.springMorph);
    }
  }

  @override
  void dispose() {
    _mid.dispose();
    _edge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final measured = _midSize != null && _miniSize != null;
    return Stack(clipBehavior: Clip.none, children: [
      // Lay out both contents once, unseen, to learn their natural sizes
      if (!measured)
        Offstage(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SizeReporter(onSize: (s) => _setSize(mid: s), child: UpNextMid(plan: widget.plan)),
            _SizeReporter(onSize: (s) => _setSize(mini: s), child: _MiniContent(plan: widget.plan)),
          ]),
        ),
      if (measured)
        AnimatedBuilder(
          animation: Listenable.merge([_mid, _edge]),
          builder: (context, _) => _pin(context),
        ),
    ]);
  }

  void _setSize({Size? mid, Size? mini}) {
    if (mid != null && _midSize != mid) _midSize = mid;
    if (mini != null && _miniSize != mini) _miniSize = mini;
    if (_midSize != null && _miniSize != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onMidHeight?.call(_midSize!.height + TokSpace.xs + PinTail.heightFor(TokSpace.xs));
        setState(() {});
        _syncMid();   // the pop-up when the trip opens: the mini pin grows into the card
      });
    }
  }

  Widget _pin(BuildContext context) {
    final m = _mid.value, e = _edge.value.clamp(0.0, 1.2);
    final eC = e.clamp(0.0, 1.0);
    const edgeSize = Size.square(TokDim.widgetEdgeSize);
    final onMap = Size.lerp(_miniSize, _midSize, m)!;
    final size = Size.lerp(onMap, edgeSize, e)!;
    final radius = lerpDouble(TokDim.surfaceRadius, edgeSize.shortestSide / 2, eC);

    // Where the card sits on the map: bottom of the tail on the place
    final tailGap = lerpDouble(TokSpace.x2xs, TokSpace.xs, m.clamp(0.0, 1.0));
    final tailH = PinTail.heightFor(tailGap);
    // The card stays on screen near the sides; only the tail keeps pointing at the place
    final half = onMap.width / 2, screen = MediaQuery.sizeOf(context).width;
    final cardX = widget.anchor.dx.clamp(TokDim.widgetEdgeInset + half, math.max(TokDim.widgetEdgeInset + half, screen - TokDim.widgetEdgeInset - half)).toDouble();
    final mapCenter = Offset(cardX, widget.anchor.dy - tailH - tailGap - onMap.height / 2);

    // Where it sits at the edge: clamped inside the safe area, arrow toward the place
    final keep = widget.safe.deflate(TokDim.widgetEdgeSize / 2 + TokDim.widgetEdgeArrow + TokDim.widgetEdgeInset);
    final edgeCenter = Offset(widget.anchor.dx.clamp(keep.left, keep.right), widget.anchor.dy.clamp(keep.top, keep.bottom));
    final toPlace = widget.anchor - edgeCenter;
    final angle = math.atan2(toPlace.dy, toPlace.dx);
    final center = Offset.lerp(mapCenter, edgeCenter, eC)!;

    // Overlapping crossfades, never a frame with neither state showing; a light blur hides the overlap
    final onMapOp = 1 - smoothstep(0.15, 0.65, eC);
    final edgeOp = smoothstep(0.35, 0.85, eC);
    final midOp = smoothstep(0.35, 0.85, m) * onMapOp;
    final miniOp = (1 - smoothstep(0.15, 0.65, m)) * onMapOp;
    final seam = TokMotion.crossfadeBlur * 4 * math.max(smoothstep(0.35, 0.85, m) * (1 - smoothstep(0.15, 0.65, m)), onMapOp * edgeOp);
    // The card's content shrinks with the surface instead of being cut off by it (it's gone before it gets small)
    final midScale = math.min(1.0, size.width / _midSize!.width);
    final arrowDist = edgeSize.width / 2 + TokSpace.x3xs + TokDim.widgetEdgeArrow / 2;
    final hide = widget.hidden ? 0.0 : 1.0;

    return Stack(clipBehavior: Clip.none, children: [
      // Tail and dash, fading out as the pin goes to the edge
      Positioned(
        left: widget.anchor.dx - TokDim.pinTailWidth / 2,
        top: widget.anchor.dy - tailH,
        child: IgnorePointer(child: Opacity(opacity: (1 - eC) * hide, child: PinTail(gap: tailGap))),
      ),
      // Edge arrow
      if (eC > 0)
        Positioned(
          left: edgeCenter.dx + math.cos(angle) * arrowDist - TokDim.widgetEdgeArrow / 2,
          top: edgeCenter.dy + math.sin(angle) * arrowDist - TokDim.widgetEdgeArrow / 2,
          child: IgnorePointer(child: Opacity(opacity: edgeOp * hide, child: EdgeArrow(angle: angle))),
        ),
      Positioned(
        left: center.dx - size.width / 2,
        top: center.dy - size.height / 2,
        width: size.width,
        height: size.height,
        child: Opacity(
          opacity: hide,
          child: IgnorePointer(
            ignoring: widget.hidden,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (m > 0.5 && eC < 0.5) {
                  HapticFeedback.lightImpact();
                  widget.onOpen?.call();
                } else {
                  HapticFeedback.mediumImpact();   // focusing a pin: a heavier tick than a button
                  widget.onTap?.call();
                }
              },
              child: Semantics(
                button: true,
                label: m > 0.5 ? 'Open ${widget.plan.name}' : '${widget.plan.name}, ${widget.plan.eta}',
                child: Container(
                  key: widget.cardKey,
                  decoration: surfaceDecoration(context, BorderRadius.circular(radius)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: _Seam(sigma: seam, child: Stack(clipBehavior: Clip.hardEdge, children: [
                      if (midOp > 0)
                        Positioned(
                          top: 0,
                          left: (size.width - _midSize!.width) / 2,
                          child: Opacity(opacity: midOp, child: Transform.scale(scale: midScale, alignment: Alignment.topCenter, child: UpNextMid(plan: widget.plan, onOpen: widget.onOpen))),
                        ),
                      if (miniOp > 0)
                        Positioned(
                          top: (size.height - _miniSize!.height) / 2,
                          left: (size.width - _miniSize!.width) / 2,
                          child: Opacity(opacity: miniOp, child: _MiniContent(plan: widget.plan)),
                        ),
                      if (edgeOp > 0)
                        Positioned.fill(child: Opacity(opacity: edgeOp, child: Center(child: Sticker(widget.plan.sticker, size: StickerSize.edge)))),
                    ])),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// 0 before [a], 1 after [b], an S-curve between: for crossfade windows driven by a spring's progress.
double smoothstep(double a, double b, double v) {
  final t = ((v - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Blurs its child slightly while two states overlap, so the crossfade reads as one object changing.
class _Seam extends StatelessWidget {
  const _Seam({required this.sigma, required this.child});
  final double sigma;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      sigma < 0.05 ? child : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child);
}

/// The same seam blur, for other files.
Widget crossfadeSeam({required double sigma, required Widget child}) => _Seam(sigma: sigma, child: child);

/// Reports its child's size after layout.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});
  final ValueChanged<Size> onSize;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);
  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter r) => r.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);
  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      final s = size;
      SchedulerBinding.instance.addPostFrameCallback((_) => onSize(s));
    }
  }
}
