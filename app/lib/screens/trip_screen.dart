import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' show Theme, ThemeReader;

import '../components/bars.dart';
import '../components/basics.dart';
import '../components/day_filter.dart';
import '../components/detail_sheet.dart';
import '../components/map_shapes.dart';
import '../components/plan_pin.dart';
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
  late final _fly = AnimationController(vsync: this);
  Timer? _tick;
  Theme? _theme;
  TileProviders? _tiles;
  bool _upNextMid = true;
  bool _meOff = false;
  bool _sheet = false;
  Rect? _from;

  /// Days picked in the filter; empty means All.
  Set<int> _days = const {};
  bool _shows(int day) => _days.isEmpty || _days.contains(day);

  Plan get _upNext => plans.first;
  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _loadMap();
    _map.mapEventStream.listen(_onMapEvent);
    // On the next minute, then every minute, so "In 64 mins" counts down
    _tick = Timer(Duration(seconds: 60 - tripNow().second), () {
      if (!mounted) return;
      setState(() {});
      _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    });
    _open.addListener(() {
      // Hand back to the pin's card as soon as the overlay is within a pixel of it; the spring's
      // last sub-pixel crawl would otherwise leave the real card hidden for no visible reason
      if (_sheet && _closing && _open.value <= 0.002) {
        _open.stop();
        setState(() => _sheet = _closing = false);
      }
    });
  }

  /// Google-like style on free OpenStreetMap vector tiles (OpenFreeMap, no key). Built by tools/google_style.py.
  Future<void> _loadMap() async {
    final style = jsonDecode(await rootBundle.loadString('assets/map/style-google.json')) as Map<String, dynamic>;
    final source = (style['sources'] as Map<String, dynamic>)['openmaptiles'] as Map<String, dynamic>;
    final tileJson = jsonDecode((await http.get(Uri.parse(source['url'] as String))).body) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _theme = ThemeReader().read(style);
      _tiles = TileProviders({
        'openmaptiles': NetworkVectorTileProvider(urlTemplate: (tileJson['tiles'] as List).first as String, maximumZoom: (tileJson['maxzoom'] as num).toInt()),
      });
    });
  }

  void _onMapEvent(MapEvent e) {
    // The card steps back to a mini pin as soon as the person moves the map
    final byUser = e.source != MapEventSource.mapController && e.source != MapEventSource.nonRotatedSizeChange;
    if (byUser && _upNextMid && (e is MapEventMoveStart || e is MapEventDoubleTapZoomStart || e is MapEventScrollWheelZoom || e is MapEventFlingAnimationStart)) {
      setState(() => _upNextMid = false);
    }
    final off = !_safe(MediaQuery.sizeOf(context)).contains(e.camera.latLngToScreenOffset(me));
    if (off != _meOff) setState(() => _meOff = off);
  }

  /// Where pins may sit: the map minus the top bar and the action bar.
  Rect _safe(Size size) {
    final pad = MediaQuery.paddingOf(context);
    return Rect.fromLTRB(
      TokDim.widgetEdgeInset,
      pad.top + TopBar.contentHeightWithFilter + TokDim.widgetEdgeInset,
      size.width - TokDim.widgetEdgeInset,
      size.height - math.max(pad.bottom, TokSpace.x2xl) - TokDim.buttonLg - TokDim.widgetEdgeInset,
    );
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
    final points = [for (final p in plans) if (days.contains(p.day)) p.at, for (final v in visited) if (days.contains(v.day)) v.at];
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

  void _openSheet() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _from = box.localToGlobal(Offset.zero) & box.size;
    _drag.value = 0;
    _closing = false;
    setState(() => _sheet = true);
    _reduce ? _open.value = 1 : springTo(_open, 1, TokMotion.springExpand);
  }

  void _closeSheet({double velocity = 0}) {
    _closing = true;
    if (_reduce) {
      _open.value = 0;
      setState(() => _sheet = _closing = false);
      return;
    }
    springTo(_open, 0, TokMotion.springCollapse, velocity: velocity);   // the system's answer: quicker than opening, no bounce
  }

  @override
  void dispose() {
    _tick?.cancel();
    _open.dispose();
    _drag.dispose();
    _fly.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tok;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final safe = _safe(size);
    return ColoredBox(
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
              _MeLayer(safe: safe),
              _PlansLayer(
                safe: safe,
                upNextMid: _upNextMid,
                cardKey: _cardKey,
                sheetOpen: _sheet,
                onOpen: _openSheet,
                onTap: (p) => _tapPlan(p, size),
                onMidHeight: (h) => _upNextHeight = h,
                shows: _shows,
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(TokSpace.xs, 0, 0, math.max(pad.bottom, TokSpace.x2xl) + TokDim.buttonLg + TokSpace.xs),
                  child: Text('© OpenFreeMap © OpenMapTiles © OpenStreetMap', style: TokText.bodySm.copyWith(color: t.cAttributionFg)),
                ),
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
            faces: topFaces,
            more: moreFaces,
            filter: DayFilter(days: tripDays, selected: _days, labelOf: _dayLabel, onChanged: (d) => _setDays(d, size)),
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: 0, child: ActionBar()),
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
                child: RecenterButton(onTap: () => _flyTo(me)),
              ),
            ),
          ),
        ),
        if (_sheet) Positioned.fill(child: _expanded(context, size, pad)),
      ]),
    );
  }

  /// The card growing into the full view: one surface whose rect, content and backdrop all follow [_open].
  Widget _expanded(BuildContext context, Size size, EdgeInsets pad) {
    final t = context.tok;
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
          // Backdrop: the map and bars blur away behind the full view
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _closeSheet(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: TokDim.sheetBackdropBlur * p, sigmaY: TokDim.sheetBackdropBlur * p),
                child: ColoredBox(color: t.cSheetScrim.withValues(alpha: t.cSheetScrim.a * p)),
              ),
            ),
          ),
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
  const _MeLayer({required this.safe});
  final Rect safe;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final p = cam.latLngToScreenOffset(me);
    final inside = safe.contains(p);
    final c = Offset(p.dx.clamp(safe.left, safe.right), p.dy.clamp(safe.top, safe.bottom));
    final angle = math.atan2(p.dy - c.dy, p.dx - c.dx);
    const edge = Size(MeEdge.width, TokDim.meGlowHeight);
    // Put the capsule (the mark's outer end) on the clamp point
    final markCenter = c - Offset(math.cos(angle), math.sin(angle)) * (edge.width / 2 - TokDim.meEdgeWidth / 2);
    return IgnorePointer(
      child: Stack(children: [
        Positioned(
          left: p.dx - TokDim.meCone,
          top: p.dy - TokDim.meCone,
          child: AnimatedOpacity(opacity: inside ? 1 : 0, duration: TokMotion.fade, curve: TokMotion.easeOut, child: const MeMarker(heading: meHeadingDegrees * math.pi / 180)),
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
  const _PlansLayer({required this.safe, required this.upNextMid, required this.cardKey, required this.sheetOpen, required this.onOpen, required this.onTap, required this.onMidHeight, required this.shows});
  final Rect safe;
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
    return Stack(children: [
      for (final p in plans.reversed)
        Positioned.fill(
          child: _Filtered(
            shown: shows(p.day),
            // Shrinks toward the place itself
            alignment: Alignment(cam.latLngToScreenOffset(p.at).dx / size.width * 2 - 1, cam.latLngToScreenOffset(p.at).dy / size.height * 2 - 1),
            child: PlanPin(
              key: ValueKey(p.id),
              plan: p,
              anchor: cam.latLngToScreenOffset(p.at),
              safe: safe,
              wantMid: p == plans.first && upNextMid,
              cardKey: p == plans.first ? cardKey : null,
              hidden: p == plans.first && sheetOpen,
              onOpen: onOpen,
              onTap: () => onTap(p),
              onMidHeight: p == plans.first ? onMidHeight : null,
            ),
          ),
        ),
    ]);
  }
}
