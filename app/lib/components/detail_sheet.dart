import 'dart:math' as math;

import 'package:flutter/material.dart' show CarouselView;
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'basics.dart';
import 'glass.dart';
import 'progressive_blur.dart';
import 'segmented_tabs.dart';
import 'stagger.dart';

const detailTabs = ['Overview', 'Menu', 'People'];

/// The full view of a plan (see Storybook: Screens/Trip → Full view). The tabs and close sit in a header at the
/// top, and each tab replaces the whole page under it: the new page staggers in with a light blur while the old
/// one fades out. Every page scrolls up under the header; pulling the header, or a page past its top, pulls the
/// sheet down ([onHeaderDragUpdate] / [onHeaderDragEnd]).
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

  /// The dishes I'll have: my picks from before, then whatever I add or remove here.
  Set<String>? _mine;

  /// How far the page has scrolled under the top edge, 0–1 over the top fade's height.
  final _under = ValueNotifier<double>(0);

  @override
  void dispose() {
    _under.dispose();
    super.dispose();
  }

  late final _pull = _Pull((dy) => widget.onHeaderDragUpdate?.call(DragUpdateDetails(globalPosition: Offset.zero, delta: Offset(0, dy), primaryDelta: dy)));

  /// The header's height: its top inset, then the taller of the tab bar and the close button.
  static double get _headerHeight => TokSpace.xs + math.max(TokDim.segmentHeight + TokDim.segmentTrackPadding * 2, TokDim.buttonSm);

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final header = _headerHeight, solid = header / (header + TokDim.sheetTopFade);
    // The tabs and close sit in a header over the page; content scrolls up under it, through a blur and the surface's white
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: TokMotion.fade,
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
              // The new page runs its own stagger; only the old one needs the switcher's fade
              transitionBuilder: (child, anim) => child.key == ValueKey(_tab) ? child : fadeBlurOut(anim, child),
              child: KeyedSubtree(key: ValueKey(_tab), child: _page(context)),
            ),
          ),
          // The header's backdrop shows once content goes under it, so a page at rest isn't faded at the top
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
                    : Opacity(
                        opacity: v,
                        child: Stack(fit: StackFit.expand, children: [
                          ProgressiveBlur(sigma: TokDim.sheetTopBlur, solidUntil: solid),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [t.cSurfaceTop, t.cSurfaceTop, t.cSurfaceTop.withValues(alpha: 0)],
                                stops: [0, solid, 1],
                              ),
                            ),
                          ),
                        ]),
                      ),
              ),
            ),
          ),
          // The header, which is also a handle for pulling the sheet down
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
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  SegmentedTabs(
                    tabs: detailTabs,
                    index: _tab,
                    onChanged: (i) {
                      _under.value = 0;   // the new page starts at its top
                      setState(() => _tab = i);
                    },
                  ),
                  TuButton(icon: TuIcons.close, label: 'Close', size: TuButtonSize.sm, onTap: widget.onClose),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// A page pulled past its top pulls the sheet; letting go hands the finger's speed to the sheet.
  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) _under.value = (n.metrics.pixels / TokDim.sheetTopFade).clamp(0.0, 1.0);
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _pull.move(-n.overscroll);
    } else if (n is ScrollEndNotification && _pull.pulled > 0) {
      _pull.pulled = 0;
      widget.onHeaderDragEnd?.call(n.dragDetails ?? DragEndDetails(velocity: Velocity.zero));
    }
    return false;
  }

  Widget _scroll(Widget child) => _fadeBottom(
        context,
        SingleChildScrollView(
          physics: _SheetPhysics(pull: _pull, parent: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())),
          // Starts under the header; room at the end for the last block to scroll clear of the bottom fade
          padding: EdgeInsets.only(top: _headerHeight + TokSpace.xs, bottom: TokDim.sheetFade + TokSpace.xs),
          child: child,
        ),
      );

  Widget _page(BuildContext context) => switch (_tab) {
        0 => _overview(context),
        1 => _menu(context),
        _ => _people(context),
      };

  /// Content scrolling past the bottom of its area fades out over the last few pixels instead of being cut off.
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

  /// The menu, with my picks seeded from it the first time it arrives.
  Widget _withMenu(Widget Function(List<MenuSection> sections, Set<String> mine) build) => FutureBuilder<List<MenuSection>>(
        future: brasserieMenu,
        builder: (context, snap) {
          final sections = snap.data ?? const <MenuSection>[];
          if (snap.hasData) _mine ??= {for (final s in sections) for (final i in s.items) if (i.pickedBy.contains(myId)) i.name};
          return build(sections, _mine ?? const {});
        },
      );

  void _toggle(String name) => setState(() => _mine!.contains(name) ? _mine!.remove(name) : _mine!.add(name));

  // ---------- Overview: Bogdan's design, then the place's facts from Google Maps
  Widget _overview(BuildContext context) {
    final t = context.tok;
    final p = widget.plan;
    return _scroll(StaggerIn(spacing: TokSpace.md, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.headingMd.copyWith(color: t.textDefault)),
          RatingLine(rating: p.rating, kind: p.cuisine, center: false),
        ]),
      ),
      _PhotoCarousel(photos: p.photos),
      Padding(padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs), child: Text(p.about, style: TokText.bodySm.copyWith(color: t.textMuted))),
      // The one highlighted block: worth knowing before going
      KnowSection(title: 'Know before you go', children: [for (final tip in p.tips) KnowRow(title: tip)]),
      if (p.services.isNotEmpty || p.details.isNotEmpty) _PlaceFacts(plan: p),
    ]));
  }

  // ---------- Menu: the whole real menu as cards, prices, who picked what, and Add
  Widget _menu(BuildContext context) {
    final t = context.tok;
    return _withMenu((sections, mine) {
      final pickers = {for (final s in sections) for (final i in s.items) ...i.pickedBy.where((id) => id != myId), if (mine.isNotEmpty) myId};
      return _scroll(StaggerIn(spacing: TokSpace.xl, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.xs, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
            Text('Menu', style: TokText.headingLg.copyWith(color: t.textDefault)),
            Text('${pickers.length} of ${people.length} have picked. Add what you\'ll have, and the bill splits itself.', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
        for (final s in sections) _MenuSectionView(section: s, mine: mine, onToggle: _toggle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
          child: Text('Prices with VAT. From the restaurant\'s own menu. Entrecôte photos are the restaurant\'s; other dish photos are illustrative, from Wikimedia Commons.', style: TokText.bodySm.copyWith(color: t.textSubtle)),
        ),
      ]));
    });
  }

  // ---------- People: who's coming, how far away each person is, and what they've picked
  Widget _people(BuildContext context) {
    final t = context.tok;
    return _withMenu((sections, mine) {
      final dishes = [for (final s in sections) ...s.items];
      List<MenuItem> picksOf(String id) => [for (final d in dishes) if (id == myId ? mine.contains(d.name) : d.pickedBy.contains(id)) d];
      // Roughly what each person's picks come to, and all of them together
      final cost = {for (final x in people) x.id: picksOf(x.id).fold(0.0, (sum, d) => sum + (eurosIn(d.price) ?? 0))};
      final total = cost.values.fold(0.0, (a, b) => a + b);
      final list = _scroll(StaggerIn(spacing: TokSpace.md, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.xs, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x2xs, children: [
            Text("Who's coming", style: TokText.headingLg.copyWith(color: t.textDefault)),
            Text('${people.where((x) => x.going).length} of ${people.length} going · ${widget.plan.whenLong}', style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
        Column(children: [
          for (var i = 0; i < people.length; i++) ...[
            if (i > 0) const _Hairline(),
            _PersonRow(person: people[i], picks: picksOf(people[i].id), cost: cost[people[i].id]!),
          ],
        ]),
      ]));
      if (total <= 0) return list;
      // The total stays put at the bottom while the list scrolls above it
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: list),
        Padding(
          padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.xs, TokSpace.xs, TokSpace.md),
          child: Row(spacing: TokSpace.sm, children: [
            Expanded(child: Text('Estimated total', style: TokText.labelLg.copyWith(color: t.textDefault))),
            Text('≈ ${euros(total)}', style: TokText.headingLg.copyWith(color: t.textDefault)),
          ]),
        ),
      ]);
    });
  }
}

/// How far the current gesture has pulled the sheet down, shared with the page's scroll physics.
class _Pull {
  _Pull(this.onMove);
  final void Function(double dy) onMove;
  double pulled = 0;

  void move(double dy) {
    final d = math.max(-pulled, dy);
    pulled += d;
    onMove(d);
  }
}

/// Bounces at the bottom like any iOS list, but stops at the top, so pulling past it pulls the sheet;
/// while the sheet is pulled, moving back up lifts it first and the content stays put.
class _SheetPhysics extends ScrollPhysics {
  const _SheetPhysics({required this.pull, super.parent});
  final _Pull pull;

  @override
  _SheetPhysics applyTo(ScrollPhysics? ancestor) => _SheetPhysics(pull: pull, parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (pull.pulled > 0 && offset < 0) {
      final lift = math.min(-offset, pull.pulled);
      pull.move(-lift);
      offset += lift;
      if (offset == 0) return 0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels && position.pixels <= position.minScrollExtent) return value - position.pixels;
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) return value - position.minScrollExtent;
    return super.applyBoundaryConditions(position, value);
  }
}

/// The place's facts, as on its Google Maps card: service options, then one line per fact.
class _PlaceFacts extends StatelessWidget {
  const _PlaceFacts({required this.plan});
  final Plan plan;

  static String _icon(PlaceDetailKind k) => switch (k) {
        PlaceDetailKind.address => TuIcons.places,
        PlaceDetailKind.hours => TuIcons.hours,
        PlaceDetailKind.price => TuIcons.price,
        PlaceDetailKind.booking => TuIcons.calendar,
        PlaceDetailKind.order => TuIcons.delivery,
        PlaceDetailKind.website => TuIcons.website,
        PlaceDetailKind.phone => TuIcons.phone,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final rows = <Widget>[
      if (plan.services.isNotEmpty)
        _FactRow(
          child: Wrap(spacing: TokSpace.sm, runSpacing: TokSpace.x2xs, children: [
            for (final s in plan.services)
              Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xs, children: [
                LucideIcon(TuIcons.check, size: TokSize.iconSm, color: t.iconSuccess),
                Text(s, style: TokText.labelMd.copyWith(color: t.textDefault)),
              ]),
          ]),
        ),
      for (final d in plan.details)
        _FactRow(
          icon: _icon(d.kind),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
            Text.rich(TextSpan(style: TokText.labelMd.copyWith(color: t.textDefault), children: [
              if (d.status != null) TextSpan(text: '${d.status} · ', style: TextStyle(color: t.textSuccess)),
              TextSpan(text: d.text),
            ])),
            if (d.sub != null) Text(d.sub!, style: TokText.bodySm.copyWith(color: t.textMuted)),
          ]),
        ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs), child: Text('Details', style: TokText.headingSm.copyWith(color: t.textDefault))),
      for (var i = 0; i < rows.length; i++) ...[if (i > 0) const _Hairline(), rows[i]],
    ]);
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({this.icon, required this.child});
  final String? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.md, children: [
          if (icon != null) LucideIcon(icon!, size: TokSize.iconMd, color: context.tok.iconMuted),
          Expanded(child: child),
        ]),
      );
}

class _MenuSectionView extends StatelessWidget {
  const _MenuSectionView({required this.section, required this.mine, required this.onToggle});
  final MenuSection section;
  final Set<String> mine;
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
        _MenuRow(item: section.items[i], index: i, added: mine.contains(section.items[i].name), onToggle: onToggle),
      ],
    ]);
  }
}

/// One dish in a plain list: its photo as a sticker, name and the full description; under them, the price,
/// who else has picked it, and Add.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.index, required this.added, required this.onToggle});
  final MenuItem item;
  final int index;
  final bool added;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final others = item.pickedBy.where((id) => id != myId).toList();
    // Add's touch target reaches past its circle; the outer right inset leaves the circle on the text's edge
    const addInset = (TokSize.touchTarget - TokDim.buttonPillHeight) / 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.sm, TokSpace.xs - addInset, TokSpace.x2xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(right: addInset),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.sm, children: [
            if (item.photo != null)
              DishSticker(item.photo!, size: TokDim.menuPhoto, edge: TokDim.menuPhotoEdge, radius: TokDim.menuPhotoRadius, tilt: index.isEven ? -TokDim.menuPhotoTilt : TokDim.menuPhotoTilt),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: TokSpace.x3xs, children: [
                Text(item.name, style: TokText.labelMd.copyWith(color: t.textDefault)),
                if (item.note != null) Text(item.note!, style: TokText.bodySm.copyWith(color: t.textMuted)),
              ]),
            ),
          ]),
        ),
        Row(spacing: TokSpace.xs, children: [
          Expanded(child: Text(item.price, style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault))),
          if (others.isNotEmpty)
            Semantics(
              label: 'Picked by ${others.map((id) => people.firstWhere((p) => p.id == id).name).join(', ')}',
              child: Overlapped(overlap: TokDim.avatarOverlap, children: [for (final id in others) Sticker(faceOf(id), size: StickerSize.chip)]),
            ),
          AddButton(added: added, itemName: item.name, onTap: () => onToggle(item.name)),
        ]),
      ]),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.picks, required this.cost});
  final Person person;
  final List<MenuItem> picks;

  /// Roughly what their picks come to.
  final double cost;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    // Two in the pile, the priciest (the mains, usually); the rest are counted on one more sticker
    final byPrice = [for (final d in picks) if (d.photo != null) d]..sort((a, b) => (eurosIn(b.price) ?? 0).compareTo(eurosIn(a.price) ?? 0));
    final shown = byPrice.take(2).toList();
    final more = picks.length - shown.length;
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
        // What they'll have, as a little pile of stickers: at a glance, who has already picked
        if (picks.isNotEmpty)
          Semantics(
            label: '${person.name} picked ${picks.map((d) => d.name).join(', ')}',
            child: Overlapped(overlap: TokDim.avatarOverlap, children: [
              for (var i = 0; i < shown.length; i++)
                DishSticker(shown[i].photo!, size: TokDim.dishPickSize, edge: TokDim.dishPickEdge, radius: TokRadius.sm, tilt: i.isEven ? TokDim.menuPhotoTilt : -TokDim.menuPhotoTilt),
              if (more > 0) _MorePicks(more, tilt: shown.length.isEven ? TokDim.menuPhotoTilt : -TokDim.menuPhotoTilt),
            ]),
          ),
        if (cost > 0)
          Text('≈ ${euros(cost)}', style: TokText.labelMd.copyWith(fontWeight: TokWeight.semibold, color: t.textDefault))
        else if (person.going)
          Text('No picks yet', style: TokText.bodySm.copyWith(color: t.textSubtle)),
      ]),
    );
  }
}

/// The rest of a person's picks, as one more sticker on the pile: "+2".
class _MorePicks extends StatelessWidget {
  const _MorePicks(this.count, {required this.tilt});
  final int count;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Container(
        width: TokDim.dishPickSize,
        height: TokDim.dishPickSize,
        padding: const EdgeInsets.all(TokDim.dishPickEdge),
        decoration: BoxDecoration(color: t.cDishEdge, borderRadius: BorderRadius.circular(TokRadius.sm + TokDim.dishPickEdge), boxShadow: TokShadow.slightlyRaised),
        child: DecoratedBox(
          decoration: BoxDecoration(color: t.cCountBubbleBg, borderRadius: BorderRadius.circular(TokRadius.sm)),
          child: Center(child: Text('+$count', style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.cCountBubbleFg))),
        ),
      ),
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

/// The place's photos as a Material 3 multi-browse carousel: a large photo first, then a medium and a small one,
/// each growing or shrinking as it moves between those places, and snapping to whole photos.
class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({required this.photos});
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return LayoutBuilder(builder: (context, box) {
      // The items' own gaps reach past the page's edges, so the photos line up with them
      final width = box.maxWidth + TokSpace.xs;
      // Small and medium keep the design's peek widths; large takes the rest
      final large = width - TokDim.photosPeekStart - TokDim.photosPeekEnd;
      return SizedBox(
        height: TokDim.photosHeight,
        child: OverflowBox(
          maxWidth: width,
          minWidth: width,
          child: CarouselView.weighted(
            flexWeights: [large.round(), TokDim.photosPeekEnd.round(), TokDim.photosPeekStart.round()],
            itemSnapping: true,
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs / 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TokRadius.card)),
            backgroundColor: t.bgMuted,
            elevation: 0,
            enableSplash: false,
            children: [
              for (final ph in photos)
                Image.asset('assets/photos/$ph.png', fit: BoxFit.cover, filterQuality: FilterQuality.medium, cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round()),
            ],
          ),
        ),
      );
    });
  }
}
