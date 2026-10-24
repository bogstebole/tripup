import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'progressive_blur.dart';

/// One of the footer's pop-ups (itinerary, money, add): the full view's surface, a header with the title and close,
/// and a page that scrolls up under the header. It rises from the bottom (see TripScreen); the header is also a
/// handle for pulling it back down.
class TripSheet extends StatefulWidget {
  const TripSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onClose,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
    this.focus,
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

  /// Stays put at the bottom while the page scrolls above it (the bill's totals and its button).
  final Widget? footer;

  final String title, subtitle;

  /// A block to open scrolled to (today, in the itinerary), just under the header.
  final GlobalKey? focus;

  /// The page, top to bottom. The sheet scrolls it.
  final Widget child;
  final VoidCallback? onClose;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;


  /// What [top] adds to the header: a gap, then a row of toggle chips.
  static const double topHeight = TokSpace.sm + TokDim.toggleChipHeight;

  /// The header's height: its top inset, then the taller of the title block and the close button.
  static double get headerHeight =>
      TokSpace.md + math.max(TokText.headingMd.fontSize! * TokText.headingMd.height! + TokSpace.x2xs + TokText.bodySm.fontSize! * TokText.bodySm.height!, TokDim.buttonSm);

  @override
  State<TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<TripSheet> {
  /// How far the page has scrolled under the header, 0–1 over the top fade's height.
  final _under = ValueNotifier<double>(0);

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final at = widget.focus?.currentContext;
      if (!mounted || at == null || !_scroll.hasClients) return;
      Scrollable.ensureVisible(at);   // its top at the top of the view…
      final pos = _scroll.position;   // …then back down by the header, so it sits just under it
      _scroll.jumpTo((pos.pixels - _header - TokSpace.md).clamp(pos.minScrollExtent, pos.maxScrollExtent));
    });
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
                    padding: const EdgeInsets.only(top: TokSpace.xs),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.md, 0),
                          // A new title fades in as the old one leaves (a step inside the pop-up)
                          child: AnimatedSwitcher(
                            duration: TokMotion.enter,
                            reverseDuration: TokMotion.fade,
                            switchInCurve: TokMotion.easeOut,
                            switchOutCurve: TokMotion.easeOut,
                            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                            child: Column(key: ValueKey(widget.title), crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
                              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
                              Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.bodySm.copyWith(color: t.textMuted)),
                            ]),
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
