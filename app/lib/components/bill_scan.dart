// Scanning the dinner's bill: the camera finds the paper, reads it, and every line lands on whoever had it.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'web_phone_frame.dart';
import 'basics.dart';
import 'glass.dart';
import 'stagger.dart';
import 'trip_sheet.dart';

/// Full screen, over everything: the camera's view of the bill on the table. The frame closes in on the paper, a
/// line reads it top to bottom, then the bill rises with every line on the faces of whoever had it. In the
/// prototype the camera shows a prepared bill (there's no real camera or OCR).
class BillScan extends StatefulWidget {
  const BillScan({super.key, required this.onClose, required this.onAdd});
  final VoidCallback onClose;

  /// The bill as checked, to add to the trip's money.
  final ValueChanged<Bill> onAdd;

  @override
  State<BillScan> createState() => _BillScanState();
}

enum _Phase { aim, read, review }

class _BillScanState extends State<BillScan> with TickerProviderStateMixin {
  var _phase = _Phase.aim;

  /// The frame closing in from the screen's edges onto the paper, then the line reading it.
  late final _lock = AnimationController(vsync: this, duration: TokMotion.enter);
  late final _sweep = AnimationController(vsync: this, duration: TokMotion.scanRead);
  final _paperKey = GlobalKey();
  Rect? _paper;
  Timer? _find;

  late Bill _bill = scannedBill(tripNow());

  /// The line whose faces are open for changing, if any, and each line's place (to bring an opened one into view).
  int? _editing;
  late final _lineKeys = [for (final _ in brasserieBill) GlobalKey()];

  void _edit(int i) {
    setState(() => _editing = _editing == i ? null : i);
    if (_editing == null) return;
    // Once its faces have grown in, scroll so the whole line shows
    Future.delayed(TokMotion.enter, () {
      final at = _lineKeys[i].currentContext;
      if (mounted && at != null && at.mounted) Scrollable.ensureVisible(at, alignment: 0.5, duration: TokMotion.enter, curve: TokMotion.easeOut);
    });
  }

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    // A moment to "find" the paper, as a camera would
    _find = Timer(TokMotion.scanFind, _found);
  }

  @override
  void dispose() {
    _find?.cancel();
    _lock.dispose();
    _sweep.dispose();
    super.dispose();
  }

  void _found() {
    if (!mounted) return;
    final box = _paperKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _paper = box.localToGlobal(Offset.zero, ancestor: WebPhoneFrame.screen) & box.size;
    HapticFeedback.mediumImpact(); // the frame catches the paper
    if (_reduce) {
      setState(() => _phase = _Phase.review);
      return;
    }
    _lock.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _phase = _Phase.read);
      _sweep.forward().whenComplete(() {
        if (!mounted) return;
        HapticFeedback.lightImpact();
        setState(() => _phase = _Phase.review);
      });
    });
  }

  void _toggle(int line, String id) {
    final who = [..._bill.who[line]];
    who.contains(id) ? who.remove(id) : who.add(id);
    if (who.isEmpty) return; // someone always has it
    HapticFeedback.selectionClick();
    setState(() => _bill = Bill(_bill.lines, [for (var i = 0; i < _bill.lines.length; i++) i == line ? who : _bill.who[i]], _bill.paidBy, _bill.at));
  }


  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final size = MediaQuery.sizeOf(context), pad = MediaQuery.paddingOf(context);
    final screen = Rect.fromLTRB(TokSpace.xl, pad.top + TokSpace.x3xl, size.width - TokSpace.xl, size.height - pad.bottom - TokSpace.x3xl);
    final review = _phase == _Phase.review;
    // White bar icons over the camera's dark view, dark ones once the bill sits on the light page
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsOver(dark: !review),
      child: Stack(
        children: [
          // The camera's view: one plain colour with the bill on it. Once the bill is read the colour gives way to the
          // app behind (the same blurred map as the full view), so the bill sits where the full view does, on the
          // same background, and adding it leads straight back into Group
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: review ? 0 : 1,
              duration: TokMotion.enter,
              curve: TokMotion.easeOut,
              child: ColoredBox(color: t.cScanBg),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: review ? 0 : 1,
              duration: TokMotion.fade,
              curve: TokMotion.easeOut,
              child: KeyedSubtree(key: _paperKey, child: const _Paper()),
            ),
          ),
          // The frame: from the edges of the screen onto the paper, turning blue once it has it
          if (!review)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _lock,
                  builder: (context, _) {
                    final k = TokMotion.easeOut.transform(_lock.value);
                    final to = _paper?.inflate(TokSpace.xs) ?? screen;
                    return CustomPaint(painter: _Corners(Rect.lerp(screen, to, k)!, _lock.value >= 1 ? t.cScanLine : t.cScanFg));
                  },
                ),
              ),
            ),
          // The reading line, top to bottom over the paper at an even pace
          if (_phase == _Phase.read && _paper != null)
            AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => Positioned(
                left: _paper!.left,
                width: _paper!.width,
                top: _paper!.top + _paper!.height * _sweep.value,
                height: TokDim.scanStroke,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.cScanLine,
                    boxShadow: [BoxShadow(color: t.cScanLine, blurRadius: TokSpace.xs)],
                  ),
                ),
              ),
            ),
          // The camera's own close and title (the bill has its own once it's up)
          if (!review)
            Positioned(
              left: TokSpace.md,
              right: TokSpace.md,
              top: pad.top + TokSpace.xs,
              child: Row(
                children: [
                  TuButton(icon: TuIcons.close, label: 'Close the camera', size: TuButtonSize.sm, onTap: widget.onClose),
                  Expanded(
                    child: Text(
                      'Scan the bill',
                      textAlign: TextAlign.center,
                      style: TokText.labelLg.copyWith(color: t.cScanFg),
                    ),
                  ),
                  const SizedBox(width: TokDim.buttonSm),
                ],
              ),
            ),
          if (!review)
            Positioned(
              left: TokSpace.md,
              right: TokSpace.md,
              bottom: math.max(pad.bottom, TokSpace.md) + TokSpace.xl,
              child: Text(
                _phase == _Phase.aim ? 'Hold the bill inside the frame' : 'Reading the bill…',
                textAlign: TextAlign.center,
                style: TokText.labelMd.copyWith(color: t.cScanFg),
              ),
            ),
          // The bill, rising over the camera once it's read
          if (review)
            Positioned(
              left: TokDim.sheetInset,
              right: TokDim.sheetInset,
              top: pad.top + TokSpace.xs + TokDim.buttonMd + TokSpace.x3xs,
              bottom: math.max(pad.bottom, TokDim.sheetInset),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: TokMotion.enter,
                curve: TokMotion.easeOut,
                builder: (context, v, child) => _reduce ? Opacity(opacity: v, child: child) : FractionalTranslation(translation: Offset(0, 1 - v), child: child), // up by its own height
                child: _review(context),
              ),
            ),
        ],
    ),
    );
  }

  Widget _review(BuildContext context) {
    final t = context.tok;
    final table = dinnerTable, shares = _bill.shares;
    String names(List<String> ids) {
      final n = [for (final id in ids) id == myId ? 'you' : personById(id).name];
      return n.length < 2 ? n.join() : '${n.sublist(0, n.length - 1).join(', ')} and ${n.last}';
    }

    return TripSheet(
      title: 'The bill',
      subtitle: "La Brasserie de L'Entrecôte · ${_bill.lines.length} lines",
      onClose: widget.onClose,
      footer: Container(
        padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.sm, TokSpace.xs, TokSpace.md),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: t.borderDefault, width: TokDim.surfaceEdgeWidth),
          ),
        ),
        child: Column(
          spacing: TokSpace.sm,
          children: [
            // What each person had, to the cent; side by side while they fit, scrolling sideways once they don't
            LayoutBuilder(
              builder: (context, box) {
                final fits = table.length * TokSpace.x5xl <= box.maxWidth;
                final cells = [
                  for (final id in table)
                    SizedBox(
                      width: fits ? box.maxWidth / table.length : TokSpace.x5xl,
                      child: Column(
                        spacing: TokSpace.x3xs,
                        children: [
                          Sticker(personById(id).sticker, size: StickerSize.avatar),
                          Text(euros(shares[id] ?? 0), style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
                        ],
                      ),
                    ),
                ];
                return fits ? Row(children: cells) : SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: cells));
              },
            ),
            Row(
              spacing: TokSpace.sm,
              children: [
                Expanded(
                  child: _PayerPicker(
                    payer: _bill.paidBy,
                    table: table,
                    onPick: (id) => setState(() => _bill = Bill(_bill.lines, _bill.who, id, _bill.at)),
                  ),
                ),
                TuTextButton(label: "Add to the trip's money", onTap: () => widget.onAdd(_bill)),
              ],
            ),
          ],
        ),
      ),
      child: StaggerIn(
        children: [
          // The total, big: it's the number everyone checks first
          Padding(
            padding: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.xs, TokSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Total', style: TokText.labelLg.copyWith(color: t.textDefault))),
                Text(euros(_bill.total), style: TokText.headingLg.copyWith(color: t.textDefault)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.xs, TokSpace.xs),
            child: Text(
              'Each line goes to whoever picked it on the menu; anything nobody picked goes to everyone. Tap a line to change who had it.',
              style: TokText.bodySm.copyWith(color: t.textMuted),
            ),
          ),
          for (final (i, line) in _bill.lines.indexed) ...[
            if (i > 0) const Hairline(),
            () {
              final who = _bill.who[i];
              final item = menuItemNamed(line.item);
              return Column(
                key: _lineKeys[i],
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetRow(
                    title: item?.name ?? line.printed,
                    subtitle: '${line.qty} × ${euros(line.unit)} · ${who.length == table.length ? 'Everyone' : names(who)}',
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: TokSpace.x3xs,
                      children: [
                        Text(euros(line.total), style: TokText.labelLg.copyWith(color: t.textDefault)),
                        // Every face, overlapped (there's room for the whole table)
                        Overlapped(overlap: TokDim.chipFaceOverlap, children: [for (final id in who) Sticker(personById(id).sticker, size: StickerSize.chip)]),
                      ],
                    ),
                    onTap: () => _edit(i),
                  ),
                  // Who had it: everyone at the table, the ones who had it full, the others faded; tap to change
                  AnimatedSize(
                    duration: TokMotion.enter,
                    curve: TokMotion.easeOut,
                    alignment: Alignment.topCenter,
                    child: _editing != i
                        ? const SizedBox(width: double.infinity)
                        : Container(
                            margin: const EdgeInsets.fromLTRB(TokSpace.xs, 0, TokSpace.xs, TokSpace.sm),
                            padding: const EdgeInsets.symmetric(vertical: TokSpace.sm),
                            decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.card)),
                            child: Row(
                              children: [
                                for (final id in table)
                                  Expanded(
                                    child: Pressable(
                                      onTap: () => _toggle(i, id),
                                      semanticLabel: '${personById(id).name}: ${who.contains(id) ? 'had it' : "didn't have it"}',
                                      child: AnimatedOpacity(
                                        opacity: who.contains(id) ? 1 : TokDim.scanOffOpacity,
                                        duration: TokMotion.fade,
                                        curve: TokMotion.easeOut,
                                        child: Column(
                                          spacing: TokSpace.x3xs,
                                          children: [
                                            Sticker(personById(id).sticker, size: StickerSize.avatar),
                                            Text(personById(id).name, style: TokText.labelMd.copyWith(color: t.textDefault)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }
}

/// The paper bill on the table, as the camera sees it.
class _Paper extends StatelessWidget {
  const _Paper();

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final ink = TokText.bodySm.copyWith(color: t.cScanInk);
    Widget line(String left, [String? right]) => Row(
      children: [
        Expanded(
          child: Text(left, maxLines: 1, overflow: TextOverflow.clip, style: ink),
        ),
        if (right != null) Text(right, style: ink),
      ],
    );
    final total = brasserieBill.fold(0.0, (sum, l) => sum + l.total);
    Widget rule() => Padding(
      padding: const EdgeInsets.symmetric(vertical: TokSpace.x2xs),
      child: SizedBox(
        height: TokDim.surfaceEdgeWidth,
        child: ColoredBox(color: t.cScanInk),
      ),
    );
    return Container(
      width: TokDim.scanPaperWidth,
      padding: const EdgeInsets.all(TokSpace.md),
      decoration: BoxDecoration(color: t.cScanPaper, borderRadius: BorderRadius.circular(TokSpace.x3xs), boxShadow: TokShadow.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "LA BRASSERIE DE L'ENTRECÔTE",
            textAlign: TextAlign.center,
            style: ink.copyWith(fontWeight: TokWeight.bold),
          ),
          Text('AV. DA IGREJA 12B · LISBOA', textAlign: TextAlign.center, style: ink),
          Text('14/05/2026  19:24  MESA 12', textAlign: TextAlign.center, style: ink),
          rule(),
          for (final l in brasserieBill) line('${l.qty} ${l.printed}', l.total.toStringAsFixed(2)),
          rule(),
          line('TOTAL EUR', total.toStringAsFixed(2)),
          Text('IVA INCLUÍDO · OBRIGADO', textAlign: TextAlign.center, style: ink),
        ],
      ),
    );
  }
}

/// The camera's frame: four corner marks around [rect].
class _Corners extends CustomPainter {
  _Corners(this.rect, this.color);
  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = TokDim.scanStroke
      ..strokeCap = StrokeCap.round;
    const c = TokDim.scanCorner;
    for (final (o, dx, dy) in [(rect.topLeft, 1.0, 1.0), (rect.topRight, -1.0, 1.0), (rect.bottomLeft, 1.0, -1.0), (rect.bottomRight, -1.0, -1.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy + c * dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx + c * dx, o.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Corners o) => o.rect != rect || o.color != color;
}

/// Who paid: shows the payer; tapping opens a small menu upward (it sits at the bottom of the screen) with everyone at
/// the table. The menu grows from the trigger's corner and fades, quickly, both ways.
class _PayerPicker extends StatefulWidget {
  const _PayerPicker({required this.payer, required this.table, required this.onPick});
  final String payer;
  final List<String> table;
  final ValueChanged<String> onPick;

  @override
  State<_PayerPicker> createState() => _PayerPickerState();
}

class _PayerPickerState extends State<_PayerPicker> with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  late final _shown = AnimationController(vsync: this, duration: TokMotion.fade, reverseDuration: TokMotion.press);
  late final _ease = CurvedAnimation(parent: _shown, curve: TokMotion.easeOut, reverseCurve: TokMotion.easeOut.flipped);

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  void _open() {
    _portal.show();
    _shown.forward();
  }

  void _close() => _shown.reverse().whenComplete(() {
        if (mounted) _portal.hide();
      });

  String _name(String id, {bool start = false}) => id == myId ? (start ? 'You' : 'you') : personById(id).name;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Stack(
          children: [
            // A tap anywhere else closes it
            Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close)),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.bottomLeft,
              offset: const Offset(0, -TokSpace.xs),
              child: FadeTransition(
                opacity: _ease,
                child: ScaleTransition(
                  scale: Tween(begin: TokMotion.pressScale, end: 1.0).animate(_ease),
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: TokDim.widgetMidWidth * 2 / 3,
                    padding: const EdgeInsets.all(TokSpace.x2xs),
                    decoration: surfaceDecoration(context, BorderRadius.circular(TokRadius.card)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final id in widget.table)
                          Pressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onPick(id);
                              _close();
                            },
                            semanticLabel: '${_name(id, start: true)} paid',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.x2xs),
                              child: Row(
                                spacing: TokSpace.xs,
                                children: [
                                  SizedBox(width: TokDim.stickerAvatar, child: Center(child: Sticker(personById(id).sticker, size: StickerSize.avatar))),
                                  Expanded(child: Text(_name(id, start: true), style: TokText.labelLg.copyWith(color: t.textDefault))),
                                  if (id == widget.payer) LucideIcon(TuIcons.check, size: TokSize.iconSm, color: t.iconBrand),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Pressable(
          onTap: _open,
          semanticLabel: '${_name(widget.payer, start: true)} paid. Change who paid',
          child: Row(
            spacing: TokSpace.x2xs,
            children: [
              Sticker(personById(widget.payer).sticker, size: StickerSize.chip),
              Flexible(child: Text('${_name(widget.payer, start: true)} paid', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault))),
              LucideIcon(TuIcons.openUp, size: TokSize.iconSm, color: t.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}
