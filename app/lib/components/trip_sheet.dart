import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'progressive_blur.dart';

/// One of the footer's pop-ups (itinerary, money, add): the full view's surface, a header with Back (for a step inside
/// it), the title and Close on one line, a page that scrolls up under the header, and a footer with the page's actions.
/// Everything sits [TokDim.surfaceInset] from every edge (header, content, footer), and the corners of
/// [TokDim.surfaceRadius] are about concentric with both the header's round buttons and the footer's big ones.
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

  /// A line under the title, in the header: a fact about what's in the pop-up (the trip's dates, who the money goes
  /// to, the poll's state), not a description of it.
  final String? subtitle;

  /// The page, top to bottom. The sheet scrolls it, and opens at its top.
  final Widget child;
  final VoidCallback? onClose;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;


  /// What [top] adds to the header: a gap, then a row of toggle chips.
  static const double topHeight = TokSpace.sm + TokDim.toggleChipHeight;

  /// The header's height: its top inset (the buttons sit concentric with the corners), then the taller of the title
  /// and the buttons, on one line.
  static double get headerHeight => TokDim.surfaceHeadInset + math.max(TokText.headingMd.fontSize! * TokText.headingMd.height!, TokDim.buttonSm);

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

  /// The header's height at this width: the title line, then the subtitle (wrapped between the buttons) when there's one.
  double _headOf(BuildContext context, double width) {
    final row = TripSheet.headerHeight - TokDim.surfaceHeadInset, title = TokText.headingMd.fontSize! * TokText.headingMd.height!;
    if (widget.subtitle == null) return TripSheet.headerHeight;
    final words = width - (widget.onBack != null ? TokDim.surfaceHeadSide + TokDim.buttonSm + TokSpace.x2xs : 0) - TokSpace.xs - TokSpace.md - TokDim.buttonSm - TokDim.surfaceHeadSide;
    final sub = TextPainter(
      text: TextSpan(text: widget.subtitle, style: TokText.bodySm),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(0, words));
    return TokDim.surfaceHeadInset + math.max(row, (row - title) / 2 + title + TokSpace.x3xs + sub.height);
  }

  @override
  void dispose() {
    _under.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return LayoutBuilder(builder: (context, outer) {
    final head = _headOf(context, outer.maxWidth - TokDim.surfaceBodySide * 2);
    // A step with a longer subtitle (Money to Pay) moves the page down with the header, on screen: ease in and out
    return TweenAnimationBuilder<double>(
      tween: Tween(end: head + (widget.top != null ? TripSheet.topHeight : 0)),
      duration: TokMotion.enter,
      curve: TokMotion.easeInOut,
      builder: (context, header, _) {
    final solid = header / (header + TokDim.sheetTopFade);
    return DecoratedBox(
      decoration: surfaceDecoration(context, BorderRadius.circular(TokDim.surfaceRadius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokDim.surfaceRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokDim.surfaceBodySide),
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
                            ? widget.child
                            : ConstrainedBox(
                                constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - pad.vertical)),
                                child: Center(child: widget.child),
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
                    padding: const EdgeInsets.only(top: TokDim.surfaceHeadInset),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // A step back slides in before the title (and out again), the title moving over for it; the
                      // buttons and the title sit 24 from the sides, on the same edge as the content and the footer
                      AnimatedSize(
                        duration: TokMotion.enter,
                        curve: TokMotion.easeOut,
                        child: widget.onBack == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(left: TokDim.surfaceHeadSide, right: TokSpace.x2xs),
                                child: TuButton(icon: TuIcons.back, label: 'Back', size: TuButtonSize.sm, onTap: widget.onBack),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(TokSpace.xs, _titleTop, TokSpace.md, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.x3xs, children: [
                            // A new title fades in once the old one has mostly gone (a step inside the pop-up), so they
                            // never read over each other
                            _swap(Text(widget.title, key: ValueKey(widget.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault))),
                            if (widget.subtitle != null)
                              _swap(Text(widget.subtitle!, key: ValueKey(widget.subtitle), style: TokText.bodySm.copyWith(color: t.textMuted))),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: TokDim.surfaceHeadSide),
                        child: TuButton(icon: TuIcons.close, label: 'Close', size: TuButtonSize.sm, onTap: widget.onClose),
                      ),
                    ]),
                  ),
                ),
              ),
              if (widget.top != null)
                Positioned(left: 0, right: 0, top: header - TripSheet.topHeight + TokSpace.sm, height: TokDim.toggleChipHeight, child: widget.top!),
            ]),
          )),
            ?widget.footer,
          ]),
        ),
      ),
    );
      },
    );
    });
  }

  /// How far the title sits down from the top of the buttons, so the two share a centre line.
  static double get _titleTop => (TripSheet.headerHeight - TokDim.surfaceHeadInset - TokText.headingMd.fontSize! * TokText.headingMd.height!) / 2;

  /// A new line comes in once the old one has mostly gone, so they never read over each other.
  Widget _swap(Widget child) => AnimatedSwitcher(
        duration: TokMotion.enter,
        reverseDuration: TokMotion.fade,
        switchInCurve: TokMotion.swapIn,
        switchOutCurve: TokMotion.easeOut,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
        child: child,
      );

  /// The page fades out over its last few pixels at the bottom instead of being cut off.
  Widget _fadeBottom(BuildContext context, Widget child) {
    final solid = context.tok.textDefault;   // only its alpha matters for the mask
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Eased, not linear, over sheet/fade: the page melts into the bottom instead of stopping at a line
        colors: [solid, for (var i = 0; i <= 8; i++) solid.withValues(alpha: 1 - (i / 8) * (i / 8) * (3 - 2 * i / 8))],
        stops: [0, for (var i = 0; i <= 8; i++) 1 - TokDim.sheetFade / r.height * (1 - i / 8)],
      ).createShader(r),
      child: child,
    );
  }
}

/// A pop-up's bottom, in view while its page scrolls: what to do there, as buttons (one wide, or several stacked or side
/// by side), with what they need above them (Money's total) or a line under them. Every pop-up's actions are here;
/// going back and closing are in the header. Its big buttons sit [TokDim.surfaceFootInset] in from the sheet's sides
/// and bottom, concentric with its corners.
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
      padding: const EdgeInsets.fromLTRB(TokDim.surfaceFootSide, TokSpace.sm, TokDim.surfaceFootSide, TokDim.surfaceFootInset),
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

/// A place's thumbnail at the start of a [SheetRow]: its sticker (or an icon, for what has no place yet) on a muted
/// square, so stickers and icons read as the same kind of thing down a list. The sticker is the row's full height,
/// cut off by the square's corners.
class RowThumb extends StatelessWidget {
  const RowThumb({super.key, this.sticker, this.icon, this.tilt = 0});
  final String? sticker;
  /// A Lucide icon name (TuIcons).
  final String? icon;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      width: TokDim.stickerRow,
      height: TokDim.stickerRow,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.control)),
      child: sticker != null ? Sticker(sticker!, size: StickerSize.row, tilt: tilt) : LucideIcon(icon!, size: TokSize.iconMd, color: t.iconBrand),
    );
  }
}
