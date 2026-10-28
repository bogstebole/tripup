// The first screen: your trips (Figma 75:5927).
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
const double _homeHeaderGap = 28;
const double _homeCardHeight = 438;
const double _homeMapFadeStart = 0.152;
const double _homeNowDot = 10;
const double _homeNowDotGlow = 2;
const double _homeHeroFace = 39;
const double _homeHeroFaceOverlap = 22;
const double _homeRowSticker = 48;
const double _homeRowFaceOverlap = 18;
const double _homeBottomFade = 89;

/// Your trips, on the brand blue. The one you're on is a big card: a still of the city with places you've been as
/// stickers, "Happening now", its name and dates, who's on it, and the way in. Under it, the trip coming up and the
/// ones before, as rows. Tapping the current one goes into its map. On a cold start it waits under the splash and
/// slides in from the right, a row at a time, as the splash's mark slides out to the left ([homeIn]).
class TripsHome extends StatelessWidget {
  const TripsHome({super.key, required this.onOpen, this.cardKey});
  final VoidCallback onOpen;

  /// On the current trip's card, so the trip can open out of it.
  final GlobalKey? cardKey;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsOver(dark: true),   // white status bar (and navigation bar icons) on the blue
      child: ColoredBox(
        color: t.bgBrand,
        child: Stack(children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, pad.top + TokSpace.md, 0, pad.bottom + _homeBottomFade),
              children: [
                StaggerIn(
                  until: homeIn,
                  // At the splash's pace, from where its mark went
                  from: const Offset(TokDim.splashSlide, 0),
                  duration: TokMotion.splashLeave,
                  stagger: TokMotion.splashLeaveStagger,
                  children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
                    child: Row(spacing: TokSpace.sm, children: [
                        Expanded(
                          // A long press shows the startup timings (hidden, for testers' phones)
                          child: GestureDetector(
                            onLongPress: StartupTimings.show,
                            child: Text('Your trips', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingLg.copyWith(color: t.textOnBrand)),
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
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(TokSpace.md, _homeHeaderGap, TokSpace.md, TokSpace.xl),
                    child: _CurrentTrip(key: cardKey, onOpen: onOpen),
                  ),
                  _section(context, 'Coming up', [for (final trip in upcomingTrips) _TripRow(trip: trip)]),
                  _section(context, 'Previous trips', [for (final trip in pastTrips) _TripRow(trip: trip)], count: pastTrips.length),
                ]),
              ],
            ),
          ),
          // The list fades into the blue at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _homeBottomFade,
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

  /// A heading in white (with a count, softer), then its rows.
  Widget _section(BuildContext context, String title, List<Widget> rows, {int? count}) {
    final t = context.tok;
    return Padding(
      padding: const EdgeInsets.all(TokSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: title),
            if (count != null) TextSpan(text: ' $count', style: TextStyle(color: TokPalette.white.withValues(alpha: 0.7))),
          ]),
          style: TokText.headingSm.copyWith(color: t.textOnBrand),
        ),
        ...rows,
      ]),
    );
  }
}

/// The trip you're on: the city's still with stickers, fading to white at the bottom, where its name, dates, who's
/// on it and the way in sit. The whole card goes in, the arrow too.
class _CurrentTrip extends StatelessWidget {
  const _CurrentTrip({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // Concentric with what sits in its corners: its padding plus the arrow's radius
    final radius = BorderRadius.circular(TokDim.homeCardRadius);
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Open $tripTitle',
      child: Container(
        height: _homeCardHeight,
        decoration: BoxDecoration(borderRadius: radius, boxShadow: TokShadow.surface),
        foregroundDecoration: BoxDecoration(borderRadius: radius, border: Border.all(color: TokPalette.white, width: TokDim.homeCardEdge)),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(children: [
            const Positioned.fill(child: TripCardStill()),
            Positioned.fill(child: TripCardFace(onOpen: onOpen)),
          ]),
        ),
      ),
    );
  }
}

/// The card's picture: the city's still with its stickers, scaled to fill whatever box it's in (the card, or the
/// surface the trip opens in).
class TripCardStill extends StatelessWidget {
  const TripCardStill({super.key});

  @override
  Widget build(BuildContext context) => const FittedBox(fit: BoxFit.cover, alignment: Alignment.topCenter, child: _HomeMap());
}

/// The card's words over its picture: white rising from the bottom, "Happening now", the trip's name, the city and
/// dates, who's on it, and the arrow in.
class TripCardFace extends StatelessWidget {
  const TripCardFace({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final crew = [for (final p in people) if (onTrip(p, tripNow())) p];
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [TokPalette.white, TokPalette.white, TokPalette.white.withValues(alpha: 0)],
              stops: const [0, _homeMapFadeStart, 1],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(TokDim.homeCardPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.md, children: [
          // A little further in than the words, so the pill is concentric with the card's corner too
          const Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(padding: EdgeInsets.only(left: TokDim.homeNowPillInset, top: TokDim.homeNowPillInset), child: _HappeningNow()),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tripTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingXl.copyWith(color: t.textDefault)),
            Text('$tripCity · $tripDates', style: TokText.labelMd.copyWith(color: t.textMuted)),
          ]),
          Row(children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Overlapped(
                  overlap: _homeHeroFaceOverlap,
                  children: [for (final p in crew) Sticker(p.sticker, height: _homeHeroFace)],
                ),
              ),
            ),
            TuButton(icon: TuIcons.forward, label: 'Open $tripTitle', kind: GlassKind.primary, onTap: onOpen),
          ]),
        ]),
      ),
    ]);
  }
}

/// Whether Your trips' rows have come in: on a cold start they're held back under the splash until its mark leaves.
final homeIn = ValueNotifier(true);

/// The still of the city with its stickers, at the design's size (the card scales it to fit).
class _HomeMap extends StatelessWidget {
  const _HomeMap();

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: homeMapFrame,
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned.fromRect(
            rect: homeMapImageRect,
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
          for (final s in homeMapStickers)
            Positioned(
              left: s.center.dx,
              top: s.center.dy,
              child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: Sticker(s.sticker, height: s.height, tilt: s.tilt)),
            ),
        ]),
      );
}

/// "Happening now": the trip is on. A small glass pill with a green bead.
class _HappeningNow extends StatelessWidget {
  const _HappeningNow();

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Glass(
      kind: GlassKind.soft,
      height: TokDim.homeNowPillHeight,
      radius: BorderRadius.circular(TokRadius.pill),
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm),
      child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
        Container(
          width: _homeNowDot,
          height: _homeNowDot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [TokPalette.green500, TokPalette.green700]),
            border: Border.all(color: TokPalette.green400, width: TokDim.surfaceEdgeWidth / 2),
            boxShadow: [BoxShadow(color: TokPalette.green500.withValues(alpha: 0.2), spreadRadius: _homeNowDotGlow)],
          ),
        ),
        Text('Happening now', style: TokText.labelMd.copyWith(color: t.textDefault)),
      ]),
    );
  }
}

/// Another trip, as a light row on the blue: its sticker, name, dates, and who's going (or went).
class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});
  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.md, vertical: TokSpace.sm),
      decoration: BoxDecoration(color: t.bgBrandSubtle, borderRadius: BorderRadius.circular(TokRadius.card)),
      child: IntrinsicHeight(
        child: Row(spacing: TokSpace.sm, children: [
          SizedBox(width: _homeRowSticker, child: Center(child: Sticker(trip.sticker, height: _homeRowSticker))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodyLg.copyWith(fontWeight: TokWeight.medium, color: t.textDefault)),
              Text(trip.dates, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodySm.copyWith(color: t.textMuted)),
            ]),
          ),
          // The faces sit on the row's bottom edge
          Align(
            alignment: Alignment.bottomCenter,
            child: Overlapped(overlap: _homeRowFaceOverlap, children: [
              for (final (i, f) in trip.faces.indexed)
                Sticker(f, size: StickerSize.avatar, tilt: i < trip.faceTilts.length ? trip.faceTilts[i] : 0),
            ]),
          ),
        ]),
      ),
    );
  }
}
