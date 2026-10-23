import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';

/// Pill tabs on a muted track. The selected pill is a Surface that springs to the tapped tab.
class SegmentedTabs extends StatefulWidget {
  const SegmentedTabs({super.key, required this.tabs, required this.index, required this.onChanged});
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<SegmentedTabs> createState() => _SegmentedTabsState();
}

class _SegmentedTabsState extends State<SegmentedTabs> with TickerProviderStateMixin {
  late final _left = AnimationController.unbounded(vsync: this);
  late final _width = AnimationController.unbounded(vsync: this);
  final _keys = <GlobalKey>[];
  final _track = GlobalKey();
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));
    SchedulerBinding.instance.addPostFrameCallback((_) => _moveTo(widget.index, animate: false));
  }

  @override
  void didUpdateWidget(SegmentedTabs old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _moveTo(widget.index, animate: true);
  }

  void _moveTo(int i, {required bool animate}) {
    final tab = _keys[i].currentContext?.findRenderObject() as RenderBox?;
    final track = _track.currentContext?.findRenderObject() as RenderBox?;
    if (tab == null || track == null) return;
    final left = tab.localToGlobal(Offset.zero, ancestor: track).dx;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!animate || reduce || !_placed) {
      _left.value = left;
      _width.value = tab.size.width;
      setState(() => _placed = true);
    } else {
      springTo(_left, left, TokMotion.springSnap);
      springTo(_width, tab.size.width, TokMotion.springSnap);
    }
  }

  @override
  void dispose() {
    _left.dispose();
    _width.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      key: _track,
      padding: const EdgeInsets.all(TokDim.segmentTrackPadding),
      decoration: BoxDecoration(color: t.cSegmentTrack, borderRadius: BorderRadius.circular(TokRadius.pill)),
      child: Stack(children: [
        if (_placed)
          AnimatedBuilder(
            animation: Listenable.merge([_left, _width]),
            builder: (context, _) => Positioned(
              left: _left.value - TokDim.segmentTrackPadding,
              top: 0,
              width: _width.value,
              height: TokDim.segmentHeight,
              child: DecoratedBox(decoration: surfaceDecoration(context, BorderRadius.circular(TokRadius.pill))),
            ),
          ),
        Row(mainAxisSize: MainAxisSize.min, spacing: TokDim.segmentGap, children: [
          for (var i = 0; i < widget.tabs.length; i++)
            Semantics(
              selected: i == widget.index,
              button: true,
              child: GestureDetector(
                key: _keys[i],
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i == widget.index) return;
                  HapticFeedback.selectionClick();   // a detent: the pill moves one step
                  widget.onChanged(i);
                },
                child: Container(
                  height: TokDim.segmentHeight,
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm),
                  alignment: Alignment.center,
                  child: AnimatedDefaultTextStyle(
                    duration: TokMotion.fade,
                    curve: TokMotion.easeOut,
                    style: TokText.bodySm.copyWith(
                      fontWeight: i == widget.index ? TokWeight.medium : TokWeight.regular,
                      color: i == widget.index ? t.cSegmentOnFg : t.cSegmentOffFg,
                    ),
                    child: Text(widget.tabs[i]),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}
