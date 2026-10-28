// The dinner poll: where to eat tonight, decided by the group (see the poll section of data.dart).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'stagger.dart';

// Its own measurements: used only here, so they're not tokens.
const double _pollBarHeight = 8;
const double _pollOptionSticker = 48;
const double _pollMetaFace = 16;
const double _pollMetaFaceOverlap = 5;
const double _pollNotVotedOpacity = 0.4;
const double _pollLiveDimOpacity = 0.35;

String _countdown(DateTime now) {
  final mins = pollClosedAt(now).difference(now).inMinutes + 1;
  return 'closes in $mins ${mins == 1 ? 'min' : 'mins'}';
}

/// Walking minutes from where I am, the way the live statuses count them.
int walkMinutes(PollOption o, DateTime now) =>
    (const Distance().as(LengthUnit.Meter, myPosition(now), o.at) * streetDetour / walkingMetresPerMinute).ceil();

/// The poll on the map (Bogdan's design, Figma 82:3). Closed, it's a compact card under the day filter: the live
/// sign and the countdown, the question, and who has voted (everyone at the table, the ones yet to vote faded).
/// Tapping it opens it in place, over a tinted, blurred map: the same card grows down to show each place, with its
/// rating, food and price, a bar of its votes, Details, who voted for it, and the vote itself. One element: the head
/// stays put, the places arrive under it one by one, and closing folds them away again.
class PollCard extends StatefulWidget {
  const PollCard({super.key, required this.expanded, required this.onToggle, required this.onDetails});
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<PollOption> onDetails;

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> with SingleTickerProviderStateMixin {
  /// How open it is: 0 the compact card, 1 open. Opening takes the usual time, folding a little less.
  late final _open = AnimationController(vsync: this, value: widget.expanded ? 1 : 0, duration: TokMotion.enter, reverseDuration: TokMotion.fold);

  /// The card's edge, ease-out both ways so it answers at once: down on opening, up on folding.
  late final _edge = CurvedAnimation(parent: _open, curve: TokMotion.easeOut, reverseCurve: TokMotion.easeOut.flipped);

  bool get expanded => widget.expanded;
  VoidCallback get onToggle => widget.onToggle;
  ValueChanged<PollOption> get onDetails => widget.onDetails;

  @override
  void didUpdateWidget(PollCard old) {
    super.didUpdateWidget(old);
    if (old.expanded == widget.expanded) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _open.value = widget.expanded ? 1 : 0;
    } else {
      widget.expanded ? _open.forward() : _open.reverse();
    }
  }

  @override
  void dispose() {
    _edge.dispose();
    _open.dispose();
    super.dispose();
  }

  // A vote shows at once (the rest of the poll moves on the demo's clock)
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: myVote, builder: (context, _) => _card(context));

  Widget _card(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final width = MediaQuery.sizeOf(context).width - 2 * TokSpace.md;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.md, TokSpace.xs, TokSpace.xs),
      // Concentric with the places in it, xs in from its sides and bottom
      decoration: surfaceDecoration(context, BorderRadius.circular(TokDim.pollRadius)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // The head: tapping it opens the poll, or closes it
        Pressable(
          onTap: onToggle,
          semanticLabel: '${expanded ? 'Close' : 'Open'} the dinner poll: ${votesIn(now)} of ${dinnerTable.length} voted, ${_countdown(now)}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.sm, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
              child: Row(spacing: TokSpace.xs, children: [
                Expanded(
                  child: Row(spacing: TokSpace.xs, children: [
                    Flexible(
                      child: Text('Live poll • ${_countdown(now)}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand)),
                    ),
                    const LiveDot(),
                  ]),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: TokMotion.enter,
                  curve: TokMotion.easeOut,
                  child: LucideIcon(TuIcons.unfold, size: TokSize.iconSm, color: t.iconDefault),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
                Text('Where for dinner tonight?', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
                Row(spacing: TokSpace.x2xs, children: [
                  Flexible(
                    child: Text('5 PM • ${personById(pollAskedBy).name} asked • ${votesIn(now)} of ${dinnerTable.length} voted',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelSm.copyWith(color: t.textMuted)),
                  ),
                  // Who has voted: the faces say it closed; open, each place shows its own
                  AnimatedOpacity(opacity: expanded ? 0 : 1, duration: expanded ? TokMotion.fade : TokMotion.enter, curve: TokMotion.easeOut, child: _Table(now: now)),
                ]),
              ]),
            ),
          ]),
        ),
        // The places, open. Like an accordion: the card's edge moves down to reveal them while they arrive one by one
        // under the head. Folding is the same move back, one continuous motion: the edge starts rising at once and
        // the places fade over the first half, so they're gone before it reaches them. With reduced motion it simply
        // shows or hides.
        Flexible(
          child: AnimatedBuilder(
            animation: _open,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: TokSpace.sm),
              child: StaggerIn(spacing: TokSpace.sm, children: [
                for (final o in pollOptions) _Place(option: o, now: now, onDetails: () => onDetails(o)),
              ]),
            ),
            builder: (context, child) {
              final v = _open.value;
              if (v == 0) return const SizedBox(width: double.infinity);   // shut: the places go (and stagger in again next time)
              final folding = _open.status == AnimationStatus.reverse;
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _edge.value,
                  child: Opacity(opacity: folding ? const Interval(0.5, 1).transform(v) : 1, child: child),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Everyone at the table, small, the ones who haven't voted yet faded: who the poll is still waiting for.
class _Table extends StatelessWidget {
  const _Table({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final voted = {for (final o in pollOptions) ...votersOf(o.id, now)};
    final order = [...dinnerTable.where(voted.contains), ...dinnerTable.where((id) => !voted.contains(id))];
    return Overlapped(overlap: _pollMetaFaceOverlap, children: [
      for (final id in order)
        Opacity(opacity: voted.contains(id) ? 1 : _pollNotVotedOpacity, child: Sticker(personById(id).sticker, height: _pollMetaFace)),
    ]);
  }
}

/// One place in the open poll: its name, rating, food and price, its sticker, a bar of its votes, Details, who voted
/// for it, and the vote (in brand once it's yours; tapping another moves it).
class _Place extends StatelessWidget {
  const _Place({required this.option, required this.now, required this.onDetails});
  final PollOption option;
  final DateTime now;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final o = option;
    final voters = votersOf(o.id, now);
    final mine = myVote.value?.option == o.id;
    final muted = TokText.labelMd.copyWith(color: t.textMuted), dot = TokText.labelSm.copyWith(color: t.textMuted);
    return Container(
      padding: const EdgeInsets.all(TokSpace.xs),
      // Concentric with its vote button, xs in from the corner
      decoration: BoxDecoration(color: t.bgSubtle, borderRadius: BorderRadius.circular(TokDim.pollPlaceRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.md, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.xs, 0),
          child: Row(spacing: TokSpace.xs, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
                Text(o.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodyMd.copyWith(fontWeight: TokWeight.medium, color: t.textDefault)),
                Row(spacing: TokSpace.x2xs, children: [
                  LucideIcon(TuIcons.star, size: TokSize.iconSm, color: t.iconBrand, filled: true),
                  Text(o.rating, style: muted),
                  Text('•', style: dot),
                  Flexible(child: Text(o.cuisine, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted)),
                  Text('•', style: dot),
                  Text(o.price, style: muted),
                ]),
              ]),
            ),
            Sticker(o.sticker, height: _pollOptionSticker),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs), child: VoteBar(votes: voters.length, ahead: true, onMuted: true)),
        // Vote xs in from the corner, like everything at the card's edge, so it's concentric with it
        Row(children: [
          Pressable(
            onTap: onDetails,
            semanticLabel: 'Details: ${o.name}',
            child: Container(
              height: TokDim.buttonMd,
              padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
              alignment: Alignment.center,
              child: Text('Details', style: TokText.bodyMd.copyWith(fontWeight: TokWeight.medium, color: t.textMuted)),
            ),
          ),
          const Spacer(),
          if (voters.isNotEmpty) Padding(padding: const EdgeInsets.only(right: TokSpace.sm), child: Voters(voters)),
          TuButton(
            icon: TuIcons.check,
            label: mine ? 'Your vote: ${o.name}' : 'Vote for ${o.name}',
            kind: mine ? GlassKind.primary : GlassKind.soft,
            size: TuButtonSize.sm,
            onTap: () {
              HapticFeedback.selectionClick();
              myVote.value = (option: o.id, at: tripNow());
            },
          ),
        ]),
      ]),
    );
  }
}

/// A place's share of the table's votes, as a bar: grows as votes come in, in brand for the one ahead. The fill
/// slides in from the left inside the track (a transform, so the rounded end keeps its shape); with reduced motion it
/// just jumps.
class VoteBar extends StatelessWidget {
  const VoteBar({super.key, required this.votes, required this.ahead, this.onMuted = false});
  final int votes;
  final bool ahead;

  /// On a grey card (the poll's places), where the usual track wouldn't show.
  final bool onMuted;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      height: _pollBarHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokRadius.pill),
        child: ColoredBox(
          color: onMuted ? t.bgDefault : t.bgMuted,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: votes / dinnerTable.length),
            duration: reduce ? Duration.zero : TokMotion.enter,
            curve: TokMotion.easeOut,
            builder: (context, share, _) => FractionalTranslation(
              translation: Offset(share - 1, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(color: ahead ? t.bgBrand : TokPalette.zinc300, borderRadius: BorderRadius.circular(TokRadius.pill)),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everyone who voted for a place, every face (five at most, so no "+N").
class Voters extends StatelessWidget {
  const Voters(this.ids, {super.key});
  final List<String> ids;

  @override
  Widget build(BuildContext context) =>
      Overlapped(overlap: TokDim.chipFaceOverlap, children: [for (final id in ids) Sticker(personById(id).sticker, size: StickerSize.chip)]);
}

/// "Live": a red dot that slowly breathes while the poll is open (still, with reduced motion).
class LiveDot extends StatefulWidget {
  const LiveDot({super.key});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: TokMotion.pulse);
  late final _opacity = Tween(begin: 1.0, end: _pollLiveDimOpacity).animate(CurvedAnimation(parent: _c, curve: TokMotion.easeBreathe));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? _c.stop() : _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            width: TokDim.pollLiveDot,
            height: TokDim.pollLiveDot,
            decoration: BoxDecoration(color: context.tok.bgDanger, shape: BoxShape.circle),
          ),
        ),
      );
}

/// The poll: a card per place (its sticker, rating, food, price and how far it is), a bar of its votes, who voted for
/// it, and Vote. Once it has closed: which one won and went into tonight; after an Undo, a way to pick one by hand.
class PollPage extends StatelessWidget {
  const PollPage({super.key});

  static String subtitle(DateTime now) => pollClosed(now)
      ? 'Closed · ${pollUndone.value ? (pickedDinner.value == null ? 'nothing added yet' : '${pollOptionById(pickedDinner.value!).short} picked by hand') : '${pollOptionById(pollLeader(now)!).short} won, ${pollScore(now)}'}'
      : '5 PM · ${personById(pollAskedBy).name} asked · ${_countdown(now)}';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([myVote, pollUndone, pickedDinner]),
        builder: (context, _) => _page(context),
      );

  Widget _page(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final open = pollOpen(now), leader = pollLeader(now), chosen = dinnerChoice(now);
    return StaggerIn(spacing: TokSpace.sm, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        child: Text(
          open
              ? '${votesIn(now)} of ${dinnerTable.length} have voted. It closes at ${clockTime(pollCloses)}, or once everyone has voted; the winner goes into tonight by itself.'
              : pollUndone.value && pickedDinner.value == null
                  ? 'The winner was taken back out. Pick tonight\'s place yourself.'
                  : 'It\'s in tonight, 5 PM: on everyone\'s map and itinerary.',
          style: TokText.bodySm.copyWith(color: t.textMuted),
        ),
      ),
      for (final o in pollOptions)
        () {
          final voters = votersOf(o.id, now);
          final mine = myVote.value?.option == o.id;
          final won = !open && o.id == chosen;
          return Opacity(
            opacity: !open && chosen != null && !won ? TokDim.pollLostOpacity : 1,
            child: Container(
              padding: const EdgeInsets.all(TokSpace.sm),
              // Concentric with Vote, sm in from the corner
              decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokDim.pollOptionRadius)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.sm, children: [
                Row(spacing: TokSpace.sm, children: [
                  SizedBox(width: TokSpace.x3xl, child: Center(child: Sticker(o.sticker, size: StickerSize.row))),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
                      Text(o.name, style: TokText.labelLg.copyWith(color: t.textDefault)),
                      RatingLine(rating: o.rating, kind: '${o.cuisine} · ${o.price}', center: false),
                      Text('${walkMinutes(o, now)} min walk', style: TokText.bodySm.copyWith(color: t.textMuted)),
                    ]),
                  ),
                ]),
                VoteBar(votes: voters.length, ahead: o.id == leader, onMuted: true),
                Row(spacing: TokSpace.xs, children: [
                  if (voters.isNotEmpty) Voters(voters),
                  Text(voters.isEmpty ? 'No votes yet' : '${voters.length} ${voters.length == 1 ? 'vote' : 'votes'}', style: TokText.bodySm.copyWith(color: t.textMuted)),
                  if (won)
                    const PollTag('Tonight')
                  else if (!open && o.id == leader)
                    const PollTag('Won'),
                  const Spacer(),
                  if (open)
                    TuTextButton(
                      label: mine ? 'Your vote' : 'Vote',
                      icon: mine ? TuIcons.check : null,
                      kind: mine ? GlassKind.primary : GlassKind.soft,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        myVote.value = (option: o.id, at: tripNow());
                      },
                    )
                  else if (pollUndone.value && chosen != o.id)
                    TuTextButton(
                      label: 'Add to tonight',
                      kind: GlassKind.soft,
                      onTap: () {
                        pickedDinner.value = o.id;
                        tripNotice.value = '${o.short} added for tonight, 5 PM';
                      },
                    ),
                ]),
              ]),
            ),
          );
        }(),
    ]);
  }
}

/// A small brand pill: "Won", "Tonight".
class PollTag extends StatelessWidget {
  const PollTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.x3xs),
      decoration: BoxDecoration(color: t.bgBrandSubtle, borderRadius: BorderRadius.circular(TokRadius.pill)),
      child: Text(label, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand)),
    );
  }
}
