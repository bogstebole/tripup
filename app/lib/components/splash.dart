// The cold start (Bogdan's reference: amo.co's loading screen, where the loader becomes the page).
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'web_phone_frame.dart';
import 'basics.dart';
import 'map_shapes.dart';
import 'plan_pin.dart' show lerpDouble, smoothstep;

/// Whether the app opens with the splash. The perf and Figma drivers turn it off.
bool splashOnStart = true;

/// The splash, on Your trips' blue (the launch screen's, so there's no cut). My dot pops in, the app's icon; "TripUp"
/// comes in under it; the trip's stickers pop up around them. Then the blue thins out to Your trips, already drawn
/// under it, and the stickers fly onto the current trip's card: the loader becomes the page. Under 2 s; a tap skips
/// ahead to the stickers flying. With reduced motion the app has none (see TripScreen).
class Splash extends StatefulWidget {
  const Splash({super.key, required this.cardKey, required this.onDone});

  /// The current trip's card on Your trips, where the stickers land.
  final GlobalKey cardKey;

  /// The stickers have landed: the card shows its own, and the splash can go.
  final VoidCallback onDone;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final _dot = AnimationController.unbounded(vsync: this);
  late final _word = AnimationController(vsync: this, duration: TokMotion.enter);
  late final _stickers = [for (final _ in homeMapStickers) AnimationController.unbounded(vsync: this)];

  /// 0 on the splash, 1 on the card (a spring, so it overshoots a little).
  late final _fly = AnimationController.unbounded(vsync: this);
  final _timers = <Timer>[];
  bool _assembling = false;

  @override
  void initState() {
    super.initState();
    // From the first frame on screen, not from now: on a cold start the first frame can take a while
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
      if (mounted) _start();
    });
  }

  void _start() {
    springTo(_dot, 1, TokMotion.springPop);
    _after(TokMotion.splashWordAt, _word.forward);
    for (final (i, c) in _stickers.indexed) {
      _after(TokMotion.splashStickersAt + TokMotion.splashStickerStagger * i, () => springTo(c, 1, TokMotion.springPop));
    }
    _after(TokMotion.splashAssembleAt, _assemble);
  }

  void _after(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  void _assemble() {
    if (_assembling) return;
    _assembling = true;
    for (final t in _timers) {
      t.cancel();
    }
    // Skipped: whatever hasn't popped up yet is simply there, and flies with the rest
    for (final c in _stickers) {
      if (!c.isAnimating && c.value == 0) c.value = 1;
    }
    springTo(_fly, 1, TokMotion.springFly).whenCompleteOrCancel(() {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _dot.dispose();
    _word.dispose();
    _fly.dispose();
    for (final c in _stickers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Where the card's sticker [s] sits on screen: the still covers the card from its top centre (see TripCardStill).
  ({Offset center, double height})? _onCard(({String sticker, Offset center, double height, double tilt}) s) {
    final box = widget.cardKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final card = box.localToGlobal(Offset.zero, ancestor: WebPhoneFrame.screen) & box.size;
    final scale = math.max(card.width / homeMapFrame.width, card.height / homeMapFrame.height);
    final origin = card.topLeft + Offset((card.width - homeMapFrame.width * scale) / 2, 0);
    return (center: origin + s.center * scale, height: s.height * scale);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final size = MediaQuery.sizeOf(context);
    final mid = size.center(Offset.zero);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _assemble,
      child: AnimatedBuilder(
        animation: Listenable.merge([_dot, _word, _fly, ..._stickers]),
        builder: (context, _) {
          final f = _fly.value, fC = f.clamp(0.0, 1.0);
          // As the stickers fly, the mark leaves and the blue thins out to Your trips: it's been there all along,
          // drawn under the splash, so revealing it costs nothing (drawing it for the first time here dropped frames)
          final ground = 1 - smoothstep(0.2, 0.8, fC);
          final mark = 1 - smoothstep(0, 0.3, fC);
          final pop = _dot.value, word = TokMotion.easeOut.transform(_word.value);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: Opacity(opacity: ground, child: ColoredBox(color: t.cHomeBg))),
            // My dot and TripUp
            Positioned.fill(
              child: Center(
                child: _blurred(
                  mark,
                  Transform.scale(
                    scale: lerpDouble(TokMotion.pressScale, 1, mark),
                    child: Column(mainAxisSize: MainAxisSize.min, spacing: TokDim.splashWordGap, children: [
                      Opacity(
                        opacity: smoothstep(0, 0.5, pop),
                        child: Transform.scale(
                          scale: lerpDouble(TokMotion.splashPopFrom, 1, pop),
                          child: SizedBox.square(dimension: TokDim.meDot * TokDim.splashDotScale, child: const FittedBox(child: MeDot(ring: true))),
                        ),
                      ),
                      _blurred(
                        word,
                        Transform.translate(
                          offset: Offset(0, TokDim.tabEnterShift * (1 - word)),
                          child: Text('TripUp', style: TokText.display.copyWith(fontSize: TokDim.splashWord, height: 1, color: t.cHomeFg)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            // The trip's stickers: popped up around the mark, then onto the card
            for (final (i, s) in homeMapStickers.indexed)
              () {
                final at = splashStickers[i], p = _stickers[i].value;
                final from = mid + Offset(math.cos(at.angle), math.sin(at.angle)) * TokDim.splashRing * at.reach;
                final to = f > 0 ? _onCard(s) : null;
                final center = to == null ? from : Offset.lerp(from, to.center, f)!;
                final height = to == null ? TokDim.splashSticker : lerpDouble(TokDim.splashSticker, to.height, f);
                final tilt = lerpDouble(at.tilt, s.tilt, fC);
                return Positioned(
                  left: center.dx,
                  top: center.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Opacity(
                      opacity: smoothstep(0, 0.4, p),
                      child: Transform.scale(scale: lerpDouble(TokMotion.splashPopFrom, 1, p), child: Sticker(s.sticker, height: height, tilt: tilt)),
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
