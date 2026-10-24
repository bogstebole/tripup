// Draws the map tiles the Android app ships for Lisbon (assets/map/tiles/), with the app's own tile code
// (lib/components/map_tiles.dart), on the Android emulator. tools/bake_map_tiles.sh builds and runs it, pulls the
// PNGs from the app's external files folder and writes them into the app as WebP, with an index naming the style
// they were drawn with (the app ignores them once the style changes).
//
// Which tiles: where the trip happens at the zoom the map opens on (14): the opening view and a screen around it, and
// a screen around every plan and every place visited (the map flies there at the same zoom); the whole trip at 13
// and 12 (the day filter frames a day's places, zooming out).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tripup/components/map_tiles.dart';
import 'package:tripup/data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final source = await MapTiles.start(bundle: false);
  final dir = Directory('${(await getExternalStorageDirectory())!.path}/baked');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final loader = source.loader();
  final layer = TileLayer(tileProvider: source.drawn);
  final tiles = bakeList();
  debugPrint('BAKE ${tiles.length} tiles');
  final names = <String>[];
  for (final (z, x, y) in tiles) {
    final info = await loader.loadTile(TileCoordinates(x, y, z), layer, () => false);
    final png = await info.image.toByteData(format: ui.ImageByteFormat.png);
    final name = '$z-$x-$y';
    await File('${dir.path}/$name.png').writeAsBytes(png!.buffer.asUint8List());
    info.dispose();
    names.add(name);
    if (names.length % 10 == 0) debugPrint('BAKE ${names.length}/${tiles.length}');
  }
  await File('${dir.path}/index.json').writeAsString(jsonEncode({'style': source.styleHash, 'tiles': names}));
  debugPrint('BAKE DONE ${names.length} ${dir.path}');
  exit(0);
}

/// The tiles to bake, as (zoom, x, y).
List<(int, int, int)> bakeList() {
  final out = <(int, int, int)>{};
  // A screen is at most about 2 tiles wide and 4 tall at zoom 14.1 on a phone; one more on each side
  void around(LatLng at, int z, {int dx = 2, int dy = 3}) {
    final (x, y) = _tile(at, z);
    for (var i = x - dx; i <= x + dx; i++) {
      for (var j = y - dy; j <= y + dy; j++) {
        out.add((z, i, j));
      }
    }
  }

  around(startCenter, 14);
  for (final p in tripPlans) {
    around(p.at, 14, dx: 1, dy: 2);
  }
  for (final v in visited) {
    around(v.at, 14, dx: 1, dy: 2);
  }
  // The whole trip at 13 and 12
  final points = [startCenter, for (final p in tripPlans) p.at, for (final v in visited) v.at];
  for (final z in [13, 12]) {
    final xs = [for (final p in points) _tile(p, z).$1], ys = [for (final p in points) _tile(p, z).$2];
    for (var i = xs.reduce(math.min) - 1; i <= xs.reduce(math.max) + 1; i++) {
      for (var j = ys.reduce(math.min) - 1; j <= ys.reduce(math.max) + 1; j++) {
        out.add((z, i, j));
      }
    }
  }
  return out.toList()..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 != b.$2 ? a.$2 - b.$2 : a.$3 - b.$3);
}

(int, int) _tile(LatLng at, int z) {
  final n = 1 << z;
  final x = (at.longitude + 180) / 360 * n;
  final lat = at.latitude * math.pi / 180;
  final y = (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n;
  return (x.floor(), y.floor());
}
