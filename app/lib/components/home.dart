// The first screen: your trips (Figma 258:12058).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../startup_timings.dart';
import 'basics.dart';
import 'glass.dart';
import 'stagger.dart';

// Its own measurements: used only here, so they're not tokens.
const double _heroBody = 356;       // the trip's name, dates, faces and button sit centred in this much, under the header
const double _heroTitle = 40;       // the trip's name: the screen's one big line, bigger than any text style
const double _heroFace = 57;
const double _heroFaceOverlap = 22;
const double _heroFaceOnButton = 8; // the faces stand this far over the button
const double _nowDot = 10;
const double _nowDotGlow = 2;
const double _rowSticker = 48;
const double _rowFaceOverlap = 18;
const double _rowFaces = 80;        // the faces' column at a row's end
const double _tripsFade = 275;      // under the map, the blue goes from clear to solid over this much
const double _tripsBlur = 2;
const double _bottomFade = 120;

/// Your trips. The one you're on fills the top of the screen: its city's map, its name big in the middle, who's on it
/// and the way in ("See trip details"). Under it, on the brand blue rising over the map, the trip coming up and the ones
/// before, as soft cards. Tapping the trip goes into its map, which opens out of the top ([heroHeight]). On a cold start
/// it waits under the splash and slides in from the right, a part at a time, as the splash's mark slides out to the left
/// ([homeIn]).
class TripsHome extends StatelessWidget {
  const TripsHome({super.key, required this.onOpen, this.cardKey});
  final VoidCallback onOpen;

  /// On the trip you're on (the top of the screen), so the trip can open out of it.
  final GlobalKey? cardKey;

  /// How tall the trip you're on is: the header under the status bar, then its name and the way in.
  static double heroHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + TokSpace.md + TokDim.buttonMd + TokSpace.md + _heroBody + TokSpace.md;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    final hero = heroHeight(context);
    // The parts arrive at the splash's pace, from where its mark went
    StaggerIn arriving(List<Widget> children) => StaggerIn(
          until: homeIn,
          from: const Offset(TokDim.splashSlide, 0),
          duration: TokMotion.splashLeave,
          stagger: TokMotion.splashLeaveStagger,
          children: children,
        );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status bar over the map; light navigation bar icons on the blue
      value: systemBarsOver(dark: true).copyWith(statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
      child: ColoredBox(
        color: t.bgBrand,
        child: Stack(children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(children: [
                  // The map, with the trip it's under (the first part to arrive)
                  Positioned(top: 0, left: 0, right: 0, child: arriving([const HomeMapStill()])),
                  // The blue rising over the map's lower part, which blurs a little under it
                  Positioned(
                    top: hero,
                    left: 0,
                    right: 0,
                    height: _tripsFade,
                    child: IgnorePointer(
                      child: ClipRect(
                        child: BackdropFilter(
                          enabled: !lightEffects,
                          filter: ui.ImageFilter.blur(sigmaX: _tripsBlur, sigmaY: _tripsBlur),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.bgBrand.withValues(alpha: 0), t.bgBrand]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    // The last row clear of the fade at the bottom
                    padding: EdgeInsets.only(bottom: pad.bottom + _bottomFade),
                    child: arriving([
                      SizedBox(key: cardKey, height: hero, child: HomeHeroFace(onOpen: onOpen)),
                      _section(context, 'Coming up', [for (final trip in upcomingTrips) _TripRow(trip: trip)]),
                      _section(context, 'Previous trips', [for (final trip in pastTrips) _TripRow(trip: trip)], count: pastTrips.length),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
          // The list fades into the blue at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _bottomFade,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.bgBrand.withValues(alpha: 0), t.bgBrand]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// A heading in white (with a count, softer), then its cards.
  Widget _section(BuildContext context, String title, List<Widget> rows, {int? count}) {
    final t = context.tok;
    return Padding(
      padding: const EdgeInsets.all(TokSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: title),
              if (count != null) TextSpan(text: ' $count', style: TextStyle(color: TokPalette.white.withValues(alpha: 0.7))),
            ]),
            style: TokText.headingSm.copyWith(color: t.textOnBrand),
          ),
        ),
        ...rows,
      ]),
    );
  }
}

/// The map behind the top of Your trips: the still of Lisbon at the design's scale, centred on the screen, from the top
/// of the screen down to where the blue covers it. Also what the trip opens out of, at the same place.
class HomeMapStill extends StatelessWidget {
  const HomeMapStill({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final r = homeMapRect;
    return SizedBox(
      height: top + r.bottom,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: homeMapWidth,
        maxWidth: homeMapWidth,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: r.left,
            top: top + r.top,
            width: r.width,
            height: r.height,
            child: Image.asset(
              homeMapImage,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              frameBuilder: (context, child, frame, _) {
                if (frame != null) StartupTimings.mark('Lisbon still decoded');
                return child;
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// The trip you're on, over its map: the header (Your trips, the bell and me), then in the middle its name, the city
/// and dates, who's on it and "See trip details". The whole of it goes in. Without [onOpen] (in the opening trip, where
/// it fades away) nothing in it takes a tap.
class HomeHeroFace extends StatelessWidget {
  const HomeHeroFace({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    final crew = [for (final p in people) if (onTrip(p, tripNow())) p];
    final lift = [for (final s in TokShadow.elevationRaised) Shadow(color: s.color, offset: s.offset, blurRadius: s.blurRadius)];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: EdgeInsets.fromLTRB(TokSpace.xl, pad.top + TokSpace.md, TokSpace.xl, TokSpace.md),
        child: Column(spacing: TokSpace.md, children: [
          Row(spacing: TokSpace.sm, children: [
            Expanded(
              // A long press shows the startup timings (hidden, for testers' phones)
              child: GestureDetector(
                onLongPress: StartupTimings.show,
                child: Text('Your trips', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingLg.copyWith(color: t.textDefault)),
              ),
            ),
            TuButton(icon: TuIcons.bell, label: 'Notifications', onTap: onOpen == null ? null : () => tripNotice.value = 'No new notifications'),
            // Me
            Semantics(
              label: myName,
              child: Glass(
                kind: GlassKind.soft,
                width: TokDim.buttonMd,
                height: TokDim.buttonMd,
                radius: BorderRadius.circular(TokRadius.pill),
                child: Center(child: Sticker(personById(myId).sticker, size: StickerSize.avatar)),
              ),
            ),
          ]),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xl, children: [
                Column(spacing: TokSpace.xs, children: [
                  _HeroTitle(style: TokText.display.copyWith(fontSize: _heroTitle, color: t.textDefault, shadows: lift)),
                  Text('$tripCity · $tripDates', style: TokText.labelMd.copyWith(color: t.textDefault)),
                ]),
                Column(children: [
                  // Everyone on it, standing on the button
                  SizedBox(
                    height: _heroFace - _heroFaceOnButton,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: _heroFace,
                      child: Overlapped(overlap: _heroFaceOverlap, children: [for (final p in crew) Sticker(p.sticker, height: _heroFace)]),
                    ),
                  ),
                  _SeeTrip(onTap: onOpen),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The trip's name, big, on up to two lines, with a white edge like a sticker's (4 outside the letters, round at the
/// corners) so it reads on any part of the map; the shadow sits under the edge. A single word too long for a line
/// shrinks to fit it instead of breaking.
class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.style});
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        var longest = 0.0;
        for (final word in tripTitle.split(' ')) {
          final p = TextPainter(text: TextSpan(text: word, style: style), textDirection: TextDirection.ltr, maxLines: 1)..layout();
          longest = math.max(longest, p.width);
          p.dispose();
        }
        final fit = longest > box.maxWidth ? style.copyWith(fontSize: style.fontSize! * box.maxWidth / longest) : style;
        // The edge is a stroke on a copy under the letters: centred on their outline, so twice as wide as it shows
        final edge = fit.copyWith(
          color: null,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = TokSpace.x2xs * 2
            ..strokeJoin = StrokeJoin.round
            ..color = TokPalette.white,
        );
        Text line(TextStyle s) => Text(tripTitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: s);
        return Stack(alignment: Alignment.center, children: [line(edge), line(fit.copyWith(shadows: const []))]);
      });
}

/// "See trip details": the way in, a primary pill with the trip's green bead (it's on now).
class _SeeTrip extends StatelessWidget {
  const _SeeTrip({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'See trip details',
      child: Glass(
        kind: GlassKind.primary,
        height: TokDim.buttonLg,
        radius: BorderRadius.circular(TokRadius.pill),
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
          const _NowDot(),
          Text('See trip details', style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.iconOnBrand)),
        ]),
      ),
    );
  }
}

/// Whether Your trips' parts have come in: on a cold start they're held back under the splash until its mark leaves.
final homeIn = ValueNotifier(true);

/// The trip is on: a green bead with a small glow around it (no blur).
class _NowDot extends StatelessWidget {
  const _NowDot();

  @override
  Widget build(BuildContext context) => Container(
        width: _nowDot,
        height: _nowDot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [TokPalette.green500, TokPalette.green700]),
          border: Border.all(color: TokPalette.green400, width: TokDim.surfaceEdgeWidth / 2),
          boxShadow: [BoxShadow(color: TokPalette.green500.withValues(alpha: 0.2), spreadRadius: _nowDotGlow)],
        ),
      );
}

/// Another trip, as a soft glass card on the blue: its sticker, name, dates, and who's going (or went).
class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});
  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Glass(
      kind: GlassKind.soft,
      radius: BorderRadius.circular(TokRadius.sheet),
      padding: const EdgeInsets.all(TokSpace.md),
      child: Row(spacing: TokSpace.sm, children: [
        // Wide stickers shrink to fit the square, so their white edge stays whole
        SizedBox.square(dimension: _rowSticker, child: FittedBox(fit: BoxFit.scaleDown, child: Sticker(trip.sticker, height: _rowSticker))),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodyLg.copyWith(fontWeight: TokWeight.medium, color: t.textDefault)),
            Text(trip.dates, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
        SizedBox(
          width: _rowFaces,
          child: Align(
            alignment: Alignment.centerRight,
            child: Overlapped(overlap: _rowFaceOverlap, children: [for (final f in trip.faces) Sticker(f, size: StickerSize.avatar)]),
          ),
        ),
      ]),
    );
  }
}
