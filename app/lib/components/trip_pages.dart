// The pages of the footer's three pop-ups: the itinerary, the group's money, and adding to the trip.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator, CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/material.dart' show Material, MaterialType, TextField, InputDecoration;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'segmented_tabs.dart';
import 'stagger.dart';
import 'toggle_chips.dart';
import 'trip_sheet.dart';

/// Every day of the trip, in order: where we've been, what's planned, and today marked. Tapping a stop shows it
/// on the map.
class ItineraryPage extends StatelessWidget {
  const ItineraryPage({super.key, this.onPick, this.onOpen, this.onPoll, this.days = const {}});

  /// A place we've been: show it on the map.
  final ValueChanged<LatLng>? onPick;

  /// A plan: open its details.
  final ValueChanged<Plan>? onOpen;

  /// The days picked in its filter; empty means all of them.
  final Set<int> days;

  /// Opens the dinner poll (from tonight's slot, while it isn't decided).
  final VoidCallback? onPoll;

  static String get subtitle => '${tripDays.first}–${tripDays.last} May · Day ${tripDays.indexOf(today) + 1} of ${tripDays.length}';

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final now = tripNow();
    final all = tripPlans;
    final next = all.where((p) => p.start.isAfter(now)).firstOrNull;
    // Today first, then the days ahead, then the ones behind us; a line between days, as on a place's Group page
    final order = [today, for (final d in tripDays) if (d > today) d, for (final d in tripDays) if (d < today) d];
    final shown = [for (final d in order) if (days.isEmpty || days.contains(d)) d];
    return StaggerIn(children: [
      for (final (k, day) in shown.indexed)
        () {
          final been = visited.where((v) => v.day == day).toList(), planned = all.where((p) => p.day == day).toList();
          final rows = <Widget>[
            for (final v in been)
              SheetRow(
                leading: RowThumb(sticker: v.sticker, tilt: v.tilt),
                title: v.name,
                subtitle: 'Been there',
                onTap: onPick == null ? null : () => onPick!(v.at),
              ),
            // Tonight's slot, until the poll has picked a place
            if (day == today && dinnerChoice(now) == null)
              SheetRow(
                leading: const RowThumb(icon: TuIcons.places),
                title: 'Dinner',
                subtitle: pollOpen(now)
                    ? 'Poll open · ${votesIn(now)} of ${dinnerTable.length} voted'
                    : pollClosed(now)
                        ? 'No place yet: pick one'
                        : 'Poll at ${clockTime(pollOpens)}',
                subtitleColor: t.textBrand,
                trailing: Text(clockTime(DateTime(tripYear, tripMonth, today, 17)), style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
                onTap: onPoll,
              ),
            for (final p in planned)
              SheetRow(
                leading: RowThumb(sticker: p.sticker),
                title: p.name,
                subtitle: [if (p == next) 'Up next', p.eta, if (p.end case final end?) 'until ${clockTime(end)}'].join(' · '),
                subtitleColor: p == next ? t.textBrand : null,
                trailing: Text(clockTime(p.start), style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
                onTap: onOpen == null ? null : () => onOpen!(p),
              ),
          ];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (k > 0) const Padding(padding: EdgeInsets.symmetric(vertical: TokSpace.xs), child: Hairline()),
            Padding(
              padding: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.xs, TokSpace.x2xs),
              child: Row(spacing: TokSpace.xs, children: [
                Text('${weekdayShort(DateTime(tripYear, tripMonth, day))} $day', style: TokText.headingSm.copyWith(color: day < today ? t.textMuted : t.textDefault)),
                // Today's tag at the far end of the line
                Expanded(child: Text('Day ${tripDays.indexOf(day) + 1}', style: TokText.bodySm.copyWith(color: t.textMuted))),
                if (day == today) _Tag('Today'),
              ]),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.xs),
                child: Text('Nothing planned yet', style: TokText.bodySm.copyWith(color: t.textMuted)),
              ),
            ...rows,
          ]);
        }(),
    ]);
  }
}

/// The group's money, one thing at a time in tabs: the fewest payments that square everyone up, each person's balance,
/// or the expenses (the list that grows all trip). Tonight's dinner joins once the bill comes. What I owe, and Pay, is
/// at the bottom (see MoneyFooter), in reach of the thumb.
class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  /// Opens on Settle up next time (Pay and back keep the tab it was on).
  static void startOver() => _MoneyPageState._lastTab = 0;

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  /// The payment whose "why" is open, if any.
  Payment? _why;

  /// Settle up, Balances or Expenses.
  static int _lastTab = 0;
  int _tab = _lastTab;

  String _name(String id) => personById(id).name;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([dinnerBill, madePayments, myPaying]),
        builder: (context, _) => _page(context),
      );

  Widget _page(BuildContext context) {
    final pays = settleUp;
    return StaggerIn(children: [
      SegmentedTabs(
        tabs: const ['Settle up', 'Balances', 'Expenses'],
        index: _tab,
        wide: true,
        onChanged: (i) => setState(() => _tab = _lastTab = i),
      ),
      // One tab's list at a time: it fades in, the last one fades out with a blur
      AnimatedSwitcher(
        duration: TokMotion.enter,
        reverseDuration: TokMotion.fade,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
        transitionBuilder: (child, anim) => child.key == ValueKey(_tab) ? FadeTransition(opacity: anim, child: child) : fadeBlurOut(anim, child),
        child: KeyedSubtree(
          key: ValueKey(_tab),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: switch (_tab) {
            0 => _settle(context, pays),
            1 => _balances(context),
            _ => _expenses(context),
          }),
        ),
      ),
    ]);
  }

  List<Widget> _settle(BuildContext context, List<Payment> pays) {
    final t = context.tok;
    return [
      SheetSection('Settle up', top: TokSpace.lg, subtitle: '${pays.length} payments square everyone, instead of $paymentsOneByOne'),
      for (final (i, p) in pays.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          leading: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x3xs, children: [
            _slot(Sticker(personById(p.from).sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
            LucideIcon(TuIcons.forward, size: TokSize.iconSm, color: t.iconMuted),
            _slot(Sticker(personById(p.to).sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
          ]),
          title: p.from == myId ? 'You pay ${_name(p.to)}' : '${_name(p.from)} pays ${_name(p.to)}',
          subtitle: '${_state(p)} · ${_why == p ? 'Hide why' : 'Why'}',
          subtitleColor: isPaid(p) ? t.textSuccess : null,
          trailing: Text(euros(p.amount), style: TokText.labelLg.copyWith(color: t.textDefault)),
          onTap: () => setState(() => _why = _why == p ? null : p),
        ),
        // Where the amount comes from: what they had, what they paid, and why it's one payment to this person
        AnimatedSize(
          duration: TokMotion.enter,
          curve: TokMotion.easeOut,
          alignment: Alignment.topCenter,
          child: _why == p ? _explain(context, p) : const SizedBox(width: double.infinity),
        ),
      ],
    ];
  }

  /// Paid; mine on its way (from my bank, or marked and waiting for them to confirm); or not yet.
  String _state(Payment p) => isPaid(p)
      ? 'Paid'
      : switch (myPaying.value) {
          (pay: final on, via: PayingVia.bank) when on == p => 'Paying…',
          (pay: final on, via: PayingVia.marked) when on == p => 'Waiting for ${_name(p.to)} to confirm',
          _ => 'Pending',
        };

  List<Widget> _balances(BuildContext context) {
    final t = context.tok;
    return [
      const SheetSection('Balances', top: TokSpace.lg, subtitle: 'Who gets money back, and who owes'),
      for (final (i, person) in people.indexed) ...[
        if (i > 0) const Hairline(),
        () {
          final b = balanceLeft(person.id);
          final joinedLate = person.joined > tripDays.first;
          return SheetRow(
            leading: _slot(Sticker(person.sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
            title: person.name,
            subtitle: b > 0.005
                ? 'Gets back'
                : b < -0.005
                    ? (person.id == myId ? 'You owe' : 'Owes')
                    : joinedLate && balanceOf(person.id).abs() < 0.005
                        ? 'Joined ${dayName(DateTime(tripYear, tripMonth, person.joined), tripNow()).toLowerCase()} · shares costs from then on'
                        : 'Square',
            trailing: b.abs() > 0.005 ? Text(euros(b.abs()), style: TokText.labelLg.copyWith(color: b > 0 ? t.textSuccess : t.textDefault)) : null,
          );
        }(),
      ],
    ];
  }

  List<Widget> _expenses(BuildContext context) {
    final t = context.tok;
    return [
      const SheetSection('Expenses', top: TokSpace.lg, subtitle: 'Newest first'),
      for (final (i, e) in tripExpenses.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          leading: _slot(Sticker(personById(e.paidBy).sticker, size: StickerSize.avatar), TokDim.stickerAvatar),
          title: e.title,
          subtitle: '${e.paidBy == myId ? 'You' : _name(e.paidBy)} paid · ${dayName(DateTime(tripYear, tripMonth, e.day), tripNow())} · ${e.split.length} people${e.shares != null ? ', by who had what' : ''}',
          trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, spacing: TokSpace.x3xs, children: [
            Text(euros(e.amount), style: TokText.labelLg.copyWith(color: t.textDefault)),
            if (e.shareOf(myId) > 0) Text('yours ${euros(e.shareOf(myId))}', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
      ],
    ];
  }
}

/// What I owe and Pay, as a rounded pill, while I owe it. Pay opens the payment (see [PayPage]); while it's on its way
/// the pill says so (my bank confirming it, or them confirming what I marked as paid). Once it's paid the pill goes
/// (the note at the top says it went through); nothing if I owe nobody.
class OwePill extends StatelessWidget {
  const OwePill({super.key, this.onPay});

  /// Pay: opens the payment.
  final ValueChanged<Payment>? onPay;

  /// The payment I still have to make, if any.
  static Payment? get owing {
    final mine = settleUp.where((p) => p.from == myId).firstOrNull;
    return mine == null || isPaid(mine) ? null : mine;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: Listenable.merge([dinnerBill, madePayments, myPaying]), builder: (context, _) => _pill(context));

  Widget _pill(BuildContext context) {
    final t = context.tok;
    final mine = owing;
    final othersPaid = settleUp.where((p) => p.from != myId).every(isPaid);
    final paying = myPaying.value;
    final via = paying != null && paying.pay == mine ? paying.via : null;
    final name = mine == null ? '' : personById(mine.to).name;
    // It fades away as Money's footer closes up under it (see MoneyFooter); on its way, the line and the end change over
    return AnimatedSwitcher(
      duration: TokMotion.enter,
      reverseDuration: TokMotion.fade,
      switchInCurve: TokMotion.easeOut,
      switchOutCurve: TokMotion.easeOut,
      child: mine == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Container(
              key: ValueKey((mine.to, via)),
              // xl in on the left, so the words sit clear of the curve
              padding: const EdgeInsets.fromLTRB(TokSpace.xl, TokSpace.xs, TokSpace.xs, TokSpace.xs),
              decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.pill)),
              child: Row(spacing: TokSpace.sm, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      switch (via) {
                        PayingVia.bank => 'Paying $name · your bank is confirming',
                        PayingVia.marked => 'Waiting for $name to confirm',
                        null => 'You owe $name${othersPaid && dinnerBill.value != null ? ' · Everyone else has paid' : ''}',
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TokText.bodySm.copyWith(color: t.textMuted),
                    ),
                    Text(euros(mine.amount), maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingSm.copyWith(color: t.textDefault)),
                  ]),
                ),
                // As high as Pay, so the pill keeps its height when Pay gives way
                SizedBox(
                  height: TuButton.sizeOf(TuButtonSize.md),
                  child: switch (via) {
                    null => TuTextButton(label: 'Pay', onTap: onPay == null ? null : () => onPay!(mine)),
                    PayingVia.bank => Padding(padding: const EdgeInsets.only(right: TokSpace.sm), child: CupertinoActivityIndicator(color: t.iconMuted)),
                    PayingVia.marked => Padding(padding: const EdgeInsets.only(right: TokSpace.sm), child: LucideIcon(TuIcons.hours, size: TokSize.iconMd, color: t.iconMuted)),
                  },
                ),
              ]),
            ),
    );
  }
}

/// Money's bottom, in view while the lists scroll: what I owe and Pay (OwePill, while I owe it), just above it where the
/// thumb reaches; then, over a hairline, what the trip has cost so far and my part of it, like the Menu's total; while
/// the dinner is on and its bill isn't in, Scan the bill under it.
class MoneyFooter extends StatelessWidget {
  const MoneyFooter({super.key, this.onScan, this.onPay});
  final VoidCallback? onScan;

  /// The pill's Pay.
  final ValueChanged<Payment>? onPay;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([dinnerBill, madePayments, myPaying]),
        builder: (context, _) {
          final t = context.tok;
          final mine = tripExpenses.fold(0.0, (sum, e) => sum + e.shareOf(myId));
          final scan = dinnerBill.value == null && isActive(plans.first, tripNow());
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AnimatedSize(
              duration: TokMotion.enter,
              curve: TokMotion.easeOut,
              alignment: Alignment.bottomCenter,
              child: Padding(padding: EdgeInsets.only(bottom: OwePill.owing != null ? TokSpace.sm : 0), child: OwePill(onPay: onPay)),
            ),
            SheetFooter(children: [
              Row(spacing: TokSpace.sm, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
                    Text('Spent so far', style: TokText.labelLg.copyWith(color: t.textDefault)),
                    Text('${tripExpenses.length} expenses · yours ${euros(mine)}', style: TokText.bodySm.copyWith(color: t.textMuted)),
                  ]),
                ),
                Text(euros(spentSoFar), style: TokText.headingLg.copyWith(color: t.textDefault)),
              ]),
              if (scan) TuTextButton(label: 'Scan the bill', size: TuButtonSize.lg, wide: true, onTap: onScan),
            ]),
          ]);
        },
      );
}

/// Why a payment is what it is: [p.from]'s share of each expense, what they paid, and why it all goes to [p.to].
Widget _explain(BuildContext context, Payment p) {
  final t = context.tok;
  String who(String id, {bool start = false}) => id == myId ? (start ? 'You' : 'you') : personById(id).name;
  final had = [for (final e in tripExpenses) if (e.shareOf(p.from) > 0) (e.title, e.shareOf(p.from))];
  final share = had.fold(0.0, (s, h) => s + h.$2), paid = tripExpenses.where((e) => e.paidBy == p.from).fold(0.0, (s, e) => s + e.amount);
  final oneByOne = tripExpenses.where((e) => e.shareOf(p.from) > 0 && e.paidBy != p.from).length;
  final style = TokText.bodySm.copyWith(color: t.textMuted);
  return Padding(
    padding: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.xs, TokSpace.sm),
    child: Container(
      padding: const EdgeInsets.all(TokSpace.sm),
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.x3xs, children: [
        for (final (title, amount) in had)
          Row(children: [Expanded(child: Text(title, style: style)), Text(euros(amount), style: style)]),
        if (paid > 0) Row(children: [Expanded(child: Text('Paid for the group', style: style)), Text('−${euros(paid)}', style: style)]),
        const SizedBox(height: TokSpace.x2xs),
        Text(
          '${who(p.from, start: true)} had ${euros(share)} of it all${paid > 0 ? ' and paid ${euros(paid)}' : ''}, so ${p.from == myId ? 'you owe' : 'owes'} ${euros(p.amount)}. '
          '${who(p.to, start: true)} paid the most for everyone, so it goes to ${who(p.to)} in one payment instead of $oneByOne.',
          style: TokText.bodySm.copyWith(color: t.textDefault),
        ),
      ]),
    ),
  );
}

/// Where Money is: the group's money, paying what I owe, or picking my bank (the first time I pay).
enum MoneyStep { list, pay, bank }

/// Money's page for each step, one at a time like Add's: it fades in, the last one fades out with a blur. The pop-up's
/// header follows the step (see [MoneyFlow.headerOf]), with Back from paying to the money and from the bank to paying.
class MoneyFlow extends StatelessWidget {
  const MoneyFlow({super.key, required this.step, this.pay, this.onBank, this.onChangeBank});
  final MoneyStep step;

  /// Paying's From: back to the bank list, to pay from another one.
  final VoidCallback? onChangeBank;

  /// What I'm paying (on the pay and bank steps).
  final Payment? pay;

  /// A bank picked: TripUp remembers it and opens it to approve.
  final ValueChanged<Bank>? onBank;

  /// The pop-up's title and the line at the top of its page, for each step.
  static (String, String?) headerOf(MoneyStep step, Payment? pay) => switch (step) {
        MoneyStep.list => ('Money', null),
        MoneyStep.pay => ('Pay ${personById(pay!.to).name}', "It goes straight from your bank to ${personById(pay.to).name}'s. TripUp never holds the money."),
        MoneyStep.bank => ('Your bank', "Pick it once and TripUp remembers it. You approve each payment in your bank's app; TripUp never sees your login."),
      };

  /// The pop-up's footer for each step: the total (and what I owe) on the money; Pay with the bank, or Mark as paid,
  /// while paying; nothing on the bank list (a tap on a bank is the step). The old one fades out as the footer
  /// takes the new one's height, and the new one comes in once it has mostly gone, so the two never overlap.
  static Widget footer({required MoneyStep step, Payment? pay, VoidCallback? onScan, ValueChanged<Payment>? onPay, VoidCallback? onBankPay, VoidCallback? onMarked}) => AnimatedSize(
        duration: TokMotion.enter,
        curve: TokMotion.easeOut,
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: TokMotion.enter,
          reverseDuration: TokMotion.fade,
          switchInCurve: TokMotion.swapIn,
          switchOutCurve: TokMotion.easeOut,
          layoutBuilder: (current, previous) => Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
          child: KeyedSubtree(
            key: ValueKey(step),
            child: switch (step) {
              MoneyStep.list => MoneyFooter(onScan: onScan, onPay: onPay),
              MoneyStep.pay => _PayFooter(pay: pay!, onBank: onBankPay, onMarked: onMarked),
              MoneyStep.bank => const SizedBox(width: double.infinity),
            },
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: TokMotion.enter,
        reverseDuration: TokMotion.fade,
        switchInCurve: TokMotion.easeOut,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
        transitionBuilder: (child, anim) => child.key == ValueKey(step) ? FadeTransition(opacity: anim, child: child) : fadeBlurOut(anim, child),
        child: KeyedSubtree(
          key: ValueKey(step),
          child: switch (step) {
            MoneyStep.list => const MoneyPage(),
            MoneyStep.pay => PayPage(pay: pay!, onChangeBank: onChangeBank),
            MoneyStep.bank => BankPage(onPick: onBank),
          },
        ),
      );
}

/// Paying what I owe: how much and to whom, big; then what the transfer will say (their account, my bank once I've
/// picked it, the reference that tells them what it's for, and that it arrives in seconds), and why it's that much.
/// Pay with the bank and Mark as paid are in the footer.
class PayPage extends StatefulWidget {
  const PayPage({super.key, required this.pay, this.onChangeBank});
  final Payment pay;

  /// A tap on From: pick another bank.
  final VoidCallback? onChangeBank;

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  bool _why = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final p = widget.pay, to = personById(p.to);
    return ValueListenableBuilder(
      valueListenable: myBank,
      builder: (context, bank, _) => StaggerIn(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: TokSpace.xl),
          child: Column(spacing: TokSpace.xs, children: [
            Sticker(to.sticker, height: TokDim.payAmountSticker),
            Text(euros(p.amount), style: TokText.display.copyWith(color: t.textDefault)),
            Text('to ${to.name}', style: TokText.bodyMd.copyWith(color: t.textMuted)),
          ]),
        ),
        // Inset like the lines of a list, as Why's breakdown is
        Container(
          margin: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm, vertical: TokSpace.x2xs),
          decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.card)),
          child: Column(children: [
            _PayLine('To', '${to.name} · ${accountOf(to.id)}'),
            if (bank != null) _PayLine('From', bank.name, onTap: widget.onChangeBank),
            _PayLine('Reference', payReference(p)),
            const _PayLine('Arrives', 'In seconds'),
          ]),
        ),
        SheetRow(
          title: 'Why ${euros(p.amount)}',
          subtitle: _why ? 'Hide why' : 'What you had, and what you paid',
          trailing: LucideIcon(_why ? TuIcons.fold : TuIcons.unfold, size: TokSize.iconSm, color: t.iconMuted),
          onTap: () => setState(() => _why = !_why),
        ),
        AnimatedSize(
          duration: TokMotion.enter,
          curve: TokMotion.easeOut,
          alignment: Alignment.topCenter,
          child: _why ? _explain(context, p) : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }
}

/// One line of what the transfer will say: what it is on the left, the value on the right (with an arrow when a tap
/// changes it).
class _PayLine extends StatelessWidget {
  const _PayLine(this.label, this.value, {this.onTap});
  final String label, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: TokSpace.xs),
      child: Row(spacing: TokSpace.sm, children: [
        Text(label, style: TokText.bodySm.copyWith(color: t.textMuted)),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: TokText.labelMd.copyWith(color: t.textDefault))),
        if (onTap != null) LucideIcon(TuIcons.next, size: TokSize.iconSm, color: t.iconMuted),
      ]),
    );
    return onTap == null ? line : Pressable(onTap: onTap, semanticLabel: '$label: $value', child: line);
  }
}

/// Paying's footer: Pay with my bank (named once TripUp knows it), and Mark as paid for money that went another way.
class _PayFooter extends StatelessWidget {
  const _PayFooter({required this.pay, this.onBank, this.onMarked});
  final Payment pay;
  final VoidCallback? onBank, onMarked;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: myBank,
        builder: (context, bank, _) => SheetFooter(
          note: 'Paid in cash or another way? ${personById(pay.to).name} confirms it.',
          children: [
            TuTextButton(label: 'Pay with ${bank?.name ?? 'your bank'}', size: TuButtonSize.lg, wide: true, onTap: onBank),
            TuTextButton(label: 'Mark as paid', kind: GlassKind.soft, size: TuButtonSize.lg, wide: true, onTap: onMarked),
          ],
        ),
      );
}

/// The banks I can pay from, the first time I pay: a tap picks one and opens it to approve.
class BankPage extends StatelessWidget {
  const BankPage({super.key, this.onPick});
  final ValueChanged<Bank>? onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return StaggerIn(children: [
      for (final (i, b) in banks.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          leading: BankLogo(b),
          title: b.name,
          trailing: LucideIcon(TuIcons.next, size: TokSize.iconSm, color: t.iconMuted),
          onTap: onPick == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPick!(b);
                },
        ),
      ],
    ]);
  }
}

/// A bank's mark in TripUp's lists: its first letter on a disc (the real app would show the bank's logo).
class BankLogo extends StatelessWidget {
  const BankLogo(this.bank, {super.key, this.size = TokDim.bankLogo});
  final Bank bank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.bgMuted, shape: BoxShape.circle),
      child: Text(bank.name.characters.first, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
    );
  }
}

/// What Add to the trip shows: the two choices, or one of them.
enum AddStep { choose, plan, invite }

/// What's being planned in Add: the place picked from the search (none yet), and when: a day, and a time range in
/// minutes from midnight. The page edits it; the pop-up's footer sends it, and its Back puts the place down again.
class PlanDraft extends ChangeNotifier {
  PlanDraft() {
    reset();
  }

  PlaceSpot? _spot;
  PlaceSpot? get spot => _spot;
  late int _day, _from, _to;
  int get day => _day;
  int get from => _from;
  int get to => _to;

  void pick(PlaceSpot? spot) {
    _spot = spot;
    notifyListeners();
  }

  void setDay(int d) {
    _day = d;
    notifyListeners();
  }

  void setFrom(int m) {
    _from = m;
    if (_to <= _from) _to = math.min(_from + 60, 23 * 60 + 45);
    notifyListeners();
  }

  void setTo(int m) {
    _to = math.max(m, _from + 15);
    notifyListeners();
  }

  /// No place yet, and tonight from 6 to 8, or from the next hour if it's already later; tomorrow once the evening is gone.
  void reset() {
    final now = tripNow();
    final late = now.hour >= 21;
    _spot = null;
    _day = late && tripDays.contains(today + 1) ? today + 1 : today;
    _from = _day == today && now.hour >= 17 ? (now.hour + 1) * 60 : 18 * 60;
    _to = math.min(_from + 120, 23 * 60 + 45);
    notifyListeners();
  }

  /// Puts it on everyone's itinerary and map.
  Plan send() {
    final s = _spot!;
    final plan = Plan(
      id: 'added-${s.id}-$_day-$_from',
      name: s.name,
      sticker: s.sticker,
      at: s.at,
      day: _day,
      hour: _from ~/ 60,
      minute: _from % 60,
      endHour: _to ~/ 60,
      endMinute: _to % 60,
    );
    HapticFeedback.mediumImpact();
    addedPlans.value = [...addedPlans.value, plan];
    return plan;
  }
}

/// Adding to the trip: a plan (find a place, pick a day and a time, send it to everyone's itinerary and map) or someone
/// new (a link: no account, and they only share costs from the day they join). The step lives with the pop-up, whose
/// header follows it: its title, and a way back.
class AddPage extends StatefulWidget {
  const AddPage({super.key, required this.step, required this.onStep, required this.draft, this.mapOf});
  final AddStep step;
  final ValueChanged<AddStep> onStep;

  /// The plan being made (its Send is in the pop-up's footer: see [AddPage.footer]).
  final PlanDraft draft;

  /// A small still map of a place, with its sticker on it.
  final Widget Function(LatLng at, String sticker)? mapOf;

  /// The pop-up's title and the line at the top of its page, for each step (Invite's page says it itself).
  static (String, String?) headerOf(AddStep step) => switch (step) {
        AddStep.choose => ('Add to the trip', null),
        AddStep.plan => ('Plan something', null),
        AddStep.invite => ('Invite someone', null),
      };

  static const link = 'tripup.app/j/lisbon-may';

  /// The pop-up's footer for each step: once a place is picked, Send; for Invite, Copy link. Nothing while choosing or
  /// searching.
  static Widget footer({required AddStep step, required PlanDraft draft, required ValueChanged<Plan> onSent}) => ListenableBuilder(
        listenable: draft,
        builder: (context, _) => AnimatedSize(
          duration: TokMotion.enter,
          curve: TokMotion.easeOut,
          alignment: Alignment.topCenter,
          child: switch (step) {
            AddStep.plan when draft.spot != null => SheetFooter(
                note: "It goes on everyone's itinerary and map.",
                children: [TuTextButton(label: 'Send to the group', size: TuButtonSize.lg, wide: true, onTap: () => onSent(draft.send()))],
              ),
            AddStep.invite => SheetFooter(children: [
                TuTextButton(
                  label: 'Copy link',
                  size: TuButtonSize.lg,
                  wide: true,
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'https://$link'));
                    tripNotice.value = 'Link copied';
                  },
                ),
              ]),
            _ => const SizedBox(width: double.infinity),
          },
        ),
      );

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  /// Which time's wheel is open: 'from', 'to', or none.
  String? _editing;

  PlanDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _draft.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    if (_draft.spot == null) _editing = null;
    setState(() {});
  }

  @override
  void didUpdateWidget(AddPage old) {
    super.didUpdateWidget(old);
    if (old.draft != widget.draft) {
      old.draft.removeListener(_changed);
      widget.draft.addListener(_changed);
    }
    // Back to the choice starts a plan over next time
    if (widget.step == AddStep.choose && old.step != AddStep.choose) {
      _query.clear();
      _editing = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _draft.reset());
    }
  }

  @override
  void dispose() {
    _draft.removeListener(_changed);
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(AddStep step) {
    HapticFeedback.selectionClick();
    widget.onStep(step);
  }

  void _pick(PlaceSpot spot) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    _editing = null;
    _draft.pick(spot);
  }

  // One step (or, in Plan, the search and then the place) at a time: it fades in, the last one fades out with a blur
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: TokMotion.enter,
        reverseDuration: TokMotion.fade,
        switchInCurve: TokMotion.easeOut,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
        transitionBuilder: (child, anim) => child.key == ValueKey((widget.step, _draft.spot?.id)) ? FadeTransition(opacity: anim, child: child) : fadeBlurOut(anim, child),
        child: KeyedSubtree(
          key: ValueKey((widget.step, _draft.spot?.id)),
          child: switch (widget.step) {
            AddStep.choose => _choose(context),
            AddStep.plan => _draft.spot == null ? _search(context) : _when(context, _draft.spot!),
            AddStep.invite => _invite(context),
          },
        ),
      );

  /// The two choices, as plain lines: what it is, a word on it, and an arrow.
  Widget _choose(BuildContext context) => StaggerIn(children: [
        _Choice(title: 'Plan something', subtitle: "A place to eat, see or do. It goes on everyone's itinerary and map.", onTap: () => _go(AddStep.plan)),
        const Hairline(),
        _Choice(title: 'Invite someone', subtitle: 'They join with a link, no account. They only share costs from the day they join.', onTap: () => _go(AddStep.invite)),
      ]);

  /// The link, in the middle of the sheet (Copy link is in the footer).
  Widget _invite(BuildContext context) {
    final t = context.tok;
    return StaggerIn(spacing: TokSpace.md, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Column(spacing: TokSpace.x2xs, children: [
        Text('Send them this link', textAlign: TextAlign.center, style: TokText.headingSm.copyWith(color: t.textDefault)),
        Text("Share it with a friend. They type their name and they're in.", textAlign: TextAlign.center, style: TokText.bodySm.copyWith(color: t.textMuted)),
      ]),
      Container(
        height: TokDim.buttonLg,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
        decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.pill)),
        child: Text(AddPage.link, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelLg.copyWith(color: t.textDefault)),
      ),
    ]);
  }

  /// Finding a place: a search over Lisbon (by name, kind or neighbourhood); before you type, what's near you.
  Widget _search(BuildContext context) {
    final t = context.tok;
    final now = tripNow(), q = _query.text.trim();
    final found = [for (final s in lisbonPlaces) if (s.matches(q)) s];
    if (q.isEmpty) found.sort((a, b) => walkMinutesTo(a.at, now).compareTo(walkMinutesTo(b.at, now)));
    final shown = q.isEmpty ? found.take(5).toList() : found;
    return StaggerIn(children: [
      Container(
        height: TokDim.buttonLg,
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
        decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.pill)),
        child: Row(spacing: TokSpace.xs, children: [
          LucideIcon(TuIcons.search, size: TokSize.iconSm, color: t.iconMuted),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _query,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                style: TokText.labelLg.copyWith(color: t.textDefault),
                decoration: const InputDecoration.collapsed(hintText: 'Search places in Lisbon'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          if (q.isNotEmpty)
            Pressable(
              onTap: () => setState(_query.clear),
              semanticLabel: 'Clear the search',
              child: LucideIcon(TuIcons.close, size: TokSize.iconSm, color: t.iconMuted),
            ),
        ]),
      ),
      SheetSection(
        q.isEmpty ? 'Near you' : (found.isEmpty ? 'Nothing found' : '${found.length} ${found.length == 1 ? 'place' : 'places'}'),
        top: TokSpace.lg,
        subtitle: q.isEmpty ? 'Or search for anywhere in Lisbon' : (found.isEmpty ? 'Try a name, a kind of place or a neighbourhood' : null),
      ),
      for (final (i, s) in shown.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          leading: RowThumb(sticker: s.sticker),
          title: s.name,
          subtitle: '${s.kind} · ${s.area} · ${walkLabel(s.at, now)}',
          trailing: LucideIcon(TuIcons.forward, size: TokSize.iconSm, color: t.iconMuted),
          onTap: () => _pick(s),
        ),
      ],
    ]);
  }

  /// The place you picked, on a small map (its sticker is on it), then when: a day, from and to. Send is in the footer;
  /// a different place is the header's Back.
  Widget _when(BuildContext context, PlaceSpot s) {
    final t = context.tok;
    final now = tripNow();
    final at = DateTime(tripYear, tripMonth, _draft.day);
    return StaggerIn(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(TokRadius.card),
        child: SizedBox(height: TokDim.planMapHeight, child: widget.mapOf?.call(s.at, s.sticker) ?? ColoredBox(color: t.bgMuted)),
      ),
      SheetRow(title: s.name, subtitle: '${s.kind} · ${s.area} · ${walkLabel(s.at, now)}'),
      const SheetSection('When', top: TokSpace.lg),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        clipBehavior: Clip.none,
        child: Row(spacing: TokDim.toggleChipGap, children: [
          for (final d in tripDays)
            if (d >= today)
              ToggleChip(
                label: dayName(DateTime(tripYear, tripMonth, d), now),
                on: d == _draft.day,
                onTap: () => _draft.setDay(d),
              ),
        ]),
      ),
      const SizedBox(height: TokSpace.sm),
      _time(context, 'From', 'from', _draft.from, at, _draft.setFrom),
      const Hairline(),
      _time(context, 'To', 'to', _draft.to, at, _draft.setTo),
    ]);
  }

  /// A time: its label and value; tapping it opens a wheel under it (15-minute steps), and closes it again.
  Widget _time(BuildContext context, String label, String key, int minutes, DateTime day, void Function(int) set) {
    final t = context.tok;
    final open = _editing == key;
    final value = day.add(Duration(minutes: minutes));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _editing = open ? null : key);
        },
        semanticLabel: '$label ${clockTime(value)}',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
          child: Row(children: [
            Expanded(child: Text(label, style: TokText.labelLg.copyWith(color: t.textDefault))),
            Text(clockTime(value), style: TokText.labelLg.copyWith(fontWeight: TokWeight.semibold, color: open ? t.textBrand : t.textDefault)),
          ]),
        ),
      ),
      AnimatedSize(
        duration: TokMotion.enter,
        curve: TokMotion.easeOut,
        alignment: Alignment.topCenter,
        child: !open
            ? const SizedBox(width: double.infinity)
            : SizedBox(
                height: TokDim.planPickerHeight,
                child: CupertinoDatePicker(
                  key: ValueKey('$key-${_draft.day}'),
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 15,
                  initialDateTime: value,
                  onDateTimeChanged: (d) => set(d.hour * 60 + d.minute),
                ),
              ),
      ),
    ]);
  }
}

/// One of Add's two choices: a big title, a line on it, and an arrow; no box around it.
class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.subtitle, required this.onTap});
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.md),
        child: Row(spacing: TokSpace.md, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
              Text(title, style: TokText.headingSm.copyWith(color: t.textDefault)),
              Text(subtitle, style: TokText.bodySm.copyWith(color: t.textMuted)),
            ]),
          ),
          LucideIcon(TuIcons.forward, size: TokSize.iconSm, color: t.iconMuted),
        ]),
      ),
    );
  }
}

/// The demo's moments of the brief's story, in order: tap one to jump there. The ones the app doesn't have yet are
/// listed too, greyed out, so the list doubles as what's left to build.
class StoryPage extends StatelessWidget {
  const StoryPage({super.key, this.onPick});
  final ValueChanged<StoryMoment>? onPick;

  static const subtitle = "Jump to a moment in the brief's scenario";

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final current = demoMoment.value ?? storyMoments.firstWhere((m) => m.at == tripNowAtLaunch);
    return StaggerIn(children: [
      for (final (i, m) in storyMoments.indexed) ...[
        if (i > 0) const Hairline(),
        SheetRow(
          title: m.title,
          subtitle: [
            'Step ${m.steps}',
            if (m.at != null) '${dayName(m.at!, tripNowAtLaunch)}, ${clockTime(m.at!)}',
            if (!m.built) 'Not built yet',
          ].join(' · '),
          muted: !m.built,
          trailing: m == current ? LucideIcon(TuIcons.check, size: TokSize.iconSm, color: t.iconBrand) : null,
          onTap: m.built && onPick != null ? () => onPick!(m) : null,
        ),
      ],
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
