// The map's tiles: the Google-like style (assets/map/style-google.json, built by tools/google_style.py) on free
// OpenStreetMap vector tiles from OpenFreeMap, drawn into images on the phone by vector_map_tiles.
//
// Drawing a vector tile is the heaviest thing the app does, and it happens on the UI thread: on an emulator set up
// like the Huawei Y7 (Android 8.1, slow cores) about half a second a tile, and the first screen needed 24 of them,
// downloaded one TLS connection each, so the map took over 20 s there and the trip's opening stalled behind it (see
// VERSIONS.md, Android performance). So here:
//  - On Android, the tiles around Lisbon come with the app, already drawn (assets/map/tiles/, baked on the Android
//    emulator by tools/bake_map_tiles.sh with this same code): no download and no drawing for them. They're only used
//    while the style is the one they were drawn with (its hash is in the index).
//  - Loading starts right after the first frame (Your trips): reading the style and the bundle's index only.
//  - The tile list (TileJSON, which names this week's tiles) is kept on disk; only the first launch waits for it.
//  - One HTTP connection pool for every tile, instead of a new TLS handshake per tile.
//  - Drawing on the phone (the parsed style, the tile workers) is set up a second after the first frame, or when the
//    first tile needs it.
//
// vector_map_tiles' own VectorTileLayer can't do the baked tiles, the shared client or the late setup, so the layer is
// put together here from the package's parts (`src/` imports, the version pinned in pubspec.yaml); it draws exactly
// what VectorTileLayer's raster mode draws.
// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_map_tiles/src/cache/byte_storage_factory.dart';
import 'package:vector_map_tiles/src/cache/caches.dart';
import 'package:vector_map_tiles/src/executors/shared_executor.dart';
import 'package:vector_map_tiles/src/raster/raster_tile_provider.dart';
import 'package:vector_map_tiles/src/raster/tile_loader.dart';
import 'package:vector_map_tiles/src/stream/tile_supplier_raster.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' show Theme, ThemeReader;

import '../startup_timings.dart';

/// Everything the map's layers share, ready once [MapTiles.start] has read the style. What only drawing tiles on the
/// phone needs (the parsed style, the tile workers and their caches) is set up on first use, or a moment after the
/// first frame ([warmUp]), so it never holds up Your trips or the baked tiles.
class MapSource {
  MapSource._(this._style, this.styleHash, this.bundled, this.tiles);
  final Map<String, dynamic> _style;

  /// FNV-1a of the style file, to tell whether the baked tiles were drawn with it.
  final String styleHash;

  /// Tiles that come with the app, already drawn, as 'z-x-y' (empty off Android, or if the style has changed).
  final Set<String> bundled;

  /// Where the vector tiles come from (the network, through one connection pool).
  final TileProviders tiles;

  late final Theme theme = ThemeReader().read(_style);
  late final Executor _executor = acquireSharedExecutor(concurrency: VectorTileLayer.defaultConcurrency);
  late final Caches _caches = () {
    final caches = Caches(
      executor: _executor,
      providers: tiles,
      theme: theme,
      sprites: null,
      ttl: VectorTileLayer.defaultCacheTtl,
      memoryTileCacheMaxSize: VectorTileLayer.defaultTileCacheMaxSize,
      memoryTileDataCacheMaxSize: VectorTileLayer.defaultTileDataCacheMaxSize,
      maxSizeInBytes: VectorTileLayer.defaultCacheMaxSize,
      maxTextCacheSize: VectorTileLayer.defaultTextCacheMaxSize,
      cacheStorage: createByteStorage(null),
    );
    Future.delayed(const Duration(seconds: 3), caches.applyConstraints);
    return caches;
  }();
  late final _raster = RasterTileProvider(providers: tiles, cache: _caches.imageLoadingCache);

  /// Tiles drawn on the phone, as VectorTileLayer's raster mode draws them.
  late final fm.TileProvider drawn = () {
    final provider = createRasterTileProvider(theme, null, _caches, _raster, _executor, TileOffset.DEFAULT, Duration.zero, VectorTileLayer.defaultConcurrency);
    StartupTimings.mark('Map: tile workers ready');
    return provider;
  }();

  /// Sets up drawing on the phone ahead of the first tile that needs it.
  void warmUp() => drawn;

  /// A loader that draws one tile at a time, the way the layer does (for baking the bundled tiles).
  TileLoader loader() =>
      createTileLoader(theme, null, _caches, _raster, _executor, TileOffset.DEFAULT, Duration.zero, VectorTileLayer.defaultConcurrency);
}

abstract final class MapTiles {
  static const style = 'assets/map/style-google.json';
  static const bundleDir = 'assets/map/tiles';

  /// The map's source once it's ready (the style read; the tiles may still be on their way).
  static final source = ValueNotifier<MapSource?>(null);
  static Future<MapSource>? _starting;

  /// Starts loading the map (once; the trip screen calls it right after its first frame). [bundle]: use the baked tiles.
  static Future<MapSource> start({bool bundle = true}) => _starting ??= _start(bundle);

  static Future<MapSource> _start(bool useBundle) async {
    StartupTimings.mark('Map: starts loading');
    final text = await rootBundle.loadString(style);
    final json = jsonDecode(text) as Map<String, dynamic>;
    final hash = fnv1a(text);
    final tiles = TileProviders({'openmaptiles': _NetworkTiles((json['sources'] as Map)['openmaptiles']['url'] as String)});
    final bundled = useBundle ? await _bundle(hash) : <String>{};
    final s = MapSource._(json, hash, bundled, tiles);
    source.value = s;
    StartupTimings.mark('Map: style read', detail: '${bundled.length} baked tiles');
    // Drawing on the phone gets ready while Your trips is up, after its first frames
    unawaited(WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) => Future.delayed(const Duration(seconds: 1), s.warmUp)));
    return s;
  }

  /// The baked tiles, if they were drawn with this style (Android only: elsewhere the labels' system font differs).
  static Future<Set<String>> _bundle(String hash) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return const {};
    try {
      final index = jsonDecode(await rootBundle.loadString('$bundleDir/index.json')) as Map<String, dynamic>;
      if (index['style'] != hash) {
        debugPrint('Map: the baked tiles were drawn with another style; drawing every tile on the phone (run tools/bake_map_tiles.sh)');
        return const {};
      }
      return {...(index['tiles'] as List).cast<String>()};
    } catch (_) {
      return const {};
    }
  }

  /// 32-bit FNV-1a of [text]'s UTF-16 code units, as hex (the bake tool computes the same).
  static String fnv1a(String text) {
    var h = 0x811c9dc5;
    for (final c in text.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}

/// OpenFreeMap's vector tiles. Their address changes each week and is read from the TileJSON at [_tileJsonUrl]; the
/// last one is kept on disk, so a launch after the first starts fetching tiles at once (and checks it in the
/// background). All requests share one client, so connections are reused.
class _NetworkTiles extends VectorTileProvider {
  _NetworkTiles(this._tileJsonUrl) {
    _template = _resolve();
  }
  final String _tileJsonUrl;
  late Future<String> _template;
  static final _client = RetryClient(http.Client());

  /// OpenFreeMap's tiles stop at 14 (higher zooms draw from them); the TileJSON says so too.
  @override
  int get maximumZoom => 14;
  @override
  int get minimumZoom => 0;
  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;

  int _count = 0;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final response = await _client.get(Uri.parse(_url(await _template, tile)));
    if (response.statusCode == 404 && !_refetched) {
      // Last week's tiles may be gone: read the TileJSON again, once
      _refetched = true;
      _template = _fetch();
      return provide(tile);
    }
    if (response.statusCode != 200) {
      throw ProviderException(
        message: 'Cannot retrieve tile: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500 || response.statusCode == 429 ? Retryable.retry : Retryable.none,
      );
    }
    StartupTimings.mark('Map: first tile downloaded');
    StartupTimings.mark('Map: tiles downloaded', latest: true, detail: '${++_count}');
    return response.bodyBytes;
  }

  bool _refetched = false;

  static String _url(String template, TileIdentity t) =>
      template.replaceAll('{z}', '${t.z}').replaceAll('{x}', '${t.x}').replaceAll('{y}', '${t.y}');

  Future<String> _resolve() async {
    final file = await _cacheFile();
    try {
      if (file != null && await file.exists()) {
        final cached = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final template = cached['template'] as String;
        StartupTimings.mark('Map: tile list from disk');
        // Check for a newer week's tiles in the background (used from the next tile on)
        if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cached['at'] as int)) > const Duration(hours: 12)) {
          unawaited(_fetch().then((t) => _template = Future.value(t), onError: (Object _) {}));
        }
        return template;
      }
    } catch (_) {
      // a damaged file: fetch it again
    }
    return _fetch();
  }

  Future<String> _fetch() async {
    final response = await _client.get(Uri.parse(_tileJsonUrl));
    final template = ((jsonDecode(response.body) as Map<String, dynamic>)['tiles'] as List).first as String;
    StartupTimings.mark('Map: tile list fetched (network)');
    final file = await _cacheFile();
    unawaited(file?.writeAsString(jsonEncode({'template': template, 'at': DateTime.now().millisecondsSinceEpoch})).then((_) {}, onError: (Object _) {}));
    return template;
  }

  static Future<File?> _cacheFile() async {
    if (kIsWeb) return null;
    try {
      return File('${(await getApplicationSupportDirectory()).path}/openfreemap-tilejson.json');
    } catch (_) {
      return null;
    }
  }
}

/// The map's tiles as a flutter_map layer: what VectorTileLayer (raster mode) draws, plus the baked tiles. The tiles
/// on screen load first (nearest the middle first), then a ring around them, for panning.
class TripTileLayer extends StatefulWidget {
  const TripTileLayer({super.key, required this.source});
  final MapSource source;

  @override
  State<TripTileLayer> createState() => _TripTileLayerState();
}

class _TripTileLayerState extends State<TripTileLayer> {
  late final _provider = _TripTileProvider(widget.source, onSettled: _settled);

  void _settled() => StartupTimings.mark('Map: all tiles in (the screen and a ring around it)',
      detail: '${_provider.drawnCount} drawn on the phone, ${_provider.bakedCount} baked');

  @override
  Widget build(BuildContext context) => fm.TileLayer(
        maxZoom: 18,
        maxNativeZoom: 18,
        evictErrorTileStrategy: fm.EvictErrorTileStrategy.notVisible,
        tileProvider: _provider,
      );
}

/// Baked tiles from the assets, the others drawn by vector_map_tiles; tells the layer when nothing is left loading.
class _TripTileProvider extends fm.TileProvider {
  _TripTileProvider(this.source, {required this.onSettled});
  final MapSource source;
  final VoidCallback onSettled;
  int _loading = 0, drawnCount = 0, bakedCount = 0;

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(fm.TileCoordinates c, fm.TileLayer options, Future<void> cancelLoading) {
    final baked = source.bundled.contains('${c.z}-${c.x}-${c.y}');
    final inner = baked ? AssetImage('${MapTiles.bundleDir}/${c.z}-${c.x}-${c.y}.webp') : source.drawn.getImageWithCancelLoadingSupport(c, options, cancelLoading);
    return _Watched(inner, () => _loading++, (ok) {
      _loading--;
      if (ok) {
        baked ? bakedCount++ : drawnCount++;
        StartupTimings.mark('Map: first tile drawn', detail: baked ? 'baked' : 'drawn on the phone');
      }
      if (_loading == 0) onSettled();
    });
  }
}

/// [inner], reporting when its image is there (or failed, or is no longer wanted), also when it comes from the image
/// cache. Its stream forwards the inner one and lets go of it when flutter_map does, so a tile pruned mid-way still
/// cancels its drawing.
class _Watched extends ImageProvider<Object> {
  _Watched(this.inner, this.onStart, this.onDone);
  final ImageProvider inner;
  final VoidCallback onStart;
  final void Function(bool ok) onDone;

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) => inner.obtainKey(configuration);

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) => _Forwarding(inner.loadImage(key, decode));

  @override
  void resolveStreamForKey(ImageConfiguration configuration, ImageStream stream, Object key, ImageErrorListener handleError) {
    super.resolveStreamForKey(configuration, stream, key, handleError);
    final completer = stream.completer;
    if (completer is _Forwarding) {
      onStart();
      completer.whenDone(onDone);
    }
  }
}

class _Forwarding extends ImageStreamCompleter {
  _Forwarding(this._inner) {
    _listener = ImageStreamListener(
      (image, _) {
        _finish(true);
        setImage(image);
      },
      onError: (Object e, StackTrace? s) {
        _finish(false);
        reportError(exception: e, stack: s, silent: true);
      },
    );
    _inner.addListener(_listener);
    addOnLastListenerRemovedCallback(() {
      _inner.removeListener(_listener);
      _finish(false);
    });
  }
  final ImageStreamCompleter _inner;
  late final ImageStreamListener _listener;
  bool? _ok;
  final _waiting = <void Function(bool ok)>[];

  void whenDone(void Function(bool ok) f) => _ok == null ? _waiting.add(f) : f(_ok!);

  void _finish(bool ok) {
    if (_ok != null) return;
    _ok = ok;
    for (final f in _waiting) {
      f(ok);
    }
    _waiting.clear();
  }
}
