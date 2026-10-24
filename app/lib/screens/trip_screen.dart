import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' show Theme, ThemeReader;

import '../components/bars.dart';
import '../components/bill_scan.dart';
import '../components/basics.dart';
import '../components/toggle_chips.dart';
import '../components/detail_sheet.dart';
import '../components/map_shapes.dart';
import '../components/people_layer.dart';
import '../components/plan_pin.dart';
import '../components/poll.dart';
import '../components/stagger.dart';
import '../components/toast.dart';
import '../components/trip_pages.dart';
import '../components/trip_sheet.dart';
import '../data.dart';
import '../design/theme.dart';
import '../design/tokens.dart';

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

  /// Run once the full view has finished closing (Settle up goes on to Money).
  VoidCallback? _afterSheet;

  /// The note at the top of the map, and whether it's showing.
  String? _notice;
  ({String label, VoidCallback onTap})? _noticeAction;
  bool _noticeShown = false;

  /// The poll as last seen (0 not open yet, 1 open, 2 closed) and its vote count, to notice when either changes.
  int _pollPhase = -1, _pollVotes = -1;
  Timer? _noticeTimer, _payTick;
  bool _wasSquare = false;

  /// Whether the full view or a pop-up covers the map.
  bool get _covered => _sheet || _popup != null;
  late final _fly = AnimationController(vsync: this);
  Timer? _tick;
  Theme? _theme;
  TileProviders? _tiles;
  bool _upNextMid = true;
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
  Set<int> _days = const {};
  bool _shows(int day) => _days.isEmpty || _days.contains(day);

  /// Whoever has already got to the Up next place.
  List<String> get _here => [for (final p in people) if (p.id != myId && isHere(p, tripNow())) p.sticker];

  Plan get _upNext => tripPlans.first;
  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _loadMap();
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
        setState(() => _sheet = _closing = false);
        final then = _afterSheet;
        _afterSheet = null;
        then?.call();
      }
    });
    tripNotice.addListener(_showNotice);
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
    _pollPhase = phase;
    _pollVotes = votes;
    // Only a change that just happened is news (not one the demo jumped over)
    bool fresh(DateTime at) => now.difference(at) < const Duration(minutes: 2);
    if (was != -1 && phase == 1 && was == 0 && fresh(pollOpens)) {
      tripNotice.value = '${personById(pollAskedBy).name} started a poll: where for dinner tonight?';
    }
    if (was != -1 && phase == 2 && was != 2 && fresh(pollClosedAt(now)) && !pollUndone.value) {
      final winner = pollOptionById(pollLeader(now)!);
      noticeAction = (label: 'Undo', onTap: _undoWinner);
      tripNotice.value = '${winner.short} won · added to tonight';
      _upNextMid = true;
    }
    _sceneChanged();
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

  /// Google-like style on free OpenStreetMap vector tiles (OpenFreeMap, no key). Built by tools/google_style.py.
  Future<void> _loadMap() async {
    final style = jsonDecode(await rootBundle.loadString('assets/map/style-google.json')) as Map<String, dynamic>;
    final source = (style['sources'] as Map<String, dynamic>)['openmaptiles'] as Map<String, dynamic>;
    final tileJson = jsonDecode((await http.get(Uri.parse(source['url'] as String))).body) as Map<String, dynamic>;
    if (!mounted) return;
    _sceneChanged();
    setState(() {
      _theme = ThemeReader().read(style);
      _tiles = TileProviders({
        'openmaptiles': NetworkVectorTileProvider(urlTemplate: (tileJson['tiles'] as List).first as String, maximumZoom: (tileJson['maxzoom'] as num).toInt()),
      });
    });
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
    // (a short pause between two drags shouldn't bring them back)
    if (byUser) {
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
      size.height - math.max(pad.bottom, TokSpace.x2xl) - TokDim.buttonLg - TokDim.widgetEdgeInset,
    ));
  }

  /// Where pins sit: [_safe], but reaching down to the bottom buttons' row, beside the buttons and never on them.
  PinArea _area(Size size) {
    final pad = MediaQuery.paddingOf(context);
    final safe = _safe(size);
    final row = size.height - math.max(pad.bottom, TokSpace.x2xl);
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

  /// The filter changed: other days' pins and places fade out, and the map frames what's left.
  /// All brings back the opening view, with the Up next card.
  void _setDays(Set<int> days, Size size) {
    setState(() {
      _days = days;
      _upNextMid = days.isEmpty;
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
    setState(() => _popup = which);
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
    setState(() => _upNextMid = true);
    if (m.opens == 'money') {
      setState(() => _popup = _Popup.money);
    } else {
      _closePopup();
    }
  }

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
    // Add has only a few rows, so it's shorter
    final to = Rect.fromLTRB(TokDim.sheetInset, _popup == _Popup.add ? math.max(full, bottom - TokDim.sheetCompactHeight) : full, size.width - TokDim.sheetInset, bottom);
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
      _Popup.itinerary => ('Itinerary', ItineraryPage.subtitle, ItineraryPage(todayKey: _todayKey, onPoll: () => setState(() => _popup = _Popup.poll), onPick: (at) {
          _closePopup();
          _flyTo(at);
        }) as Widget),
      _Popup.money => ('Money', MoneyPage.subtitle, MoneyPage(onScan: _scan)),
      _Popup.add => ('Add to the trip', AddPage.subtitle, const AddPage()),
      _Popup.story => ('Story', StoryPage.subtitle, StoryPage(onPick: _jump)),
      _Popup.poll => ('Dinner tonight', PollPage.subtitle(tripNow()), const PollPage()),
    };
    return Positioned.fromRect(
      rect: to,
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
          child: page,
        ),
      ),
    );
  }

  void _openSheet() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
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

  void _closeSheet({double velocity = 0}) {
    _closing = true;
    _release(_still);
    if (_reduce) {
      _open.value = 0;
      _release(_under);
      setState(() => _sheet = _closing = false);
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
    _under.image?.dispose();
    _still.image?.dispose();
    _rescene?.cancel();
    _tick?.cancel();
    _settle?.cancel();
    _open.dispose();
    _drag.dispose();
    _pop.dispose();
    _popDrag.dispose();
    addedPlans.removeListener(_sceneChanged);
    tripNotice.removeListener(_showNotice);
    myVote.removeListener(_pollTick);
    pollUndone.removeListener(_dinnerChanged);
    pickedDinner.removeListener(_dinnerChanged);
    madePayments.removeListener(_paymentsChanged);
    _noticeTimer?.cancel();
    _payTick?.cancel();
    demoMoment.removeListener(_sceneChanged);
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
    final under = ColoredBox(
      color: t.bgCanvas,
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
            ),
            children: [
              if (_theme != null && _tiles != null) VectorTileLayer(theme: _theme!, tileProviders: _tiles!),
              _VisitedLayer(shows: _shows),
              // Where everyone is right now; they only show for today
              PeopleLayer(shown: _shows(today)),
              _MeLayer(area: area, breathe: !_covered),
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
            trailing: DemoButton(time: clockTime(tripNow()), onTap: () => _openPopup(_Popup.story)),
            filter: ToggleChips<int>(options: tripDays, selected: _days, labelOf: _dayLabel, onChanged: (d) => _setDays(d, size)),
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
        // buttons step away)
        Positioned(
          left: 0,
          right: 0,
          bottom: math.max(pad.bottom, TokSpace.x2xl) - TokText.bodySm.fontSize! * TokText.bodySm.height! - TokSpace.x3xs,
          child: IgnorePointer(child: Text('© OpenFreeMap © OpenMapTiles © OpenStreetMap', textAlign: TextAlign.center, style: TokText.bodySm.copyWith(color: t.cAttributionFg))),
        ),
        Positioned(
          right: TokSpace.md,
          bottom: math.max(pad.bottom, TokSpace.x2xl) + TokDim.buttonLg + TokSpace.xl,
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
        // While the dinner poll is open it stands where the Up next card would, under the day filter
        Positioned(
          left: 0,
          right: 0,
          top: _safe(size).top,
          child: IgnorePointer(
            ignoring: !pollOpen(tripNow()) || _covered,
            child: AnimatedSwitcher(
              duration: TokMotion.enter,
              reverseDuration: TokMotion.fade,
              switchInCurve: TokMotion.easeOut,
              switchOutCurve: TokMotion.easeOut,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: TokMotion.morphEnterScale, end: 1.0).animate(anim), alignment: Alignment.topCenter, child: child),
              ),
              child: pollOpen(tripNow()) && !_covered ? Center(key: const ValueKey('poll'), child: PollCard(onOpen: () => _openPopup(_Popup.poll))) : const SizedBox.shrink(),
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
          filter: ui.ImageFilter.blur(sigmaX: TokDim.sheetBackdropBlur * p, sigmaY: TokDim.sheetBackdropBlur * p),
          child: ColoredBox(color: t.cSheetScrim.withValues(alpha: t.cSheetScrim.a * p)),
        );
      },
    );
  }

  /// The card growing into the full view: one surface whose rect and content follow [_open] (the backdrop is in [_backdrop]).
  Widget _expanded(BuildContext context, Size size, EdgeInsets pad) {
    final to = Rect.fromLTRB(
      TokDim.sheetInset,
      pad.top + TokSpace.xs + TokDim.buttonMd + TokSpace.x3xs,
      size.width - TokDim.sheetInset,
      size.height - math.max(pad.bottom, TokDim.sheetInset),
    );
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
        final midOp = 1 - smoothstep(0.05, 0.55, p);
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
                                child: UpNextMid(plan: _upNext),
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
                                  plan: _upNext,
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
