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

/// The parts of the Up next card that move on their own while it morphs to and from the mini pin.
enum MidPart { label, name, rating, fan, chips }

/// The mini pin's parts.
enum MiniPart { sticker, name, eta }

/// Wraps one part of a layout (the [index]th of its kind) without changing the layout.
typedef PartWrap<P> = Widget Function(P part, int index, Widget child);

/// The Up next card's content (mid state). Also drawn by the full-view morph as its starting picture.
class UpNextMid extends StatelessWidget {
  const UpNextMid({super.key, required this.plan, this.onOpen, this.part, this.here = const []});
  final Plan plan;
  final VoidCallback? onOpen;

  /// Stickers of whoever is already at the place.
  final List<String> here;

  /// Lets the pin move each part on its own while it morphs. Nothing by default.
  final PartWrap<MidPart>? part;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    Widget p(MidPart k, Widget child, [int i = 0]) => part?.call(k, i, child) ?? child;
    return SizedBox(
      width: TokDim.widgetMidWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.md, TokSpace.xs, TokSpace.xs),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, spacing: TokSpace.md, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
            child: Column(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xs, children: [
              p(MidPart.label, SizedBox(width: double.infinity, child: Text('Up next · ${plan.startsAt}', textAlign: TextAlign.center, maxLines: 1, style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.textBrand)))),
              p(MidPart.name, SizedBox(width: double.infinity, child: Text(plan.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingSm.copyWith(color: t.textDefault)))),
              p(MidPart.rating, RatingLine(rating: plan.rating, kind: plan.cuisine)),
            ]),
          ),
          SizedBox(
            width: double.infinity,
            child: Center(child: Overlapped(overlap: TokDim.stickerOverlap, children: [
              for (final (i, f) in plan.fan.indexed) p(MidPart.fan, Sticker(f.sticker, height: f.height, tilt: f.tilt), i),
            ])),
          ),
          p(MidPart.chips, Row(spacing: TokSpace.md, children: [
            // Equal-width chips: the first says who's coming, or once people arrive, who's already there
            Expanded(
              child: InfoChips(items: [
                if (here.isNotEmpty) InfoChip('${here.length} here', faces: here, grow: true) else ...plan.chips.take(1),
                ...plan.chips.skip(1),
              ]),
            ),
            TuButton(icon: TuIcons.forward, label: 'Open ${plan.name}', kind: GlassKind.primary, size: TuButtonSize.sm, onTap: onOpen),
          ])),
        ]),
      ),
    );
  }
}

/// The mini state's content: sticker, name, when.
class _MiniContent extends StatelessWidget {
  const _MiniContent({required this.plan, this.part});
  final Plan plan;
  final PartWrap<MiniPart>? part;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    Widget p(MiniPart k, Widget child) => part?.call(k, 0, child) ?? child;
    return SizedBox(
      width: TokDim.widgetMiniWidth,
      child: Padding(
        padding: const EdgeInsets.all(TokSpace.xs),
        child: Row(spacing: TokSpace.x2xs, children: [
          p(MiniPart.sticker, Sticker(plan.sticker, size: StickerSize.mini)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              p(MiniPart.name, Text(plan.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand))),
              p(MiniPart.eta, Text(plan.eta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(color: t.textMuted))),
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
    this.here = const [],
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

  /// Stickers of whoever is already at the place: on the card's first chip, and on the mini pin's corner.
  final List<String> here;

  /// How far a mini pin reaches above its place (card, gap and tail): room to leave when fitting the map around pins.
  static double get miniReach =>
      math.max(TokDim.stickerMini, TokText.labelMd.fontSize! * TokText.labelMd.height! * 2) + TokSpace.xs * 2 + TokSpace.x2xs + PinTail.heightFor(TokSpace.x2xs);

  @override
  State<PlanPin> createState() => _PlanPinState();
}

class _PlanPinState extends State<PlanPin> with TickerProviderStateMixin {
  late final _mid = AnimationController.unbounded(vsync: this);
  late final _edge = AnimationController.unbounded(vsync: this);
  Size? _midSize, _miniSize;
  final _probe = _Probe();
  _Geo? _geo;
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
    return Stack(clipBehavior: Clip.none, children: [
      // Lay out both contents once, unseen, to learn their sizes and where each part sits
      if (_geo == null)
        Offstage(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SizeReporter(
              onSize: (s) => _setSize(mid: s),
              child: KeyedSubtree(key: _probe.midRoot, child: UpNextMid(plan: widget.plan, part: (p, i, c) => KeyedSubtree(key: _probe.midKey(p, i), child: c))),
            ),
            _SizeReporter(
              onSize: (s) => _setSize(mini: s),
              child: KeyedSubtree(key: _probe.miniRoot, child: _MiniContent(plan: widget.plan, part: (p, i, c) => KeyedSubtree(key: _probe.miniKey(p), child: c))),
            ),
          ]),
        ),
      if (_geo != null)
        AnimatedBuilder(
          animation: Listenable.merge([_mid, _edge]),
          builder: (context, _) => _pin(context),
        ),
    ]);
  }

  void _setSize({Size? mid, Size? mini}) {
    if (mid != null) _midSize = mid;
    if (mini != null) _miniSize = mini;
    if (_midSize != null && _miniSize != null && _geo == null) {
      final shared = widget.plan.fan.indexWhere((f) => f.sticker == widget.plan.sticker);
      _geo = _probe.read(_midSize!, _miniSize!, sharedFan: shared < 0 ? null : shared);
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
    final midSize = _midSize!, miniSize = _miniSize!;
    final onMap = Size.lerp(miniSize, midSize, m)!;
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

    // Map ↔ edge: overlapping crossfades, never a frame with neither state showing; a light blur hides the overlap
    final onMapOp = 1 - smoothstep(0.15, 0.65, eC);
    final edgeOp = smoothstep(0.35, 0.85, eC);
    final seam = TokMotion.crossfadeBlur * 4 * onMapOp * edgeOp;
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
                      // On the map, both layouts sit on the card's bottom centre (where it grows out of the tail),
                      // and their parts travel between the two: see _midPart and _miniPart
                      if (onMapOp > 0)
                        Positioned(
                          left: (size.width - onMap.width) / 2,
                          top: (size.height - onMap.height) / 2,
                          width: onMap.width,
                          height: onMap.height,
                          child: Opacity(
                            opacity: onMapOp,
                            child: Stack(clipBehavior: Clip.none, children: [
                              if (m > 0.001)
                                Positioned(
                                  left: (onMap.width - midSize.width) / 2,
                                  top: onMap.height - midSize.height,
                                  width: midSize.width,
                                  child: IgnorePointer(
                                    ignoring: m < 0.5 || eC > 0.5,
                                    child: UpNextMid(plan: widget.plan, onOpen: widget.onOpen, here: widget.here, part: (p, i, c) => _midPart(p, i, c, m)),
                                  ),
                                ),
                              if (m < 0.999)
                                Positioned(
                                  left: (onMap.width - miniSize.width) / 2,
                                  top: onMap.height - miniSize.height,
                                  width: miniSize.width,
                                  child: IgnorePointer(child: _MiniContent(plan: widget.plan, part: (p, i, c) => _miniPart(p, c, m))),
                                ),
                            ]),
                          ),
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
      // Who's already there, on the mini pin's corner (on the card they're in the first chip)
      if (widget.here.isNotEmpty && m < 0.5 && onMapOp > 0)
        Positioned(
          left: center.dx + size.width / 2,
          top: center.dy - size.height / 2,
          child: IgnorePointer(
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Opacity(opacity: (1 - smoothstep(0, 0.5, m)) * onMapOp * hide, child: FacePile(faces: widget.here, size: StickerSize.chip)),
            ),
          ),
        ),
    ]);
  }

  // Card ↔ mini pin, as one object. m is how far the pin is toward the card (0 mini, 1 card; a spring, so it overshoots a little).
  // · The plan's sticker is the same picture in both: it travels from the mini's slot into the middle of the fan, growing.
  // · The name slides between its two places, scaling with its type size, and crossfades between the two styles.
  // · Everything else hangs on those two: the label and rating ride with the name, the fan opens out from the sticker,
  //   the eta leaves with the mini name. The chips are the card's own and rise in at its bottom last.
  // Parts that fade also blur while they're half there, so a crossfade reads as one thing changing.

  Widget _midPart(MidPart p, int i, Widget child, double m) {
    final g = _geo!;
    final own = g.mid[(p, i)];
    if (own == null) return Opacity(opacity: smoothstep(0.5, 1, m), child: child);
    final u = 1 - m;
    switch (p) {
      case MidPart.label || MidPart.name || MidPart.rating:
        final from = g.mini[MiniPart.name], to = g.mid[(MidPart.name, 0)];
        final shift = from == null || to == null ? Offset.zero : (from.center - to.center) * u;
        final scale = from == null || to == null ? 1.0 : lerpDouble(1, from.height / to.height, u);
        final op = p == MidPart.name ? smoothstep(0.25, 0.65, m) : smoothstep(0.45, 0.9, m);
        return _move(child, rect: own, pivot: (to ?? own).center, shift: shift, scale: scale, opacity: op);
      case MidPart.fan:
        final si = g.sharedFan, from = g.mini[MiniPart.sticker];
        final hub = si == null ? null : g.mid[(MidPart.fan, si)];
        if (hub == null || from == null) {
          return _move(child, rect: own, pivot: own.center, scale: lerpDouble(TokMotion.morphEnterScale, 1, m.clamp(0.0, 1.0)), opacity: smoothstep(0.35, 0.8, m));
        }
        final hubShift = (from.center - hub.center) * u;
        final hubScale = lerpDouble(1, from.height / hub.height, u);
        // The shared sticker: swaps with the mini's copy halfway, where both are the same size in the same place
        if (i == si) return _move(child, rect: own, pivot: own.center, shift: hubShift, scale: hubScale, opacity: m >= 0.5 ? 1 : 0, blur: false);
        // The others open out from behind it
        final k = smoothstep(0.15, 1, m);
        final at = hub.center + hubShift + (own.center - hub.center) * hubScale * k;
        return _move(child, rect: own, pivot: own.center, shift: at - own.center, scale: hubScale * lerpDouble(TokMotion.morphEnterScale, 1, k), opacity: smoothstep(0.2, 0.7, m));
      case MidPart.chips:
        final k = smoothstep(0.55, 1, m);
        return _move(child, rect: own, pivot: own.bottomCenter, scale: lerpDouble(TokMotion.morphEnterScale, 1, k), opacity: k);
    }
  }

  Widget _miniPart(MiniPart p, Widget child, double m) {
    final g = _geo!;
    final own = g.mini[p];
    if (own == null) return Opacity(opacity: 1 - smoothstep(0, 0.5, m), child: child);
    switch (p) {
      case MiniPart.sticker:
        final hub = g.sharedFan == null ? null : g.mid[(MidPart.fan, g.sharedFan!)];
        if (hub == null) return _move(child, rect: own, pivot: own.center, opacity: 1 - smoothstep(0.1, 0.5, m));
        return _move(child, rect: own, pivot: own.center, shift: (hub.center - own.center) * m, scale: lerpDouble(1, hub.height / own.height, m), opacity: m < 0.5 ? 1 : 0, blur: false);
      case MiniPart.name || MiniPart.eta:
        final from = g.mini[MiniPart.name]!, to = g.mid[(MidPart.name, 0)];
        final shift = to == null ? Offset.zero : (to.center - from.center) * m;
        final scale = to == null ? 1.0 : lerpDouble(1, to.height / from.height, m);
        final op = p == MiniPart.name ? 1 - smoothstep(0.25, 0.65, m) : 1 - smoothstep(0.05, 0.4, m);
        return _move(child, rect: own, pivot: from.center, shift: shift, scale: scale, opacity: op);
    }
  }
}

/// Moves a part by [shift] and scales it by [scale] about [pivot], then fades it (blurring while it's half there).
/// [rect] is where the layout put the part; [rect] and [pivot] are in the pin's own frame. Layout is left as it was.
Widget _move(Widget child, {required Rect rect, required Offset pivot, Offset shift = Offset.zero, double scale = 1, double opacity = 1, bool blur = true}) {
  if (opacity <= 0.001) return Opacity(opacity: 0, child: child);
  var w = child;
  final sigma = blur ? TokMotion.enterBlur * (1 - opacity) : 0.0;
  if (sigma > 0.05) w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: w);
  if (shift != Offset.zero || scale != 1) {
    final local = pivot - rect.topLeft;
    final t = shift + local * (1 - scale);
    w = Transform(transform: Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(t.dx, t.dy, 0), child: w);
  }
  return opacity >= 0.999 ? w : Opacity(opacity: opacity, child: w);
}

/// Finds where each part of the two layouts sits, from the unseen pass.
class _Probe {
  final midRoot = GlobalKey(), miniRoot = GlobalKey();
  final _mid = <(MidPart, int), GlobalKey>{};
  final _mini = <MiniPart, GlobalKey>{};

  GlobalKey midKey(MidPart p, int i) => _mid.putIfAbsent((p, i), GlobalKey.new);
  GlobalKey miniKey(MiniPart p) => _mini.putIfAbsent(p, GlobalKey.new);

  /// Rects in the pin's own frame: origin at each layout's bottom centre, where the card meets the tail.
  _Geo read(Size mid, Size mini, {int? sharedFan}) {
    Rect? rectOf(GlobalKey k, GlobalKey root, Size s) {
      final box = k.currentContext?.findRenderObject(), base = root.currentContext?.findRenderObject();
      if (box is! RenderBox || base is! RenderBox || !box.hasSize) return null;
      return (box.localToGlobal(Offset.zero, ancestor: base) & box.size).shift(Offset(-s.width / 2, -s.height));
    }

    return _Geo(
      mid: {for (final e in _mid.entries) e.key: ?rectOf(e.value, midRoot, mid)},
      mini: {for (final e in _mini.entries) e.key: ?rectOf(e.value, miniRoot, mini)},
      sharedFan: sharedFan,
    );
  }
}

class _Geo {
  const _Geo({required this.mid, required this.mini, this.sharedFan});
  final Map<(MidPart, int), Rect> mid;
  final Map<MiniPart, Rect> mini;

  /// Which fan sticker is the mini's sticker (the one that travels), if any.
  final int? sharedFan;
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
