import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'progressive_blur.dart';

/// One of the footer's pop-ups (itinerary, money, add): the full view's surface, a header with Back (for a step inside
/// it), the title and Close on one line, a page that scrolls up under the header, and a footer with the page's actions.
/// Every pop-up is built the same way: going back and closing in the header, doing things in the footer. It rises from
/// the bottom (see TripScreen); the header is also a handle for pulling it back down.
class TripSheet extends StatefulWidget {
  const TripSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onClose,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
    this.footer,
    this.top,
    this.onBack,
    this.centered = false,
  });

  /// A step back inside the pop-up (Add's Plan or Invite back to its choice): a back button before the title.
  final VoidCallback? onBack;

  /// The page sits in the middle of the sheet when it's shorter than it (Invite's link).
  final bool centered;

  /// Stays put under the title while the page scrolls under it (the itinerary's day filter). One chip row high.
  final Widget? top;

  /// Stays put at the bottom while the page scrolls above it: the page's actions (see [SheetFooter]).
  final Widget? footer;

  final String title;

  /// A line on what the pop-up is for, at the top of its page (not in the header, so the header stays one line).
  final String? subtitle;

  /// The page, top to bottom. The sheet scrolls it, and opens at its top.
  final Widget child;
  final VoidCallback? onClose;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;


  /// What [top] adds to the header: a gap, then a row of toggle chips.
  static const double topHeight = TokSpace.sm + TokDim.toggleChipHeight;

  /// The header's height: its top inset, then the taller of the title and the buttons, on one line.
  static double get headerHeight => TokSpace.xs + math.max(TokText.headingMd.fontSize! * TokText.headingMd.height!, TokDim.buttonSm);

  @override
  State<TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<TripSheet> {
  /// How far the page has scrolled under the header, 0–1 over the top fade's height.
  final _under = ValueNotifier<double>(0);

  final _scroll = ScrollController();

  @override
  void didUpdateWidget(TripSheet old) {
    super.didUpdateWidget(old);
    // A new step starts at its top (Money's list scrolled down, then Pay)
    if (old.title != widget.title && _scroll.hasClients) _scroll.jumpTo(0);
  }

  double get _header => TripSheet.headerHeight + (widget.top != null ? TripSheet.topHeight : 0);

  @override
  void dispose() {
    _under.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final header = _header, solid = header / (header + TokDim.sheetTopFade);
    return DecoratedBox(
      decoration: surfaceDecoration(context, BorderRadius.circular(TokDim.surfaceRadius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokDim.surfaceRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
          child: Column(children: [
            Expanded(child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0 && (n is ScrollUpdateNotification || n is ScrollEndNotification)) {
                _under.value = (n.metrics.pixels / TokDim.sheetTopFade).clamp(0.0, 1.0);
              }
              return false;
            },
            child: Stack(children: [
              Positioned.fill(
                child: _fadeBottom(
                  context,
                  LayoutBuilder(
                    builder: (context, box) {
                      final pad = EdgeInsets.only(top: header + TokSpace.md, bottom: TokDim.sheetFade + TokSpace.xs);
                      return SingleChildScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: pad,
                        child: !widget.centered
                            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_subtitle(context), widget.child])
                            : ConstrainedBox(
                                constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - pad.vertical)),
                                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [_subtitle(context), widget.child])),
                              ),
                      );
                    },
                  ),
                ),
              ),
              // The header's white shows once the page goes under it, so a page at rest isn't faded at the top
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: header + TokDim.sheetTopFade,
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _under,
                    builder: (context, v, _) => v <= 0
                        ? const SizedBox.shrink()
                        : Opacity(opacity: v, child: DecoratedBox(decoration: BoxDecoration(gradient: easedFade(t.cSurfaceTop, from: solid)))),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: widget.onHeaderDragUpdate,
                  onVerticalDragEnd: widget.onHeaderDragEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: TokSpace.xs),
                    child: Row(children: [
                      // A step back slides in before the title (and out again), the title moving over for it
                      AnimatedSize(
                        duration: TokMotion.enter,
                        curve: TokMotion.easeOut,
                        child: widget.onBack == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(right: TokSpace.x2xs),
                                child: TuButton(icon: TuIcons.back, label: 'Back', size: TuButtonSize.sm, onTap: widget.onBack),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.md, 0),
                          // A new title fades in once the old one has mostly gone (a step inside the pop-up), so they never read
                          // over each other
                          child: AnimatedSwitcher(
                            duration: TokMotion.enter,
                            reverseDuration: TokMotion.fade,
                            switchInCurve: TokMotion.swapIn,
                            switchOutCurve: TokMotion.easeOut,
                            layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                            child: Text(widget.title, key: ValueKey(widget.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
                          ),
                        ),
                      ),
                      TuButton(icon: TuIcons.close, label: 'Close', size: TuButtonSize.sm, onTap: widget.onClose),
                    ]),
                  ),
                ),
              ),
              if (widget.top != null)
                Positioned(left: 0, right: 0, top: TripSheet.headerHeight + TokSpace.sm, height: TokDim.toggleChipHeight, child: widget.top!),
            ]),
          )),
            ?widget.footer,
          ]),
        ),
      ),
    );
  }

  /// The pop-up's line at the top of its page, lined up with the page's text; when a step changes it, the new line
  /// comes in once the old one has mostly gone.
  Widget _subtitle(BuildContext context) => AnimatedSwitcher(
        duration: TokMotion.enter,
        reverseDuration: TokMotion.fade,
        switchInCurve: TokMotion.swapIn,
        switchOutCurve: TokMotion.easeOut,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
        child: widget.subtitle == null
            ? const SizedBox(key: ValueKey(null), width: double.infinity)
            : Padding(
                key: ValueKey(widget.subtitle),
                padding: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.xs, TokSpace.md),
                child: Text(widget.subtitle!, style: TokText.bodySm.copyWith(color: context.tok.textMuted)),
              ),
      );

  /// The page fades out over its last few pixels at the bottom instead of being cut off.
  Widget _fadeBottom(BuildContext context, Widget child) {
    final solid = context.tok.textDefault;   // only its alpha matters for the mask
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [solid, solid, solid.withValues(alpha: 0)],
        stops: [0, 1 - TokDim.sheetFade / r.height, 1],
      ).createShader(r),
      child: child,
    );
  }
}

/// A pop-up's bottom, in view while its page scrolls: what to do there, as buttons (one wide, or several stacked or side
/// by side), with what they need above them (Money's total) or a line under them. Every pop-up's actions are here;
/// going back and closing are in the header.
class SheetFooter extends StatelessWidget {
  const SheetFooter({super.key, required this.children, this.note});
  final List<Widget> children;

  /// A line under the last button: what it will do.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final last = note == null
        ? children.last
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
            children.last,
            Text(note!, textAlign: TextAlign.center, style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]);
    return Container(
      padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.sm, TokSpace.xs, TokSpace.md),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.borderDefault, width: TokDim.surfaceEdgeWidth))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.md, children: [...children.take(children.length - 1), last]),
    );
  }
}

/// A heading inside a pop-up's page, with an optional line under it.
class SheetSection extends StatelessWidget {
  const SheetSection(this.title, {super.key, this.subtitle, this.top = TokSpace.xl});
  final String title;
  final String? subtitle;

  /// Room above it, from whatever comes before.
  final double top;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Padding(
      padding: EdgeInsets.fromLTRB(TokSpace.xs, top, TokSpace.xs, TokSpace.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
        Text(title, style: TokText.headingSm.copyWith(color: t.textDefault)),
        if (subtitle != null) Text(subtitle!, style: TokText.bodySm.copyWith(color: t.textMuted)),
      ]),
    );
  }
}

/// One line in a pop-up's list: something on the left (a sticker or faces), a name and a line under it, and
/// whatever sits at the end (an amount, a time, a button).
class SheetRow extends StatelessWidget {
  const SheetRow({super.key, this.leading, required this.title, this.subtitle, this.subtitleColor, this.trailing, this.onTap, this.muted = false});
  final Widget? leading;
  final String title;

  /// Greyed out: there, but not available (yet).
  final bool muted;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
      child: Row(spacing: TokSpace.sm, children: [
        ?leading,
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TokText.labelLg.copyWith(color: muted ? t.textSubtle : t.textDefault)),
            if (subtitle != null) Text(subtitle!, style: TokText.bodySm.copyWith(color: muted ? t.textSubtle : subtitleColor ?? t.textMuted)),
          ]),
        ),
        ?trailing,
      ]),
    );
    return onTap == null ? row : Pressable(onTap: onTap, semanticLabel: title, child: row);
  }
}
