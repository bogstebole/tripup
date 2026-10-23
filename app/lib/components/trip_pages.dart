// The pages of the footer's three pop-ups: the itinerary, the group's money, and adding to the trip.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'stagger.dart';
import 'trip_sheet.dart';

/// Every day of the trip, in order: where we've been, what's planned, and today marked. Tapping a stop shows it
/// on the map.
class ItineraryPage extends StatelessWidget {
  const ItineraryPage({super.key, this.onPick, this.todayKey});
  final ValueChanged<LatLng>? onPick;

  /// Put on today's block, so the pop-up can open there.
  final GlobalKey? todayKey;

  static String get subtitle => '${tripDays.first}–${tripDays.last} May · Day ${tripDays.indexOf(today) + 1} of ${tripDays.length}';

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final all = tripPlans;
    final next = all.where((p) => p.start.isAfter(now)).firstOrNull;
    return StaggerIn(children: [
      for (final (i, day) in tripDays.indexed)
        () {
          final been = visited.where((v) => v.day == day).toList(), planned = all.where((p) => p.day == day).toList();
          final rows = <Widget>[
            for (final v in been)
              SheetRow(
                leading: _slot(Sticker(v.sticker, size: StickerSize.row, tilt: v.tilt)),
                title: v.name,
                subtitle: 'Been there',
                trailing: LucideIcon(TuIcons.check, size: TokSize.iconSm, color: t.iconSuccess),
                onTap: onPick == null ? null : () => onPick!(v.at),
              ),
            for (final p in planned)
              SheetRow(
                leading: _slot(Sticker(p.sticker, size: StickerSize.row)),
                title: p.name,
                subtitle: p == next ? 'Up next · ${p.eta}' : p.eta,
                subtitleColor: p == next ? t.textBrand : null,
                trailing: Text(clockTime(p.start), style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
                onTap: onPick == null ? null : () => onPick!(p.at),
              ),
          ];
          return Column(key: day == today ? todayKey : null, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: EdgeInsets.fromLTRB(TokSpace.xs, i == 0 ? 0 : TokSpace.xl, TokSpace.xs, TokSpace.x2xs),
              child: Row(spacing: TokSpace.xs, children: [
                Text('${weekdayShort(DateTime(tripYear, tripMonth, day))} $day', style: TokText.headingSm.copyWith(color: day < today ? t.textMuted : t.textDefault)),
                Text('Day ${i + 1}', style: TokText.bodySm.copyWith(color: t.textMuted)),
                if (day == today) _Tag('Today'),
              ]),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.xs),
                child: Text('Nothing planned yet', style: TokText.bodySm.copyWith(color: t.textSubtle)),
              ),
            for (final (j, r) in rows.indexed) ...[if (j > 0) const Hairline(), r],
          ]);
        }(),
    ]);
  }
}

/// The group's money: what I owe (and paying it), what's been spent, the fewest payments that square everyone up,
/// each person's balance, and the expenses. Tonight's dinner joins once the bill comes; until then it's an estimate.
class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key, this.toast});
  final ValueNotifier<String?>? toast;

  static String get subtitle => '${euros(spentSoFar)} spent so far · ${expenses.length} expenses';

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  /// Whether I've paid my part (in the prototype, only mine can be paid from here).
  bool _paid = false;

  String _name(String id) => personById(id).name;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pays = settleUp;
    final mine = pays.where((p) => p.from == myId).firstOrNull;
    double balance(String id) => balanceOf(id) + (_paid && mine != null ? (id == myId ? mine.amount : id == mine.to ? -mine.amount : 0) : 0);
    final estimate = dinnerEstimate;
    return StaggerIn(children: [
      if (mine != null)
        Container(
          padding: const EdgeInsets.all(TokSpace.md),
          decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.sheet)),
          child: Row(spacing: TokSpace.sm, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
                Text(_paid ? "You're square with ${_name(mine.to)}" : 'You owe ${_name(mine.to)}', style: TokText.labelLg.copyWith(color: t.textDefault)),
                Text(_paid ? 'Paid ${euros(mine.amount)}' : euros(mine.amount), style: (_paid ? TokText.bodySm : TokText.headingLg).copyWith(color: _paid ? t.textSuccess : t.textDefault)),
              ]),
            ),
            if (_paid)
              LucideIcon(TuIcons.done, size: TokSize.iconMd, color: t.iconSuccess)
            else
              TuTextButton(
                label: 'Pay',
                onTap: () {
                  setState(() => _paid = true);
                  widget.toast?.value = 'Paid ${_name(mine.to)} ${euros(mine.amount)}';
                },
              ),
          ]),
        ),
      if (estimate != null && estimate > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.md, TokSpace.xs, 0),
          child: Text("Tonight's dinner isn't on it yet: about ${euros(estimate)}, from what everyone picked. It splits by who had what.",
              style: TokText.bodySm.copyWith(color: t.textMuted)),
        ),
      SheetSection('Settle up', subtitle: '${pays.length} payments square everyone, instead of $paymentsOneByOne'),
      for (final (i, p) in pays.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          leading: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x3xs, children: [
            _slot(Sticker(personById(p.from).sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
            LucideIcon(TuIcons.forward, size: TokSize.iconSm, color: t.iconMuted),
            _slot(Sticker(personById(p.to).sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
          ]),
          title: p.from == myId ? 'You pay ${_name(p.to)}' : '${_name(p.from)} pays ${_name(p.to)}',
          subtitle: p == mine && _paid ? 'Paid' : 'Pending',
          subtitleColor: p == mine && _paid ? t.textSuccess : null,
          trailing: Text(euros(p.amount), style: TokText.labelLg.copyWith(color: t.textDefault)),
        ),
      ],
      const SheetSection('Balances'),
      for (final (i, person) in people.indexed) ...[
        if (i > 0) const Hairline(),
        () {
          final b = balance(person.id);
          final joinedLate = person.joined > tripDays.first;
          return SheetRow(
            leading: _slot(Sticker(person.sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
            title: person.name,
            subtitle: b > 0.005
                ? 'Gets back'
                : b < -0.005
                    ? (person.id == myId ? 'You owe' : 'Owes')
                    : joinedLate
                        ? 'Joined ${dayName(DateTime(tripYear, tripMonth, person.joined), tripNow()).toLowerCase()} · shares costs from then on'
                        : 'Square',
            trailing: b.abs() > 0.005 ? Text(euros(b.abs()), style: TokText.labelLg.copyWith(color: b > 0 ? t.textSuccess : t.textDefault)) : null,
          );
        }(),
      ],
      const SheetSection('Expenses', subtitle: 'Newest first'),
      for (final (i, e) in expenses.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          leading: _slot(Sticker(personById(e.paidBy).sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
          title: e.title,
          subtitle: '${e.paidBy == myId ? 'You' : _name(e.paidBy)} paid · ${dayName(DateTime(tripYear, tripMonth, e.day), tripNow())} · ${e.split.length} people',
          trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, spacing: TokSpace.x3xs, children: [
            Text(euros(e.amount), style: TokText.labelLg.copyWith(color: t.textDefault)),
            if (e.split.contains(myId)) Text('yours ${euros(e.shareOf(myId))}', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
      ],
    ]);
  }
}

/// Adding to the trip: a plan (a place to go, put in a free slot on everyone's itinerary and map) or someone new
/// (a link: no account, and they only share costs from the day they join).
class AddPage extends StatefulWidget {
  const AddPage({super.key, this.toast});
  final ValueNotifier<String?>? toast;

  static const subtitle = 'A plan, or someone new';

  @override
  State<AddPage> createState() => _AddPageState();
}

enum _AddStep { choose, plan, invite }

class _AddPageState extends State<AddPage> {
  var _step = _AddStep.choose;

  static const _link = 'tripup.app/j/lisbon-may';

  void _go(_AddStep s) {
    HapticFeedback.selectionClick();
    setState(() => _step = s);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: TokMotion.fade,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
        transitionBuilder: (child, anim) => child.key == ValueKey(_step) ? child : fadeBlurOut(anim, child),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: switch (_step) {
            _AddStep.choose => _choose(context),
            _AddStep.plan => _plan(context),
            _AddStep.invite => _invite(context),
          },
        ),
      );

  Widget _choose(BuildContext context) {
    final t = context.tok;
    return StaggerIn(spacing: TokSpace.xs, children: [
      KnowRow(
        title: 'Plan something',
        subtitle: "A place to eat, see or do. It goes on everyone's itinerary and map.",
        leading: LucideIcon(TuIcons.plan, size: TokSize.iconMd, color: t.iconBrand),
        onTap: () => _go(_AddStep.plan),
      ),
      KnowRow(
        title: 'Invite someone',
        subtitle: 'They join with a link, no account. They only share costs from the day they join.',
        leading: LucideIcon(TuIcons.invite, size: TokSize.iconMd, color: t.iconBrand),
        onTap: () => _go(_AddStep.invite),
      ),
    ]);
  }

  Widget _back(BuildContext context) {
    final t = context.tok;
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: () => _go(_AddStep.choose),
        semanticLabel: 'Back',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.x2xs),
          child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x3xs, children: [
            LucideIcon(TuIcons.backSmall, size: TokSize.iconSm, color: t.textBrand),
            Text('Back', style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textBrand)),
          ]),
        ),
      ),
    );
  }

  Widget _plan(BuildContext context) => ValueListenableBuilder<List<Plan>>(
        valueListenable: addedPlans,
        builder: (context, added, _) => StaggerIn(children: [
          _back(context),
          const SheetSection('Ideas nearby', top: TokSpace.md, subtitle: 'Each one goes in a free slot. Everyone sees it on their map.'),
          for (final (i, idea) in planIdeas.indexed) ...[
            if (i > 0) const Hairline(),
            () {
              final on = added.any((p) => p.id == idea.id);
              final slot = '${dayName(idea.plan.start, tripNow())}, ${clockTime(idea.plan.start)}';
              return SheetRow(
                leading: _slot(Sticker(idea.sticker, size: StickerSize.row)),
                title: idea.name,
                subtitle: '${idea.kind} · $slot',
                trailing: AddButton(
                  added: on,
                  itemName: idea.name,
                  onTap: () {
                    addedPlans.value = on ? [for (final p in added) if (p.id != idea.id) p] : [...added, idea.plan];
                    if (!on) widget.toast?.value = 'Added for $slot';
                  },
                ),
              );
            }(),
          ],
        ]),
      );

  Widget _invite(BuildContext context) {
    final t = context.tok;
    return StaggerIn(children: [
      _back(context),
      const SheetSection('Invite someone', top: TokSpace.md, subtitle: 'Send them this link. They type their name and they\'re in.'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        child: Container(
          padding: const EdgeInsets.fromLTRB(TokSpace.md, TokSpace.xs, TokSpace.xs, TokSpace.xs),
          decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.pill)),
          child: Row(spacing: TokSpace.sm, children: [
            Expanded(child: Text(_link, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelLg.copyWith(color: t.textDefault))),
            TuTextButton(
              label: 'Copy link',
              icon: TuIcons.copy,
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://$_link'));
                widget.toast?.value = 'Link copied';
              },
            ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.md, TokSpace.xs, 0),
        child: Text(
          "No account needed. They see the trip so far, and only costs from the day they join are theirs: Ren joined today, so the €${spentSoFar.toStringAsFixed(0)} from before stays with the four of you.",
          style: TokText.bodySm.copyWith(color: t.textMuted),
        ),
      ),
    ]);
  }
}

/// Stickers come in their own widths; a fixed slot keeps the names after them in one line.
Widget _slot(Widget sticker, [double width = TokDim.stickerRow]) => SizedBox(width: width, child: Center(child: sticker));

/// A small brand pill next to a heading ("Today").
class _Tag extends StatelessWidget {
  const _Tag(this.label);
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
