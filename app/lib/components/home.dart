// The first screen: your trips.
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'stagger.dart';
import 'trip_sheet.dart';

/// Your trips. The one you're on sits on top, big: what's happening on it now, who's on it, and what you owe. The ones
/// coming up are under it; past ones are folded away (they're done and settled). Tapping the current one goes into
/// its map.
class TripsHome extends StatefulWidget {
  const TripsHome({super.key, required this.onOpen, this.demo});
  final VoidCallback onOpen;

  /// The demo's clock and moments, top right (not part of the product).
  final Widget? demo;

  @override
  State<TripsHome> createState() => _TripsHomeState();
}

class _TripsHomeState extends State<TripsHome> {
  bool _pastOpen = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: t.bgCanvas,
      child: ListView(
        padding: EdgeInsets.fromLTRB(TokSpace.md, pad.top + TokSpace.md, TokSpace.md, pad.bottom + TokSpace.xl),
        children: [
          Row(children: [
            Expanded(child: Text('Your trips', style: TokText.headingLg.copyWith(color: t.textDefault))),
            ?widget.demo,
          ]),
          const SizedBox(height: TokSpace.md),
          StaggerIn(children: [
            _CurrentTrip(onOpen: widget.onOpen),
            const SheetSection('Coming up'),
            for (final trip in upcomingTrips) _TripRow(trip: trip),
            const SizedBox(height: TokSpace.md),
            // Past trips, folded away until asked for
            Pressable(
              onTap: () => setState(() => _pastOpen = !_pastOpen),
              semanticLabel: _pastOpen ? 'Hide past trips' : 'Show past trips',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
                child: Row(spacing: TokSpace.xs, children: [
                  Text('Past trips', style: TokText.headingSm.copyWith(color: t.textDefault)),
                  Text('${pastTrips.length}', style: TokText.bodySm.copyWith(color: t.textMuted)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _pastOpen ? 0 : 0.5,
                    duration: TokMotion.enter,
                    curve: TokMotion.easeOut,
                    child: LucideIcon(TuIcons.openUp, size: TokSize.iconSm, color: t.iconMuted),
                  ),
                ]),
              ),
            ),
            AnimatedSize(
              duration: TokMotion.enter,
              curve: TokMotion.easeOut,
              alignment: Alignment.topCenter,
              child: !_pastOpen
                  ? const SizedBox(width: double.infinity)
                  : Column(children: [
                      for (final (i, trip) in pastTrips.indexed) ...[if (i > 0) const Hairline(), _TripRow(trip: trip)],
                    ]),
            ),
          ]),
        ],
      ),
    );
  }
}

/// The trip you're on: its name and where, the day it's on, what's happening now, who's on it (their faces), and what
/// you owe.
class _CurrentTrip extends StatelessWidget {
  const _CurrentTrip({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final dinner = plans.first;
    final next = tripPlans.where((p) => p.start.add(planLasts).isAfter(now)).firstOrNull;
    // What's on right now, the way you'd say it
    final status = pollOpen(now)
        ? 'Poll open: where for dinner tonight?'
        : isActive(dinner, now)
            ? 'Now: dinner at ${dinner.name.split(' - ').first}'
            : next == null
                ? 'Nothing planned'
                : 'Up next: ${next.name.split(' - ').first}, ${next.startsAt}';
    final crew = [for (final p in people) if (onTrip(p, now)) p];
    final mine = settleUp.where((p) => p.from == myId && !isPaid(p)).firstOrNull;
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Open $tripTitle',
      child: Container(
        padding: const EdgeInsets.all(TokSpace.md),
        decoration: surfaceDecoration(context, BorderRadius.circular(TokDim.surfaceRadius)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.sm, children: [
          // Where we've been so far, as stickers
          Overlapped(overlap: TokDim.stickerOverlap, children: [
            for (final v in visited.take(5)) Sticker(v.sticker, size: StickerSize.row, tilt: v.tilt),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
            Text(tripTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
            Text('Lisbon · ${tripDays.first}–${tripDays.last} May · Day ${tripDays.indexOf(today) + 1} of ${tripDays.length}', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
          Text(status, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand)),
          Row(spacing: TokSpace.xs, children: [
            Overlapped(overlap: TokDim.chipFaceOverlap, children: [for (final p in crew) Sticker(p.sticker, size: StickerSize.chip)]),
            Expanded(
              child: Text(
                mine != null ? 'You owe ${personById(mine.to).name} ${euros(mine.amount)}' : '${crew.length} on this trip',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TokText.bodySm.copyWith(color: t.textMuted),
              ),
            ),
            TuButton(icon: TuIcons.forward, label: 'Open $tripTitle', kind: GlassKind.primary, size: TuButtonSize.sm, onTap: onOpen),
          ]),
        ]),
      ),
    );
  }
}

/// Another trip, as a line: its sticker, name, when, a word about it, and who.
class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});
  final TripSummary trip;

  @override
  Widget build(BuildContext context) => SheetRow(
        leading: SizedBox(width: TokDim.stickerRow, child: Center(child: Sticker(trip.sticker, size: StickerSize.row))),
        title: trip.title,
        subtitle: '${trip.dates} · ${trip.note}',
        trailing: Overlapped(overlap: TokDim.chipFaceOverlap, children: [for (final f in trip.faces) Sticker(f, size: StickerSize.chip)]),
      );
}
