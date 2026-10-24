// The trip map for the Figma screens: at each moment of the story, the map exactly as the app frames it, drawn with
// nothing on top (the pins, cards and bars are Figma components), and where everything on the map sits.
// On the iPhone 17 Pro Max simulator (440 × 956, the Figma frames' size):
//   flutter build ios --simulator --debug -t perf/figma_map.dart
//   xcrun simctl install <id> build/ios/iphonesimulator/Runner.app && xcrun simctl launch <id> com.bogste.tripup
// For each moment it writes tmp/figma/<moment>.png (the map at 2×) and tmp/figma/<moment>.json (the camera, and each
// marker's kind, name and rect in screen points) in the app's container, prints FIGMA DONE and quits.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:tripup/components/basics.dart';
import 'package:tripup/components/map_shapes.dart';
import 'package:tripup/components/map_tiles.dart';
import 'package:tripup/components/plan_pin.dart';
import 'package:tripup/data.dart';
import 'package:tripup/design/tokens.dart';

import 'trip_perf.dart' show Player;

/// The moments the Figma flows show, by their title in [storyMoments].
const _moments = ['Your trips', 'Ren joins', 'Dinner poll', 'The poll closes', 'On the way', 'Before dinner', "Everyone's there", 'The bill'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = Directory('${Directory.systemTemp.path}/figma')..createSync(recursive: true);
  final p = Player({});
  for (final title in _moments) {
    final m = storyMoments.firstWhere((m) => m.title == title);
    await p.start(inTrip: false);
    jumpTo(m);
    await p.wait(1500);
    await p.tap(Player.tripCard);
    await p.wait(4000);   // the opening, Up next, and the tiles
    final name = title.toLowerCase().replaceAll(RegExp(r"[^a-z]+"), '-');
    final scene = _scene();
    File('${dir.path}/$name.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(scene));
    await _drawMap(scene, File('${dir.path}/$name.png'));
    debugPrint('FIGMA $name');
  }
  debugPrint('FIGMA DONE ${dir.path}');
  exit(0);
}

/// The camera, and every marker on the map: pins (mid card, mini pin, tail), people, me, and the places' stickers.
Map<String, dynamic> _scene() {
  final marks = <Map<String, dynamic>>[];
  fm.MapCamera? camera;
  void visit(Element e, bool inMap) {
    final w = e.widget;
    if (w is fm.FlutterMap) inMap = true;
    if (inMap) {
      camera ??= fm.MapCamera.maybeOf(e);
      final box = e.findRenderObject();
      Map<String, dynamic>? mark;
      if (w is PlanPin) {
        mark = {'kind': 'pin', 'plan': w.plan.id, 'anchor': [w.anchor.dx, w.anchor.dy], 'mid': w.wantMid, 'here': w.here};
      } else if (w is UpNextMid) {
        mark = {'kind': 'mid', 'plan': w.plan.id, 'here': w.here};
      } else if (w.runtimeType.toString() == '_MiniContent') {
        mark = {'kind': 'mini'};
      } else if (w is PinTail) {
        mark = {'kind': 'tail'};
      } else if (w is FacePile) {
        mark = {'kind': 'faces', 'faces': w.faces, 'size': w.size.name};
      } else if (w is MeMarker) {
        mark = {'kind': 'me', 'heading': w.heading};
      } else if (w is EdgeArrow) {
        mark = {'kind': 'arrow', 'angle': w.angle};
      } else if (w is Sticker) {
        mark = {'kind': 'sticker', 'name': w.name, 'tilt': w.tilt};
      }
      if (mark != null && box is RenderBox && box.attached && box.hasSize) {
        final r = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
        final dpr = WidgetsBinding.instance.platformDispatcher.implicitView!.devicePixelRatio;
        mark['rect'] = [r.left / dpr, r.top / dpr, r.width / dpr, r.height / dpr];
        mark['opacity'] = _opacity(e);
        marks.add(mark);
      }
    }
    e.visitChildElements((c) => visit(c, inMap));
  }

  WidgetsBinding.instance.rootElement?.visitChildElements((c) => visit(c, false));
  final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
  final size = view.physicalSize / view.devicePixelRatio;
  return {
    'time': clockTime(tripNow()),
    'size': [size.width, size.height],
    'center': [camera!.center.latitude, camera!.center.longitude],
    'zoom': camera!.zoom,
    'marks': marks,
  };
}

/// How visible an element is through its ancestors' opacities.
double _opacity(Element e) {
  var o = 1.0;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Opacity) o *= w.opacity;
    if (w is AnimatedOpacity) o *= w.opacity;
    return true;
  });
  return o;
}

/// The map alone at the scene's camera: the same tiles, the same canvas colour, nothing on it.
Future<void> _drawMap(Map<String, dynamic> scene, File to) async {
  final key = GlobalKey();
  final center = scene['center'] as List;
  final size = scene['size'] as List;
  runApp(Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: (size[0] as num).toDouble(),
          height: (size[1] as num).toDouble(),
          child: fm.FlutterMap(
            options: fm.MapOptions(
              initialCenter: LatLng(center[0] as double, center[1] as double),
              initialZoom: scene['zoom'] as double,
              backgroundColor: TokColors.light.bgCanvas,
            ),
            children: [TripTileLayer(source: MapTiles.source.value!)],
          ),
        ),
      ),
    ),
  ));
  await Future<void>.delayed(const Duration(seconds: 6));
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  to.writeAsBytesSync(png!.buffer.asUint8List());
}
