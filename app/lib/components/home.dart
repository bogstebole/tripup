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
import 'progressive_blur.dart';
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

/// Your trips, as an overlay on the trip you're on: its live map shows through the top (just the map, none of the
/// trip's pins, people or controls), with its name big in the middle, who's on it and the way in ("See trip
/// details"). Under it, on the brand blue rising over the map, the trip coming up and the ones before, as soft cards.
/// Going in, its parts leave one after another ([HomeLeave]) while the map under it zooms in to the trip. On a cold
/// start it waits under the splash and slides in from the right, a part at a time, as the splash's mark slides out to
/// the left ([homeIn]). The header (Your trips, the bell and me) stays put at the top while the list scrolls under it.
class TripsHome extends StatefulWidget {
  const TripsHome({super.key, required this.onOpen});
  final VoidCallback onOpen;

  /// How tall the trip you're on is: the header under the status bar, then its name and the way in. The map under it
  /// is framed on this part of the screen.
  static double heroHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + TokSpace.md + TokDim.buttonMd + TokSpace.md + _heroBody + TokSpace.md;

  @override
  State<TripsHome> createState() => _TripsHomeState();
}

class _TripsHomeState extends State<TripsHome> {
  /// How far the list has gone under the header, 0–1 over space-2xl: its see-through white shows as it does.
  final _under = ValueNotifier<double>(0);

  /// How far the list is pulled past its end (the bounce).
  final _over = ValueNotifier<double>(0);

  @override
  void dispose() {
    _under.dispose();
    _over.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    final hero = TripsHome.heroHeight(context);
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
      child: Stack(children: [
        // Pulling past the last card shows blue, not the map: blue under the list's end, as tall as the pull
        ValueListenableBuilder<double>(
          valueListenable: _over,
          builder: (context, over, _) => Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: over <= 0 ? 0 : over + _bottomFade,
            child: HomePart(index: HomePart.blue, child: ColoredBox(color: t.bgBrand)),
          ),
        ),
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0) {
                _under.value = (n.metrics.pixels / TokSpace.x2xl).clamp(0.0, 1.0);
                _over.value = math.max(0, n.metrics.pixels - n.metrics.maxScrollExtent);
              }
              return false;
            },
            child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(children: [
                // The blue, from under the trip down: clear at first, so the map's lower part fades into it (and
                // blurs a little under it), then solid. It scrolls with the list, over the map, which stays put.
                Positioned(
                  top: hero,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: HomePart(
                    index: HomePart.blue,
                    child: IgnorePointer(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        SizedBox(
                          height: _tripsFade,
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
                        Expanded(child: ColoredBox(color: t.bgBrand)),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  // The last row clear of the fade at the bottom
                  padding: EdgeInsets.only(bottom: pad.bottom + _bottomFade),
                  child: arriving([
                    SizedBox(height: hero, child: _HeroFace(onOpen: widget.onOpen)),
                    _section(context, 'Coming up', HomePart.comingUp, [for (final trip in upcomingTrips) _TripRow(trip: trip)]),
                    _section(context, 'Previous trips', HomePart.previous, [for (final trip in pastTrips) _TripRow(trip: trip)], count: pastTrips.length),
                  ]),
                ),
              ]),
            ],
          ),
          ),
        ),
        // The header, staying put: over the map at rest; once the list goes under it, over the same see-through white
        // as the trip's top bar, so it reads over the cards and the blue
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: arriving([
            HomePart(
              index: HomePart.header,
              child: Stack(children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _under,
                      builder: (context, v, _) => v <= 0
                          ? const SizedBox.shrink()
                          : Opacity(opacity: v, child: DecoratedBox(decoration: BoxDecoration(gradient: easedFade(t.bgDefault.withValues(alpha: 0.7), from: TokDim.topBarFadeStart)))),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(TokSpace.xl, pad.top + TokSpace.md, TokSpace.xl, TokSpace.md + TokSpace.x2xl),
                  child: const _HomeHeader(),
                ),
              ]),
            ),
          ]),
        ),
        // The list fades into the blue at the bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _bottomFade,
          child: HomePart(
            index: HomePart.blue,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.bgBrand.withValues(alpha: 0), t.bgBrand]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  /// A heading in white (with a count, softer), then its cards; each its own part, from [part] on.
  Widget _section(BuildContext context, String title, int part, List<Widget> rows, {int? count}) {
    final t = context.tok;
    return Padding(
      padding: const EdgeInsets.all(TokSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
        HomePart(
          index: part,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: title),
              if (count != null) TextSpan(text: ' $count', style: TextStyle(color: TokPalette.white.withValues(alpha: 0.7))),
            ]),
            style: TokText.headingSm.copyWith(color: t.textOnBrand),
          ),
        ),
        ),
        for (final (i, row) in rows.indexed) HomePart(index: part + 1 + i, child: row),
      ]),
    );
  }
}

/// Carries Your trips' clock down to its parts: 1 while it's showing, 0 once it has gone (the trip is in). Going in,
/// the parts leave top to bottom, one after another; coming back ([back]) they arrive top to bottom. At rest (or
/// outside one) every part simply shows.
class HomeLeave extends InheritedWidget {
  const HomeLeave({super.key, required this.clock, required this.back, required super.child});
  final Animation<double> clock;

  /// Coming back from the trip, rather than going in.
  final bool back;

  /// How long the parts take, from the first starting to the last landing.
  static Duration get total => TokMotion.enter + TokMotion.openStagger * (HomePart.count - 1);

  static HomeLeave? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HomeLeave>();

  @override
  bool updateShouldNotify(HomeLeave old) => old.clock != clock || old.back != back;
}

/// One element of Your trips, leaving or arriving on its own at its place in the order (each line of text, the faces,
/// the button, each heading and each card): it fades, blurs (up to enter-blur) and moves a little (up as it leaves, up
/// into place as it comes back), ease-out, enter-ms each, open-stagger-ms apart. The blue leaves last and comes back
/// first. With reduced motion every part only fades, together; no blur with light effects.
class HomePart extends StatelessWidget {
  const HomePart({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  static const header = 0, title = 1, dates = 2, faces = 3, wayIn = 4, comingUp = 5;

  /// Previous trips' heading, after Coming up's heading and cards; then its cards, then the blue, last.
  static int get previous => comingUp + 1 + upcomingTrips.length;
  static int get blue => previous + 1 + pastTrips.length;
  static int get count => blue + 1;

  @override
  Widget build(BuildContext context) {
    final leave = HomeLeave.of(context);
    if (leave == null) return child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final total = HomeLeave.total.inMicroseconds;
    // Coming back, the blue comes with the header, so the cards never land on the bare map
    final order = leave.back && index == blue ? header : index;
    final start = reduce ? 0.0 : (TokMotion.openStagger * order).inMicroseconds / total;
    final curve = Interval(start, reduce ? 1 : (start + TokMotion.enter.inMicroseconds / total).clamp(0.0, 1.0), curve: TokMotion.easeOut);
    return AnimatedBuilder(
      animation: leave.clock,
      child: child,
      builder: (context, child) {
        final c = leave.clock.value.clamp(0.0, 1.0);
        // How far this part is out: going in it runs with the clock's fall, coming back with its rise
        final out = leave.back ? 1 - curve.transform(c) : curve.transform(1 - c);
        // A part that's out keeps its place, so nothing below it moves up
        final blur = reduce || lightEffects ? 0.0 : TokMotion.enterBlur * out;
        return Opacity(
          opacity: 1 - out,
          child: ImageFiltered(
            enabled: blur >= 0.05 && out < 1,
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Transform.translate(offset: Offset(0, reduce ? 0 : (leave.back ? out : -out) * TokSpace.xs), child: child),
          ),
        );
      },
    );
  }
}

/// Your trips' header: "Your trips", the bell and me. It stays put at the top of Your trips.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Row(spacing: TokSpace.sm, children: [
      Expanded(
        // A long press shows the startup timings (hidden, for testers' phones)
        child: GestureDetector(
          onLongPress: StartupTimings.show,
          child: Text('Your trips', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingLg.copyWith(color: t.textDefault)),
        ),
      ),
      TuButton(icon: TuIcons.bell, label: 'Notifications', onTap: () => tripNotice.value = 'No new notifications'),
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
    ]);
  }
}

/// The trip you're on, over its map: under the header's place, in the middle its name, the city and dates, who's on it
/// and "See trip details". The whole of it goes in.
class _HeroFace extends StatelessWidget {
  const _HeroFace({required this.onOpen});
  final VoidCallback onOpen;

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
          // The header's place: the header itself stays put over the list (see TripsHome)
          const SizedBox(height: TokDim.buttonMd),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xl, children: [
                Column(spacing: TokSpace.xs, children: [
                  HomePart(index: HomePart.title, child: _HeroTitle(style: TokText.display.copyWith(fontSize: _heroTitle, color: t.textDefault, shadows: lift))),
                  HomePart(index: HomePart.dates, child: Text('$tripCity · $tripDates', style: TokText.labelMd.copyWith(color: t.textDefault))),
                ]),
                Column(children: [
                  // Everyone on it, standing on the button
                  HomePart(
                    index: HomePart.faces,
                    child: SizedBox(
                      height: _heroFace - _heroFaceOnButton,
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: _heroFace,
                        child: Overlapped(overlap: _heroFaceOverlap, children: [for (final p in crew) Sticker(p.sticker, height: _heroFace)]),
                      ),
                    ),
                  ),
                  HomePart(index: HomePart.wayIn, child: _SeeTrip(onTap: onOpen)),
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
