import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'segmented_tabs.dart';

const detailTabs = ['Overview', 'Menu', 'People'];

/// The full view of a plan (see Storybook: Screens/Trip → Full view). Photos and name stay put;
/// the body switches with the tabs. [onHeaderDrag*] let the screen drag the sheet down to close it.
class DetailSheet extends StatefulWidget {
  const DetailSheet({super.key, required this.plan, this.onClose, this.onHeaderDragUpdate, this.onHeaderDragEnd});
  final Plan plan;
  final VoidCallback? onClose;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  int _tab = 0, _from = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final p = widget.plan;
    return Padding(
      padding: const EdgeInsets.all(TokSpace.xs),
      child: Column(spacing: TokSpace.md, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: widget.onHeaderDragUpdate,
          onVerticalDragEnd: widget.onHeaderDragEnd,
          child: Column(spacing: TokSpace.md, children: [
            SizedBox(
              height: TokDim.photosHeight,
              child: Row(spacing: TokSpace.xs, children: [
                for (var i = 0; i < p.photos.length; i++)
                  i == 0
                      ? SizedBox(width: TokDim.photosPeekStart, child: _Photo(p.photos[i]))
                      : i == p.photos.length - 1
                          ? SizedBox(width: TokDim.photosPeekEnd, child: _Photo(p.photos[i]))
                          : Expanded(child: _Photo(p.photos[i])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
                RatingLine(rating: p.rating, kind: p.cuisine, center: false),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: TokMotion.fade,
            switchInCurve: TokMotion.easeOut,
            switchOutCurve: TokMotion.easeOut,
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            transitionBuilder: (child, anim) {
              // Tabs slide in from the side they come from
              final dir = _tab >= _from ? 1.0 : -1.0;
              final incoming = child.key == ValueKey(_tab);
              final dx = (incoming ? dir : -dir) * TokSpace.xs;
              return FadeTransition(
                opacity: anim,
                child: AnimatedBuilder(animation: anim, builder: (_, c) => Transform.translate(offset: Offset(dx * (1 - anim.value), 0), child: c), child: child),
              );
            },
            child: KeyedSubtree(key: ValueKey(_tab), child: _body(context)),
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SegmentedTabs(tabs: detailTabs, index: _tab, onChanged: (i) => setState(() {
                _from = _tab;
                _tab = i;
              })),
          TuButton(icon: TuIcons.close, label: 'Close', size: TuButtonSize.sm, onTap: widget.onClose),
        ]),
      ]),
    );
  }

  Widget _body(BuildContext context) {
    final t = context.tok;
    final p = widget.plan;
    final about = TokText.bodySm.copyWith(color: t.textMuted);
    final children = switch (_tab) {
      0 => [
          Padding(padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs), child: Text(p.about, style: about)),
          KnowSection(title: 'Know before you go', children: [for (final tip in p.tips) KnowRow(title: tip)]),
        ],
      1 => [
          Padding(padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs), child: Text("Pick what you'll have. When the bill comes, scan it and each line goes to whoever picked it.", style: about)),
          KnowSection(
            title: 'Menu picks',
            meta: '${p.menu.expand((d) => d.pickedBy).toSet().length} of ${people.length} picked',
            children: [
              for (final d in p.menu)
                KnowRow(
                  title: d.name,
                  subtitle: d.price,
                  leading: _slot(Sticker(d.sticker, size: StickerSize.row)),
                  trailing: Overlapped(overlap: TokDim.avatarOverlap, children: [for (final id in d.pickedBy) Sticker(faceOf(id), size: StickerSize.chip)]),
                ),
            ],
          ),
        ],
      _ => [
          KnowSection(
            title: "Who's coming",
            meta: '${people.where((x) => x.going).length} of ${people.length} going',
            children: [for (final x in people) KnowRow(title: x.name, subtitle: x.status, leading: _slot(Sticker(x.sticker, size: StickerSize.avatar)))],
          ),
        ],
    };
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.md, children: children));
  }
}

/// A square slot the height of a row sticker, so titles line up whatever the sticker's width.
Widget _slot(Widget sticker) => SizedBox.square(dimension: TokDim.stickerRow, child: FittedBox(fit: BoxFit.contain, child: sticker));

class _Photo extends StatelessWidget {
  const _Photo(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(TokRadius.card),
        child: Image.asset('assets/photos/$name.png', fit: BoxFit.cover, height: double.infinity, filterQuality: FilterQuality.medium),
      );
}
