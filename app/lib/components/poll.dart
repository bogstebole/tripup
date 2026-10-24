// The dinner poll: where to eat tonight, decided by the group (see the poll section of data.dart).
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'plan_pin.dart' show crossfadeSeam, reportSize, smoothstep;
import 'stagger.dart';

String _countdown(DateTime now) {
  final mins = pollClosedAt(now).difference(now).inMinutes + 1;
  return 'closes in $mins ${mins == 1 ? 'min' : 'mins'}';
}

/// Walking minutes from where I am, the way the live statuses count them.
int walkMinutes(PollOption o, DateTime now) =>
    (const Distance().as(LengthUnit.Meter, myPosition(now), o.at) * streetDetour / walkingMetresPerMinute).ceil();

/// The poll on the map, as one surface that folds between the card and the pill. Its box springs between their two
/// sizes while one's content fades out and the other's fades in, slightly blurred where they overlap; both are
/// pinned to the box's left edge, so the live dot and the line beside it travel with it. It reads as the same thing
/// changing shape, not two things swapping. With reduced motion the box jumps and the contents only fade.
class PollOnMap extends StatefulWidget {
  const PollOnMap({super.key, required this.folded, required this.onFold, required this.onUnfold, required this.onOpen});
  final bool folded;
  final VoidCallback onFold, onUnfold, onOpen;

  @override
  State<PollOnMap> createState() => _PollOnMapState();
}

class _PollOnMapState extends State<PollOnMap> with SingleTickerProviderStateMixin {
  /// 0 = the pill, 1 = the card.
  late final _t = AnimationController.unbounded(vsync: this, value: widget.folded ? 0 : 1);
  Size? _pill, _card;

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didUpdateWidget(PollOnMap old) {
    super.didUpdateWidget(old);
    if (old.folded == widget.folded) return;
    final to = widget.folded ? 0.0 : 1.0;
    _reduce ? _t.animateTo(to, duration: TokMotion.fade) : springTo(_t, to, TokMotion.springMorph);
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 2 * TokSpace.md;
    final radius = BorderRadius.circular(TokDim.surfaceRadius);
    // Each content at its own size, whatever the box is doing; the box clips them
    Widget sized(Widget child, Size? known, void Function(Size) keep) => OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: maxWidth,
          minHeight: 0,
          maxHeight: double.infinity,
          child: reportSize(onSize: (s) => s == known ? null : setState(() => keep(s)), child: child),
        );
    final pill = sized(PollPill(onUnfold: widget.onUnfold), _pill, (s) => _pill = s);
    final card = sized(PollCard(onOpen: widget.onOpen, onFold: widget.onFold), _card, (s) => _card = s);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value, p = v.clamp(0.0, 1.0);
        // Until both are measured (the first frame), lay them out unseen
        if (_pill == null || _card == null) return Opacity(opacity: 0, child: SizedBox.shrink(child: Stack(clipBehavior: Clip.none, children: [pill, card])));
        final box = _reduce ? (widget.folded ? _pill! : _card!) : Size.lerp(_pill, _card, v)!;
        final cardOp = _reduce ? p : smoothstep(0.3, 0.8, p), pillOp = _reduce ? 1 - p : 1 - smoothstep(0.05, 0.55, p);
        return SizedBox.fromSize(
          size: box,
          child: DecoratedBox(
            decoration: surfaceDecoration(context, radius),
            child: ClipRRect(
              borderRadius: radius,
              child: crossfadeSeam(
                sigma: _reduce ? 0 : TokMotion.crossfadeBlur * 4 * cardOp * pillOp,
                child: Stack(children: [
                  Positioned.fill(child: IgnorePointer(ignoring: !widget.folded, child: Opacity(opacity: pillOp, child: pill))),
                  Positioned.fill(child: IgnorePointer(ignoring: widget.folded, child: Opacity(opacity: cardOp, child: card))),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The card's content: a live sign and the countdown (and the fold button), the question, then each place with
/// everyone who voted for it and a bar of its votes (the one ahead in brand). Tapping a place votes for it, right
/// there; the poll itself (ratings, prices, walks) is a tap further, at the bottom.
class PollCard extends StatelessWidget {
  const PollCard({super.key, required this.onOpen, required this.onFold});
  final VoidCallback onOpen, onFold;

  // A vote shows at once (the rest of the poll moves on the demo's clock)
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: myVote, builder: (context, _) => _card(context));

  Widget _card(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final leader = pollLeader(now);
    return Container(
      width: math.min(TokDim.pollWidth, MediaQuery.sizeOf(context).width - 2 * TokSpace.md),
      padding: const EdgeInsets.fromLTRB(TokSpace.md, TokSpace.x2xs, TokSpace.x2xs, TokSpace.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // The same height as the pill, so the live dot and its line stay put as it folds
        SizedBox(
          height: TokDim.buttonMd,
          child: Row(spacing: TokSpace.xs, children: [
            const LiveDot(),
            Expanded(child: Text('Live poll · ${_countdown(now)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.textBrand))),
            TuButton(icon: TuIcons.fold, label: 'Fold the poll away', size: TuButtonSize.sm, onTap: onFold),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(right: TokSpace.sm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.x3xs, children: [
            Text('Where for dinner tonight?', style: TokText.headingSm.copyWith(color: t.textDefault)),
            Text('5 PM · ${personById(pollAskedBy).name} asked · ${votesIn(now)} of ${dinnerTable.length} voted', style: TokText.bodySm.copyWith(color: t.textMuted)),
            const SizedBox(height: TokSpace.x2xs),
          ]),
        ),
        for (final o in pollOptions) _VoteRow(option: o, now: now, ahead: o.id == leader),
        // The places in full
        Pressable(
          onTap: onOpen,
          semanticLabel: 'See the places: ratings, prices and walks',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, TokSpace.xs, TokSpace.sm, TokSpace.xs),
            child: Row(spacing: TokSpace.x2xs, children: [
              Text('Ratings, prices and walks', style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand)),
              LucideIcon(TuIcons.forward, size: TokSize.iconSm, color: t.iconBrand),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A place on the card: its sticker, name, voters and bar, and a round mark that is the vote. Tapping the row votes
/// for it (or moves your vote to it).
class _VoteRow extends StatelessWidget {
  const _VoteRow({required this.option, required this.now, required this.ahead});
  final PollOption option;
  final DateTime now;
  final bool ahead;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final voters = votersOf(option.id, now);
    final mine = myVote.value?.option == option.id;
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        myVote.value = (option: option.id, at: tripNow());
      },
      semanticLabel: mine ? 'Your vote: ${option.name}' : 'Vote for ${option.name}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, TokSpace.x2xs, TokSpace.sm, TokSpace.x2xs),
        child: Row(spacing: TokSpace.sm, children: [
          SizedBox(width: TokDim.stickerAvatar, child: Center(child: Sticker(option.sticker, size: StickerSize.avatar))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.x2xs, children: [
              Row(spacing: TokSpace.xs, children: [
                Expanded(child: Text(option.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault))),
                Voters(voters),
              ]),
              VoteBar(votes: voters.length, ahead: ahead),
            ]),
          ),
          VoteMark(on: mine),
        ]),
      ),
    );
  }
}

/// The vote itself: an empty ring, or filled in brand with a check once it's yours. It fills with a quick scale.
class VoteMark extends StatelessWidget {
  const VoteMark({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      width: TokDim.pollMark,
      height: TokDim.pollMark,
      child: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.borderStrong, width: TokDim.pollMarkRing))),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: on ? 1 : 0,
            duration: on ? TokMotion.press : TokMotion.fade,
            curve: TokMotion.easeOut,
            child: AnimatedScale(
              scale: on || reduce ? 1 : TokMotion.morphEnterScale,
              duration: on ? TokMotion.press : TokMotion.fade,
              curve: TokMotion.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: t.cPollBarLead),
                child: Center(child: LucideIcon(TuIcons.check, size: TokSize.iconSm, color: t.iconOnBrand)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// The pill's content: the live sign, how many voted, the countdown. Tapping it unfolds the card.
class PollPill extends StatelessWidget {
  const PollPill({super.key, required this.onUnfold});
  final VoidCallback onUnfold;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: myVote, builder: (context, _) => _pill(context));

  Widget _pill(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    return Pressable(
      onTap: onUnfold,
      semanticLabel: 'Dinner poll: ${votesIn(now)} of ${dinnerTable.length} voted, ${_countdown(now)}. Unfold',
      child: Container(
        height: TokDim.buttonMd,
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
          const LiveDot(),
          Flexible(
            child: Text('Dinner poll · ${votesIn(now)} of ${dinnerTable.length} · ${_countdown(now)}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
          ),
          LucideIcon(TuIcons.unfold, size: TokSize.iconSm, color: t.iconMuted),
        ]),
      ),
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
      height: TokDim.pollBarHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokRadius.pill),
        child: ColoredBox(
          color: onMuted ? t.cPollBarTrackOnMuted : t.cPollBarTrack,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: votes / dinnerTable.length),
            duration: reduce ? Duration.zero : TokMotion.enter,
            curve: TokMotion.easeOut,
            builder: (context, share, _) => FractionalTranslation(
              translation: Offset(share - 1, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(color: ahead ? t.cPollBarLead : t.cPollBar, borderRadius: BorderRadius.circular(TokRadius.pill)),
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
  late final _opacity = Tween(begin: 1.0, end: TokDim.pollLiveDimOpacity).animate(CurvedAnimation(parent: _c, curve: TokMotion.easeBreathe));

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
            decoration: BoxDecoration(color: context.tok.cPollLive, shape: BoxShape.circle),
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
              decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.sheet)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.sm, children: [
                Row(spacing: TokSpace.sm, children: [
                  SizedBox(width: TokDim.stickerRow, child: Center(child: Sticker(o.sticker, size: StickerSize.row))),
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
