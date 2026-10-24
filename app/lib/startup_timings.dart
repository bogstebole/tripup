// How long the app takes to get going, step by step, on whatever phone it runs on: for testers' phones we can't
// reach with adb. Each step is logged ("TripUp startup: …" in logcat) and listed on a hidden panel, with the phone,
// the renderer Flutter picked, and the frames of the launch and of opening the trip: long-press "Your trips" to see
// it (a screenshot of it is the report), tap the panel to close it. Nothing shows in the normal UI.
import 'dart:async';
import 'dart:developer' show Timeline;
import 'dart:io' show Platform;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'design/theme.dart';
import 'design/tokens.dart';

/// One step of the start, [ms] after Dart's main().
typedef StartupStep = ({String name, int ms, String? detail});

abstract final class StartupTimings {
  static final _clock = Stopwatch();
  static const _channel = MethodChannel('tripup/startup');

  /// Whether this phone draws with Skia on Android (before 10), whose GPUs can't afford the app's blurs: see
  /// [lightEffects]. Anywhere else, or if the question fails, no.
  static Future<bool> weakGraphics() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<int>('sdk') ?? 99) < 29;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// From the app's process starting to Dart's main(), from Android (null until it answers, or elsewhere).
  static int? _beforeMain;

  /// The phone: model, Android version, cores, memory, and the renderer Flutter picked.
  static final device = ValueNotifier<List<String>>(const []);
  static final steps = ValueNotifier<List<StartupStep>>(const []);

  /// The panel is up.
  static final shown = ValueNotifier(false);

  /// At the very start of main().
  static void begin() {
    _clock.start();
    _phaseStart('Launch, first 3 s');
    Timer(const Duration(seconds: 3), () => phaseEnd('Launch, first 3 s'));
    // Once main() has set up the bindings: every frame's times, and the phone (Android)
    scheduleMicrotask(() => SchedulerBinding.instance.addTimingsCallback(_frames));
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    scheduleMicrotask(() => _channel.invokeMapMethod<String, Object?>('info').then((info) {
      if (info == null) return;
      _beforeMain = (info['sinceProcessStart'] as int) - _clock.elapsedMilliseconds;
      device.value = ['${info['device']} · Android ${info['android']}', '${info['cores']} cores · ${info['ramMb']} MB RAM · ${info['screen']}'];
      debugPrint('TripUp startup: process start → Dart main ${_beforeMain}ms · ${device.value.join(' · ')}');
      steps.value = [...steps.value];
    }, onError: (Object _) {}));
  }

  /// Spans of time whose frames are summed up on the panel: name → start and end (µs, the frames' clock).
  static final _phases = <String, (int, int?)>{};
  static final _phaseFrames = <String, List<FrameTiming>>{};
  static FrameTiming? _first;

  static void _phaseStart(String name) {
    _phases[name] = (Timeline.now, null);
    _phaseFrames[name] = [];
  }

  /// Frames from now on count toward [name] (shown as frames, late frames, build and raster ms), until [phaseEnd].
  static void phaseStart(String name) {
    _phaseStart(name);
    steps.value = [...steps.value];
  }

  static void phaseEnd(String name) {
    final p = _phases[name];
    if (p == null || p.$2 != null) return;
    _phases[name] = (p.$1, Timeline.now);
    // The engine reports frames in batches: summarise a moment later
    Timer(const Duration(milliseconds: 600), () {
      debugPrint('TripUp startup: frames · $name · ${_frameSummary(name)}');
      steps.value = [...steps.value];
    });
  }

  static void _frames(List<FrameTiming> timings) {
    _first ??= timings.first;
    for (final t in timings) {
      final at = t.timestampInMicroseconds(FramePhase.vsyncStart);
      for (final MapEntry(key: name, value: (from, to)) in _phases.entries) {
        if (at >= from && (to == null || at <= to)) _phaseFrames[name]!.add(t);
      }
    }
  }

  static String _frameSummary(String name) {
    final f = _phaseFrames[name] ?? const [];
    if (f.isEmpty) return 'no frames';
    double ms(Duration d) => d.inMicroseconds / 1000;
    const budget = 1000 / 60;
    final build = [for (final t in f) ms(t.buildDuration)], raster = [for (final t in f) ms(t.rasterDuration)];
    final late = [for (var i = 0; i < f.length; i++) if (build[i] > budget || raster[i] > budget) i].length;
    String stat(List<double> v) => 'avg ${(v.reduce((a, b) => a + b) / v.length).toStringAsFixed(1)} max ${v.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}';
    return '${f.length} frames, $late late · build ${stat(build)} · raster ${stat(raster)} ms';
  }

  static final _stickers = <String>{};

  /// A sticker has its first frame: the last of them so far, and how many.
  static void sticker(String name) {
    if (_stickers.add(name)) mark('Stickers decoded', latest: true, detail: '${_stickers.length} files');
  }

  /// Records [name] now, once; with [latest], each call moves it to now (the last of several, like tiles).
  static void mark(String name, {String? detail, bool latest = false}) {
    final at = _clock.elapsedMilliseconds;
    final i = steps.value.indexWhere((s) => s.name == name);
    if (i >= 0 && !latest) return;
    final step = (name: name, ms: at, detail: detail);
    final list = [...steps.value];
    i >= 0 ? list[i] = step : list.add(step);
    steps.value = list;
    debugPrint('TripUp startup: main +${at}ms $name${detail == null ? '' : ' ($detail)'}');
  }

  /// Opens the panel, asking Android which renderer is running (read from Flutter's own line in the log).
  static Future<void> show() async {
    shown.value = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final renderer = await _channel.invokeMethod<String>('renderer');
      if (renderer != null && !device.value.any((l) => l.startsWith('Renderer'))) device.value = [...device.value, 'Renderer: $renderer'];
    } on PlatformException catch (_) {}
  }

  /// Logs everything so far in one go (also when the panel opens).
  static String report() => [
        ...device.value,
        if (_beforeMain != null) '${_beforeMain}ms  Dart starts',
        for (final s in [...steps.value]..sort((a, b) => a.ms - b.ms)) '${s.ms + (_beforeMain ?? 0)}ms  ${s.name}${s.detail == null ? '' : ' · ${s.detail}'}',
        if (_first case final f?) 'First frame: build ${f.buildDuration.inMilliseconds} ms, raster ${f.rasterDuration.inMilliseconds} ms',
        for (final MapEntry(key: name, value: (_, to)) in _phases.entries)
          if (to != null) '$name: ${_frameSummary(name)}',
      ].join('\n');
}

/// The hidden panel: every step so far, in ms since the app's process started. Tap it to close.
class StartupPanel extends StatelessWidget {
  const StartupPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final pad = MediaQuery.paddingOf(context);
    return ValueListenableBuilder(
      valueListenable: StartupTimings.shown,
      builder: (context, shown, _) => !shown
          ? const SizedBox.shrink()
          : Positioned(
              left: TokSpace.md,
              right: TokSpace.md,
              top: pad.top + TokSpace.xs,
              child: GestureDetector(
                onTap: () => StartupTimings.shown.value = false,
                child: Container(
                  padding: const EdgeInsets.all(TokSpace.md),
                  decoration: BoxDecoration(color: t.bgInverse, borderRadius: BorderRadius.circular(TokRadius.card)),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([StartupTimings.steps, StartupTimings.device]),
                    builder: (context, _) {
                      debugPrint('TripUp startup report:\n${StartupTimings.report()}');
                      return Text(
                        'Startup, ms since the app started\n${StartupTimings.report()}\n\nTap to close',
                        style: TokText.caption.copyWith(color: t.textInverse, fontFeatures: const [FontFeature.tabularFigures()]),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
