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

String _countdown(DateTime now) {
  final mins = pollClosedAt(now).difference(now).inMinutes + 1;
  return 'closes in $mins ${mins == 1 ? 'min' : 'mins'}';
}

/// Walking minutes from where I am, the way the live statuses count them.
int walkMinutes(PollOption o, DateTime now) =>
    (const Distance().as(LengthUnit.Meter, myPosition(now), o.at) * streetDetour / walkingMetresPerMinute).ceil();

/// While the poll is open it stands where the Up next card would: the question, the three places with who voted for
/// each, the leading one marked, and the countdown. Tapping it opens the poll.
class PollCard extends StatelessWidget {
  const PollCard({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final leader = pollLeader(now);
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Dinner poll: ${votesIn(now)} of ${dinnerTable.length} voted, ${_countdown(now)}. Open',
      child: Container(
        width: TokDim.widgetMidWidth,
        padding: const EdgeInsets.fromLTRB(TokSpace.md, TokSpace.md, TokSpace.md, TokSpace.sm),
        decoration: surfaceDecoration(context, BorderRadius.circular(TokDim.surfaceRadius)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.x2xs, children: [
          Text('Poll · ${_countdown(now)}', textAlign: TextAlign.center, style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.textBrand)),
          Text('Where for dinner tonight?', textAlign: TextAlign.center, style: TokText.headingSm.copyWith(color: t.textDefault)),
          Text('5 PM · ${personById(pollAskedBy).name} asked · ${votesIn(now)} of ${dinnerTable.length} voted', textAlign: TextAlign.center, style: TokText.bodySm.copyWith(color: t.textMuted)),
          const SizedBox(height: TokSpace.xs),
          for (final o in pollOptions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TokSpace.x3xs),
              child: Row(spacing: TokSpace.xs, children: [
                SizedBox(width: TokDim.stickerAvatar, child: Center(child: Sticker(o.sticker, size: StickerSize.avatar))),
                Expanded(child: Text(o.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault))),
                if (o.id == leader) const PollTag('Leading'),
                if (votersOf(o.id, now) case final v when v.isNotEmpty) FacePile(faces: [for (final id in v) personById(id).sticker], size: StickerSize.chip),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// The poll: a card per place (its sticker, rating, food, price and how far it is), who voted for it, and Vote. Once
/// it has closed: which one won and went into tonight; after an Undo, a way to pick one by hand.
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
                Row(spacing: TokSpace.xs, children: [
                  if (voters.isNotEmpty) FacePile(faces: [for (final id in voters) personById(id).sticker], size: StickerSize.chip),
                  Text(voters.isEmpty ? 'No votes yet' : '${voters.length} ${voters.length == 1 ? 'vote' : 'votes'}', style: TokText.bodySm.copyWith(color: t.textMuted)),
                  if (won)
                    const PollTag('Tonight')
                  else if (o.id == leader)
                    PollTag(open ? 'Leading' : 'Won'),
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

/// A small brand pill: "Leading", "Won", "Tonight".
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
