import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'segmented_tabs.dart';
import 'stagger.dart';

const detailTabs = ['Overview', 'Menu', 'People'];

/// The full view of a plan (see Storybook: Screens/Trip → Full view). Each tab replaces everything above the
/// tabs; the new page staggers in with a light blur while the old one fades out. The top of each page is the
/// handle for pulling the sheet down ([onHeaderDragUpdate] / [onHeaderDragEnd]).
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
  int _tab = 0;
  final _added = <String>{};   // dishes I added, on top of my picks from before

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TokSpace.xs),
      child: Column(spacing: TokSpace.md, children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: TokMotion.fade,
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            // The new page runs its own stagger; only the old one needs the switcher's fade
            transitionBuilder: (child, anim) => child.key == ValueKey(_tab) ? child : fadeBlurOut(anim, child),
            child: KeyedSubtree(key: ValueKey(_tab), child: _page(context)),
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SegmentedTabs(tabs: detailTabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
          TuButton(icon: TuIcons.close, label: 'Close', size: TuButtonSize.sm, onTap: widget.onClose),
        ]),
      ]),
    );
  }

  Widget _handle(Widget child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: widget.onHeaderDragUpdate,
        onVerticalDragEnd: widget.onHeaderDragEnd,
        child: child,
      );

  Widget _page(BuildContext context) => _fadeBottom(context, switch (_tab) {
        0 => _overview(context),
        1 => _menu(context),
        _ => _people(context),
      });

  /// Content scrolling under the tab bar fades out over the last few pixels instead of being cut off.
  Widget _fadeBottom(BuildContext context, Widget child) {
    final solid = context.tok.textDefault;   // only its alpha matters for the mask
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [solid, solid, solid.withValues(alpha: 0)],
        stops: [0, 1 - TokSpace.xl / r.height, 1],
      ).createShader(r),
      child: child,
    );
  }

  // ---------- Overview: Bogdan's design, unchanged
  Widget _overview(BuildContext context) {
    final t = context.tok;
    final p = widget.plan;
    return SingleChildScrollView(
      child: StaggerIn(spacing: TokSpace.md, children: [
        _handle(SizedBox(
          height: TokDim.photosHeight,
          child: Row(spacing: TokSpace.xs, children: [
            for (var i = 0; i < p.photos.length; i++)
              i == 0
                  ? SizedBox(width: TokDim.photosPeekStart, child: _Photo(p.photos[i]))
                  : i == p.photos.length - 1
                      ? SizedBox(width: TokDim.photosPeekEnd, child: _Photo(p.photos[i]))
                      : Expanded(child: _Photo(p.photos[i])),
          ]),
        )),
        _handle(Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
            RatingLine(rating: p.rating, kind: p.cuisine, center: false),
          ]),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs), child: Text(p.about, style: TokText.bodySm.copyWith(color: t.textMuted))),
        // The one highlighted block: worth knowing before going
        KnowSection(title: 'Know before you go', children: [for (final tip in p.tips) KnowRow(title: tip)]),
      ]),
    );
  }

  // ---------- Menu: the whole real menu, prices, who picked what, and Add
  Widget _menu(BuildContext context) {
    final t = context.tok;
    return FutureBuilder<List<MenuSection>>(
      future: brasserieMenu,
      builder: (context, snap) {
        final sections = snap.data ?? const <MenuSection>[];
        final pickers = {for (final s in sections) for (final i in s.items) ...i.pickedBy};
        return SingleChildScrollView(
          child: StaggerIn(spacing: TokSpace.xl, children: [
            _handle(Padding(
              padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.xs, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
                Text('Menu', style: TokText.headingLg.copyWith(color: t.textDefault)),
                Text('${pickers.length} of ${people.length} have picked. Add what you\'ll have, and the bill splits itself.', style: TokText.bodySm.copyWith(color: t.textMuted)),
              ]),
            )),
            for (final s in sections) _MenuSectionView(section: s, added: _added, onToggle: (name) => setState(() => _added.contains(name) ? _added.remove(name) : _added.add(name))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
              child: Text('Prices with VAT. From the restaurant\'s own menu. Entrecôte photos are the restaurant\'s; other dish photos are illustrative, from Wikimedia Commons.', style: TokText.bodySm.copyWith(color: t.textSubtle)),
            ),
          ]),
        );
      },
    );
  }

  // ---------- People: who's coming and how far away each person is
  Widget _people(BuildContext context) {
    final t = context.tok;
    return SingleChildScrollView(
      child: StaggerIn(spacing: TokSpace.md, children: [
        _handle(Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.xs, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
            Text("Who's coming", style: TokText.headingLg.copyWith(color: t.textDefault)),
            Text('${people.where((x) => x.going).length} of ${people.length} going · 5 PM today', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        )),
        Column(children: [
          for (var i = 0; i < people.length; i++) ...[
            if (i > 0) const _Hairline(),
            _PersonRow(person: people[i]),
          ],
        ]),
      ]),
    );
  }
}

class _MenuSectionView extends StatelessWidget {
  const _MenuSectionView({required this.section, required this.added, required this.onToggle});
  final MenuSection section;
  final Set<String> added;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
          Text(section.title, style: TokText.headingSm.copyWith(color: t.textDefault)),
          if (section.note != null) Text(section.note!, style: TokText.bodySm.copyWith(color: t.textMuted)),
        ]),
      ),
      for (var i = 0; i < section.items.length; i++) ...[
        if (i > 0) const _Hairline(),
        _MenuRow(item: section.items[i], added: added.contains(section.items[i].name) || section.items[i].pickedBy.contains('ari'), onToggle: onToggle),
      ],
    ]);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.added, required this.onToggle});
  final MenuItem item;
  final bool added;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final others = item.pickedBy.where((id) => id != 'ari').toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
      child: Row(spacing: TokSpace.sm, children: [
        if (item.photo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(TokDim.menuPhotoRadius),
            child: Image.asset(
              'assets/photos/menu/${item.photo}.jpg',
              width: TokDim.menuPhoto,
              height: TokDim.menuPhoto,
              fit: BoxFit.cover,
              cacheWidth: (TokDim.menuPhoto * MediaQuery.devicePixelRatioOf(context)).round(),
              excludeFromSemantics: true,
            ),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
            Text(item.name, style: TokText.labelMd.copyWith(color: t.textDefault)),
            if (item.note != null) Text(item.note!, style: TokText.bodySm.copyWith(color: t.textMuted)),
            Text(item.price, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault)),
          ]),
        ),
        if (others.isNotEmpty) Overlapped(overlap: TokDim.avatarOverlap, children: [for (final id in others) Sticker(faceOf(id), size: StickerSize.chip)]),
        AddButton(added: added, itemName: item.name, onTap: () => onToggle(item.name)),
      ]),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
      child: Row(spacing: TokSpace.sm, children: [
        SizedBox.square(dimension: TokDim.stickerRow, child: FittedBox(fit: BoxFit.contain, child: Sticker(person.sticker, size: StickerSize.avatar))),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person.name, style: TokText.labelMd.copyWith(color: t.textDefault)),
            Text(person.status, style: TokText.bodySm.copyWith(color: person.going ? t.textMuted : t.textSubtle)),
          ]),
        ),
      ]),
    );
  }
}

/// A 1 px line between rows of a plain list.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        child: SizedBox(width: double.infinity, height: TokDim.surfaceEdgeWidth, child: ColoredBox(color: context.tok.borderDefault)),
      );
}

class _Photo extends StatelessWidget {
  const _Photo(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(TokRadius.card),
        child: Image.asset('assets/photos/$name.png', fit: BoxFit.cover, height: double.infinity, filterQuality: FilterQuality.medium),
      );
}
