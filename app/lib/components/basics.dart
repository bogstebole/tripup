import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import '../startup_timings.dart';
import 'glass.dart';

/// The raised white glass every widget sits on (see Storybook: Components/Basics → Surface).
BoxDecoration surfaceDecoration(BuildContext context, BorderRadius radius) {
  final t = context.tok;
  return BoxDecoration(
    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.cSurfaceTop, t.cSurfaceBottom]),
    border: Border.all(color: t.cSurfaceEdge, width: TokDim.surfaceEdgeWidth),
    borderRadius: radius,
    boxShadow: TokShadow.surface,
  );
}

enum StickerSize { avatar, chip, mini, edge, row, map }

/// A die-cut photo sticker. Height from a sticker size token (or an exact height for hand-placed compositions).
class Sticker extends StatelessWidget {
  const Sticker(this.name, {super.key, this.size, this.height, this.tilt = 0});
  final String name;
  final StickerSize? size;
  final double? height;
  final double tilt;

  static double heightOf(StickerSize s) => switch (s) {
        StickerSize.avatar => TokDim.stickerAvatar,
        StickerSize.chip => TokDim.stickerChip,
        StickerSize.mini => TokDim.stickerMini,
        StickerSize.edge => TokDim.stickerEdge,
        StickerSize.row => TokDim.stickerRow,
        StickerSize.map => TokDim.stickerMap,
      };

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/stickers/$name.png',
      height: height ?? heightOf(size!),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, _) {
        if (frame != null) StartupTimings.sticker(name);
        return child;
      },
    );
    return tilt == 0 ? img : Transform.rotate(angle: tilt * 3.141592653589793 / 180, child: img);
  }
}

/// A dish photo dressed as one of the app's die-cut stickers: white edge, soft shadow, a slight tilt.
class DishSticker extends StatelessWidget {
  const DishSticker(this.photo, {super.key, required this.size, required this.edge, required this.radius, this.tilt = 0});

  /// File name in assets/photos/menu, without .jpg.
  final String photo;
  final double size, edge, radius;

  /// Degrees.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final inner = size - edge * 2;
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(edge),
        decoration: BoxDecoration(color: t.cDishEdge, borderRadius: BorderRadius.circular(radius + edge), boxShadow: TokShadow.slightlyRaised),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            'assets/photos/menu/$photo.jpg',
            width: inner,
            height: inner,
            fit: BoxFit.cover,
            cacheWidth: (inner * MediaQuery.devicePixelRatioOf(context)).round(),
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// Children overlapping by [overlap] and centred as a group (the overlap is taken out of the width).
class Overlapped extends StatelessWidget {
  const Overlapped({super.key, required this.overlap, required this.children});
  final double overlap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        for (var i = 0; i < children.length; i++) i == 0 ? children[i] : _Pull(overlap: overlap, child: children[i]),
      ]);
}

/// Pulls a child left by [overlap] without leaving a gap on the right.
class _Pull extends SingleChildRenderObjectWidget {
  const _Pull({required this.overlap, super.child});
  final double overlap;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPull(overlap);
  @override
  void updateRenderObject(BuildContext context, _RenderPull r) => r.overlap = overlap;
}

class _RenderPull extends RenderShiftedBox {
  _RenderPull(this._overlap) : super(null);
  double _overlap;
  set overlap(double v) {
    if (v != _overlap) {
      _overlap = v;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    child!.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(Size((child!.size.width - _overlap).clamp(0, double.infinity), child!.size.height));
    (child!.parentData! as BoxParentData).offset = Offset(-_overlap, 0);
  }
}

/// Filled brand star, rating and review count, then the place type.
class RatingLine extends StatelessWidget {
  const RatingLine({super.key, required this.rating, required this.kind, this.center = true});
  final String rating;
  final String kind;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final muted = TokText.labelMd.copyWith(color: t.textMuted);
    return Row(
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      spacing: TokSpace.x3xs,
      children: [
        Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x2xs, children: [
          LucideIcon(TuIcons.star, size: TokSize.iconSm, color: t.iconBrand, filled: true),
          Text(rating, style: muted),
        ]),
        Text('-', style: TokText.labelMd.copyWith(color: t.textMuted)),
        Text(kind, style: muted),
      ],
    );
  }
}

class InfoChip {
  const InfoChip(this.text, {this.sticker, this.faces = const [], this.tilt = 0, this.grow = false});
  final String text;
  final String? sticker;

  /// People's stickers, overlapped in front of the text ("here"); shown instead of [sticker].
  final List<String> faces;
  final double tilt;
  final bool grow;
}

/// Joined facts about a plan: who's going, price level, time. Only the outer corners are rounded.
class InfoChips extends StatelessWidget {
  const InfoChips({super.key, required this.items});
  final List<InfoChip> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final r = const Radius.circular(TokDim.chipRadius);
    return Row(spacing: TokDim.chipGap, children: [
      for (var i = 0; i < items.length; i++)
        () {
          final c = items[i];
          final chip = Container(
            height: TokDim.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs, vertical: TokSpace.x2xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.cChipBg,
              borderRadius: BorderRadius.horizontal(left: i == 0 ? r : Radius.zero, right: i == items.length - 1 ? r : Radius.zero),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, spacing: c.faces.isEmpty ? 0 : TokSpace.x2xs, children: [
              if (c.faces.isNotEmpty)
                Overlapped(overlap: TokDim.chipFaceOverlap, children: [for (final f in c.faces) Sticker(f, size: StickerSize.chip)])
              else if (c.sticker != null)
                Sticker(c.sticker!, size: StickerSize.chip, tilt: c.tilt),
              Text(c.text, maxLines: 1, overflow: TextOverflow.clip, style: TokText.bodySm.copyWith(fontWeight: TokWeight.semibold, color: t.cChipFg)),
            ]),
          );
          return c.grow ? Expanded(child: chip) : chip;
        }(),
    ]);
  }
}

/// People as a little pile: up to two of their stickers, then a "+N" bubble for the rest. On the map it's a
/// group walking together; on a pin, who's already there.
class FacePile extends StatelessWidget {
  const FacePile({super.key, required this.faces, this.size = StickerSize.avatar});
  final List<String> faces;
  final StickerSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final more = faces.length - 2;
    return Overlapped(overlap: TokDim.avatarOverlap, children: [
      for (final f in faces.take(2)) Sticker(f, size: size),
      if (more > 0)
        Container(
          width: TokDim.countBubbleSize,
          height: TokDim.countBubbleSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.bgDefault, borderRadius: BorderRadius.circular(TokRadius.pill), boxShadow: TokShadow.slightlyRaised),
          child: Text('+$more', style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.textDefault)),
        ),
    ]);
  }
}

/// A tip inside a section (Bogdan's Overview, Figma 62:4828): a short line in brand on a muted block. Read, not
/// tapped, so no arrow and no glass.
class KnowTip extends StatelessWidget {
  const KnowTip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      constraints: const BoxConstraints(minHeight: TokDim.knowRowHeight),
      padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm, vertical: TokSpace.xs),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.card)),
      child: Text(text, style: TokText.labelSm.copyWith(color: t.textBrand)),
    );
  }
}

/// A subtle group with a brand heading and rows: the place's tips.
class KnowSection extends StatelessWidget {
  const KnowSection({super.key, required this.title, this.meta, required this.children});
  final String title;
  final String? meta;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.md, TokSpace.xs, TokSpace.xs),
      decoration: BoxDecoration(color: t.bgSubtle, borderRadius: BorderRadius.circular(TokRadius.sheet)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(title, style: TokText.headingSm.copyWith(color: t.textBrand))),
            if (meta != null) Text(meta!, style: TokText.labelMd.copyWith(color: t.textMuted)),
          ]),
        ),
        ...children,
      ]),
    );
  }
}

/// A thin divider between rows in a list, inset to the rows' text.
class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
        child: SizedBox(width: double.infinity, height: TokDim.surfaceEdgeWidth, child: ColoredBox(color: context.tok.borderDefault)),
      );
}
