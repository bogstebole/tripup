// Joining a trip mid-way, from the invite link: what the new person sees on their own phone.
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType, TextField, InputDecoration;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'detail_sheet.dart' show openDirections, openWebsite;
import 'glass.dart';
import 'progressive_blur.dart';
import 'stagger.dart';
import 'trip_sheet.dart';

/// What Ren sees after opening the link: the trip and who invited him, then his name (no account, no password),
/// then the trip so far: where they're staying, where they've been, what's coming (an open poll included) and the
/// rule for money. It's the other person's phone, so the top says so.
class JoinFlow extends StatefulWidget {
  const JoinFlow({super.key, required this.onJoined, required this.onClose});

  /// He joined and opens the trip.
  final VoidCallback onJoined;
  final VoidCallback onClose;

  @override
  State<JoinFlow> createState() => _JoinFlowState();
}

class _JoinFlowState extends State<JoinFlow> {
  var _recap = false;
  late final _name = TextEditingController(text: personById('ren').name);
  final _nameFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    // Ren's screen is light: dark icons in the system bars
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsOver(dark: false),
      child: ColoredBox(
      color: t.bgCanvas,
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: TokMotion.enter,
            reverseDuration: TokMotion.fade,
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            transitionBuilder: (child, anim) => child.key == ValueKey(_recap) ? FadeTransition(opacity: anim, child: child) : fadeBlurOut(anim, child),
            child: KeyedSubtree(key: ValueKey(_recap), child: _recap ? _recapPage(context, pad) : _invite(context, pad)),
          ),
        ),
        // The page fades out under the top, so the pill reads over whatever scrolls by
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: pad.top + TokSpace.xs + TokDim.buttonSm + TokSpace.xl,
          child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: easedFade(t.bgCanvas, from: TokDim.topBarFadeStart)))),
        ),
        // Whose phone this is (the demo switches to Ren's), and a way back
        Positioned(
          left: TokSpace.md,
          right: TokSpace.md,
          top: pad.top + TokSpace.xs,
          child: Row(children: [
            const SizedBox(width: TokDim.buttonSm),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm, vertical: TokSpace.x2xs),
                  decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.pill)),
                  child: Text("${personById('ren').name}'s phone", style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textMuted)),
                ),
              ),
            ),
            TuButton(icon: TuIcons.close, label: "Back to $myName's phone", size: TuButtonSize.sm, onTap: widget.onClose),
          ]),
        ),
      ]),
    ),
    );
  }

  Widget _invite(BuildContext context, EdgeInsets pad) {
    final t = context.tok;
    final now = tripNow();
    final crew = [for (final p in people) if (onTrip(p, now) && p.id != 'ren') p];
    // In the middle of the screen (clear of the pill on top), scrolling only if it doesn't fit
    final inset = EdgeInsets.fromLTRB(TokSpace.lg, pad.top + TokSpace.x5xl, TokSpace.lg, pad.bottom + TokSpace.x5xl);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: inset,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - inset.vertical)),
          child: Center(
            child: StaggerIn(spacing: TokSpace.md, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Overlapped(overlap: TokSpace.xs, children: [for (final p in crew) Sticker(p.sticker, size: StickerSize.row)]),
          Column(spacing: TokSpace.x2xs, children: [
            Text("$myName invited you to", textAlign: TextAlign.center, style: TokText.bodyMd.copyWith(color: t.textMuted)),
            Text(tripTitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TokText.headingLg.copyWith(color: t.textDefault)),
            Text('Lisbon · ${tripDays.first}–${tripDays.last} May · ${crew.length} friends are there',
                textAlign: TextAlign.center, style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
          const SizedBox(height: TokSpace.md),
          // The one thing to do: say who you are
          Container(
            height: TokDim.buttonLg,
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.pill)),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _name,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                style: TokText.labelLg.copyWith(color: t.textDefault),
                decoration: const InputDecoration.collapsed(hintText: 'Your name'),
              ),
            ),
          ),
          Text('No account and no password: your name is all it takes.', textAlign: TextAlign.center, style: TokText.bodySm.copyWith(color: t.textMuted)),
          TuTextButton(
            label: 'Join the trip',
            size: TuButtonSize.lg,
            wide: true,
            // Without a name yet, it goes to the name field instead
            onTap: () {
              if (_name.text.trim().isEmpty) return _nameFocus.requestFocus();
              HapticFeedback.mediumImpact();
              FocusScope.of(context).unfocus();
              setState(() => _recap = true);
            },
          ),
        ]),
          ),
        ),
      ),
    );
  }

  /// The trip so far, for someone arriving in the middle of it.
  Widget _recapPage(BuildContext context, EdgeInsets pad) {
    final t = context.tok;
    final now = tripNow();
    final days = visited.map((v) => v.day).toSet().length;
    // Tonight's dinner is in as a plan even before the poll picks the place: he's told when, not asked to vote
    final next = [
      for (final p in tripPlans) if (p.start.add(planLasts).isAfter(now)) p,
      if (dinnerChoice(now) == null) pollOptionById(dinnerSlotId).plan,
    ]..sort((a, b) => a.start.compareTo(b.start));
    final crew = [for (final p in people) if (onTrip(p, now) && p.id != 'ren') p];
    // Open the trip stays at the bottom, as a footer; the recap scrolls up under its fade
    final bottom = math.max(pad.bottom, TokSpace.md);
    final footer = TokSpace.xl + TokDim.buttonLg + bottom;
    return Stack(children: [
      ListView(
      padding: EdgeInsets.fromLTRB(TokSpace.md, pad.top + TokSpace.x5xl, TokSpace.md, footer + TokSpace.md),
      children: [
        // Each part of the trip on a card of its own, its heading above it, so the page reads as a few clear blocks
        StaggerIn(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
            child: Text('Welcome, ${_name.text.trim()}', style: TokText.headingLg.copyWith(color: t.textDefault)),
          ),
          const SheetSection("Where you're staying"),
          // The flat: where it is, and the booking
          _card(context, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SheetRow(
              leading: RowThumb(sticker: stay.sticker),
              title: stay.name,
              subtitle: 'Airbnb · until ${tripDays.last} May · ${personById('maya').name} booked it',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(TokSpace.sm, 0, TokSpace.sm, TokSpace.sm),
              child: Row(spacing: TokSpace.xs, children: [
                Expanded(child: TuTextButton(label: 'Directions', kind: GlassKind.soft, wide: true, onTap: () => openDirections(stay.at, stay.name))),
                Expanded(child: TuTextButton(label: 'Open in Airbnb', kind: GlassKind.soft, wide: true, onTap: () => openWebsite(stay.link))),
              ]),
            ),
          ])),
          const SheetSection('Coming up'),
          _card(context, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in next.take(4)) SheetRow(leading: RowThumb(sticker: p.sticker), title: p.name, subtitle: p.startsAt),
          ])),
          SheetSection('Been so far', subtitle: '${visited.length} places in $days days'),
          // Two to a row, each with its name and what it is, so he can see what they've done; the page scrolls
          Column(spacing: TokSpace.xs, children: [
            for (var i = 0; i < visited.length; i += 2)
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
                  Expanded(child: _PlaceTile(visited[i])),
                  Expanded(child: i + 1 < visited.length ? _PlaceTile(visited[i + 1]) : const SizedBox.shrink()),
                ]),
              ),
          ]),
          const SheetSection('Money'),
          _card(context, Padding(
            padding: const EdgeInsets.all(TokSpace.sm),
            child: Text(
              'You share costs from today on. The ${euros(spentSoFar)} spent before you joined stays with the ${_numbers[crew.length] ?? crew.length} of them.',
              style: TokText.bodySm.copyWith(color: t.textDefault),
            ),
          )),
        ]),
      ],
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(TokSpace.md, TokSpace.xl, TokSpace.md, bottom),
          decoration: BoxDecoration(gradient: easedFade(t.bgCanvas, from: TokDim.actionBarFadeStart, up: true)),
          child: StaggerIn(children: [TuTextButton(label: 'Open the trip', size: TuButtonSize.lg, wide: true, onTap: widget.onJoined)]),
        ),
      ),
    ]);
  }
}

/// A place they've been, on Ren's catch-up: its sticker on a muted block, then its name and what it is, and the day.
class _PlaceTile extends StatelessWidget {
  const _PlaceTile(this.place);
  final Visited place;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return _card(context, Padding(
      padding: const EdgeInsets.all(TokSpace.x2xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: (TokSpace.x5xl * 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.control)),
          padding: const EdgeInsets.all(TokSpace.sm),
          // A wide place (the stadium) gets narrower instead of running off the block
          child: FittedBox(fit: BoxFit.scaleDown, child: Sticker(place.sticker, height: (TokSpace.x5xl + TokSpace.xl), tilt: place.tilt)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.x2xs, TokSpace.sm, TokSpace.x2xs, TokSpace.xs),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
            Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TokText.labelLg.copyWith(color: t.textDefault)),
            Text('${place.kind} · ${weekdayShort(DateTime(tripYear, tripMonth, place.day))} ${place.day}', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
      ]),
    ));
  }
}

/// A white card on Ren's grey page, holding one part of the recap.
Widget _card(BuildContext context, Widget child) => Container(
      padding: const EdgeInsets.all(TokSpace.x2xs),
      decoration: BoxDecoration(color: context.tok.bgDefault, borderRadius: BorderRadius.circular(TokRadius.card)),
      child: child,
    );

const _numbers = {2: 'two', 3: 'three', 4: 'four', 5: 'five', 6: 'six'};
