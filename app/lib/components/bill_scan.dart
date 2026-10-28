// Scanning the dinner's bill: the camera finds the paper, reads it, and every line lands on whoever had it.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

// Its own measurements: used only here, so they're not tokens.
const double _scanPaperWidth = 296;
const double _scanStroke = 3;
const double _scanOffOpacity = 0.3;

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
    // Once its people have come in, scroll so the whole line shows
    Future.delayed(_BillLine.opening, () {
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
              child: ColoredBox(color: TokPalette.zinc900),
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
                    return CustomPaint(painter: _Corners(Rect.lerp(screen, to, k)!, _lock.value >= 1 ? t.bgBrand : TokPalette.white));
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
                height: _scanStroke,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.bgBrand,
                    boxShadow: [BoxShadow(color: t.bgBrand, blurRadius: TokSpace.xs)],
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
                      style: TokText.labelLg.copyWith(color: TokPalette.white),
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
                style: TokText.labelMd.copyWith(color: TokPalette.white),
              ),
            ),
          // The bill, rising over the camera once it's read
          if (review)
            Positioned(
              left: TokSpace.md,
              right: TokSpace.md,
              top: pad.top + TokSpace.xs + TokDim.buttonMd + TokSpace.x3xs,
              bottom: math.max(pad.bottom, TokSpace.md),
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

    return TripSheet(
      title: 'The bill',
      subtitle: "La Brasserie de L'Entrecôte · ${_bill.lines.length} lines${switch (_bill.unclaimed.length) { 0 => '', 1 => ' · 1 nobody has yet', final n => ' · $n nobody has yet' }}",
      onClose: widget.onClose,
      footer: Container(
        padding: const EdgeInsets.fromLTRB(TokDim.surfaceFootSide, TokSpace.sm, TokDim.surfaceFootSide, TokDim.surfaceInset),
        child: Column(
          spacing: TokSpace.sm,
          children: [
            // The summary in a grey block of its own: everyone's share, then the total. It sets itself apart from the
            // lines above, so the footer needs no edge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.md),
              decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.card)),
              child: Column(
                spacing: TokSpace.md,
                children: [
                // What each person had, to the cent; side by side while they fit, scrolling sideways once they don't
                LayoutBuilder(
                  builder: (context, box) {
                    // Each share needs about an amount's width (€59.12); five fit on a 393-wide phone
                    const cell = TokSpace.x4xl + TokSpace.xs;
                    final fits = table.length * cell <= box.maxWidth;
                    final cells = [
                      for (final id in table)
                        SizedBox(
                          width: fits ? box.maxWidth / table.length : cell,
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
                // On the grey, the line needs the stronger border to show
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
                  child: SizedBox(height: TokDim.surfaceEdgeWidth, width: double.infinity, child: ColoredBox(color: t.borderStrong)),
                ),
                // The total, big: it's the number everyone checks first, and it stays in view under the lines
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text('Total', style: TokText.labelLg.copyWith(color: t.textDefault))),
                      Text(euros(_bill.total), style: TokText.headingLg.copyWith(color: t.textDefault)),
                    ],
                  ),
                ),
                ],
              ),
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
                // Big, like every footer's main action, and so concentric with the sheet's corner
                TuTextButton(label: "Add to the trip's money", size: TuButtonSize.lg, onTap: () => widget.onAdd(_bill)),
              ],
            ),
          ],
        ),
      ),
      child: StaggerIn(
        children: [
          for (final (i, line) in _bill.lines.indexed) ...[
            if (i > 0) const Hairline(),
            _BillLine(
              key: _lineKeys[i],
              line: line,
              who: _bill.who[i],
              table: table,
              open: _editing == i,
              onOpen: () => _edit(i),
              onToggle: (id) => _toggle(i, id),
            ),
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
    final ink = TokText.bodySm.copyWith(color: TokPalette.zinc800);
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
        child: ColoredBox(color: TokPalette.zinc800),
      ),
    );
    return Container(
      width: _scanPaperWidth,
      padding: const EdgeInsets.all(TokSpace.md),
      decoration: BoxDecoration(color: TokPalette.white, borderRadius: BorderRadius.circular(TokSpace.x3xs), boxShadow: TokShadow.surface),
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
      ..strokeWidth = _scanStroke
      ..strokeCap = StrokeCap.round;
    const c = TokSpace.xl;
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
                                  SizedBox(width: TokSpace.x2xl, child: Center(child: Sticker(personById(id).sticker, size: StickerSize.avatar))),
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
          // A soft button, as tall as the main action next to it
          child: Glass(
            kind: GlassKind.soft,
            height: TokDim.buttonLg,
            radius: BorderRadius.circular(TokRadius.pill),
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: TokSpace.x2xs,
              children: [
                Sticker(personById(widget.payer).sticker, size: StickerSize.chip),
                Flexible(child: Text('${_name(widget.payer, start: true)} paid', maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault))),
                LucideIcon(TuIcons.openUp, size: TokSize.iconSm, color: t.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One line of the bill: the dish, then what it comes to (and how many at what price), and at the end who had it.
/// Whoever had it are faces on a soft pill with a chevron; a line nobody has yet is a round add-a-person button. Either
/// opens the line: everyone at the table in a grey block, the ones who had it full with a red minus, the others faded
/// with a plus; a tap on a person adds or takes them off.
///
/// Every face and person sharpens from a little blur as it comes in, and blurs as it goes (enter-blur).
/// Opening is one move: the pill's faces leave one after another, the pill gives way to a round chevron (up), the block
/// grows, and the people come in one after another (about 420 ms, ease-out). Closing is its own move, quicker, in the
/// order things go back: the people leave (the last first), the block folds away at once, the chevron turns back into
/// the pill and the faces drop into it one after another (about 360 ms). With reduced motion it only fades.
class _BillLine extends StatefulWidget {
  const _BillLine({super.key, required this.line, required this.who, required this.table, required this.open, required this.onOpen, required this.onToggle});
  final BillLine line;
  final List<String> who, table;
  final bool open;
  final VoidCallback onOpen;
  final ValueChanged<String> onToggle;

  /// How long opening takes: the faces leaving, the block growing, the last person landing.
  static Duration get opening => _blockAt + _peopleAt + _peopleStagger * (dinnerTable.length - 1) + TokMotion.fade;

  /// How long closing takes: to the last face back in the pill.
  static Duration get closing => _facesBackAt + _faceStagger * (dinnerTable.length - 1) + _faceBack;

  @override
  State<_BillLine> createState() => _BillLineState();
}

// The opening's steps (its own timing: a quick move people make many times over a bill)
const _faceOut = Duration(milliseconds: 100);       // each face leaving the pill
const _faceStagger = Duration(milliseconds: 25);
const _blockAt = Duration(milliseconds: 60);         // the block starts growing
const _peopleAt = Duration(milliseconds: 60);        // after the block starts, the first person
const _peopleStagger = Duration(milliseconds: 30);
// Closing
const _personOut = Duration(milliseconds: 120);      // each person leaving the block, the last first
const _personOutStagger = Duration(milliseconds: 20);
const _blockShutAt = Duration(milliseconds: 60);
const _blockShut = Duration(milliseconds: 220);
const _pillBackAt = Duration(milliseconds: 80);      // the chevron turns back into the pill
const _facesBackAt = Duration(milliseconds: 120);    // the first face back in the pill
const _faceBack = Duration(milliseconds: 140);

class _BillLineState extends State<_BillLine> with SingleTickerProviderStateMixin {
  /// 0 closed, 1 open. Opening runs it up on the opening's steps; closing runs it down on the closing's ([_closing]).
  late final _c = AnimationController(vsync: this, duration: _BillLine.opening, reverseDuration: _BillLine.closing, value: widget.open ? 1 : 0);
  bool _closing = false;

  @override
  void didUpdateWidget(_BillLine old) {
    super.didUpdateWidget(old);
    if (widget.open == old.open) return;
    _closing = !widget.open;
    widget.open ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// How open a part is (0–1): opening, on its step from [openAt] for [openFor]; closing, on its own step from
  /// [shutAt] for [shutFor] (both ease-out). With reduced motion, all of it at once.
  double _part(Duration openAt, Duration openFor, Duration shutAt, Duration shutFor) {
    if (_reduce) return _c.value;
    double step(Duration at, Duration length, Duration total, double t) {
      final a = (at.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0), b = ((at + length).inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
      return Interval(a, b, curve: TokMotion.easeOut).transform(t);
    }
    return _closing ? 1 - step(shutAt, shutFor, _BillLine.closing, 1 - _c.value) : step(openAt, openFor, _BillLine.opening, _c.value);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (context, _) => _line(context));

  Widget _line(BuildContext context) {
    final t = context.tok;
    final item = menuItemNamed(widget.line.item);
    final block = _part(_blockAt, TokMotion.enter, _blockShutAt, _blockShut);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Pressable(
          onTap: widget.onOpen,
          semanticLabel: '${item?.name ?? widget.line.printed}, ${euros(widget.line.total)}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.sm, children: [
            Text(item?.name ?? widget.line.printed, style: TokText.labelLg.copyWith(color: t.textDefault)),
            Row(spacing: TokSpace.xs, children: [
              // What it comes to, and how many at what price
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(euros(widget.line.total), style: TokText.bodyLg.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
                  Text('${widget.line.qty} × ${euros(widget.line.unit)}', style: TokText.bodySm.copyWith(color: t.textMuted)),
                ]),
              ),
              _control(context),
            ]),
          ]),
        ),
        // Everyone at the table, in a grey block that grows under the line
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: block,
            child: block <= 0 ? const SizedBox(width: double.infinity) : Padding(
            padding: const EdgeInsets.only(top: TokSpace.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: TokSpace.sm),
              decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.card)),
              child: Row(children: [
                for (final (j, id) in widget.table.indexed)
                  Expanded(
                    child: _arriving(
                      _part(_blockAt + _peopleAt + _peopleStagger * j, TokMotion.fade, _personOutStagger * (widget.table.length - 1 - j), _personOut),
                      _person(context, id),
                    ),
                  ),
              ]),
            ),
            ),
          ),
        ),
      ]),
    );
  }

  /// A part coming in on its own step: it fades in, sharpens from a blur and rises a little (only fades with reduced
  /// motion); leaving, the other way.
  Widget _arriving(double v, Widget child) => Opacity(
        opacity: v,
        child: _blurred(1 - v, Transform.translate(offset: Offset(0, _reduce ? 0 : (1 - v) * TokSpace.xs), child: child)),
      );

  /// Blurred by [out] of enter-blur while a part is half in or out (none with reduced motion or light effects).
  Widget _blurred(double out, Widget child) {
    final b = _reduce || lightEffects ? 0.0 : TokMotion.enterBlur * out;
    return ImageFiltered(enabled: b >= 0.05 && out < 1, imageFilter: ui.ImageFilter.blur(sigmaX: b, sigmaY: b), child: child);
  }

  /// The line's end: the faces on a pill (or the add-a-person button), giving way to a round chevron while it's open.
  Widget _control(BuildContext context) {
    final t = context.tok;
    final who = widget.who;
    final swap = _part(_faceStagger * (who.length - 1 < 0 ? 0 : who.length - 1), _faceOut, _pillBackAt, _faceOut);
    final closed = who.isEmpty
        ? Glass(kind: GlassKind.soft, width: TokDim.buttonSm, height: TokDim.buttonSm, radius: BorderRadius.circular(TokRadius.pill), child: Center(child: LucideIcon(TuIcons.invite, size: TokSize.iconSm, color: t.iconDefault)))
        : Glass(
            kind: GlassKind.soft,
            height: TokDim.buttonSm,
            radius: BorderRadius.circular(TokRadius.pill),
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm),
            child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
              // The faces leave one after another as the line opens
              Overlapped(overlap: TokDim.chipFaceOverlap, children: [
                for (final (k, id) in who.indexed)
                  () {
                    final v = _part(_faceStagger * k, _faceOut, _facesBackAt + _faceStagger * k, _faceBack);
                    return Opacity(
                      opacity: 1 - v,
                      child: _blurred(v, Transform.scale(scale: _reduce ? 1 : 1 - (1 - TokMotion.morphEnterScale) * v, child: Sticker(personById(id).sticker, size: StickerSize.chip))),
                    );
                  }(),
              ]),
              LucideIcon(TuIcons.unfold, size: TokSize.iconSm, color: t.iconDefault),
            ]),
          );
    final opened = Glass(kind: GlassKind.soft, width: TokDim.buttonSm, height: TokDim.buttonSm, radius: BorderRadius.circular(TokRadius.pill), child: Center(child: LucideIcon(TuIcons.fold, size: TokSize.iconSm, color: t.iconDefault)));
    // One gives way to the other on the spot, a little blurred while both show
    final v = swap, blur = _reduce || lightEffects ? 0.0 : TokMotion.enterBlur * 4 * v * (1 - v);
    return ImageFiltered(
      enabled: blur >= 0.05,
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Stack(alignment: Alignment.centerRight, children: [
        Opacity(opacity: 1 - v, child: closed),
        Opacity(opacity: v, child: opened),
      ]),
    );
  }

  /// A person in the open line: their face with a minus (red) if they had it, or faded with a plus if not; a tap adds
  /// or takes them off.
  Widget _person(BuildContext context, String id) {
    final t = context.tok;
    final had = widget.who.contains(id);
    return Pressable(
      onTap: () => widget.onToggle(id),
      semanticLabel: '${personById(id).name}: ${had ? 'had it, tap to take off' : "didn't have it, tap to add"}',
      child: Column(spacing: TokSpace.x3xs, children: [
        Stack(clipBehavior: Clip.none, children: [
          AnimatedOpacity(
            opacity: had ? 1 : _scanOffOpacity,
            duration: TokMotion.fade,
            curve: TokMotion.easeOut,
            child: Sticker(personById(id).sticker, size: StickerSize.avatar),
          ),
          // At the face's top-right corner
          Positioned(right: -TokSpace.xs, top: -TokSpace.x2xs, child: _AddRemove(on: had)),
        ]),
        AnimatedOpacity(
          opacity: had ? 1 : _scanOffOpacity,
          duration: TokMotion.fade,
          curve: TokMotion.easeOut,
          child: Text(personById(id).name, style: TokText.labelMd.copyWith(color: t.textDefault)),
        ),
      ]),
    );
  }
}

/// The small add/remove mark on a person: a small round button (the sm button's glass, at [_markScale]) with a plus,
/// soft, for someone who didn't have it; red with a minus for someone who did. It turns from one into the other on the
/// spot: the glass fades from soft to red and the plus's upright bar folds away into the minus (fade-ms, ease-out).
class _AddRemove extends StatelessWidget {
  const _AddRemove({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final round = BorderRadius.circular(TokRadius.pill);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: on ? 1 : 0),
      duration: TokMotion.fade,
      curve: TokMotion.easeOut,
      builder: (context, v, _) {
        final bar = Color.lerp(t.iconDefault, t.iconOnBrand, v)!;
        return SizedBox.square(
          dimension: TokDim.buttonSm * _markScale,
          child: OverflowBox(
            maxWidth: TokDim.buttonSm,
            maxHeight: TokDim.buttonSm,
            child: Transform.scale(
              scale: _markScale,
              child: Stack(alignment: Alignment.center, children: [
                Opacity(opacity: 1 - v, child: Glass(kind: GlassKind.soft, width: TokDim.buttonSm, height: TokDim.buttonSm, radius: round)),
                Opacity(opacity: v, child: Glass(kind: GlassKind.danger, width: TokDim.buttonSm, height: TokDim.buttonSm, radius: round)),
                // The minus's bar, and the plus's upright one folding away (gone at once with reduced motion)
                _bar(bar),
                Transform.scale(scaleY: reduce ? (on ? 0 : 1) : 1 - v, child: RotatedBox(quarterTurns: 1, child: _bar(bar))),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _bar(Color color) => Container(
        width: _markBar,
        height: _markBar * _markThickness,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(TokRadius.pill)),
      );
}

// The mark is the sm button's glass at this scale (16 of 40), so its edge and shadow shrink with it, as in Figma
const double _markScale = 0.4;
const double _markBar = 15;        // the bars, at the button's size: 6 long on the mark
const double _markThickness = 1 / 3;
