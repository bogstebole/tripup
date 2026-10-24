// The trip screen's entrance: as a trip opens out of its card, its controls arrive one by one.
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The order the controls arrive in: the top bar's three, then the day chips (only as many as show on a phone; the
/// rest arrive with the last one), then the footer's. Up next comes after all of them (see TripScreen).
abstract final class EnterOrder {
  static const back = 0, title = 1, demo = 2, firstChip = 3, chipsShown = 6;
  static const footer = firstChip + chipsShown;   // the footer's buttons follow, one by one
  static const count = footer + 3;

  /// How long the whole entrance takes, from the tap: the wait while the surface grows, one step per control, and
  /// the last one's own time.
  static Duration get total => TokMotion.openDelay + TokMotion.openStagger * (count - 1) + TokMotion.openItem;

  /// When the last control starts: Up next comes then.
  static Duration get last => TokMotion.openDelay + TokMotion.openStagger * (count - 1);
}

/// Carries the entrance's clock (0 at the tap, 1 once the last control has landed) down to the controls. At rest it
/// stays at 1, so everything simply shows.
class TripEntrance extends InheritedWidget {
  const TripEntrance({super.key, required this.clock, required super.child});
  final Animation<double> clock;

  static Animation<double>? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TripEntrance>()?.clock;

  @override
  bool updateShouldNotify(TripEntrance old) => old.clock != clock;
}

/// One control arriving on its own: it fades in and rises a little, at its place in [EnterOrder], ease-out. With
/// reduced motion it only fades. Outside a [TripEntrance] (or at rest) it's just the control. The same widgets wrap it
/// either way, so nothing is rebuilt when the entrance ends.
class EnterItem extends StatelessWidget {
  const EnterItem({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = TripEntrance.of(context);
    if (clock == null) return child;
    final total = EnterOrder.total.inMicroseconds;
    final start = (TokMotion.openDelay + TokMotion.openStagger * index.clamp(0, EnterOrder.count - 1)).inMicroseconds / total;
    final curve = Interval(start, (start + TokMotion.openItem.inMicroseconds / total).clamp(0.0, 1.0), curve: TokMotion.easeOut);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final v = curve.transform(clock.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, reduce ? 0 : (1 - v) * TokSpace.xs), child: child),
        );
      },
    );
  }
}
