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

/// The parts of the Up next card, in the order they come in when the mini pin grows into it.
enum MidPart { label, name, rating, fan, chips }

/// Wraps one part of the card (the [index]th of its kind) without changing its layout.
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
              p(MidPart.label, SizedBox(width: double.infinity, child: _NowLabel(plan: plan))),
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
            // Who's coming, or once people arrive, who's already there; then the price range. The two share the width
            // equally until four or more faces need the room, then the price shrinks to its text.
            Expanded(
              child: InfoChips(items: [
                if (here.isEmpty) InfoChip('${people.where((p) => p.going).length} coming', grow: true) else InfoChip('here', faces: here, grow: true),
                if (plan.priceRange case final price?) InfoChip(price, grow: here.length < 4),
              ]),
            ),
            TuButton(icon: TuIcons.forward, label: 'Open ${plan.name}', kind: GlassKind.primary, size: TuButtonSize.sm, onTap: onOpen),
          ])),
        ]),
      ),
    );
  }
}

/// The card's top line: "Up next · 5 PM" until the dinner is on, then "Now", with a dot, and "You're here" once
/// I'm inside its geofence.
class _NowLabel extends StatelessWidget {
  const _NowLabel({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final style = TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.textBrand);
    if (!isActive(plan, now)) return Text('Up next · ${plan.startsAt}', textAlign: TextAlign.center, maxLines: 1, style: style);
    return Row(mainAxisAlignment: MainAxisAlignment.center, spacing: TokSpace.x2xs, children: [
      Container(width: TokSpace.xs, height: TokSpace.xs, decoration: BoxDecoration(color: t.bgBrand, shape: BoxShape.circle)),
      Text(isHere(personById(myId), now) ? "Now · You're here" : 'Now · ${clockTime(plan.start)}', maxLines: 1, style: style),
    ]);
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
              Text(isActive(plan, tripNow()) ? 'Now' : plan.eta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(color: t.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A plan pinned to its place on the map. One surface that morphs between mid, mini and edge with springs,
/// so every change reads as the same object growing or shrinking (see Storybook: Widget/Up next). Between mid and
/// mini its content swaps like the Dynamic Island's: the old leaves, the surface changes size, the new comes in.
class PlanPin extends StatefulWidget {
  const PlanPin({
    super.key,
    required this.plan,
    required this.anchor,
    required this.area,
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

  /// Where pins may sit (the map between the bars, beside the bottom buttons). Outside it the pin goes to the edge.
  final PinArea area;

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

  /// Stickers of whoever is already at the place: on the card's first chip, and on the middle of the mini pin's top edge.
  final List<String> here;

  /// How far a mini pin reaches above its place (card, gap and tail): room to leave when fitting the map around pins.
  static double get miniReach =>
      math.max(TokDim.stickerMini, TokText.labelMd.fontSize! * TokText.labelMd.height! * 2) + TokSpace.xs * 2 + TokSpace.x2xs + PinTail.heightFor(TokSpace.x2xs);

  @override
  State<PlanPin> createState() => _PlanPinState();
}

class _PlanPinState extends State<PlanPin> with TickerProviderStateMixin {
  late final _mid = AnimationController.unbounded(vsync: this)..addListener(_reveal);
  late final _edge = AnimationController.unbounded(vsync: this);

  // What's on the surface. Each content leaves quickly as soon as the surface starts to change, and the next comes
  // in only once the surface is (nearly) its new size: the card's parts one after another from the top, the mini's
  // all at once. So the two never show together.
  late final _cardIn = AnimationController(
    vsync: this,
    duration: TokMotion.openStagger * (MidPart.values.length - 1) + TokMotion.openItem,
    reverseDuration: TokMotion.pinOut,
  );
  late final _miniIn = AnimationController(vsync: this, duration: TokMotion.fade, reverseDuration: TokMotion.pinOut, value: 1);
  Size? _midSize, _miniSize;
  bool _measured = false;
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
    if (_measured) _syncMid();
  }

  void _syncMid() {
    final target = widget.wantMid && !_atEdge ? 1.0 : 0.0;
    if (target == _midTarget) return;
    _midTarget = target;
    if (_jump) {
      _mid.value = target;
      _cardIn.value = target;
      _miniIn.value = 1 - target;
      return;
    }
    (target == 1 ? _miniIn : _cardIn).reverse();
    springTo(_mid, target, TokMotion.springMorph);
  }

  /// The next content comes in once the surface has (nearly) reached its new size.
  void _reveal() {
    if (_midTarget == 1 && _mid.value >= TokMotion.pinInAt && !_cardIn.isForwardOrCompleted) _cardIn.forward();
    if (_midTarget == 0 && _mid.value <= TokMotion.pinMiniAt && !_miniIn.isForwardOrCompleted) _miniIn.forward();
  }

  bool _isOutside(Offset p, double inset) => !widget.area.contains(p, inset);

  // Not on screen (the trip behind your trips), or reduced motion: jump, so it doesn't play out the next time it shows
  bool get _jump => _reduce || !TickerMode.valuesOf(context).enabled;

  void _go(AnimationController c, double target) {
    if (_jump) {
      c.value = target;
    } else {
      springTo(c, target, TokMotion.springMorph);
    }
  }

  @override
  void dispose() {
    _mid.dispose();
    _edge.dispose();
    _cardIn.dispose();
    _miniIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      // Lay out both contents once, unseen, to learn their sizes
      if (!_measured)
        Offstage(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SizeReporter(onSize: (s) => _setSize(mid: s), child: UpNextMid(plan: widget.plan)),
            _SizeReporter(onSize: (s) => _setSize(mini: s), child: _MiniContent(plan: widget.plan)),
          ]),
        ),
      if (_measured)
        AnimatedBuilder(
          animation: Listenable.merge([_mid, _edge, _cardIn, _miniIn]),
          builder: (context, _) => _pin(context),
        ),
    ]);
  }

  void _setSize({Size? mid, Size? mini}) {
    // Android's first frame can come before the screen has a size: wait for a real one
    if ((mid ?? mini)!.isEmpty) return;
    if (mid != null) _midSize = mid;
    if (mini != null) _miniSize = mini;
    if (_midSize != null && _miniSize != null && !_measured) {
      _measured = true;
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
    final edgeCenter = widget.area.clamp(widget.anchor, TokDim.widgetEdgeSize / 2 + TokDim.widgetEdgeArrow + TokDim.widgetEdgeInset);
    final toPlace = widget.anchor - edgeCenter;
    final angle = math.atan2(toPlace.dy, toPlace.dx);
    final center = Offset.lerp(mapCenter, edgeCenter, eC)!;

    // Map ↔ edge: overlapping crossfades, never a frame with neither state showing; a light blur hides the overlap
    final onMapOp = 1 - smoothstep(0.15, 0.65, eC);
    final edgeOp = smoothstep(0.35, 0.85, eC);
    final seam = TokMotion.crossfadeBlur * 4 * onMapOp * edgeOp;
    final arrowDist = edgeSize.width / 2 + TokSpace.x3xs + TokDim.widgetEdgeArrow / 2;
    final hide = widget.hidden ? 0.0 : 1.0;
    final mini = _shown(_miniIn);

    return Stack(clipBehavior: Clip.none, children: [
      // Tail and dash, fading out as the pin goes to the edge. They stay while the card is the full view: the card comes
      // back down onto them, so nothing pops in when it lands
      Positioned(
        left: widget.anchor.dx - TokDim.pinTailWidth / 2,
        top: widget.anchor.dy - tailH,
        child: IgnorePointer(child: Opacity(opacity: 1 - eC, child: PinTail(gap: tailGap))),
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
                      // On the map, both contents sit at their own size, centred: the mini's on the bottom (where the card
                      // grows out of the tail), the card's from the top
                      if (onMapOp > 0)
                        Positioned(
                          left: (size.width - onMap.width) / 2,
                          top: (size.height - onMap.height) / 2,
                          width: onMap.width,
                          height: onMap.height,
                          child: Opacity(
                            opacity: onMapOp,
                            child: Stack(clipBehavior: Clip.none, children: [
                              // The card's content hangs from the surface's top edge, so it rides up as the card grows
                              if (_cardIn.value > 0)
                                Positioned(
                                  left: (onMap.width - midSize.width) / 2,
                                  top: 0,
                                  width: midSize.width,
                                  child: IgnorePointer(
                                    ignoring: m < 0.5 || eC > 0.5,
                                    child: UpNextMid(plan: widget.plan, onOpen: widget.onOpen, here: widget.here, part: (p, i, c) => _fade(c, _cardPart(p))),
                                  ),
                                ),
                              if (mini > 0)
                                Positioned(
                                  left: (onMap.width - miniSize.width) / 2,
                                  top: onMap.height - miniSize.height,
                                  width: miniSize.width,
                                  child: IgnorePointer(child: _fade(_MiniContent(plan: widget.plan), mini, rise: 0)),
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
      // Who's already there, on the middle of the mini pin's top edge, lifted a little off it (on the card they're in
      // the first chip)
      if (widget.here.isNotEmpty && mini > 0 && onMapOp > 0)
        Positioned(
          left: center.dx,
          top: center.dy - size.height / 2 - TokDim.widgetHereLift,
          child: IgnorePointer(
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Opacity(opacity: mini * onMapOp * hide, child: FacePile(faces: widget.here, size: StickerSize.chip)),
            ),
          ),
        ),
    ]);
  }

  /// How much a content shows. Coming in, it eases out; leaving, it fades evenly (the strong ease-out would make it
  /// a cut at this length).
  double _shown(AnimationController c) => c.status == AnimationStatus.reverse ? c.value : TokMotion.easeOut.transform(c.value);

  /// How much a part of the card shows. Coming in, the parts follow one another from the top (label, name, rating,
  /// the fan, the chips); leaving, they all go together.
  double _cardPart(MidPart p) {
    if (_cardIn.status == AnimationStatus.reverse) return _shown(_cardIn);
    final total = _cardIn.duration!.inMicroseconds;
    final start = TokMotion.openStagger.inMicroseconds * p.index / total;
    final t = ((_cardIn.value - start) * total / TokMotion.openItem.inMicroseconds).clamp(0.0, 1.0);
    return TokMotion.easeOut.transform(t);
  }
}

/// A part fading in or out without changing the layout: [k] is how much it shows. It blurs while it's half there and,
/// coming in, rises [rise] into place.
Widget _fade(Widget child, double k, {double rise = TokDim.tabEnterShift}) {
  if (k <= 0.001) return Opacity(opacity: 0, child: child);
  var w = child;
  final sigma = lightEffects ? 0.0 : TokMotion.enterBlur * (1 - k);
  if (sigma > 0.05) w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: w);
  if (rise != 0 && k < 0.999) w = Transform.translate(offset: Offset(0, rise * (1 - k)), child: w);
  return k >= 0.999 ? w : Opacity(opacity: k, child: w);
}

/// Where pins may sit: a rect (the map between the bars) minus a [dock] (the bottom buttons), which pins pass
/// beside but never sit on. The buttons sit in the middle, so the bottom corners stay free for pins.
class PinArea {
  const PinArea(this.rect, {this.dock = Rect.zero});
  final Rect rect;
  final Rect dock;

  /// Whether [p] is inside, by at least [inset].
  bool contains(Offset p, [double inset = 0]) => rect.deflate(inset).contains(p) && (dock.isEmpty || !dock.inflate(inset).contains(p));

  /// The nearest place to [p] where something [reach] across stays inside: clamped into the rect, then lifted
  /// above the dock if it would sit on the buttons.
  Offset clamp(Offset p, double reach) {
    final keep = nonInverted(rect.deflate(reach));
    final c = Offset(p.dx.clamp(keep.left, keep.right), p.dy.clamp(keep.top, keep.bottom));
    final avoid = dock.inflate(reach);
    return !dock.isEmpty && avoid.contains(c) ? Offset(c.dx, avoid.top) : c;
  }
}

/// [r], but never inside out: deflating a small rect, or measuring before the screen has a size (Android's
/// first frame), can put its right edge left of its left one, and clamping into that throws.
Rect nonInverted(Rect r) => Rect.fromLTRB(r.left, r.top, math.max(r.left, r.right), math.max(r.top, r.bottom));

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
      sigma < 0.05 || lightEffects ? child : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child);
}

/// The same seam blur, for other files.
Widget crossfadeSeam({required double sigma, required Widget child}) => _Seam(sigma: sigma, child: child);

/// The size reporter, for other files.
Widget reportSize({required ValueChanged<Size> onSize, required Widget child}) => _SizeReporter(onSize: onSize, child: child);

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
