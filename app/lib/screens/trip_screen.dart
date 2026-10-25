import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../components/bars.dart';
import '../components/bill_scan.dart';
import '../components/basics.dart';
import '../components/toggle_chips.dart';
import '../components/detail_sheet.dart';
import '../components/entrance.dart';
import '../components/home.dart';
import '../components/join.dart';
import '../components/map_shapes.dart';
import '../components/map_tiles.dart';
import '../components/people_layer.dart';
import '../components/splash.dart';
import '../components/plan_pin.dart';
import '../components/poll.dart';
import '../components/stagger.dart';
import '../components/toast.dart';
import '../components/trip_pages.dart';
import '../components/trip_sheet.dart';
import '../data.dart';
import '../platform/poll_activity.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../startup_timings.dart';

/// The trip: the map with past places and planned pins, the Up next card, and its full view.
class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with TickerProviderStateMixin {
  final _map = MapController();
  final _cardKey = GlobalKey();
  late final _open = AnimationController.unbounded(vsync: this);   // 0 = card on the map, 1 = full view
  late final _drag = AnimationController.unbounded(vsync: this);   // how far the full view is pulled down
  late final _pop = AnimationController.unbounded(vsync: this);   // 0 = closed, 1 = a footer pop-up open
  late final _popDrag = AnimationController.unbounded(vsync: this);   // how far it is pulled down

  /// Which footer pop-up is up (or closing), if any.
  _Popup? _popup;
  bool _popClosing = false;
  final _todayKey = GlobalKey();

  /// The camera is up, scanning the dinner's bill.
  bool _scanning = false;

  /// Your trips and the trip's map: 1 is the list, 0 is in the trip, a spring between. Going in, the trip card opens
  /// into the map: the whole trip screen grows out of the card's place, from a small copy of itself to the real one,
  /// while the list behind fades and leans in. Back closes it into the card again.
  late final _home = AnimationController.unbounded(vsync: this, value: 1);
  final _homeKey = GlobalKey(), _homeCardKey = GlobalKey();

  /// The splash on a cold start (none with reduced motion).
  bool _splash = splashOnStart && !ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

  /// Where the trip card is on the screen, taken as a transition starts.
  Rect? _homeCard;

  /// Resting on the list (the map under it needn't be drawn), or in the trip (the list needn't be).
  bool get _onHome => !_home.isAnimating && _home.value > 0.5;
  bool get _inTrip => !_home.isAnimating && _home.value <= 0.5;

  /// Ren's phone, from the invite link: the 'Ren joins' moment.
  bool _joining = false;

  /// Run once the full view has finished closing (Settle up goes on to Money).
  VoidCallback? _afterSheet;

  /// The note at the top of the map, and whether it's showing.
  String? _notice;
  ({String label, VoidCallback onTap})? _noticeAction;
  bool _noticeShown = false;

  /// The poll on the map opened up (over a tinted map), or closed to its compact card.
  bool _pollExpanded = false;

  /// The poll as last seen (0 not open yet, 1 open, 2 closed) and its vote count, to notice when either changes.
  int _pollPhase = -1, _pollVotes = -1;
  Timer? _noticeTimer, _payTick;
  bool _wasSquare = false;

  /// Whether the full view or a pop-up covers the map.
  bool get _covered => _sheet || _popup != null;
  late final _fly = AnimationController(vsync: this);
  Timer? _tick;
  bool _upNextMid = false;   // the app opens on your trips; Up next opens last as you go in

  /// Up next has opened by itself once since the app started: the first time into the trip. After that only a tap on
  /// its pin opens it (or news about it: the poll's winner, a dinner picked by hand, a moment of the demo).
  bool _upNextShown = false;

  /// The trip's entrance clock (see [EnterOrder]): 0 at the tap, 1 once every control is in. At rest it's 1.
  late final _enter = AnimationController(vsync: this, duration: EnterOrder.total, value: 1);

  /// Up next (or the poll) has had its turn in the entrance.
  bool _upNextIn = false;
  bool _meOff = false;
  bool _sheet = false;
  Rect? _from;

  /// What's behind the full view, as last drawn, shown instead of drawing (and blurring) it again every frame while
  /// none of it moves: [_under] is the map and the bars, from the first frame of opening (if the map is at rest);
  /// [_still] adds the backdrop's blur, once the full view rests open.
  final _under = _Held(), _still = _Held();

  /// Time since the map last moved.
  final _mapQuiet = Stopwatch()..start();

  /// Fingers on the screen, and a wait for them (and any animation) to finish before re-picturing the scene.
  int _touches = 0;
  Timer? _rescene;

  /// Days picked in the filter; empty means All.
  Set<int> _days = {today};   // the trip opens on today: that's where the focus is

  /// Days picked in the itinerary's own filter (it opens on all of them).
  Set<int> _planDays = const {};

  /// Where Add to the trip is: its choice, Plan something or Invite someone (it opens on the choice).
  AddStep _addStep = AddStep.choose;

  /// The plan being made in Add: shared by its page, its footer (Send) and its Back (a different place).
  final _draft = PlanDraft();
  bool _shows(int day) => _days.isEmpty || _days.contains(day);

  /// Whoever has already got to the Up next place.
  List<String> get _here => [for (final p in people) if (p.id != myId && isHere(p, tripNow())) p.sticker];

  Plan get _upNext => tripPlans.first;

  /// A plan opened from the itinerary, whose details show in the full view instead of Up next's.
  Plan? _sheetPlan;
  Plan get _detailPlan => _sheetPlan ?? _upNext;

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    homeCardStickersShown.value = !_splash;
    // The map's style and tiles load right after the first frame (Your trips), not before it; draw it once they're ready
    SchedulerBinding.instance.addPostFrameCallback((_) => MapTiles.start());
    MapTiles.source.addListener(_sceneChanged);
    _map.mapEventStream.listen(_onMapEvent);
    // On the next minute, then every minute, so "In 64 mins" counts down
    _tick = Timer(Duration(seconds: 60 - tripNow().second), () {
      if (!mounted) return;
      _sceneChanged();
      _tick = Timer.periodic(const Duration(minutes: 1), (_) => _sceneChanged());
    });
    // A plan added from the Add pop-up shows on the map (which is a picture while the pop-up is up)
    addedPlans.addListener(_sceneChanged);
    demoMoment.addListener(_sceneChanged);
    // The money pop-up estimates tonight's dinner from the menu's picks, so load it now
    brasserieMenu.then((_) => _sceneChanged());
    _home.addStatusListener((_) {
      // Back on your trips: Up next waits, small, for the next way in (it jumps there unseen; the trip isn't ticking)
      if (!_home.isAnimating && _home.value > 0.5) {
        _upNextMid = false;
        _upNextIn = false;
      }
      if (_inTrip) StartupTimings.mark('Trip opened (map full screen)');
      setState(() {});
    });
    _enter.addStatusListener((status) {
      if (status == AnimationStatus.completed) StartupTimings.phaseEnd('Opening the trip');
    });
    // The last control has started: Up next opens now, the end of the entrance
    _enter.addListener(() {
      if (!_upNextIn && _enter.value * EnterOrder.total.inMicroseconds >= EnterOrder.last.inMicroseconds) {
        setState(() {
          _upNextIn = true;
          _upNextMid = !_upNextShown;
          _upNextShown = true;
        });
      }
    });
    _pop.addListener(() {
      if (_popup != null && _popClosing && _pop.value <= 0.002) {
        _pop.stop();
        _release(_under);
        setState(() {
          _popup = null;
          _popClosing = false;
        });
      }
    });
    _open.addListener(() {
      // Hand back to the pin's card as soon as the overlay is within a pixel of it; the spring's
      // last sub-pixel crawl would otherwise leave the real card hidden for no visible reason
      if (_sheet && _closing && _open.value <= 0.002) {
        _open.stop();
        _release(_under);
        setState(() {
          _sheet = _closing = false;
          _sheetPlan = null;
        });
        final then = _afterSheet;
        _afterSheet = null;
        then?.call();
      }
    });
    tripNotice.addListener(_showNotice);
    // Votes cast from the lock screen or the notification come back as my vote; mine goes out to them
    PollActivity.listen(onOpen: _showPoll);
    myVote.addListener(_pollOutside);
    pollUndone.addListener(_pollOutside);
    madePayments.addListener(_paymentsChanged);
    // The others' payments come in on their own, a little apart (see addBill)
    _payTick = Timer.periodic(const Duration(seconds: 1), (_) {
      for (final p in takeDuePayments(tripNow())) {
        tripNotice.value = payLine(p);
      }
      _pollTick();
    });
    myVote.addListener(_pollTick);
    pollUndone.addListener(_dinnerChanged);
    pickedDinner.addListener(_dinnerChanged);
  }

  /// The poll on the demo clock: everyone hears when it opens and when it closes (the winner going into tonight,
  /// with Undo), and the card follows the votes as they come in.
  void _pollTick() {
    if (!mounted) return;
    final now = tripNow();
    final phase = pollClosed(now) ? 2 : pollOpen(now) ? 1 : 0, votes = votesIn(now);
    if (phase == _pollPhase && votes == _pollVotes) return;
    final was = _pollPhase;
    if (phase != was) _pollExpanded = false;   // a poll that opens shows as its compact card
    _pollPhase = phase;
    _pollVotes = votes;
    // Only a change that just happened is news (not one the demo jumped over)
    bool fresh(DateTime at) => now.difference(at) < const Duration(minutes: 2);
    final opened = was != -1 && phase == 1 && was == 0 && fresh(pollOpens);
    // Outside the app too (iOS): the Live Activity follows the poll, and a poll that has just opened sends the
    // notification with its vote buttons, which then stands in for the note at the top
    PollActivity.sync(now, fresh: opened).then((posted) {
      if (opened && !posted && mounted) tripNotice.value = '${personById(pollAskedBy).name} started a poll: where for dinner tonight?';
    });
    if (was != -1 && phase == 2 && was != 2 && fresh(pollClosedAt(now)) && !pollUndone.value) {
      final winner = pollOptionById(pollLeader(now)!);
      noticeAction = (label: 'Undo', onTap: _undoWinner);
      tripNotice.value = '${winner.short} won · added to tonight';
      _upNextMid = true;
    }
    _sceneChanged();
  }

  void _pollOutside() => PollActivity.sync(tripNow());

  /// From the notification or the Live Activity: the poll, open. Whatever was up gives way; from your trips the trip
  /// opens first, and the poll opens once its entrance is done (it's the last thing in). A poll that has closed shows
  /// its result in the poll's pop-up instead.
  void _showPoll() {
    if (!mounted) return;
    if (_joining) setState(() => _joining = false);
    final covered = _covered;
    if (_sheet) _closeSheet();
    if (_popup != null) _closePopup();
    // Wait for the trip's entrance, or for what covered the map to leave
    final wait = !_inTrip
        ? EnterOrder.total
        : covered
            ? Duration(milliseconds: (TokMotion.springCollapse.duration * 1000).round())
            : Duration.zero;
    _goIn();
    Future.delayed(wait, () {
      if (!mounted) return;
      if (pollOpen(tripNow())) {
        setState(() => _pollExpanded = true);
      } else {
        _openPopup(_Popup.poll);
      }
    });
  }

  void _expandPoll(bool open) {
    HapticFeedback.selectionClick();
    setState(() => _pollExpanded = open);
  }

  /// Tonight's place changed by hand (Undo, or picked in the poll): the map and the Up next card follow at once.
  void _dinnerChanged() {
    if (!mounted) return;
    setState(() => _upNextMid = true);
    _sceneChanged();
  }

  /// Takes the poll's winner back out of tonight; the poll then lets anyone pick by hand.
  void _undoWinner() {
    pollUndone.value = true;
    _openPopup(_Popup.poll);
  }

  /// Does what the note offers (Undo), and puts the note away.
  void _actOnNotice(({String label, VoidCallback onTap}) action) {
    _noticeTimer?.cancel();
    setState(() => _noticeShown = false);
    tripNotice.value = null;
    action.onTap();
  }

  void _showNotice() {
    final text = tripNotice.value;
    if (text == null || !mounted) return;
    HapticFeedback.lightImpact();
    final action = noticeAction;
    noticeAction = null;
    setState(() {
      _notice = text;
      _noticeAction = action;
      _noticeShown = true;
    });
    _noticeTimer?.cancel();
    // A note you can act on (Undo) stays twice as long, so there's time to reach it
    _noticeTimer = Timer(action != null ? TokMotion.toastAction : TokMotion.toast, () {
      if (mounted) setState(() => _noticeShown = false);
      tripNotice.value = null;
    });
  }

  /// When the last payment lands, everyone hears the trip is squared up.
  void _paymentsChanged() {
    final square = squaredUp;
    if (square && !_wasSquare) {
      Timer(TokMotion.toast ~/ 2, () => tripNotice.value = 'Lisbon is squared up · everyone has paid');
    }
    _wasSquare = square;
    _sceneChanged();
  }

  void _scan() => setState(() => _scanning = true);

  /// From the full view's Group: close it, then show who owes what.
  void _settleUp() {
    _afterSheet = () => _openPopup(_Popup.money);
    _closeSheet();
  }

  void _onMapEvent(MapEvent e) {
    if (e is MapEventWithMove) {
      _mapQuiet.reset();
      if (_under.image != null) _sceneChanged(now: true);   // never expected while the full view is up, but stay true to the map
    }
    // The card steps back to a mini pin as soon as the person moves the map
    final byUser = e.source != MapEventSource.mapController && e.source != MapEventSource.nonRotatedSizeChange;
    if (byUser && _upNextMid && (e is MapEventMoveStart || e is MapEventDoubleTapZoomStart || e is MapEventScrollWheelZoom || e is MapEventFlingAnimationStart)) {
      setState(() => _upNextMid = false);
    }
    final off = !_area(MediaQuery.sizeOf(context)).contains(e.camera.latLngToScreenOffset(myPosition(tripNow())));
    if (off != _meOff) setState(() => _meOff = off);
    // The actions step out of the way while the person moves the map, and come back once it has been still a moment
    // (a short pause between two drags shouldn't bring them back). Only when the map really moves: a tap is a user's
    // event too, and shouldn't send them away
    if (byUser && e is MapEventWithMove) {
      if (!_moving) setState(() => _moving = true);
      _settle?.cancel();
      _settle = Timer(TokMotion.settle, () {
        if (mounted) setState(() => _moving = false);
      });
    }
  }

  /// Whether the person is moving the map (the actions slide down meanwhile).
  bool _moving = false;
  Timer? _settle;

  /// Where pins may sit: the map minus the top bar and the action bar.
  Rect _safe(Size size) {
    final pad = MediaQuery.paddingOf(context);
    return nonInverted(Rect.fromLTRB(
      TokDim.widgetEdgeInset,
      pad.top + TopBar.contentHeightWithFilter + TokDim.widgetEdgeInset,
      size.width - TokDim.widgetEdgeInset,
      size.height - ActionBar.rowInset(context) - TokDim.buttonLg - TokDim.widgetEdgeInset,
    ));
  }

  /// Where pins sit: [_safe], but reaching down to the bottom buttons' row, beside the buttons and never on them.
  PinArea _area(Size size) {
    final safe = _safe(size);
    final row = size.height - ActionBar.rowInset(context);
    final dock = Rect.fromLTRB((size.width - ActionBar.width) / 2, row - TokDim.buttonLg, (size.width + ActionBar.width) / 2, row).inflate(TokDim.widgetEdgeInset);
    return PinArea(nonInverted(Rect.fromLTRB(safe.left, safe.top, safe.right, row)), dock: dock);
  }

  /// Moves the map so [target] lands on [screenPoint] (default: the middle), on the snap spring.
  void _flyTo(LatLng target, {Offset? screenPoint}) {
    final cam = _map.camera;
    final want = screenPoint ?? cam.nonRotatedSize.center(Offset.zero);
    final shift = cam.latLngToScreenOffset(target) - want;
    final from = cam.center;
    final to = cam.screenOffsetToLatLng(cam.nonRotatedSize.center(Offset.zero) + shift);
    if (_reduce) {
      _map.move(to, cam.zoom);
      return;
    }
    _fly
      ..stop()
      ..value = 0;
    void step() {
      final t = _fly.value;
      _map.move(LatLng(from.latitude + (to.latitude - from.latitude) * t, from.longitude + (to.longitude - from.longitude) * t), cam.zoom);
    }
    _fly.addListener(step);
    _fly.animateWith(SpringSimulation(springOf(TokMotion.springSnap), 0, 1, 0)).whenCompleteOrCancel(() => _fly.removeListener(step));
  }

  /// Moves and zooms the map to [center] and [zoom], on the snap spring.
  void _flyCamera(LatLng center, double zoom) {
    final from = _map.camera;
    if (_reduce) {
      _map.move(center, zoom);
      return;
    }
    _fly
      ..stop()
      ..value = 0;
    void step() {
      final t = _fly.value;
      _map.move(
        LatLng(from.center.latitude + (center.latitude - from.center.latitude) * t, from.center.longitude + (center.longitude - from.center.longitude) * t),
        from.zoom + (zoom - from.zoom) * t,
      );
    }
    _fly.addListener(step);
    _fly.animateWith(SpringSimulation(springOf(TokMotion.springSnap), 0, 1, 0)).whenCompleteOrCancel(() => _fly.removeListener(step));
  }

  /// The filter changed: other days' pins and places fade out, and the map frames what's left. All brings back the
  /// opening view. The Up next card doesn't open for it (it steps back if its day is filtered out).
  void _setDays(Set<int> days, Size size) {
    setState(() {
      _days = days;
      _upNextMid = _upNextMid && (days.isEmpty || days.contains(_upNext.day));
    });
    if (days.isEmpty) {
      _flyCamera(startCenter, startZoom);
      return;
    }
    final points = [for (final p in tripPlans) if (days.contains(p.day)) p.at, for (final v in visited) if (days.contains(v.day)) v.at];
    if (points.isEmpty) return;
    final safe = _safe(size);
    const half = TokDim.widgetMiniWidth / 2;
    final fit = CameraFit.coordinates(
      coordinates: points,
      padding: EdgeInsets.fromLTRB(safe.left + half, safe.top + PlanPin.miniReach, size.width - safe.right + half, size.height - safe.bottom + TokDim.stickerMap / 2),
      maxZoom: startZoom,
    ).fit(_map.camera);
    _flyCamera(fit.center, fit.zoom);
  }

  /// "Tue 12": the weekday and the day of the month.
  static String _dayLabel(int day) => '${weekdayShort(DateTime(tripYear, tripMonth, day))} $day';

  void _tapPlan(Plan p, Size size) {
    if (p.id == _upNext.id) {
      // Make room above the place for the card, then let it grow
      final at = _map.camera.latLngToScreenOffset(p.at);
      final safe = _safe(size);
      final roomNeeded = safe.top + _upNextHeight;
      if (at.dy < roomNeeded || !safe.contains(at)) _flyTo(p.at, screenPoint: Offset(size.width / 2, roomNeeded));
      setState(() => _upNextMid = true);
    } else {
      _flyTo(p.at);
    }
  }

  bool _closing = false;

  /// The Up next card's height with its tail, reported by the pin once it has measured itself.
  double _upNextHeight = 0;

  /// Opens one of the footer's pop-ups: it rises from the bottom, where its button is, over the blurred map.
  void _openPopup(_Popup which) {
    if (_covered) return;
    _popDrag.value = 0;
    _popClosing = false;
    setState(() {
      _popup = which;
      _planDays = const {};
      _addStep = AddStep.choose;
    });
    _draft.reset();
    _holdUnder();
    if (_reduce) {
      _pop.value = 1;
      _holdStill();
    } else {
      springTo(_pop, 1, TokMotion.springExpand).whenCompleteOrCancel(_holdStill);
    }
  }

  /// The demo jumps to [m]: the clock moves there, the Up next card comes back, and the moment's pop-up (if it has
  /// one) takes the place of the moment list; otherwise the list closes.
  void _jump(StoryMoment m) {
    HapticFeedback.selectionClick();
    jumpTo(m);
    setState(() {
      // From your trips, Up next waits for its turn in the entrance
      if (!_onHome) _upNextMid = true;
      _pollExpanded = false;
      _joining = m.opens == 'join';
    });
    if (m.opens == 'money') {
      setState(() => _popup = _Popup.money);
    } else {
      _closePopup();
    }
    if (m.opens == 'home') {
      _goHome();
    } else if (m.opens != 'join') {
      _goIn();
    }
  }

  /// Into the trip's map, from the list: the surface grows out of the card (see [_openingTrip]) while the clock of
  /// the trip's entrance runs: its controls arrive one by one, and Up next opens last. All of it within a second.
  void _goIn() {
    if (_inTrip || _home.isAnimating && _home.velocity < 0) return;
    HapticFeedback.selectionClick();
    _homeCard = _cardRect();
    if (_reduce) {
      _openOnToday();
      setState(() {
        _upNextIn = true;
        _upNextMid = !_upNextShown;
        _upNextShown = true;
      });
      _enter.value = 1;
      _home.animateTo(0, duration: TokMotion.fade);
      return;
    }
    // Up next is small for the start (one frame here, unseen, so it doesn't shrink on screen), then it all begins.
    // The trip opens on today, where it started, whatever day was picked last time
    _openOnToday();
    setState(() {
      _upNextMid = false;
      _upNextIn = false;
    });
    _enter.value = 0;
    StartupTimings.mark('Trip card tapped');
    StartupTimings.phaseStart('Opening the trip');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      springTo(_home, 0, TokMotion.springOpen);
      _enter.forward(from: 0);
      setState(() {});
    });
  }

  /// Today picked in the day filter, and the map where it starts (it's out of sight: this is before the trip opens).
  void _openOnToday() {
    _days = {today};
    _map.move(startCenter, startZoom);
  }

  /// Back to your trips.
  void _goHome() {
    if (_onHome) return;
    _homeCard = _cardRect();
    _reduce ? _home.animateTo(1, duration: TokMotion.fade) : springTo(_home, 1, TokMotion.springCollapse);
    setState(() {});
  }

  /// The trip card's place on the screen, as laid out (without the list's lean).
  Rect? _cardRect() {
    final card = _homeCardKey.currentContext?.findRenderObject(), home = _homeKey.currentContext?.findRenderObject();
    if (card is! RenderBox || home is! RenderBox || !card.hasSize) return null;
    return card.localToGlobal(Offset.zero, ancestor: home) & card.size;
  }

  /// Off Ren's phone: after joining, back on Ari's map, where everyone hears he's in.
  void _closeJoin({bool joined = false}) {
    setState(() => _joining = false);
    if (!joined) return;
    setState(() {
      _home.value = 0;
      _enter.value = 1;
      _upNextIn = true;
      _upNextMid = true;
    });
    tripNotice.value = '${personById('ren').name} joined the trip';
  }

  /// A small still map of [at] for Plan something, with the place's sticker on it and the map's credit.
  Widget _mapOf(LatLng at, String sticker) {
    final t = context.tok;
    return IgnorePointer(
      child: Stack(children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(initialCenter: at, initialZoom: 15.5, backgroundColor: t.bgCanvas, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
            children: [
              if (MapTiles.source.value case final source?) TripTileLayer(source: source),
              MarkerLayer(markers: [
                Marker(point: at, width: TokDim.stickerMap * 2, height: TokDim.stickerMap, child: Center(child: Sticker(sticker, size: StickerSize.map))),
              ]),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: TokSpace.x2xs,
          child: Text('© OpenFreeMap © OpenMapTiles © OpenStreetMap', textAlign: TextAlign.center, style: TokText.caption.copyWith(color: t.cAttributionFg)),
        ),
      ]),
    );
  }

  /// Your trips, behind the opening trip (which blurs and washes them out). They don't move.
  Widget _homeLayer(BuildContext context) => AnimatedBuilder(
        animation: _home,
        builder: (context, child) => IgnorePointer(ignoring: _home.isAnimating, child: child),
        child: TripsHome(key: _homeKey, onOpen: _goIn, cardKey: _homeCardKey),
      );

  /// The trip opening out of its card, the way Airbnb opens a listing (Bogdan's reference, 24 Oct): the list behind
  /// blurs and washes out, and one rounded surface grows from the card to the whole screen. It starts as the card (the
  /// city's still growing with it, the card's words leaving at once); near full size the live map and its bars fade in
  /// over the still, slightly blurred while the two overlap; the corners square up last. Closing runs it back into the
  /// card, quicker. With reduced motion it only fades.
  ///
  /// The widgets around the trip stay the same at rest and in motion (only their values change): a different wrapper
  /// on landing would build the map and its pins anew, and the Up next card would play its entrance a second time.
  Widget _openingTrip(BuildContext context, Size size, Widget trip) => AnimatedBuilder(
        animation: _home,
        child: trip,
        builder: (context, child) {
          final t = context.tok;
          final p = (1 - _home.value).clamp(0.0, 1.0);   // 0 on the list, 1 in the trip
          final moving = !_inTrip && !_reduce;
          final screen = Offset.zero & size, card = _homeCard ?? screen;
          final rect = moving ? Rect.lerp(card, screen, p)! : screen;
          final radius = BorderRadius.circular(moving ? TokDim.surfaceRadius * (1 - smoothstep(0.7, 1, p)) : 0);
          final scale = rect.width / size.width;
          // What shows when: the card's words leave first, the live trip arrives near full size
          final words = moving ? 1 - smoothstep(0, 0.25, p) : 0.0;
          final live = _inTrip ? 1.0 : _reduce ? p : smoothstep(0.45, 0.85, p);
          final seam = moving && !lightEffects ? TokMotion.crossfadeBlur * 4 * live * (1 - live) : 0.0;
          final behind = _inTrip ? 0.0 : smoothstep(0, 0.6, p);
          return Stack(children: [
            // The list behind blurs and washes out
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  enabled: behind > 0.01 && !lightEffects,
                  filter: ui.ImageFilter.blur(sigmaX: TokDim.tripOpenBlur * behind, sigmaY: TokDim.tripOpenBlur * behind),
                  child: ColoredBox(color: t.cTripOpenWash.withValues(alpha: t.cTripOpenWash.a * behind)),
                ),
              ),
            ),
            // The surface's lift, while it's a card in the air
            Positioned.fromRect(
              rect: rect,
              child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: radius, boxShadow: moving ? TokShadow.elevationOverlay : const []))),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_inTrip,
                child: ClipRRect(
                  clipper: _RRectClip(radius.toRRect(rect)),
                  clipBehavior: moving ? Clip.antiAlias : Clip.none,
                  child: Stack(children: [
                    // The card's still, growing with the surface
                    Positioned.fromRect(rect: rect, child: Opacity(opacity: moving ? 1 : 0, child: const TripCardStill())),
                    // The card's words, at the card's size, leaving
                    Positioned.fromRect(
                      rect: rect,
                      child: Opacity(
                        opacity: words,
                        child: OverflowBox(
                          alignment: Alignment.bottomLeft,
                          minWidth: card.width,
                          maxWidth: card.width,
                          minHeight: card.height,
                          maxHeight: card.height,
                          child: const TripCardFace(),
                        ),
                      ),
                    ),
                    // The live trip, at its own size, scaled to the surface
                    Positioned.fill(
                      child: Opacity(
                        opacity: live,
                        child: ImageFiltered(
                          enabled: seam >= 0.05,
                          imageFilter: ui.ImageFilter.blur(sigmaX: seam, sigmaY: seam),
                          child: Transform(
                            transform: Matrix4.translationValues(rect.center.dx - size.width / 2 * scale, rect.center.dy - size.height / 2 * scale, 0)
                              ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]);
        },
      );

  void _closePopup({double velocity = 0}) {
    _popClosing = true;
    _release(_still);
    if (_reduce) {
      _pop.value = 0;
      _release(_under);
      setState(() {
        _popup = null;
        _popClosing = false;
      });
      return;
    }
    springTo(_pop, 0, TokMotion.springCollapse, velocity: velocity);
  }

  /// The open pop-up, in the full view's place, sliding up from below the screen (with reduced motion, fading in).
  Widget _popupSheet(BuildContext context, Size size, EdgeInsets pad) {
    final bottom = size.height - math.max(pad.bottom, TokDim.sheetInset), full = pad.top + TokSpace.xs + TokDim.buttonMd + TokSpace.x3xs;
    // Add's choice and its invite are short, so the sheet is too; planning takes the whole height
    final compact = _popup == _Popup.add && _addStep != AddStep.plan;
    final to = Rect.fromLTRB(TokDim.sheetInset, compact ? math.max(full, bottom - TokDim.sheetCompactHeight) : full, size.width - TokDim.sheetInset, bottom);
    void dragEnd(DragEndDetails d) {
      final vy = d.velocity.pixelsPerSecond.dy;
      if (_popDrag.value > TokSpace.x5xl * 2 || vy > 900) {
        HapticFeedback.lightImpact();   // the pull commits
        _closePopup(velocity: -vy / (size.height - to.top));
        springTo(_popDrag, 0, TokMotion.springCollapse);
      } else {
        springTo(_popDrag, 0, TokMotion.springSnap, velocity: vy);
      }
    }

    void dragUpdate(DragUpdateDetails d) => _popDrag.value = math.max(0, _popDrag.value + d.delta.dy);
    final (title, subtitle, page) = switch (_popup!) {
      _Popup.itinerary => ('Itinerary', ItineraryPage.subtitle, ItineraryPage(todayKey: _todayKey, days: _planDays, onOpen: _openDetails, onPoll: () => setState(() => _popup = _Popup.poll), onPick: (at) {
          _closePopup();
          _flyTo(at);
        }) as Widget),
      _Popup.money => ('Money', MoneyPage.subtitle, const MoneyPage()),
      _Popup.add => (
          AddPage.headerOf(_addStep).$1,
          AddPage.headerOf(_addStep).$2,
          AddPage(step: _addStep, onStep: (s) => setState(() => _addStep = s), draft: _draft, mapOf: _mapOf)
        ),
      _Popup.story => ('Story', StoryPage.subtitle, StoryPage(onPick: _jump)),
      _Popup.poll => ('Dinner tonight', PollPage.subtitle(tripNow()), const PollPage()),
    };
    // A change of height (Add going into Plan, or back) is a morph on screen: ease in and out
    return AnimatedPositioned.fromRect(
      rect: to,
      duration: TokMotion.enter,
      curve: TokMotion.easeInOut,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _popDrag]),
        builder: (context, child) {
          final v = _pop.value;
          if (_reduce) return Opacity(opacity: v.clamp(0.0, 1.0), child: child);
          return Transform.translate(offset: Offset(0, (1 - v) * (size.height - to.top) + _popDrag.value), child: child);
        },
        child: TripSheet(
          key: ValueKey(_popup),
          title: title,
          subtitle: subtitle,
          onClose: () => _closePopup(),
          onHeaderDragUpdate: dragUpdate,
          onHeaderDragEnd: dragEnd,
          focus: _popup == _Popup.itinerary ? _todayKey : null,
          onBack: _popup == _Popup.add && _addStep != AddStep.choose ? _addBack : null,
          centered: _popup == _Popup.add && _addStep == AddStep.invite,
          footer: switch (_popup) {
            _Popup.money => MoneyFooter(onScan: _scan),
            _Popup.add => AddPage.footer(step: _addStep, draft: _draft, onSent: _sentPlan),
            _ => null,
          },
          // The itinerary filters by day, like the map
          top: _popup != _Popup.itinerary
              ? null
              : ToggleChips<int>(
                  options: tripDays,
                  selected: _planDays,
                  labelOf: _dayLabel,
                  padding: const EdgeInsets.symmetric(horizontal: TokSpace.xs),
                  onChanged: (d) => setState(() => _planDays = d),
                ),
          child: page,
        ),
      ),
    );
  }

  /// Back in Add: from a picked place to the search, from the search or the invite to the choice.
  void _addBack() {
    HapticFeedback.selectionClick();
    if (_addStep == AddStep.plan && _draft.spot != null) {
      _draft.pick(null);
    } else {
      setState(() => _addStep = AddStep.choose);
    }
  }

  /// A plan went to the group: the pop-up closes and the map flies to it.
  void _sentPlan(Plan plan) {
    _closePopup();
    _flyTo(plan.at);
    final day = dayName(plan.start, tripNow());
    tripNotice.value = 'Sent: ${plan.name}, ${day == 'Today' ? '' : '$day '}${clockTime(plan.start)}–${clockTime(plan.end!)}';
  }

  void _openSheet() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _sheetPlan = null;
    _from = box.localToGlobal(Offset.zero) & box.size;
    _drag.value = 0;
    _closing = false;
    setState(() => _sheet = true);
    _holdUnder();
    if (_reduce) {
      _open.value = 1;
      _holdStill();
    } else {
      springTo(_open, 1, TokMotion.springExpand).whenCompleteOrCancel(_holdStill);
    }
  }

  /// A plan's details, from the itinerary: the pop-up and the full view are the same surface in the same place, so
  /// the itinerary gives way to the plan's page right there (its content fading in), no detour to the map.
  void _openDetails(Plan p) {
    final to = _fullRect(MediaQuery.sizeOf(context), MediaQuery.paddingOf(context));
    HapticFeedback.selectionClick();
    setState(() {
      _sheetPlan = p;
      _from = to;
      _drag.value = 0;
      _closing = false;
      _sheet = true;
      // The pop-up goes at once; the backdrop stays as it is ([_pop] holds it until the details rest open)
      _popup = null;
      _popClosing = false;
    });
    if (_reduce) {
      _open.value = 1;
      _pop.value = 0;
      return;
    }
    _open.value = 0.45;   // the details' content a third in already (see the crossfade in [_expanded]); it fades the rest
    springTo(_open, 1, TokMotion.springSnap).whenCompleteOrCancel(() {
      if (mounted && _sheet) _pop.value = 0;
    });
  }

  void _closeSheet({double velocity = 0}) {
    _closing = true;
    _release(_still);
    // Details opened in place (from the itinerary) leave the way pop-ups do: down, off the screen
    if (_sheetPlan != null) {
      final size = MediaQuery.sizeOf(context), to = _fullRect(size, MediaQuery.paddingOf(context));
      _from = to.shift(Offset(0, size.height - to.top));
    }
    if (_reduce) {
      _open.value = 0;
      _release(_under);
      setState(() {
        _sheet = _closing = false;
        _sheetPlan = null;
      });
      return;
    }
    springTo(_open, 0, TokMotion.springCollapse, velocity: velocity);   // the system's answer: quicker than opening, no bounce
  }

  /// The map and bars stay put while the full view is up (it covers them), so from the first frame of opening they can
  /// be a picture; only if the map isn't still gliding.
  void _holdUnder() => _hold(_under, () => _covered && !_fly.isAnimating && _mapQuiet.elapsedMilliseconds > 100);

  /// Once the full view rests open, the backdrop's blur stops changing too.
  void _holdStill() => _hold(_still, () => _covered && !_closing && !_popClosing && !_open.isAnimating && !_pop.isAnimating);

  /// Pictures [held] right after this frame is drawn, if [when] still holds then.
  void _hold(_Held held, bool Function() when) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || held.image != null || !when()) return;
      final box = held.key.currentContext?.findRenderObject();
      if (box is! RenderRepaintBoundary) return;
      setState(() => held.image = box.toImageSync(pixelRatio: MediaQuery.devicePixelRatioOf(context)));
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Back to drawing [held] live.
  void _release(_Held held) {
    final image = held.image;
    if (image == null) return;
    setState(() => held.image = null);
    SchedulerBinding.instance.addPostFrameCallback((_) => image.dispose());
  }

  /// Something behind the full view changed: draw it live for a frame, then picture it again if it still may be.
  /// Unless it's [now], that waits until nothing moves and no finger is down (a pin's "In 64 mins" turning 63 under the
  /// blur), so the extra work can't land in the middle of a scroll.
  void _sceneChanged({bool now = false}) {
    if (!mounted) return;
    setState(() {});
    if (_under.image == null && _still.image == null) return;
    _rescene?.cancel();
    if (!now && (_touches > 0 || SchedulerBinding.instance.transientCallbackCount > 0)) {
      _rescene = Timer(const Duration(milliseconds: 300), _sceneChanged);
      return;
    }
    _release(_under);
    _release(_still);
    _holdUnder();
    _holdStill();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_under.image != null || _still.image != null) WidgetsBinding.instance.addPostFrameCallback((_) => _sceneChanged(now: true));   // new size or density
  }

  @override
  void dispose() {
    _draft.dispose();
    _under.image?.dispose();
    _still.image?.dispose();
    _rescene?.cancel();
    _tick?.cancel();
    _settle?.cancel();
    _open.dispose();
    _drag.dispose();
    _pop.dispose();
    _home.dispose();
    _enter.dispose();
    _popDrag.dispose();
    addedPlans.removeListener(_sceneChanged);
    tripNotice.removeListener(_showNotice);
    myVote.removeListener(_pollOutside);
    pollUndone.removeListener(_pollOutside);
    myVote.removeListener(_pollTick);
    pollUndone.removeListener(_dinnerChanged);
    pickedDinner.removeListener(_dinnerChanged);
    madePayments.removeListener(_paymentsChanged);
    _noticeTimer?.cancel();
    _payTick?.cancel();
    demoMoment.removeListener(_sceneChanged);
    MapTiles.source.removeListener(_sceneChanged);
    _fly.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final area = _area(size);
    // The map is light: dark icons in the system bars over it (the app draws under them, edge to edge)
    final trip = AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsOver(dark: false),
      child: Stack(children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: startCenter,
              initialZoom: startZoom,
              minZoom: 11,
              maxZoom: 18,
              backgroundColor: t.bgCanvas,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              // A tap on the map beside the card steps it back to a mini pin, as moving the map does (pins take
              // their own taps)
              onTap: (_, _) {
                if (_upNextMid) setState(() => _upNextMid = false);
              },
            ),
            children: [
              if (MapTiles.source.value case final source?) TripTileLayer(source: source),
              _VisitedLayer(shows: _shows),
              // Where everyone is right now; they only show for today
              PeopleLayer(shown: _shows(today)),
              _MeLayer(area: area, breathe: !_covered && !_onHome),
              _PlansLayer(
                area: area,
                upNextMid: _upNextMid,
                cardKey: _cardKey,
                sheetOpen: _sheet,
                onOpen: _openSheet,
                onTap: (p) => _tapPlan(p, size),
                onMidHeight: (h) => _upNextHeight = h,
                shows: _shows,
                here: _here,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: TopBar(
            title: tripTitle,
            dates: tripDates,
            onBack: _goHome,
            trailing: DemoButton(time: clockTime(tripNow()), onTap: () => _openPopup(_Popup.story)),
            filter: ToggleChips<int>(options: tripDays, selected: _days, labelOf: _dayLabel, enterFrom: EnterOrder.firstChip, onChanged: (d) => _setDays(d, size)),
          ),
        ),
        // Slides down past the edge while the map moves (quick), and back up once it settles (a little slower)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: _moving,
            child: AnimatedSlide(
              offset: _moving && !_reduce ? const Offset(0, 1) : Offset.zero,
              duration: _moving ? TokMotion.fade : TokMotion.enter,
              curve: TokMotion.easeOut,
              child: AnimatedOpacity(opacity: _moving ? 0 : 1, duration: _moving ? TokMotion.fade : TokMotion.enter, curve: TokMotion.easeOut, child: ActionBar(onItinerary: () => _openPopup(_Popup.itinerary), onMoney: () => _openPopup(_Popup.money), onAdd: () => _openPopup(_Popup.add))),
            ),
          ),
        ),
        // The map's credit, under the buttons where pins never go, so it always stays readable (and stays while the
        // buttons step away); on Android just above the system's navigation bar, never under it (see ActionBar)
        Positioned(
          left: 0,
          right: 0,
          bottom: ActionBar.creditInset(context),
          child: IgnorePointer(child: Text('© OpenFreeMap © OpenMapTiles © OpenStreetMap', textAlign: TextAlign.center, style: ActionBar.creditStyle.copyWith(color: t.cAttributionFg))),
        ),
        Positioned(
          right: TokSpace.md,
          bottom: ActionBar.rowInset(context) + TokDim.buttonLg + TokSpace.xl,
          child: IgnorePointer(
            ignoring: !_meOff,
            child: AnimatedOpacity(
              opacity: _meOff ? 1 : 0,
              duration: TokMotion.fade,
              curve: TokMotion.easeOut,
              child: AnimatedScale(
                scale: _meOff ? 1 : TokMotion.pressScale,
                duration: TokMotion.fade,
                curve: TokMotion.easeOut,
                child: RecenterButton(onTap: () => _flyTo(myPosition(tripNow()))),
              ),
            ),
          ),
        ),
      ]),
    );
    // Your trips, and the trip opening out of its card over them; whichever isn't showing isn't drawn or ticking
    final under = ColoredBox(
      color: t.bgCanvas,
      child: Stack(children: [
        Positioned.fill(child: Offstage(offstage: _inTrip, child: TickerMode(enabled: !_inTrip, child: _homeLayer(context)))),
        Positioned.fill(child: Offstage(offstage: _onHome, child: TickerMode(enabled: !_onHome, child: _openingTrip(context, size, TripEntrance(clock: _enter, child: trip))))),
      ]),
    );
    final scene = Stack(children: [
      Positioned.fill(child: _under.build(context, under)),
      if (_covered) Positioned.fill(child: _backdrop(context)),
    ]);
    return Listener(
      onPointerDown: (_) => _touches++,
      onPointerUp: (_) => _touches--,
      onPointerCancel: (_) => _touches--,
      child: Stack(children: [
        Positioned.fill(child: _still.build(context, scene)),
        // The poll opened up: the map and its bars behind it tint and blur a little; a tap there closes it
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_pollExpanded || !pollOpen(tripNow()) || _covered,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _expandPoll(false),
              child: AnimatedOpacity(
                opacity: _pollExpanded && pollOpen(tripNow()) && !_covered ? 1 : 0,
                duration: _pollExpanded ? TokMotion.enter : TokMotion.fold,   // in step with the card
                curve: TokMotion.easeOut,
                child: lightEffects
                    ? ColoredBox(color: t.cPollScrim)
                    : BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: TokDim.pollScrimBlur, sigmaY: TokDim.pollScrimBlur),
                        child: ColoredBox(color: t.cPollScrim),
                      ),
              ),
            ),
          ),
        ),
        // While the dinner poll is open it stands where the Up next card would, under the day filter
        Positioned(
          left: 0,
          right: 0,
          top: _safe(size).top + TokSpace.xs,   // a little clear of the day filter
          bottom: math.max(pad.bottom, TokSpace.md),
          child: IgnorePointer(
            ignoring: !pollOpen(tripNow()) || _covered || !_inTrip || !_upNextIn,
            // It comes and goes with a fade and a slight scale from the top; folding is the card's own morph
            child: AnimatedSwitcher(
              duration: TokMotion.enter,
              reverseDuration: TokMotion.fade,
              switchInCurve: TokMotion.easeOut,
              switchOutCurve: TokMotion.easeOut,
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: _reduce ? child : ScaleTransition(scale: Tween(begin: TokMotion.morphEnterScale, end: 1.0).animate(anim), alignment: Alignment.topCenter, child: child),
              ),
              // Only on the map: not over your trips, nor while the trip opens
              // (in the entrance it comes last, in Up next's place)
              child: !pollOpen(tripNow()) || _covered || !_inTrip || !_upNextIn
                  ? const SizedBox.shrink()
                  : Align(
                      key: const ValueKey('poll'),
                      alignment: Alignment.topCenter,
                      child: PollCard(
                        expanded: _pollExpanded,
                        onToggle: () => _expandPoll(!_pollExpanded),
                        onDetails: (_) {
                          setState(() => _pollExpanded = false);
                          _openPopup(_Popup.poll);
                        },
                      ),
                    ),
            ),
          ),
        ),
        if (_sheet) ...[
          // A tap outside the full view closes it
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _closeSheet())),
          Positioned.fill(child: _expanded(context, size, pad)),
        ],
        if (_popup != null) ...[
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _closePopup())),
          _popupSheet(context, size, pad),
        ],
        // The camera, over everything, fading in like any modal
        // The camera, over everything: it fades in, and leaves with a blur, so the bill melts into the page under it
        // (Group or Money, in the same place on the same background)
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: TokMotion.enter,
            reverseDuration: TokMotion.fade,
            switchInCurve: TokMotion.easeOut,
            transitionBuilder: (child, anim) => child.key != const ValueKey('scan')
                ? child
                : _scanning
                    ? FadeTransition(opacity: anim, child: child)
                    : fadeBlurOut(anim, child),
            child: !_scanning
                ? const SizedBox.shrink(key: ValueKey('none'))
                : BillScan(
                    key: const ValueKey('scan'),
                    onClose: () => setState(() => _scanning = false),
                    onAdd: (bill) {
                      addBill(bill);
                      setState(() => _scanning = false);
                      tripNotice.value = 'Dinner added · ${euros(bill.total)}, split by who had what';
                    },
                  ),
          ),
        ),
        // Ren's phone, over Ari's: it fades in from a slight zoom and fades away
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: TokMotion.enter,
            reverseDuration: TokMotion.fade,
            switchInCurve: TokMotion.easeOut,
            switchOutCurve: TokMotion.easeOut,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: _reduce || !_joining ? child : ScaleTransition(scale: Tween(begin: TokMotion.pageZoomScale, end: 1.0).animate(anim), child: child),
            ),
            child: !_joining
                ? const SizedBox.shrink(key: ValueKey('none'))
                : JoinFlow(onJoined: () => _closeJoin(joined: true), onClose: _closeJoin),
          ),
        ),
        // A note for everyone, sliding down from the top and back up the way it came
        Positioned(
          left: TokSpace.md,
          right: TokSpace.md,
          top: pad.top + TokSpace.xs,
          child: IgnorePointer(
            ignoring: !_noticeShown || _noticeAction == null,
            child: AnimatedSlide(
              offset: _noticeShown || _reduce ? Offset.zero : const Offset(0, -1.5),
              duration: _noticeShown ? TokMotion.enter : TokMotion.fade,
              curve: TokMotion.easeOut,
              child: AnimatedOpacity(
                opacity: _noticeShown ? 1 : 0,
                duration: _noticeShown ? TokMotion.enter : TokMotion.fade,
                curve: TokMotion.easeOut,
                child: Center(
                  child: _notice == null
                      ? const SizedBox.shrink()
                      : Toast(label: _notice!, actionLabel: _noticeAction?.label, onAction: _noticeAction == null ? null : () => _actOnNotice(_noticeAction!)),
                ),
              ),
            ),
          ),
        ),
        if (_splash)
          Positioned.fill(
            child: Splash(
              cardKey: _homeCardKey,
              onDone: () {
                homeCardStickersShown.value = true;
                setState(() => _splash = false);
              },
            ),
          ),
      ]),
    );
  }

  /// Behind the full view: the map and bars blur away as it opens.
  Widget _backdrop(BuildContext context) {
    final t = context.tok;
    return AnimatedBuilder(
      animation: Listenable.merge([_open, _pop]),
      builder: (context, _) {
        final p = math.max(_open.value, _pop.value).clamp(0.0, 1.0);
        return BackdropFilter(
          enabled: !lightEffects,
          filter: ui.ImageFilter.blur(sigmaX: TokDim.sheetBackdropBlur * p, sigmaY: TokDim.sheetBackdropBlur * p),
          // Without the blur (light effects) a stronger wash keeps the map back
          child: ColoredBox(color: (lightEffects ? t.cSheetScrimFlat : t.cSheetScrim).withValues(alpha: (lightEffects ? t.cSheetScrimFlat : t.cSheetScrim).a * p)),
        );
      },
    );
  }

  /// The card growing into the full view: one surface whose rect and content follow [_open] (the backdrop is in [_backdrop]).
  /// Where the full view (and a full-height pop-up) rests: under the top bar's buttons, inset from the edges.
  Rect _fullRect(Size size, EdgeInsets pad) => Rect.fromLTRB(
        TokDim.sheetInset,
        pad.top + TokSpace.xs + TokDim.buttonMd + TokSpace.x3xs,
        size.width - TokDim.sheetInset,
        size.height - math.max(pad.bottom, TokDim.sheetInset),
      );

  Widget _expanded(BuildContext context, Size size, EdgeInsets pad) {
    final to = _fullRect(size, pad);
    return AnimatedBuilder(
      animation: Listenable.merge([_open, _drag]),
      builder: (context, _) {
        final v = _open.value;
        final p = v.clamp(0.0, 1.0);
        final rect = Rect.lerp(_from, to, v)!;
        final pull = _drag.value.clamp(0.0, double.infinity);
        final shrink = 1 - (pull / to.height) * (1 - TokMotion.pressScale) * 4;
        // Overlapping crossfade: the card's content leaves over the first half of the way, the sheet's
        // arrives over the second, both are partly there in the middle (blurred slightly), never neither
        // (Details opened from the itinerary have no card to come from)
        final midOp = _sheetPlan != null ? 0.0 : 1 - smoothstep(0.05, 0.55, p);
        final sheetOp = smoothstep(0.3, 0.8, p);
        final seam = TokMotion.crossfadeBlur * 4 * midOp * sheetOp;
        final sx = rect.width / to.width;
        return Stack(children: [
          Positioned.fromRect(
            rect: rect,
            child: Transform.translate(
              offset: Offset(0, pull),
              child: Transform.scale(
                scale: shrink,
                alignment: Alignment.topCenter,
                child: Container(
                  decoration: surfaceDecoration(context, BorderRadius.circular(TokDim.surfaceRadius)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TokDim.surfaceRadius),
                    child: crossfadeSeam(sigma: seam, child: Stack(children: [
                      if (midOp > 0)
                        // The card's own content at its own width, scaled with the surface from its top edge
                        Positioned.fill(
                          child: Opacity(
                            opacity: midOp,
                            child: Transform.scale(
                              scale: rect.width / _from!.width,
                              alignment: Alignment.topCenter,
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minWidth: _from!.width,
                                maxWidth: _from!.width,
                                minHeight: 0,
                                maxHeight: double.infinity,
                                // The very card that's on the map, who's there included, so nothing changes as it lands
                                child: UpNextMid(plan: _upNext, here: _here),
                              ),
                            ),
                          ),
                        ),
                      if (sheetOp > 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: rect.height / sx,
                          child: Opacity(
                            opacity: sheetOp,
                            child: Transform.scale(
                              scale: sx,
                              alignment: Alignment.topLeft,
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                minWidth: to.width,
                                maxWidth: to.width,
                                minHeight: to.height,
                                maxHeight: to.height,
                                child: DetailSheet(
                                  key: ValueKey(_detailPlan.id),
                                  plan: _detailPlan,
                                  mapOf: _mapOf,
                                  onClose: () => _closeSheet(),
                                  onScan: _scan,
                                  onSettle: _settleUp,
                                  onHeaderDragUpdate: (d) => _drag.value = math.max(0, _drag.value + d.delta.dy),
                                  onHeaderDragEnd: (d) {
                                    final vy = d.velocity.pixelsPerSecond.dy;
                                    if (_drag.value > TokSpace.x5xl * 2 || vy > 900) {
                                      HapticFeedback.lightImpact();   // the pull commits
                                      // Hand the finger's speed to the close spring so it doesn't stall
                                      _closeSheet(velocity: -vy / to.height);
                                      springTo(_drag, 0, TokMotion.springCollapse);
                                    } else {
                                      springTo(_drag, 0, TokMotion.springSnap, velocity: vy);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                    ])),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Clips to a given rounded rect (the trip card opening into the map).
class _RRectClip extends CustomClipper<RRect> {
  const _RRectClip(this.rrect);
  final RRect rrect;

  @override
  RRect getClip(Size size) => rrect;

  @override
  bool shouldReclip(_RRectClip old) => old.rrect != rrect;
}

/// A part of the screen that can stand in as a picture of itself, drawn once, while nothing in it changes.
class _Held {
  final key = GlobalKey();
  ui.Image? image;

  /// [live] as it is, or (offstage, keeping its state) under the picture of it.
  Widget build(BuildContext context, Widget live) => Stack(children: [
        Positioned.fill(child: Offstage(offstage: image != null, child: RepaintBoundary(key: key, child: live))),
        // One image pixel per screen pixel, so it's the very same picture
        if (image != null) Positioned.fill(child: RawImage(image: image, scale: MediaQuery.devicePixelRatioOf(context), fit: BoxFit.none, alignment: Alignment.topLeft)),
      ]);
}

/// Past places: stickers on the map, the trip's history.
class _VisitedLayer extends StatelessWidget {
  const _VisitedLayer({required this.shows});
  final bool Function(int day) shows;

  @override
  Widget build(BuildContext context) => MarkerLayer(markers: [
        for (final v in visited)
          Marker(
            point: v.at,
            width: TokDim.stickerMap * 2,
            height: TokDim.stickerMap,
            child: IgnorePointer(child: Center(child: _Filtered(shown: shows(v.day), child: Sticker(v.sticker, size: StickerSize.map, tilt: v.tilt)))),
          ),
      ]);
}

/// Fades and shrinks a mark away when the day filter leaves it out, and back when it's in again.
class _Filtered extends StatelessWidget {
  const _Filtered({required this.shown, required this.child, this.alignment = Alignment.center});
  final bool shown;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !shown,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: TokMotion.enter,
          curve: TokMotion.easeOut,
          child: AnimatedScale(scale: shown ? 1 : TokMotion.morphEnterScale, alignment: alignment, duration: TokMotion.enter, curve: TokMotion.easeOut, child: child),
        ),
      );
}

/// My location: the dot with a heading cone, or the edge mark when I'm off-screen.
class _MeLayer extends StatelessWidget {
  const _MeLayer({required this.area, required this.breathe});
  final PinArea area;

  /// Off while the full view covers the map, so the dot isn't animating unseen.
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final p = cam.latLngToScreenOffset(myPosition(tripNow()));   // I walk to dinner too
    final inside = area.contains(p);
    final c = area.clamp(p, 0);
    final angle = math.atan2(p.dy - c.dy, p.dx - c.dx);
    const edge = Size(MeEdge.width, TokDim.meGlowHeight);
    // Put the capsule (the mark's outer end) on the clamp point
    final markCenter = c - Offset(math.cos(angle), math.sin(angle)) * (edge.width / 2 - TokDim.meEdgeWidth / 2);
    return IgnorePointer(
      child: Stack(children: [
        Positioned(
          left: p.dx - TokDim.meCone,
          top: p.dy - TokDim.meCone,
          child: AnimatedOpacity(
            opacity: inside ? 1 : 0,
            duration: TokMotion.fade,
            curve: TokMotion.easeOut,
            child: TickerMode(enabled: inside && breathe, child: const MeMarker(heading: meHeadingDegrees * math.pi / 180)),
          ),
        ),
        Positioned(
          left: markCenter.dx - edge.width / 2,
          top: markCenter.dy - edge.height / 2,
          width: edge.width,
          height: edge.height,
          child: AnimatedOpacity(opacity: inside ? 0 : 1, duration: TokMotion.fade, curve: TokMotion.easeOut, child: Center(child: MeEdge(angle: angle))),
        ),
      ]),
    );
  }
}

/// Every planned stop as a pin; the first (Up next) can grow into the card.
class _PlansLayer extends StatelessWidget {
  const _PlansLayer({required this.area, required this.upNextMid, required this.cardKey, required this.sheetOpen, required this.onOpen, required this.onTap, required this.onMidHeight, required this.shows, required this.here});
  final PinArea area;
  final List<String> here;
  final bool Function(int day) shows;
  final bool upNextMid, sheetOpen;
  final GlobalKey cardKey;
  final VoidCallback onOpen;
  final ValueChanged<Plan> onTap;
  final ValueChanged<double> onMidHeight;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final size = cam.nonRotatedSize;
    // Later plans first so Up next draws on top
    final all = tripPlans;
    return Stack(children: [
      for (final p in all.reversed)
        Positioned.fill(
          child: _Filtered(
            shown: shows(p.day),
            // Shrinks toward the place itself
            alignment: Alignment(cam.latLngToScreenOffset(p.at).dx / size.width * 2 - 1, cam.latLngToScreenOffset(p.at).dy / size.height * 2 - 1),
            child: PlanPin(
              key: ValueKey(p.id),
              plan: p,
              anchor: cam.latLngToScreenOffset(p.at),
              area: area,
              wantMid: p == all.first && upNextMid && p.fan.isNotEmpty,   // only a plan with its own card
              cardKey: p == all.first ? cardKey : null,
              hidden: p == all.first && sheetOpen,
              onOpen: onOpen,
              onTap: () => onTap(p),
              onMidHeight: p == all.first ? onMidHeight : null,
              here: p == all.first ? here : const [],
            ),
          ),
        ),
    ]);
  }
}

/// The footer's pop-ups.
enum _Popup { itinerary, money, add, story, poll }
