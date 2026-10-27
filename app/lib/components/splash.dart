// The cold start (Bogdan's reference: amo.co's loading screen; reworked 27 Oct: stickers everywhere, then the page slides in).
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'map_shapes.dart';
import 'plan_pin.dart' show lerpDouble, smoothstep;

/// Whether the app opens with the splash. The perf and Figma drivers turn it off.
bool splashOnStart = true;

/// The splash, on Your trips' blue (the launch screen's, so there's no cut). My dot pops in, the app's icon, and small
/// stickers pop up one after another at random spots all over the screen; "TripUp" comes in under the dot. The
/// stickers pop away the way they came, in the same order. Then the dot and TripUp slide out to the left, one after
/// the other, and Your trips slides in from the right, a row at a time. Under 2 s; a tap skips to the leaving. With
/// reduced motion the app has none (see TripScreen).
class Splash extends StatefulWidget {
  const Splash({super.key, required this.onLeave, required this.onDone});

  /// The mark starts to leave: Your trips can come in.
  final VoidCallback onLeave;

  /// The mark has gone, and the splash can go.
  final VoidCallback onDone;

  @override
  State<Splash> createState() => _SplashState();
}

typedef _Spot = ({String sticker, Offset center, double tilt});

/// The longest the splash waits for the stickers to decode (a slow web load), before it starts without them ready.
const _decodeWait = Duration(milliseconds: 500);

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final _dot = AnimationController.unbounded(vsync: this);
  late final _word = AnimationController(vsync: this, duration: TokMotion.enter);

  /// 0 → 1 as the dot, then TripUp, slide out.
  late final _leave = AnimationController(vsync: this, duration: TokMotion.enter + TokMotion.splashLeaveStagger);
  final _markKey = GlobalKey();
  final _timers = <Timer>[];
  final _random = math.Random();
  late final _names = [...splashStickers]..shuffle(_random);

  /// This launch's stickers, in the order they pop, and how far each has popped in (0 to 1, a spring).
  var _spots = <_Spot>[];
  var _pops = <AnimationController>[];
  bool _started = false, _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Decoded before they pop, so none comes in empty and fills in a frame later (they're Your trips' own, so it's
    // work that screen needs anyway). From the first frame on screen, not from now: on a cold start it can take a while.
    final decoded = Future.wait([for (final n in _names) precacheImage(AssetImage('assets/stickers/$n.png'), context)]);
    Future.wait([WidgetsBinding.instance.waitUntilFirstFrameRasterized, decoded.timeout(_decodeWait, onTimeout: () => [])]).then((_) {
      if (mounted && !_leaving) _start();
    });
  }

  void _start() {
    _scatter();
    springTo(_dot, 1, TokMotion.springPop);
    _after(TokMotion.splashWordAt, _word.forward);
    for (final (i, c) in _pops.indexed) {
      _after(TokMotion.splashStickersAt + TokMotion.splashStickerStagger * i, () => springTo(c, 1, TokMotion.springPop));
      _after(TokMotion.splashStickersOutAt + TokMotion.splashStickerStagger * i, () => springTo(c, 0, TokMotion.springPop));
    }
    _after(TokMotion.splashLeaveAt, _goAway);
  }

  void _after(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  /// At most one sticker in each cell of a 3 × 4 grid over the screen (inside its safe area), at a random spot in the
  /// cell and clear of the mark: everywhere, but never on top of one another or of TripUp.
  void _scatter() {
    final box = context.findRenderObject(), mark = _markKey.currentContext?.findRenderObject();
    if (box is! RenderBox || mark is! RenderBox) return;
    const cols = 3, rows = 4, s = TokDim.splashSticker;
    final keepOut = (mark.localToGlobal(Offset.zero, ancestor: box) & mark.size).inflate(s);
    final area = MediaQuery.paddingOf(context).deflateRect(Offset.zero & box.size).deflate(TokSpace.md);
    final cw = area.width / cols, ch = area.height / rows;
    final spots = <_Spot>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // A sticker's room in from the cell's edges, so two neighbours can't overlap
        final cell = Rect.fromLTWH(area.left + c * cw, area.top + r * ch, cw, ch).deflate(s / 2 + TokSpace.x2xs);
        for (var tries = 0; tries < 8; tries++) {
          final at = cell.topLeft + Offset(_random.nextDouble() * cell.width, _random.nextDouble() * cell.height);
          if (keepOut.contains(at)) continue;
          spots.add((sticker: _names[spots.length], center: at, tilt: (_random.nextDouble() * 2 - 1) * splashStickerTilt));
          break;
        }
      }
    }
    // They pop in a random order, not row by row
    setState(() {
      _spots = spots..shuffle(_random);
      _pops = [for (final _ in spots) AnimationController.unbounded(vsync: this)];
    });
  }

  /// The mark slides out and Your trips comes in behind it. Skipped: TripUp finishes coming in as it goes, and the
  /// stickers still up pop away together.
  void _goAway() {
    if (_leaving) return;
    _leaving = true;
    for (final t in _timers) {
      t.cancel();
    }
    _word.forward();
    for (final c in _pops) {
      if (c.value > 0) springTo(c, 0, TokMotion.springPop);
    }
    setState(() {});
    // Your trips comes in once TripUp is half way out, so the two don't read over each other
    _after(TokMotion.splashLeaveStagger + TokMotion.enter ~/ 2, widget.onLeave);
    _leave.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _dot.dispose();
    _word.dispose();
    _leave.dispose();
    for (final c in _pops) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goAway,
      child: AnimatedBuilder(
        animation: Listenable.merge([_dot, _word, _leave, ..._pops]),
        builder: (context, _) {
          final pop = _dot.value, word = TokMotion.easeOut.transform(_word.value);
          // Each slides for enter-ms, TripUp splash-leave-stagger-ms after the dot
          final step = TokMotion.enter.inMicroseconds / _leave.duration!.inMicroseconds;
          final dotOut = Interval(0, step, curve: TokMotion.easeOut).transform(_leave.value);
          final wordOut = Interval(1 - step, 1, curve: TokMotion.easeOut).transform(_leave.value);
          return Stack(clipBehavior: Clip.none, children: [
            // The same blue as Your trips, whose rows are held back until the mark leaves; so it can go at once
            Positioned.fill(child: Opacity(opacity: _leaving ? 0 : 1, child: ColoredBox(color: t.cHomeBg))),
            // My dot and TripUp
            Positioned.fill(
              child: Center(
                child: Column(key: _markKey, mainAxisSize: MainAxisSize.min, spacing: TokDim.splashWordGap, children: [
                  _sliding(
                    dotOut,
                    Opacity(
                      opacity: smoothstep(0, 0.5, pop),
                      child: Transform.scale(
                        scale: lerpDouble(TokMotion.splashPopFrom, 1, pop),
                        child: SizedBox.square(dimension: TokDim.meDot * TokDim.splashDotScale, child: const FittedBox(child: MeDot(ring: true))),
                      ),
                    ),
                  ),
                  _sliding(
                    wordOut,
                    _blurred(
                      word,
                      Transform.translate(
                        offset: Offset(0, TokDim.tabEnterShift * (1 - word)),
                        child: Text('TripUp', style: TokText.display.copyWith(fontSize: TokDim.splashWord, height: 1, color: t.cHomeFg)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            // The stickers, small, all over the screen
            for (final (i, s) in _spots.indexed)
              () {
                final p = _pops[i].value;
                return Positioned(
                  left: s.center.dx,
                  top: s.center.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Opacity(
                      opacity: smoothstep(0, 0.4, p),
                      child: Transform.scale(
                        scale: lerpDouble(TokMotion.splashPopFrom, 1, p),
                        child: Sticker(s.sticker, height: TokDim.splashSticker, tilt: s.tilt),
                      ),
                    ),
                  ),
                );
              }(),
          ]);
        },
      ),
    );
  }
}

/// [child] at [k] opacity, blurred while it's half there.
Widget _blurred(double k, Widget child) {
  if (k <= 0.001) return Opacity(opacity: 0, child: child);
  final sigma = lightEffects ? 0.0 : TokMotion.enterBlur * (1 - k);
  final w = sigma < 0.05 ? child : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child);
  return k >= 0.999 ? w : Opacity(opacity: k, child: w);
}

/// [child] leaving to the left as [k] goes from 0 to 1, the way Your trips' rows come in from the right. It fades and
/// blurs late, so the slide is what you see. The same widgets all the way, so the mark isn't rebuilt when it starts
/// to move.
Widget _sliding(double k, Widget child) {
  final gone = smoothstep(0.3, 1, k), sigma = lightEffects ? 0.0 : TokMotion.enterBlur * gone;
  return Transform.translate(
    offset: Offset(-TokDim.splashSlide * k, 0),
    child: Opacity(
      opacity: 1 - gone,
      child: ImageFiltered(enabled: sigma >= 0.05, imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child),
    ),
  );
}
