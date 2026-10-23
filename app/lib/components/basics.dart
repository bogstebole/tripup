import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
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
    final img = Image.asset('assets/stickers/$name.png', height: height ?? heightOf(size!), fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    return tilt == 0 ? img : Transform.rotate(angle: tilt * 3.141592653589793 / 180, child: img);
  }
}

/// Soft pill in the top bar: two people stickers and a "+N" bubble.
class PeopleButton extends StatelessWidget {
  const PeopleButton({super.key, required this.faces, required this.more, this.onTap});
  final List<String> faces;
  final int more;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${faces.length + more} people on this trip',
      child: Glass(
        kind: GlassKind.soft,
        height: TokDim.buttonMd,
        radius: BorderRadius.circular(TokRadius.pill),
        padding: const EdgeInsets.fromLTRB(TokSpace.xs, TokSpace.x2xs, TokSpace.x3xs, TokSpace.x2xs),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.x3xs, children: [
          Overlapped(overlap: TokDim.avatarOverlap, children: [for (final f in faces) Sticker(f, size: StickerSize.avatar)]),
          Container(
            width: TokDim.countBubbleSize,
            height: TokDim.countBubbleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.cCountBubbleBg, borderRadius: BorderRadius.circular(TokRadius.pill)),
            child: Text('+$more', style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: t.cCountBubbleFg)),
          ),
        ]),
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

/// Lucide "star", filled (the icon font only has the outline).
const _lucideStar = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#000" stroke="#000" stroke-width="2" stroke-linejoin="round" d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"/></svg>';

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
          SvgPicture.string(_lucideStar, width: TokSize.iconSm, height: TokSize.iconSm, colorFilter: ColorFilter.mode(t.iconBrand, BlendMode.srcIn)),
          Text(rating, style: muted),
        ]),
        Text('-', style: TokText.labelSm.copyWith(color: t.textMuted)),
        Text(kind, style: muted),
      ],
    );
  }
}

class InfoChip {
  const InfoChip(this.text, {this.sticker, this.tilt = 0, this.grow = false});
  final String text;
  final String? sticker;
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (c.sticker != null) Sticker(c.sticker!, size: StickerSize.chip, tilt: c.tilt),
              Text(c.text, maxLines: 1, overflow: TextOverflow.clip, style: TokText.bodySm.copyWith(fontWeight: TokWeight.semibold, color: t.cChipFg)),
            ]),
          );
          return c.grow ? Expanded(child: chip) : chip;
        }(),
    ]);
  }
}

/// A tappable soft row inside a section: brand text and an arrow.
class KnowRow extends StatelessWidget {
  const KnowRow({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Glass(
        kind: GlassKind.soft,
        radius: BorderRadius.circular(TokRadius.card),
        padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm, vertical: TokSpace.xs),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TokDim.knowRowHeight - 2 * TokSpace.xs),
          child: Row(spacing: TokSpace.md, children: [
            ?leading,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: TokText.labelSm.copyWith(color: t.textBrand)),
                if (subtitle != null) Text(subtitle!, style: TokText.labelSm.copyWith(color: t.textMuted)),
              ]),
            ),
            ?trailing,
            Icon(LucideIcons.arrowRight, size: TokSize.iconSm, color: t.iconBrand),
          ]),
        ),
      ),
    );
  }
}

/// A muted group with a brand heading and rows: tips, menu picks, people.
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
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: BorderRadius.circular(TokRadius.sheet)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: TokSpace.xs, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokSpace.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(title, style: TokText.headingSm.copyWith(color: t.textBrand))),
            if (meta != null) Text(meta!, style: TokText.labelSm.copyWith(color: t.textMuted)),
          ]),
        ),
        ...children,
      ]),
    );
  }
}
