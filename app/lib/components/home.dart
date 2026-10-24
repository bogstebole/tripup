// The first screen: your trips (Figma 75:5927).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'stagger.dart';

/// Your trips, on the brand blue. The one you're on is a big card: a still of the city with places you've been as
/// stickers, "Happening now", its name and dates, who's on it, and the way in. Under it, the trip coming up and the
/// ones before, as rows. Tapping the current one goes into its map.
class TripsHome extends StatelessWidget {
  const TripsHome({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,   // white status bar on the blue
      child: ColoredBox(
        color: t.cHomeBg,
        child: Stack(children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, pad.top + TokSpace.md, 0, pad.bottom + TokDim.homeBottomFade),
              children: [
                StaggerIn(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
                    child: Column(children: [
                      Row(spacing: TokSpace.sm, children: [
                        Expanded(
                          child: Text('Your trips', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingLg.copyWith(color: t.cHomeFg)),
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
                      const SizedBox(height: TokDim.homeHeaderGap),
                      _CurrentTrip(onOpen: onOpen),
                    ]),
                  ),
                  const SizedBox(height: TokSpace.xl),
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
            height: TokDim.homeBottomFade,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.cHomeBg.withValues(alpha: 0), t.cHomeBg]),
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
            if (count != null) TextSpan(text: ' $count', style: TextStyle(color: t.cHomeCountFg)),
          ]),
          style: TokText.headingSm.copyWith(color: t.cHomeFg),
        ),
        ...rows,
      ]),
    );
  }
}

/// The trip you're on: the city's still with stickers, fading to white at the bottom, where its name, dates, who's
/// on it and the way in sit. The whole card goes in, the arrow too.
class _CurrentTrip extends StatelessWidget {
  const _CurrentTrip({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final crew = [for (final p in people) if (onTrip(p, tripNow())) p];
    final radius = BorderRadius.circular(TokDim.surfaceRadius);
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Open $tripTitle',
      child: Container(
        height: TokDim.homeCardHeight,
        decoration: BoxDecoration(borderRadius: radius, boxShadow: TokShadow.surface),
        foregroundDecoration: BoxDecoration(borderRadius: radius, border: Border.all(color: t.cHomeCardEdge, width: TokDim.homeCardEdge)),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(children: [
            // The city, scaled to fill the card, then white rising from the bottom so the text reads
            const Positioned.fill(child: FittedBox(fit: BoxFit.cover, alignment: Alignment.topCenter, child: _HomeMap())),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [t.cHomeMapFade, t.cHomeMapFade, t.cHomeMapFade.withValues(alpha: 0)],
                    stops: const [0, TokDim.homeMapFadeStart, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TokSpace.xl + TokDim.homeCardEdge),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.md, children: [
                const Expanded(child: Align(alignment: Alignment.topLeft, child: _HappeningNow())),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tripTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingXl.copyWith(color: t.textDefault)),
                  Text('$tripCity · $tripDates', style: TokText.labelMd.copyWith(color: t.textMuted)),
                ]),
                Row(children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Overlapped(
                        overlap: TokDim.homeHeroFaceOverlap,
                        children: [for (final p in crew) Sticker(p.sticker, height: TokDim.homeHeroFace)],
                      ),
                    ),
                  ),
                  TuButton(icon: TuIcons.forward, label: 'Open $tripTitle', kind: GlassKind.primary, onTap: onOpen),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The still of the city with its stickers, at the design's size (the card scales it to fit).
class _HomeMap extends StatelessWidget {
  const _HomeMap();

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: homeMapFrame,
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned.fromRect(rect: homeMapImageRect, child: Image.asset(homeMapImage, fit: BoxFit.fill, filterQuality: FilterQuality.medium)),
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
          width: TokDim.homeNowDot,
          height: TokDim.homeNowDot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.cNowDotTop, t.cNowDotBottom]),
            border: Border.all(color: t.cNowDotEdge, width: TokDim.surfaceEdgeWidth / 2),
            boxShadow: [BoxShadow(color: t.cNowDotGlow, spreadRadius: TokDim.homeNowDotGlow)],
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
      decoration: BoxDecoration(color: t.cHomeRowBg, borderRadius: BorderRadius.circular(TokRadius.card)),
      child: IntrinsicHeight(
        child: Row(spacing: TokSpace.sm, children: [
          SizedBox(width: TokDim.homeRowSticker, child: Center(child: Sticker(trip.sticker, height: TokDim.homeRowSticker))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodyLg.copyWith(fontWeight: TokWeight.medium, color: t.textDefault)),
              Text(trip.dates, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodySm.copyWith(color: t.textMuted)),
            ]),
          ),
          // The faces sit on the row's bottom edge
          Align(
            alignment: Alignment.bottomCenter,
            child: Overlapped(overlap: TokDim.homeRowFaceOverlap, children: [
              for (final (i, f) in trip.faces.indexed)
                Sticker(f, size: StickerSize.avatar, tilt: i < trip.faceTilts.length ? trip.faceTilts[i] : 0),
            ]),
          ),
        ]),
      ),
    );
  }
}
