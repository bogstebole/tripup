// Joining a trip mid-way, from the invite link: what the new person sees on their own phone.
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType, TextField, InputDecoration;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'progressive_blur.dart';
import 'stagger.dart';
import 'trip_sheet.dart';

/// What Ren sees after opening the link: the trip and who invited him, then his name (no account, no password),
/// then the trip so far: where they're staying, where they've been, what's coming (an open poll included) and the
/// rule for money. It's the other person's phone, so the top says so.
class JoinFlow extends StatefulWidget {
  const JoinFlow({super.key, required this.onJoined, required this.onClose, this.preview = false});

  /// Only a look, from Invite, at what someone you invite will see (nobody joins).
  final bool preview;

  /// He joined and opens the trip.
  final VoidCallback onJoined;
  final VoidCallback onClose;

  @override
  State<JoinFlow> createState() => _JoinFlowState();
}

class _JoinFlowState extends State<JoinFlow> {
  var _recap = false;
  late final _name = TextEditingController(text: widget.preview ? '' : personById('ren').name);
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
                  child: Text(widget.preview ? "What they'll see" : "${personById('ren').name}'s phone", style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textMuted)),
                ),
              ),
            ),
            TuButton(icon: TuIcons.close, label: widget.preview ? 'Close the preview' : "Back to $myName's phone", size: TuButtonSize.sm, onTap: widget.onClose),
          ]),
        ),
      ]),
    ),
    );
  }

  Widget _invite(BuildContext context, EdgeInsets pad) {
    final t = context.tok;
    final now = tripNow();
    final crew = [for (final p in people) if (onTrip(p, now) && (widget.preview || p.id != 'ren')) p];
    // In the middle of the screen (clear of the pill on top), scrolling only if it doesn't fit
    final inset = EdgeInsets.fromLTRB(TokSpace.lg, pad.top + TokSpace.x5xl, TokSpace.lg, pad.bottom + TokSpace.x5xl);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: inset,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - inset.vertical)),
          child: Center(
            child: StaggerIn(spacing: TokSpace.md, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Overlapped(overlap: TokDim.avatarOverlap, children: [for (final p in crew) Sticker(p.sticker, size: StickerSize.row)]),
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
    final next = [for (final p in tripPlans) if (p.start.add(planLasts).isAfter(now)) p].take(3).toList();
    final undecided = dinnerChoice(now) == null;
    final crew = [for (final p in people) if (onTrip(p, now) && p.id != 'ren') p];
    return ListView(
      padding: EdgeInsets.fromLTRB(TokSpace.md, pad.top + TokSpace.x5xl, TokSpace.md, pad.bottom + TokSpace.xl),
      children: [
        StaggerIn(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
              Text('Welcome, ${_name.text.trim()}', style: TokText.headingLg.copyWith(color: t.textDefault)),
              Text("Here's the trip so far, so you're caught up.", style: TokText.bodySm.copyWith(color: t.textMuted)),
            ]),
          ),
          const SheetSection("Where you're staying"),
          SheetRow(
            leading: SizedBox(width: TokDim.stickerRow, child: Center(child: LucideIcon(TuIcons.stay, size: TokSize.iconMd, color: t.iconBrand))),
            title: 'Alfama flat',
            subtitle: 'Airbnb · until ${tripDays.last} May · ${personById('maya').name} booked it',
          ),
          SheetSection('Been so far', subtitle: '${visited.length} places in $days days'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Overlapped(overlap: TokDim.stickerOverlap, children: [for (final v in visited) Sticker(v.sticker, size: StickerSize.row, tilt: v.tilt)]),
            ),
          ),
          const SheetSection('Coming up'),
          if (undecided)
            SheetRow(
              leading: SizedBox(width: TokDim.stickerRow, child: Center(child: LucideIcon(TuIcons.poll, size: TokSize.iconMd, color: t.iconBrand))),
              title: 'Dinner tonight, 5 PM',
              subtitle: pollOpen(now) ? 'Poll open: where? Your vote counts too' : 'A poll opens at ${clockTime(pollOpens)}: you can vote',
              subtitleColor: t.textBrand,
            ),
          for (final p in next)
            SheetRow(
              leading: SizedBox(width: TokDim.stickerRow, child: Center(child: Sticker(p.sticker, size: StickerSize.row))),
              title: p.name,
              subtitle: p.startsAt,
            ),
          const SheetSection('Money'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
            child: Text(
              'You share costs from today on. The ${euros(spentSoFar)} spent before you joined stays with the ${_numbers[crew.length] ?? crew.length} of them.',
              style: TokText.bodySm.copyWith(color: t.textDefault),
            ),
          ),
          const SizedBox(height: TokSpace.xl),
          TuTextButton(label: widget.preview ? 'Close the preview' : 'Open the trip', size: TuButtonSize.lg, wide: true, onTap: widget.onJoined),
        ]),
      ],
    );
  }
}

const _numbers = {2: 'two', 3: 'three', 4: 'four', 5: 'five', 6: 'six'};
