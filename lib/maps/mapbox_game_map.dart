import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../models/quest_location.dart';
import '../models/map_spawn.dart';
import '../models/animal_metadata.dart';

import 'dart:math' as math;

class MapboxGameMap extends StatefulWidget {
  final LatLng playerPosition;
  final List<QuestLocation> locations;
  final Set<String> visited;
  final String playerAsset;
  final String? nearestLocationId;
  final List<MapSpawn> activeSpawns;
  final LatLng? fruitMarketPosition;
  final LatLng? animalMarketPosition;
  final Future<bool> Function(String spawnId)? onSpawnTapped;
  final bool showHud;

  const MapboxGameMap({
    super.key,
    required this.playerPosition,
    required this.locations,
    required this.visited,
    required this.playerAsset,
    required this.nearestLocationId,
    required this.activeSpawns,
    this.fruitMarketPosition,
    this.animalMarketPosition,
    this.onSpawnTapped,
    this.showHud = true,
  });

  @override
  State<MapboxGameMap> createState() => _MapboxGameMapState();
}

class _MapboxGameMapState extends State<MapboxGameMap>
    with SingleTickerProviderStateMixin {
  MapboxMap? mapboxMap;
  bool styleReady = false;
  bool autoFollow = false;
  bool initialCameraSet = false;
  bool _isIntroAnimating = false;
  bool _introFinished = false;
  double _mapBearing = 0.0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  double _bearingDeltaToNorth(double bearing) {
    final normalized = (bearing % 360 + 360) % 360;
    return math.min(normalized, 360 - normalized);
  }

  double _metersToPixels(double meters, double latitude, double zoom) {
    const earthCircumference = 40075016.686; // meters
    final latitudeRadians = latitude * (3.141592653589793 / 180);
    final metersPerPixel = earthCircumference *
        math.cos(latitudeRadians) /
        (256 * math.pow(2, zoom));

    return meters / metersPerPixel;
  }

  @override
  void initState() {
    super.initState();

    MapboxOptions.setAccessToken(
      const String.fromEnvironment('MAPBOX_TOKEN',
          defaultValue:
              ''),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 10, // meters
      end: 100, // meters
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _pulseAnimation.addListener(() {
      if (mapboxMap != null && styleReady) {
        _updatePulseRadius();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;

    // geen const: de constructors zijn niet const
    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await map.compass.updateSettings(CompassSettings(enabled: false));
    await map.logo.updateSettings(LogoSettings(enabled: false));
    await map.attribution.updateSettings(AttributionSettings(enabled: false));

    // geen subscription hier; map clicks worden afgehandeld door MapWidget's
    // onMapClickListener (zie build)
  }

  // map click handler (gebruikt mapboxMap om features op te vragen)
  Future<void> _onMapClicked(MapContentGestureContext context) async {
    if (mapboxMap == null) return;
    final screenCoordinate = ScreenCoordinate(
      x: context.touchPosition.x,
      y: context.touchPosition.y,
    );
    final features = await mapboxMap!.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(screenCoordinate),
      RenderedQueryOptions(layerIds: ['spawn-layer']),
    );
    if (features.isEmpty) return;
    final tappedId = features.first?.queriedFeature.feature['id']?.toString();
    if (tappedId == null) return;
    final spawnIndex = widget.activeSpawns.indexWhere((s) => s.id == tappedId);
    if (spawnIndex == -1) return;
    final spawn = widget.activeSpawns[spawnIndex];
    if (!spawn.isVisible || spawn.isFading || spawn.isCollected) return;
    await _fadeOutSpawn(spawn);
  }

  Future<void> _fadeOutSpawn(MapSpawn spawn) async {
    if (spawn.isFading || spawn.isCollected) return;
    spawn.isFading = true;

    const steps = 12;
    const stepDelay = Duration(milliseconds: 60);

    for (var i = 1; i <= steps; i++) {
      spawn.opacity = (1.0 - (i / steps)).clamp(0.0, 1.0);
      await _updateSpawnSource();
      await Future.delayed(stepDelay);
    }

    spawn.isVisible = false;
    spawn.opacity = 0.0;
    await _updateSpawnSource();
    final didCollect = await widget.onSpawnTapped?.call(spawn.id) ?? true;
    if (!didCollect) {
      spawn.isFading = false;
      spawn.isVisible = true;
      spawn.opacity = 1.0;
      await _updateSpawnSource();
    }
  }

  // parameter krijgt expliciet type zodat analyzer stopt te klagen
  void _onStyleLoaded(dynamic _) {
    styleReady = true;
    _updateMap();
    // after style is ready we can evaluate water proximity for marine spawns
    _filterMarineSpawns();
  }

  Future<void> _updatePulseRadius() async {
    if (mapboxMap == null) return;

    final style = mapboxMap!.style;
    final radiusInMeters = _pulseAnimation.value;

    final cameraState = await mapboxMap!.getCameraState();
    final zoom = cameraState.zoom;
    final latitude = widget.playerPosition.latitude;

    final radiusInPixels = _metersToPixels(radiusInMeters, latitude, zoom);

    final progress = (radiusInMeters - 10) / (100 - 10);
    final opacity = 1 - progress;

    if (!await style.styleLayerExists('player-pulse')) {
      await style.addLayer(
        CircleLayer(
          id: 'player-pulse',
          sourceId: 'player-source',
          circleRadius: radiusInPixels,
          circleColor: 0x33203066,
          circleOpacity: opacity,
          circleStrokeColor: 0xFF1F2A66,
          circleStrokeWidth: 3.0,
          circleStrokeOpacity: opacity,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circlePitchScale: CirclePitchScale.MAP,
        ),
      );
    }

    await style.setStyleLayerProperty(
      'player-pulse',
      'circle-radius',
      radiusInPixels,
    );

    await style.setStyleLayerProperty(
      'player-pulse',
      'circle-opacity',
      opacity,
    );

    await style.setStyleLayerProperty(
      'player-pulse',
      'circle-stroke-opacity',
      opacity,
    );

    // also animate quest pulse radius/opacity to give a breathing effect
    if (await style.styleLayerExists('quest-pulse')) {
      // make the pulse grow/shrink more noticeably
      final questRadiusMeters = 20 + (radiusInMeters - 10) * 0.5; // 20->~55
      final questRadiusPixels =
          _metersToPixels(questRadiusMeters, latitude, zoom);
      final questOpacity = 0.6 + (opacity * 0.4);
      await style.setStyleLayerProperty(
        'quest-pulse',
        'circle-radius',
        questRadiusPixels,
      );
      await style.setStyleLayerProperty(
        'quest-pulse',
        'circle-opacity',
        questOpacity,
      );
    }

    // animate the quest icon's size for additional visual feedback
    if (await style.styleLayerExists('quest-layer')) {
      // simple oscillation based on the same opacity value used above
      final baseSize = 0.03;
      final iconScale = baseSize * (0.85 + 0.30 * (1 - opacity));
      await style.setStyleLayerProperty('quest-layer', 'icon-size', iconScale);
    }
  }

  @override
  void didUpdateWidget(covariant MapboxGameMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (styleReady && mapboxMap != null) {
      _updateMap();
      // new spawns may have arrived – make sure marine animals are clipped
      _filterMarineSpawns();
    }
  }

  Future<void> _startIntroCameraZoom() async {
    if (mapboxMap == null || _isIntroAnimating || _introFinished) return;
    _isIntroAnimating = true;

    const startZoom = 1.5;
    const endZoom = 17.5;
    const steps = 60;
    const stepDelay = Duration(milliseconds: 83);

    for (var i = 0; i <= steps; i++) {
      if (!mounted || mapboxMap == null) break;
      final t = i / steps;
      final eased = Curves.easeOutCubic.transform(t);
      final zoom = startZoom + (endZoom - startZoom) * eased;

      await mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              widget.playerPosition.longitude,
              widget.playerPosition.latitude,
            ),
          ),
          zoom: zoom,
        ),
      );
      await Future.delayed(stepDelay);
    }

    _isIntroAnimating = false;
    _introFinished = true;
    initialCameraSet = true;
  }

  Future<void> _updateMap() async {
    if (!styleReady || mapboxMap == null) return;
    final style = mapboxMap!.style;
    final player = widget.playerPosition;

    // camera positioning (gebruik Position voor Point coördinaten)
    if (!initialCameraSet) {
      if (!_introFinished && !_isIntroAnimating) {
        _startIntroCameraZoom();
      }
    } else if (autoFollow) {
      await mapboxMap!.setCamera(CameraOptions(
        center: Point(
          coordinates: Position(player.longitude, player.latitude),
        ),
        zoom: 17.5,
      ));
    }
    await mapboxMap!.location
        .updateSettings(LocationComponentSettings(enabled: false));

    // --- load images -------------------------------------------------------
    // player avatar
    if (await style.getStyleImage('player-avatar') == null) {
      final data = await rootBundle.load(widget.playerAsset);
      final bytes = data.buffer.asUint8List();
      final img = await decodeImageFromList(bytes);
      await style.addStyleImage(
        'player-avatar',
        1.0,
        MbxImage(width: img.width, height: img.height, data: bytes),
        false,
        [],
        [],
        null,
      );
    }

    // quest icons (bronze/silver/gold)
    for (final name in ['quest_bronze', 'quest_silver', 'quest_gold']) {
      if (await style.getStyleImage(name) == null) {
        final data = await rootBundle.load('assets/$name.png');
        final bytes = data.buffer.asUint8List();
        final img = await decodeImageFromList(bytes);
        await style.addStyleImage(
          name,
          1.0,
          MbxImage(width: img.width, height: img.height, data: bytes),
          false,
          [],
          [],
          null,
        );
      }
    }

    // fruit market icon
    if (await style.getStyleImage('fruit-market') == null) {
      try {
        final data = await rootBundle.load('assets/fruitmarket.png');
        final bytes = data.buffer.asUint8List();
        final img = await decodeImageFromList(bytes);
        await style.addStyleImage(
          'fruit-market',
          1.0,
          MbxImage(width: img.width, height: img.height, data: bytes),
          false,
          [],
          [],
          null,
        );
      } catch (e) {
        // If the asset isn't in pubspec yet, we don't want the entire map HUD to disappear.
        debugPrint('fruit market icon load failed: $e');
      }
    }

    // animal market icon
    if (await style.getStyleImage('animal-market') == null) {
      try {
        final data = await rootBundle.load('assets/animalmarket.png');
        final bytes = data.buffer.asUint8List();
        final img = await decodeImageFromList(bytes);
        await style.addStyleImage(
          'animal-market',
          1.0,
          MbxImage(width: img.width, height: img.height, data: bytes),
          false,
          [],
          [],
          null,
        );
      } catch (e) {
        debugPrint('animal market icon load failed: $e');
      }
    }

    // spawn icons
    for (final spawn in widget.activeSpawns) {
      final iconName = spawn.asset;
      if (await style.getStyleImage(iconName) == null) {
        final path = spawn.type == SpawnType.animal
            ? 'assets/animals/icons_300/$iconName.png'
            : 'assets/seeds/icons_300/$iconName.png';
        try {
          final data = await rootBundle.load(path);
          final bytes = data.buffer.asUint8List();
          final img = await decodeImageFromList(bytes);
          await style.addStyleImage(
            iconName,
            1.0,
            MbxImage(width: img.width, height: img.height, data: bytes),
            false,
            [],
            [],
            null,
          );
        } catch (e) {
          debugPrint('spawn icon $path load failed: $e');
        }
      }
    }

    // --- update sources ----------------------------------------------------
    final playerGeoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': <num>[player.longitude, player.latitude],
          }
        }
      ]
    };
    if (!await style.styleSourceExists('player-source')) {
      await style.addSource(GeoJsonSource(
        id: 'player-source',
        data: jsonEncode(playerGeoJson),
      ));
    } else {
      final src = await style.getSource('player-source') as GeoJsonSource;
      await src.updateGeoJSON(jsonEncode(playerGeoJson));
    }

    final questGeoJson = {
      'type': 'FeatureCollection',
      'features': widget.locations
          .map((loc) => {
                'type': 'Feature',
                'properties': {'icon': loc.icon},
                'geometry': {
                  'type': 'Point',
                  'coordinates': <num>[loc.longitude, loc.latitude]
                }
              })
          .toList(),
    };
    if (!await style.styleSourceExists('quest-source')) {
      await style.addSource(GeoJsonSource(
        id: 'quest-source',
        data: jsonEncode(questGeoJson),
      ));
    } else {
      final src = await style.getSource('quest-source') as GeoJsonSource;
      await src.updateGeoJSON(jsonEncode(questGeoJson));
    }

    final spawnGeoJson = _buildSpawnGeoJson();
    if (!await style.styleSourceExists('spawn-source')) {
      await style.addSource(GeoJsonSource(
        id: 'spawn-source',
        data: jsonEncode(spawnGeoJson),
      ));
    } else {
      final src = await style.getSource('spawn-source') as GeoJsonSource;
      await src.updateGeoJSON(jsonEncode(spawnGeoJson));
    }

    final marketPos = widget.fruitMarketPosition;
    final marketGeoJson = {
      'type': 'FeatureCollection',
      'features': marketPos == null
          ? []
          : [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': <num>[marketPos.longitude, marketPos.latitude]
                }
              }
            ],
    };
    if (!await style.styleSourceExists('market-source')) {
      await style.addSource(GeoJsonSource(
        id: 'market-source',
        data: jsonEncode(marketGeoJson),
      ));
    } else {
      final src = await style.getSource('market-source') as GeoJsonSource;
      await src.updateGeoJSON(jsonEncode(marketGeoJson));
    }

    final animalMarketPos = widget.animalMarketPosition;
    final animalMarketGeoJson = {
      'type': 'FeatureCollection',
      'features': animalMarketPos == null
          ? []
          : [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': <num>[
                    animalMarketPos.longitude,
                    animalMarketPos.latitude,
                  ]
                }
              }
            ],
    };
    if (!await style.styleSourceExists('animal-market-source')) {
      await style.addSource(GeoJsonSource(
        id: 'animal-market-source',
        data: jsonEncode(animalMarketGeoJson),
      ));
    } else {
      final src = await style.getSource('animal-market-source') as GeoJsonSource;
      await src.updateGeoJSON(jsonEncode(animalMarketGeoJson));
    }

    // --- add layers if missing -------------------------------------------

    if (!await style.styleLayerExists('player-layer')) {
      await style.addLayer(SymbolLayer(
        id: 'player-layer',
        sourceId: 'player-source',
        iconImage: 'player-avatar',
        iconSize: 0.1,
        iconAnchor: IconAnchor.CENTER,
        iconAllowOverlap: true,
      ));
    }

    if (!await style.styleLayerExists('quest-pulse')) {
      await style.addLayer(
        CircleLayer(
          id: 'quest-pulse',
          sourceId: 'quest-source',
          // start with a slightly larger base radius so the pulse is visible
          circleRadius: 20,
          // more opaque red so it can be seen behind the icon
          circleColor: 0x88FF0000,
          circleBlur: 0.5,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circlePitchScale: CirclePitchScale.MAP,
        ),
      );
    }

    if (!await style.styleLayerExists('quest-layer')) {
      await style.addLayer(SymbolLayer(
        id: 'quest-layer',
        sourceId: 'quest-source',
        iconImage: 'quest_bronze', // temporary default
        // reduce to roughly 20% of the previous size
        iconSize: 0.03,
        iconAnchor: IconAnchor.CENTER,
        iconAllowOverlap: true,
      ));
    }
    // ensure iconImage uses per-feature property once layer exists
    await style.setStyleLayerProperty(
      'quest-layer',
      'icon-image',
      ['get', 'icon'],
    );
    if (!await style.styleLayerExists('spawn-layer')) {
      await style.addLayer(SymbolLayer(
        id: 'spawn-layer',
        sourceId: 'spawn-source',
        iconSize: 0.20,
        iconAllowOverlap: true,
      ));
    }

    if (!await style.styleLayerExists('market-layer')) {
      await style.addLayer(SymbolLayer(
        id: 'market-layer',
        sourceId: 'market-source',
        iconImage: 'fruit-market',
        // 150% of quest markers (quest-layer uses 0.03)
        iconSize: 0.045,
        iconAnchor: IconAnchor.CENTER,
        iconAllowOverlap: true,
      ));
    }

    if (!await style.styleLayerExists('animal-market-layer')) {
      await style.addLayer(SymbolLayer(
        id: 'animal-market-layer',
        sourceId: 'animal-market-source',
        iconImage: 'animal-market',
        iconSize: 0.045,
        iconAnchor: IconAnchor.CENTER,
        iconAllowOverlap: true,
      ));
    }
    await style.setStyleLayerProperty(
      'spawn-layer',
      'icon-size',
      [
        'interpolate',
        ['linear'],
        ['zoom'],
        12.0,
        [
          '*',
          0.10,
          [
            'coalesce',
            ['get', 'sizeScale'],
            1.0
          ],
          0.60
        ],
        16.0,
        [
          '*',
          0.10,
          [
            'coalesce',
            ['get', 'sizeScale'],
            1.0
          ],
          0.85
        ],
        19.0,
        [
          '*',
          0.10,
          [
            'coalesce',
            ['get', 'sizeScale'],
            1.0
          ],
          1.00
        ],
        22.0,
        [
          '*',
          0.10,
          [
            'coalesce',
            ['get', 'sizeScale'],
            1.0
          ],
          1.20
        ],
      ],
    );
    await style.setStyleLayerProperty(
      'spawn-layer',
      'icon-image',
      ['get', 'asset'],
    );
    await style.setStyleLayerProperty(
      'spawn-layer',
      'icon-opacity',
      [
        'coalesce',
        ['get', 'opacity'],
        1.0
      ],
    );
    // Apply silhouette effect for animals (dark color), keep seeds normal
    await style.setStyleLayerProperty(
      'spawn-layer',
      'icon-color',
      [
        'case',
        ['get', 'isAnimal'],
        '#333333', // Dark gray for animal silhouettes
        '#FFFFFF'  // White (original color) for seeds
      ],
    );
    // Add slight transparency to make silhouettes more mysterious
    await style.setStyleLayerProperty(
      'spawn-layer',
      'icon-color-alpha',
      [
        'case',
        ['get', 'isAnimal'],
        0.85, // Slightly transparent for animals
        1.0   // Fully opaque for seeds
      ],
    );
    if (await style.styleLayerExists('player-layer') &&
        await style.styleLayerExists('spawn-layer')) {
      await style.moveStyleLayer(
        'player-layer',
        LayerPosition(above: 'spawn-layer'),
      );
    }
  }

  // helper used by the water filter *if* you re‑enable that logic.
  // kept here for reference but the current stubbed filter does nothing, so
  // the analyzer may still warn that it's unused.  Feel free to delete it
  // once you implement real water‑checking code.
  // ignore: unused_element
  bool _isMarineAsset(String asset) {
    final meta = kAnimalMetadataByName[asset];
    return meta?.habitat == AnimalHabitat.marine;
  }

  /// scan visible spawns and query the map for "water" features at their
  /// location; any marine animal outside of water will be hidden.  the
  /// implementation here is illustrative – depending on the Mapbox plugin you
  /// may need to convert coordinates to screen pixels first or use a
  /// reverse‑geocode API instead.
  Future<void> _filterMarineSpawns() async {
    // this method is intentionally left as an example – the logic for
    // determining whether a given LatLng lies in or near a water feature
    // depends on the Mapbox plugin version and your data.  one common
    // solution is to call `queryRenderedFeatures` on the `'water'` layer at
    // the spawn's screen position, and hide the spawn if the feature list is
    // empty.  another approach is to perform a reverse‑geocode lookup and
    // inspect the returned place type.
    //
    // because the correct pixel‑conversion routine varies and the demo code
    // above would hide *every* marine animal (since we passed a constant
    // coordinate), we deliberately do nothing here.  replace this stub with
    // a real implementation when you hook in the actual Mapbox API.
  }

  Map<String, dynamic> _buildSpawnGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': widget.activeSpawns
          .map((s) => {
                'type': 'Feature',
                'id': s.id,
                'properties': {
                  'asset': s.asset,
                  'opacity': s.isVisible ? s.opacity : 0.0,
                  'isAnimal': s.type == SpawnType.animal,
                  'sizeScale': s.type == SpawnType.animal
                      ? getAnimalMapSizeMultiplier(s.asset)
                      : getSeedMapSizeMultiplier(s.asset),
                },
                'geometry': {
                  'type': 'Point',
                  'coordinates': <num>[
                    s.position.longitude,
                    s.position.latitude,
                  ]
                }
              })
          .toList(),
    };
  }

  Future<void> _updateSpawnSource() async {
    if (!styleReady || mapboxMap == null) return;
    final style = mapboxMap!.style;
    if (!await style.styleSourceExists('spawn-source')) return;
    final src = await style.getSource('spawn-source') as GeoJsonSource;
    await src.updateGeoJSON(jsonEncode(_buildSpawnGeoJson()));
  }

  @override
  Widget build(BuildContext context) {
    final showCompassInButton = _bearingDeltaToNorth(_mapBearing) > 0.5;

    return Stack(
      children: [
        MapWidget(
          styleUri: MapboxStyles.MAPBOX_STREETS,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onCameraChangeListener: (event) {
            if (!mounted) return;
            final newBearing = event.cameraState.bearing;
            if ((newBearing - _mapBearing).abs() < 0.1) return;
            setState(() => _mapBearing = newBearing);
          },
          // MapWidget gebruikt onMapClickListener (niet onMapClick)
          onTapListener: _onMapClicked,
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: AnimatedOpacity(
            duration: const Duration(seconds: 5),
            opacity: widget.showHud ? 1 : 0,
            child: Material(
              elevation: 6,
              color: autoFollow
                  ? const Color(0xFF1F2A66)
                  : const Color(0xFF11194A),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  setState(() => autoFollow = !autoFollow);
                  if (autoFollow && styleReady && mapboxMap != null) {
                    _updateMap();
                  }
                },
                onLongPress: showCompassInButton
                    ? () async {
                        if (mapboxMap == null) return;
                        final camera = await mapboxMap!.getCameraState();
                        await mapboxMap!.setCamera(
                          CameraOptions(
                            center: camera.center,
                            zoom: camera.zoom,
                            pitch: camera.pitch,
                            bearing: 0,
                          ),
                        );
                      }
                    : null,
                onDoubleTap: showCompassInButton
                    ? () async {
                        if (mapboxMap == null) return;
                        final camera = await mapboxMap!.getCameraState();
                        await mapboxMap!.setCamera(
                          CameraOptions(
                            center: camera.center,
                            zoom: camera.zoom,
                            pitch: camera.pitch,
                            bearing: 0,
                          ),
                        );
                      }
                    : null,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 140),
                        opacity: showCompassInButton ? 0.35 : 1.0,
                        child: Icon(
                          autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: const Color(0xFFFFCC00),
                        ),
                      ),
                      if (showCompassInButton)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: -_mapBearing * math.pi / 180,
                              child: const Opacity(
                                opacity: 0.25,
                                child: Icon(
                                  Icons.navigation,
                                  color: Color(0xFF5B6BFF),
                                  size: 38,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
