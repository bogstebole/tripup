import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

/// Children arrive one after another: each fades in, sharpens from a light blur and settles into place from
/// [from] (Emil: 30–80 ms stagger, ease-out, under 300 ms each). Waits [delay] first, so whatever is leaving
/// has mostly gone. Runs once when it's built, or once [until] turns true.
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.children,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.from = const Offset(0, TokDim.tabEnterShift),
    this.delay = Duration.zero,
    this.until,
  });
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  /// Where each child starts, relative to its place.
  final Offset from;
  final Duration delay;

  /// Holds the children back (not there yet) until this is true: Your trips under the splash.
  final ValueListenable<bool>? until;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Past the first few, the rest come in together with the last one, so a long list doesn't drag on
  int get _steps => widget.children.length.clamp(1, TokMotion.staggerMax);
  Duration get _total => widget.delay + TokMotion.enter + TokMotion.stagger * (TokMotion.staggerMax - 1);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _total);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = 1;
      } else if (widget.until?.value ?? true) {
        _c.forward();
      } else {
        widget.until!.addListener(_go);
      }
    });
  }

  void _go() {
    if (!widget.until!.value) return;
    widget.until!.removeListener(_go);
    _c.forward();
  }

  @override
  void dispose() {
    widget.until?.removeListener(_go);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _total.inMicroseconds;
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      spacing: widget.spacing,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          () {
            final start = (widget.delay + TokMotion.stagger * (i < _steps ? i : _steps - 1)).inMicroseconds / total;
            final end = start + TokMotion.enter.inMicroseconds / total;
            final anim = CurvedAnimation(parent: _c, curve: Interval(start, end.clamp(0.0, 1.0), curve: TokMotion.easeOut));
            return AnimatedBuilder(
              animation: anim,
              child: widget.children[i],
              builder: (context, child) {
                final t = anim.value, blur = lightEffects ? 0.0 : TokMotion.enterBlur * (1 - t);
                final moved = Transform.translate(offset: widget.from * (1 - t), child: child);
                // The filter stays in the tree, only switched off once sharp: taking it out would rebuild the block
                return Opacity(
                  opacity: t,
                  child: ImageFiltered(enabled: blur >= 0.05, imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: moved),
                );
              },
            );
          }(),
      ],
    );
  }
}

/// How the outgoing tab leaves while the new one staggers in: a short fade with a blur, moving toward [to].
Widget fadeBlurOut(Animation<double> anim, Widget child, {Offset to = Offset.zero}) => AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        // The switcher runs this from 1 down to 0; ease the leaving itself out, so it starts quick
        final v = 1 - TokMotion.easeOut.transform(1 - anim.value.clamp(0.0, 1.0));
        final blur = lightEffects ? 0.0 : TokMotion.enterBlur * (1 - v);
        final moved = Transform.translate(offset: to * (1 - v), child: child);
        return Opacity(
          opacity: v,
          child: ImageFiltered(enabled: blur >= 0.05, imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: moved),
        );
      },
    );
