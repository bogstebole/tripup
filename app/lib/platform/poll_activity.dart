// The dinner poll outside the app, on iOS: a Live Activity (lock screen and Dynamic Island) and a notification with a
// button per place; both vote without opening the app. The native side is ios/Runner/PollBridge.swift and the
// ios/PollWidget extension. Elsewhere this does nothing.
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data.dart';

abstract final class PollActivity {
  static const _channel = MethodChannel('tripup/poll');
  static bool get _on => !kIsWeb && Platform.isIOS;

  /// Whether the activity is up (the poll opened while the app was running).
  static bool _started = false;
  static String? _last;

  /// Votes from the activity or the notification come in as my vote; one cast while the app wasn't running waits
  /// for it here.
  static Future<void> listen() async {
    if (!_on) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'voted' && call.arguments is String) myVote.value = (option: call.arguments as String, at: tripNow());
    });
    // An activity left from an earlier run belongs to a poll this demo hasn't reached yet
    await _channel.invokeMethod('clear');
    final pending = await _channel.invokeMethod<String>('takeVote');
    if (pending != null) myVote.value = (option: pending, at: tripNow());
  }

  /// The poll as the activity shows it. Its countdown runs on real time, so the demo's close time is turned into
  /// the moment it will be on this phone.
  static Map<String, Object?> _state(DateTime now) => {
        'votes': {for (final o in pollOptions) o.id: votersOf(o.id, now).length},
        'mine': myVote.value?.option,
        'voted': votesIn(now),
        'table': dinnerTable.length,
        'closesAt': DateTime.now().add(pollClosedAt(now).difference(now)).millisecondsSinceEpoch.toDouble(),
        'winner': pollClosed(now) && !pollUndone.value ? pollLeader(now) : null,
      };

  /// Keeps the activity in step with the poll: starts it as the poll opens (with the notification, when [fresh]),
  /// updates it as votes come in, and ends it once the poll has closed. Returns whether the notification went out.
  static Future<bool> sync(DateTime now, {bool fresh = false}) async {
    if (!_on) return false;
    final state = _state(now);
    final key = state.toString();
    try {
      if (pollOpen(now) && !_started) {
        _started = true;
        _last = key;
        return await _channel.invokeMethod<bool>('start', {
              'question': 'Where for dinner tonight?',
              'askedBy': personById(pollAskedBy).name,
              'places': [for (final o in pollOptions) {'id': o.id, 'name': o.name, 'short': o.short, 'sticker': o.sticker}],
              'state': state,
              'notify': fresh,
            }) ??
            false;
      }
      if (!_started || key == _last) return false;
      _last = key;
      if (pollOpen(now)) {
        await _channel.invokeMethod('update', {'state': state});
      } else {
        _started = false;
        await _channel.invokeMethod('end', {'state': state});
      }
    } on PlatformException catch (e) {
      debugPrint('Poll activity: ${e.message}');
    }
    return false;
  }
}
