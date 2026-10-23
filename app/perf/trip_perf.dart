// Frame times for the trip screen's heaviest moments, measured with the real app on the phone in profile mode:
//   flutter build ios --profile -t perf/trip_perf.dart
//   xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app
//   xcrun devicectl device process launch --console --terminate-existing --device <id> com.bogste.tripup
//   xcrun devicectl device copy from --device <id> --domain-type appDataContainer --domain-identifier com.bogste.tripup \
//     --source tmp/perf.json --destination perf.json
// It plays each scenario with synthetic touches at the display's pace, records every frame's UI (build) and raster
// time, prints one summary line per scenario, writes everything to the app's tmp/perf.json and quits.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tripup/components/glass.dart';
import 'package:tripup/components/segmented_tabs.dart';
import 'package:tripup/components/toggle_chips.dart';
import 'package:tripup/main.dart';

typedef Scenario = Future<void> Function(Player p);

/// The scenarios, in the order they run (the first full-view open also decodes the photos).
final scenarios = <String, Scenario>{
  'map_pan_zoom': mapPanZoom,
  'sheet_open_close': sheetOpenClose,
  'tabs': tabs,
  'menu_scroll': menuScroll,
  'overview_scroll': overviewScroll,
  'group_scroll': groupScroll,
  'day_filter': dayFilter,
};

Future<void> main() => runAll({for (final e in scenarios.entries) e.key: e.value});

/// Runs each scenario on a fresh app and reports. [before] runs ahead of each one (for experiments).
Future<void> runAll(Map<String, Scenario> plan, {void Function(String key)? before}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  final results = <String, dynamic>{};
  final p = Player(results);
  final file = File('${Directory.systemTemp.path}/perf.json');
  for (final MapEntry(:key, :value) in plan.entries) {
    before?.call(key);
    p.prefix = key;
    try {
      // A scenario that can't find what to tap (or hangs) is recorded and skipped, not the end of the run
      await value(p).timeout(const Duration(minutes: 2));
    } catch (e) {
      results['$key error'] = '$e';
      debugPrint('PERF $key failed: $e');
    }
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(results));   // so far, in case the run stops
  }
  debugPrint('PERF DONE ${file.path}');
  await Future<void>.delayed(const Duration(seconds: 1));
  exit(0);
}

Future<void> mapPanZoom(Player p) async {
  final s = await p.start();
  Future<void> route() async {
    await p.drag(Offset(s.width * .75, s.height * .6), Offset(-s.width * .5, 0));
    await p.drag(Offset(s.width * .5, s.height * .4), Offset(0, s.height * .25));
    await p.drag(Offset(s.width * .25, s.height * .6), Offset(s.width * .5, 0));
    await p.drag(Offset(s.width * .5, s.height * .65), Offset(0, -s.height * .25));
    await p.pinch(Offset(s.width / 2, s.height * .55), 80, 260);
    await p.wait(300);
    await p.pinch(Offset(s.width / 2, s.height * .55), 260, 80);
    await p.wait(800);
  }

  await route();   // warm-up: the tiles on the route load once
  await p.wait(3000);
  await p.measure('', route);
}

Future<void> sheetOpenClose(Player p) async {
  await p.start();
  Future<void> cycle() async {
    await p.tap(Player.openButton);
    await p.wait(1000);
    await p.tap(Player.closeButton);
    await p.wait(1000);
  }

  await p.measure('_first', cycle);
  await p.measure('', () async {
    for (var i = 0; i < 3; i++) {
      await cycle();
    }
  });
}

Future<void> tabs(Player p) async {
  await p.start();
  await p.openSheet();
  // Every page once first, so the measured pass isn't decoding images
  for (final name in ['Menu', 'Group', 'Overview']) {
    await p.tap(Player.tab(name), within: Player.tabs);
    await p.wait(1000);
  }
  await p.measure('', () async {
    for (final name in ['Menu', 'Group', 'Overview', 'Group', 'Menu', 'Overview']) {
      await p.tap(Player.tab(name), within: Player.tabs);
      await p.wait(900);
    }
  });
}

Future<void> menuScroll(Player p) async {
  final s = await p.start();
  await p.openSheet();
  await p.tap(Player.tab('Menu'), within: Player.tabs);
  await p.wait(1200);
  await _flings(p, s);   // warm-up: every dish photo decoded once
  await p.measure('', () => _flings(p, s));
}

/// Up and down through a page of the full view, flinging the way a thumb does.
Future<void> _flings(Player p, Size s, {int times = 4}) async {
  for (var i = 0; i < times; i++) {
    await p.drag(Offset(s.width / 2, s.height * .75), Offset(0, -s.height * .35), ms: 220, fling: true);
    await p.wait(1200);
  }
  for (var i = 0; i < times; i++) {
    await p.drag(Offset(s.width / 2, s.height * .35), Offset(0, s.height * .35), ms: 220, fling: true);
    await p.wait(1200);
  }
}

Future<void> overviewScroll(Player p) async {
  final s = await p.start();
  await p.openSheet();
  Future<void> run() async {
    // The photos first: two swipes to the next ones and two back, then the page itself
    for (final dx in [-.6, -.6, .6, .6]) {
      await p.drag(Offset(s.width * (dx < 0 ? .8 : .2), s.height * .36), Offset(s.width * dx, 0), ms: 200, fling: true);
      await p.wait(900);
    }
    await _flings(p, s, times: 2);
  }

  await run();   // warm-up: every photo decoded once
  await p.measure('', run);
}

Future<void> groupScroll(Player p) async {
  final s = await p.start();
  await p.openSheet();
  await p.tap(Player.tab('Group'), within: Player.tabs);
  await p.wait(1200);
  await _flings(p, s, times: 2);   // warm-up
  await p.measure('', () => _flings(p, s, times: 2));
}

Future<void> dayFilter(Player p) async {
  await p.start();
  Future<void> taps() async {
    for (final d in ['12', '15', 'All', '15', 'All']) {
      await p.tap(Player.day(d));
      await p.wait(1200);
    }
  }

  await taps();   // warm-up: tiles where the camera flies
  await p.wait(2000);
  await p.measure('', taps);
}

/// Starts the app, plays touches, finds widgets and records frames.
class Player {
  Player(this.results);
  final Map<String, dynamic> results;
  String prefix = '';
  var _pointer = 100;
  final _clock = Stopwatch()..start();

  static bool openButton(Widget w) => w is TuButton && w.icon == TuIcons.forward;
  static bool closeButton(Widget w) => w is TuButton && w.label == 'Close';
  static bool tabs(Widget w) => w is SegmentedTabs;
  static bool Function(Widget) tab(String name) => (w) => w is Text && w.data == name;
  static bool Function(Widget) day(String d) => (w) => w is ToggleChip && (d == 'All' ? w.label == 'All' : w.label.endsWith(' $d'));

  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
  Future<void> _frame() => SchedulerBinding.instance.endOfFrame;

  /// A fresh app, as it opens: tiles loaded, the Up next card up.
  Future<Size> start() async {
    runApp(KeyedSubtree(key: UniqueKey(), child: const TripUpApp()));
    await wait(6000);
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    return view.physicalSize / view.devicePixelRatio;
  }

  Future<void> openSheet() async {
    await tap(openButton);
    await wait(1000);
  }

  /// Records every frame drawn while [action] runs, under this scenario's name plus [suffix].
  Future<void> measure(String suffix, Future<void> Function() action) async {
    await wait(2000);   // let earlier frame timings flush
    final timings = <FrameTiming>[];
    void add(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(add);
    await action();
    await wait(2000);   // the engine reports timings in batches
    SchedulerBinding.instance.removeTimingsCallback(add);
    final summary = _summary(timings);
    results['$prefix$suffix'] = summary;
    debugPrint('PERF $prefix$suffix ${jsonEncode({for (final e in summary.entries) if (e.value is! List) e.key: e.value})}');
  }

  void _send(PointerEvent e) => GestureBinding.instance.handlePointerEvent(e);

  /// A one-finger drag, one step per frame; [fling] lets go while moving, otherwise it stops first.
  Future<void> drag(Offset from, Offset by, {int ms = 600, bool fling = false}) async {
    final id = _pointer++, steps = math.max(1, (ms / 16.667).round());
    final step = by / steps.toDouble();
    var at = from;
    _send(PointerDownEvent(pointer: id, position: at, timeStamp: _clock.elapsed));
    await _frame();
    for (var i = 0; i < steps; i++) {
      at += step;
      _send(PointerMoveEvent(pointer: id, position: at, delta: step, timeStamp: _clock.elapsed));
      await _frame();
    }
    if (!fling) await wait(150);
    _send(PointerUpEvent(pointer: id, position: at, timeStamp: _clock.elapsed));
  }

  /// Two fingers moving apart (zoom in) or together (zoom out) around [center].
  Future<void> pinch(Offset center, double fromGap, double toGap, {int ms = 700}) async {
    final a = _pointer++, b = _pointer++, steps = math.max(1, (ms / 16.667).round());
    final step = Offset((toGap - fromGap) / 2 / steps, 0);
    var pa = center - Offset(fromGap / 2, 0), pb = center + Offset(fromGap / 2, 0);
    _send(PointerDownEvent(pointer: a, position: pa, timeStamp: _clock.elapsed));
    _send(PointerDownEvent(pointer: b, position: pb, timeStamp: _clock.elapsed));
    await _frame();
    for (var i = 0; i < steps; i++) {
      pa -= step;
      pb += step;
      _send(PointerMoveEvent(pointer: a, position: pa, delta: -step, timeStamp: _clock.elapsed));
      _send(PointerMoveEvent(pointer: b, position: pb, delta: step, timeStamp: _clock.elapsed));
      await _frame();
    }
    await wait(150);
    _send(PointerUpEvent(pointer: a, position: pa, timeStamp: _clock.elapsed));
    _send(PointerUpEvent(pointer: b, position: pb, timeStamp: _clock.elapsed));
  }

  /// Taps the first widget matching [test] (inside one matching [within], if given) that a touch would reach.
  Future<void> tap(bool Function(Widget) test, {bool Function(Widget)? within}) async {
    final box = _find(test, within);
    if (box == null) throw StateError('$prefix: nothing to tap');
    final at = box.localToGlobal(box.size.center(Offset.zero)), id = _pointer++;
    _send(PointerDownEvent(pointer: id, position: at, timeStamp: _clock.elapsed));
    await _frame();
    await wait(60);
    _send(PointerUpEvent(pointer: id, position: at, timeStamp: _clock.elapsed));
  }

  RenderBox? _find(bool Function(Widget) test, bool Function(Widget)? within) {
    RenderBox? found;
    void visit(Element e, bool inside) {
      if (found != null) return;
      final here = inside || (within?.call(e.widget) ?? true);
      if (here && test(e.widget)) {
        final box = e.findRenderObject();
        if (box is RenderBox && box.attached && box.hasSize && _reachable(box)) {
          found = box;
          return;
        }
      }
      e.visitChildElements((c) => visit(c, here));
    }

    WidgetsBinding.instance.rootElement?.visitChildElements((c) => visit(c, false));
    return found;
  }

  bool _reachable(RenderBox box) {
    final result = HitTestResult();
    final viewId = WidgetsBinding.instance.platformDispatcher.implicitView!.viewId;
    WidgetsBinding.instance.hitTestInView(result, box.localToGlobal(box.size.center(Offset.zero)), viewId);
    return result.path.any((entry) => entry.target == box);
  }
}

/// Per-frame UI and raster times (ms), with how many frames went over one 60 Hz frame.
Map<String, dynamic> _summary(List<FrameTiming> timings) {
  double ms(Duration d) => d.inMicroseconds / 1000;
  double round(double v) => (v * 100).round() / 100;
  final build = [for (final t in timings) ms(t.buildDuration)];
  final raster = [for (final t in timings) ms(t.rasterDuration)];
  const budget = 1000 / 60;
  Map<String, num> stats(List<double> v) {
    final s = [...v]..sort();
    num at(double q) => s.isEmpty ? 0 : round(s[((s.length - 1) * q).round()]);
    return {
      'avg': s.isEmpty ? 0 : round(s.reduce((a, b) => a + b) / s.length),
      'p50': at(.5),
      'p90': at(.9),
      'p99': at(.99),
      'max': at(1),
      'over': s.where((x) => x > budget).length,
    };
  }

  return {
    'frames': timings.length,
    'janky': [for (var i = 0; i < timings.length; i++) if (build[i] > budget || raster[i] > budget) i].length,
    'build': stats(build),
    'raster': stats(raster),
    'build_ms': [for (final b in build) round(b)],
    'raster_ms': [for (final r in raster) round(r)],
  };
}
