import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// Children arrive one after another: each fades in, sharpens from a light blur and settles up from a few
/// pixels below (Emil: 30–80 ms stagger, ease-out, under 300 ms each). Runs once when it's built.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.children, this.spacing = 0, this.crossAxisAlignment = CrossAxisAlignment.stretch});
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Past the first few, the rest come in together with the last one, so a long list doesn't drag on
  int get _steps => widget.children.length.clamp(1, TokMotion.staggerMax);
  Duration get _total => TokMotion.enter + TokMotion.stagger * (_steps - 1);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _total);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? _c.value = 1 : _c.forward();
    });
  }

  @override
  void dispose() {
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
            final start = (TokMotion.stagger * (i < _steps ? i : _steps - 1)).inMicroseconds / total;
            final end = start + TokMotion.enter.inMicroseconds / total;
            final anim = CurvedAnimation(parent: _c, curve: Interval(start, end.clamp(0.0, 1.0), curve: TokMotion.easeOut));
            return AnimatedBuilder(
              animation: anim,
              child: widget.children[i],
              builder: (context, child) {
                final t = anim.value, blur = TokMotion.enterBlur * (1 - t);
                final moved = Transform.translate(offset: Offset(0, TokDim.tabEnterShift * (1 - t)), child: child);
                return Opacity(
                  opacity: t,
                  child: blur < 0.05 ? moved : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: moved),
                );
              },
            );
          }(),
      ],
    );
  }
}

/// How the outgoing tab leaves while the new one staggers in: a short fade with a slight blur.
Widget fadeBlurOut(Animation<double> anim, Widget child) => AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final blur = TokMotion.enterBlur * (1 - anim.value);
        return Opacity(
          opacity: anim.value,
          child: blur < 0.05 ? child : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: child),
        );
      },
    );
