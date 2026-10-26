// Frame times for the trip screen's heaviest moments, measured with the real app on the phone in profile mode.
// Android (emulator or phone): flutter run --profile -t perf/trip_perf.dart -d <id>, and read the PERF lines in the log
// (--dart-define=PERF_ONLY=launch,trip_open runs only some). iPhone:
//   flutter build ios --profile -t perf/trip_perf.dart
//   xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app
//   xcrun devicectl device process launch --console --terminate-existing --device <id> com.bogste.tripup
//   xcrun devicectl device copy from --device <id> --domain-type appDataContainer --domain-identifier com.bogste.tripup \
//     --source tmp/perf.json --destination perf.json
// Web: flutter build web --profile -t perf/trip_perf.dart, serve build/web and open it; the PERF lines go to the
// browser console, and the whole run as one `PERF JSON` line at the end (tools/web_perf.mjs does all of it).
// --dart-define=LIGHT_EFFECTS=true runs it without the blurs (see lightEffects), to see what they cost.
// It plays each scenario with synthetic touches at the display's pace, records every frame's UI (build) and raster
// time, prints one summary line per scenario, writes everything to the app's tmp/perf.json and quits.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tripup/components/glass.dart';
import 'package:tripup/components/segmented_tabs.dart';
import 'package:tripup/components/splash.dart';
import 'package:tripup/components/toggle_chips.dart';
import 'package:tripup/design/theme.dart';
import 'package:tripup/main.dart';
import 'package:tripup/screens/trip_screen.dart';

typedef Scenario = Future<void> Function(Player p);

/// The scenarios, in the order they run (the first full-view open also decodes the photos).
final scenarios = <String, Scenario>{
  'launch': launch,
  'trip_open': tripOpen,
  'popup_itinerary': (p) => popup(p, Player.button('Itinerary')),
  'popup_money': (p) => popup(p, Player.money),
  'map_idle': mapIdle,
  'map_pan_zoom': mapPanZoom,
  'sheet_open_close': sheetOpenClose,
  'tabs': tabs,
  'menu_scroll': menuScroll,
  'overview_scroll': overviewScroll,
  'group_scroll': groupScroll,
  'day_filter': dayFilter,
};

/// `--dart-define=PERF_ONLY=launch,trip_open` runs only those.
const _only = String.fromEnvironment('PERF_ONLY');

Future<void> main() => runAll({for (final e in scenarios.entries) if (_only.isEmpty || _only.split(',').contains(e.key)) e.key: e.value});

/// Runs each scenario on a fresh app and reports. [before] runs ahead of each one (for experiments).
Future<void> runAll(Map<String, Scenario> plan, {void Function(String key)? before}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  if (const bool.fromEnvironment('LIGHT_EFFECTS')) lightEffects = true;
  final results = <String, dynamic>{};
  final p = Player(results);
  // No files on the web: the results go to the console instead
  final file = kIsWeb ? null : File('${Directory.systemTemp.path}/perf.json');
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
    await file?.writeAsString(const JsonEncoder.withIndent('  ').convert(results));   // so far, in case the run stops
  }
  if (file == null) {
    debugPrint('PERF JSON ${jsonEncode(results)}');
    debugPrint('PERF DONE');
    return;
  }
  debugPrint('PERF DONE ${file.path}');
  await Future<void>.delayed(const Duration(seconds: 1));
  exit(0);
}

/// From runApp: Your trips' first frames and its entrance, while the map loads behind it.
Future<void> launch(Player p) async {
  await p.measure('', () async {
    await p.start(inTrip: false, settle: 0);
    await p.wait(4000);
  }, settle: 0);
}

/// The trip opening out of its card (the opening, the entrance), and back to Your trips.
Future<void> tripOpen(Player p) async {
  await p.start(inTrip: false);
  Future<void> cycle() async {
    await p.tap(Player.tripCard);
    await p.wait(2500);
    await p.tap(Player.button('Back to trips'));
    await p.wait(1500);
  }

  await p.measure('_first', cycle);
  await p.measure('', () async {
    for (var i = 0; i < 2; i++) {
      await cycle();
    }
  });
}

/// A footer pop-up rising over the blurred map and closing, three times.
Future<void> popup(Player p, bool Function(Widget) button) async {
  await p.start();
  Future<void> cycle() async {
    await p.tap(button);
    await p.wait(1200);
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

/// Nothing touched: whatever keeps animating on its own (my location breathing) still draws frames.
Future<void> mapIdle(Player p) async {
  await p.start();
  await p.measure('', () => p.wait(5000));
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

  /// From the app's own coordinates to the window's: the same, unless the app sits in a frame (the web build on a
  /// wide window, see WebPhoneFrame), where drags have to land inside it.
  Offset Function(Offset) _toWindow = (o) => o;

  static bool openButton(Widget w) => w is TuButton && w.icon == TuIcons.forward;
  static bool tripCard(Widget w) => w is TuButton && w.label.startsWith('Open ');
  static bool money(Widget w) => w.runtimeType.toString() == '_CrewButton';
  static bool Function(Widget) button(String label) => (w) => w is TuButton && w.label == label;
  static bool closeButton(Widget w) => w is TuButton && w.label == 'Close';
  static bool tabs(Widget w) => w is SegmentedTabs;
  static bool Function(Widget) tab(String name) => (w) => w is Text && w.data == name;
  static bool Function(Widget) day(String d) => (w) => w is ToggleChip && (d == 'All' ? w.label == 'All' : w.label.endsWith(' $d'));

  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
  Future<void> _frame() => SchedulerBinding.instance.endOfFrame;

  /// A fresh app, as it opens on Your trips; then (unless not [inTrip]) into the trip: tiles loaded, the Up next card up.
  Future<Size> start({bool inTrip = true, int settle = 6000}) async {
    splashOnStart = false;   // straight to Your trips: the timings and taps start there
    runApp(KeyedSubtree(key: UniqueKey(), child: const TripUpApp()));
    await wait(settle);
    if (inTrip) {
      await tap(tripCard);
      await wait(2500);
    }
    final screen = _find((w) => w is TripScreen, null);
    if (screen != null) {
      _toWindow = screen.localToGlobal;
      return screen.size;
    }
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    return view.physicalSize / view.devicePixelRatio;
  }

  Future<void> openSheet() async {
    await tap(openButton);
    await wait(1000);
  }

  /// Records every frame drawn while [action] runs, under this scenario's name plus [suffix].
  Future<void> measure(String suffix, Future<void> Function() action, {int settle = 2000}) async {
    await wait(settle);   // let earlier frame timings flush
    final timings = <FrameTiming>[];
    void add(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(add);
    if (kIsWeb) debugPrint('PERF MARK start $prefix$suffix');   // the browser times its own frames between the marks
    await action();
    if (kIsWeb) debugPrint('PERF MARK end $prefix$suffix');
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
    var at = from, was = _toWindow(from);
    _send(PointerDownEvent(pointer: id, position: was, timeStamp: _clock.elapsed));
    await _frame();
    for (var i = 0; i < steps; i++) {
      at += step;
      final now = _toWindow(at);
      _send(PointerMoveEvent(pointer: id, position: now, delta: now - was, timeStamp: _clock.elapsed));
      was = now;
      await _frame();
    }
    if (!fling) await wait(150);
    _send(PointerUpEvent(pointer: id, position: was, timeStamp: _clock.elapsed));
  }

  /// Two fingers moving apart (zoom in) or together (zoom out) around [center].
  Future<void> pinch(Offset center, double fromGap, double toGap, {int ms = 700}) async {
    final a = _pointer++, b = _pointer++, steps = math.max(1, (ms / 16.667).round());
    final step = Offset((toGap - fromGap) / 2 / steps, 0);
    var pa = center - Offset(fromGap / 2, 0), pb = center + Offset(fromGap / 2, 0);
    var wa = _toWindow(pa), wb = _toWindow(pb);
    _send(PointerDownEvent(pointer: a, position: wa, timeStamp: _clock.elapsed));
    _send(PointerDownEvent(pointer: b, position: wb, timeStamp: _clock.elapsed));
    await _frame();
    for (var i = 0; i < steps; i++) {
      pa -= step;
      pb += step;
      final na = _toWindow(pa), nb = _toWindow(pb);
      _send(PointerMoveEvent(pointer: a, position: na, delta: na - wa, timeStamp: _clock.elapsed));
      _send(PointerMoveEvent(pointer: b, position: nb, delta: nb - wb, timeStamp: _clock.elapsed));
      wa = na;
      wb = nb;
      await _frame();
    }
    await wait(150);
    _send(PointerUpEvent(pointer: a, position: wa, timeStamp: _clock.elapsed));
    _send(PointerUpEvent(pointer: b, position: wb, timeStamp: _clock.elapsed));
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
