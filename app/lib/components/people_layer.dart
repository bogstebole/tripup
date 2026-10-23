import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data.dart';
import '../design/tokens.dart';
import 'basics.dart';

/// The group's live locations on the map (simulated on the demo clock). People close together on screen
/// merge into one pile with "+N", so a group walking together never turns into a heap; whoever has arrived
/// leaves the map and shows on the place's pin instead. Nobody taps anything for any of it.
class PeopleLayer extends StatefulWidget {
  const PeopleLayer({super.key, required this.shown});

  /// Off when the day filter leaves today out.
  final bool shown;

  @override
  State<PeopleLayer> createState() => _PeopleLayerState();
}

class _PeopleLayerState extends State<PeopleLayer> {
  // Walking moves about a pixel every few seconds at this zoom, so a few seconds between updates is smooth enough
  late final Timer _tick = Timer.periodic(const Duration(seconds: 5), (_) => setState(() {}));

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final now = tripNow();
    // Everyone on their way (or about to leave), where they are on screen
    final dots = [
      for (final p in people)
        if (p.id != myId && !isHere(p, now))
          if (whereIs(p, now) case final at?) (p, cam.latLngToScreenOffset(at)),
    ];
    // Merge whoever overlaps on screen: each joins the first pile within a sticker's width of them
    final piles = <({List<Person> who, Offset at})>[];
    for (final (p, at) in dots) {
      final i = piles.indexWhere((g) => (g.at - at).distance < TokDim.stickerAvatar);
      if (i < 0) {
        piles.add((who: [p], at: at));
      } else {
        final g = piles[i];
        piles[i] = (who: [...g.who, p], at: (g.at * g.who.length.toDouble() + at) / (g.who.length + 1.0));
      }
    }
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.shown ? 1 : 0,
        duration: TokMotion.enter,
        curve: TokMotion.easeOut,
        child: Stack(children: [
          for (final g in piles)
            Positioned(
              left: g.at.dx,
              top: g.at.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Semantics(
                  label: '${g.who.map((p) => p.name).join(', ')}: ${g.who.map((p) => statusOf(p, now)).join(', ')}',
                  child: FacePile(faces: [for (final p in g.who) p.sticker]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
