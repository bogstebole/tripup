import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'glass.dart';

/// A short note: a flat pill in the brand blue (not glass, so it doesn't read as a button), with a check,
/// the one line that matters, and Undo.
class Toast extends StatelessWidget {
  const Toast({super.key, required this.label, this.actionLabel, this.onAction});
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final fg = t.textOnBrand;
    return Semantics(
      liveRegion: true,
      child: Container(
        height: TokDim.buttonMd,
        padding: const EdgeInsets.only(left: TokSpace.md),
        decoration: BoxDecoration(color: TokPalette.blue700, borderRadius: BorderRadius.circular(TokRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: TokSpace.xs, children: [
          LucideIcon(TuIcons.check, size: TokSize.iconSm, color: fg),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TokText.labelMd.copyWith(color: fg))),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              semanticLabel: actionLabel,
              child: SizedBox(
                height: TokDim.buttonMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.md),
                  child: Center(widthFactor: 1, child: Text(actionLabel!, style: TokText.labelMd.copyWith(fontWeight: TokWeight.bold, color: fg))),
                ),
              ),
            )
          else
            const SizedBox(width: TokSpace.x2xs),
        ]),
      ),
    );
  }
}
