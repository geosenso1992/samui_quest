import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../maps/mapbox_game_map.dart';
import '../models/animal_metadata.dart';
import '../models/map_spawn.dart';
import '../models/minigame_result.dart';
import '../models/quest_location.dart';
import '../services/audio_service.dart';
import '../providers/game_provider.dart';
import 'quest_screen.dart';
import 'final_word_screen.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'my_garden_screen.dart';
import 'my_stats_screen.dart';
import 'research_screen.dart';
import 'flying_catch_minigame_screen.dart';
import 'land_net_trap_minigame_screen.dart';
import 'water_fishing_minigame_screen.dart';
import '../widgets/game_top_bar.dart';
import 'fruit_market_screen.dart';
import 'animal_market_screen.dart';


class MapScreen extends StatefulWidget {
  final dynamic selectedAvatar; 

  const MapScreen({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ✅ NIEUWE HELPER: Voorkomt de 'String is not a subtype of PlayerAvatar' crash
  String _getAvatarAssetPath() {
    // 1. Check of de avatar een object is met een assetPath (Nieuw spel)
    if (widget.selectedAvatar != null &&
        widget.selectedAvatar is! String &&
        widget.selectedAvatar.assetPath != null) {
      return widget.selectedAvatar.assetPath;
    }

    // 2. Als het een String is (bijv. opgeslagen asset pad), gebruik die
    if (widget.selectedAvatar is String &&
        (widget.selectedAvatar as String).isNotEmpty) {
      return widget.selectedAvatar as String;
    }

    // 3. Default avatar (tijdelijk altijd monkey)
    return 'assets/monkey_player.png';
  }

  bool _isNavigating = false;
  bool _isMarketNavigating = false;
  bool _marketWasInRange = false;
  bool _isAnimalMarketNavigating = false;
  bool _animalMarketWasInRange = false;
  static const double _dotRadius = 31;
  static const double _miniRadarSize = 80;
  static const double _miniRadarLeft = 20;
  static const double _uiGap = 12;
  static const double _coinIndicatorWidth = 86;
  static const double _coinIndicatorRight = 20;
  static const Color _hudPrimary = Color(0xFF1F2A66);
  static const Color _hudBorder = Color(0xFF11194A);
  static const Color _hudAccent = Color(0xFF5B6BFF);
  static const Color _hudGold = Color(0xFFFFCC00);
  bool _xpGlow = false;
  int? _floatingXp;
  bool _showXp = false;
  Timer? _walkingGuardTimer;
  Timer? _discoveryFadeTimer;
  Timer? _discoveryClearTimer;
  Timer? _collectToastFadeTimer;
  Timer? _collectToastClearTimer;
  Timer? _badgePopupTimer;
  bool _showDiscovery = false;
  String? _discoveryAssetPath;
  String? _discoveryTitle;
  String? _discoveryName;
  String? _discoveryRarityLabel;
  Color? _discoveryRarityColor;
  bool _showCollectToastVisible = false;
  String? _collectToastMessage;
  bool _showBadgePopup = false;
  String? _badgePopupMessage;
  bool _showIntroHud = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AudioService().setBackgroundVolume(0.06);
      if (!mounted) return;
      setState(() {
        _showIntroHud = true;
      });
    });
  }

  @override
  void dispose() {
    _walkingGuardTimer?.cancel();
    _discoveryFadeTimer?.cancel();
    _discoveryClearTimer?.cancel();
    _collectToastFadeTimer?.cancel();
    _collectToastClearTimer?.cancel();
    _badgePopupTimer?.cancel();
    super.dispose();
  }

  void _openQuestIfUnlocked(GameProvider game, QuestLocation? location) {
    if (_isNavigating) return;

    if (location != null &&
        game.isUnlocked(location.id) &&
        game.markVisited(location.id)) {
      _consumePendingBadges(game);
      _isNavigating = true;

      Future.microtask(() async {
        if (!mounted) return;
        final enriched = await game.enrichQuestWithAI(location);

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestScreen(location: enriched),
          ),
        );

        if (!mounted) return;
        _isNavigating = false;
      });
    }
  }

  void _maybeOpenFruitMarket(GameProvider game, LatLng playerLatLng) {
    final market = game.fruitMarketPosition;
    if (market == null) {
      _marketWasInRange = false;
      return;
    }

    final distanceMeters =
        const Distance().as(LengthUnit.Meter, playerLatLng, market);
    final inRange = distanceMeters <= 50;

    if (inRange && !_marketWasInRange && !_isMarketNavigating) {
      _isMarketNavigating = true;
      Future.microtask(() async {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        await navigator.push(
          MaterialPageRoute(builder: (_) => const FruitMarketScreen()),
        );
        if (!mounted) return;
        setState(() => _isMarketNavigating = false);
      });
    }

    _marketWasInRange = inRange;
  }

  void _maybeOpenAnimalMarket(GameProvider game, LatLng playerLatLng) {
    final market = game.animalMarketPosition;
    if (market == null) {
      _animalMarketWasInRange = false;
      return;
    }

    final distanceMeters =
        const Distance().as(LengthUnit.Meter, playerLatLng, market);
    final inRange = distanceMeters <= 50;

    if (inRange && !_animalMarketWasInRange && !_isAnimalMarketNavigating) {
      _isAnimalMarketNavigating = true;
      Future.microtask(() async {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        await navigator.push(
          MaterialPageRoute(builder: (_) => const AnimalMarketScreen()),
        );
        if (!mounted) return;
        setState(() => _isAnimalMarketNavigating = false);
      });
    }

    _animalMarketWasInRange = inRange;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLon = (end.longitude - start.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  Offset _radarDotPosition(double angleRad, double radius) {
    final x = radius * math.sin(angleRad);
    final y = -radius * math.cos(angleRad);
    return Offset(x, y);
  }

  void _triggerXpGlow() {
    setState(() {
      _xpGlow = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _xpGlow = false;
        });
      }
    });
  }

  void _showFloatingXp(int amount) {
    setState(() {
      _floatingXp = amount;
      _showXp = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showXp = false;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _floatingXp = null;
        });
      }
    });
  }

  String _toDisplayName(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split(RegExp(r'[_\-\s]+'))
        .where((p) => p.isNotEmpty)
        .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
        .join(' ');
  }

  void _goHome() {
    context.read<GameProvider>().persistNow();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(showMenuImmediately: true),
      ),
      (route) => false,
    );
  }

  void _showDiscoveryPopup({
    required String assetPath,
    required String title,
    required String name,
    String? rarityLabel,
    Color? rarityColor,
  }) {
    _discoveryFadeTimer?.cancel();
    _discoveryClearTimer?.cancel();

    setState(() {
      _discoveryAssetPath = assetPath;
      _discoveryTitle = title;
      _discoveryName = name;
      _discoveryRarityLabel = rarityLabel;
      _discoveryRarityColor = rarityColor;
      _showDiscovery = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showDiscovery = true;
      });
    });

    _discoveryFadeTimer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      setState(() {
        _showDiscovery = false;
      });
    });

    _discoveryClearTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _discoveryAssetPath = null;
        _discoveryTitle = null;
        _discoveryName = null;
        _discoveryRarityLabel = null;
        _discoveryRarityColor = null;
      });
    });
  }

  void _showCollectToast(String message) {
    _collectToastFadeTimer?.cancel();
    _collectToastClearTimer?.cancel();

    setState(() {
      _collectToastMessage = message;
      _showCollectToastVisible = true;
    });

    _collectToastFadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _showCollectToastVisible = false;
      });
    });

    _collectToastClearTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _collectToastMessage = null;
      });
    });
  }

  void _showBadgePopupMessage(List<String> badgeTitles) {
    if (badgeTitles.isEmpty) return;

    _badgePopupTimer?.cancel();
    final first = badgeTitles.first;
    final remaining = badgeTitles.length - 1;
    final message = remaining > 0
        ? "New badges unlocked:\n$first (+$remaining more)"
        : "New badge unlocked:\n$first";

    AudioService().playNewBadge();

    setState(() {
      _badgePopupMessage = message;
      _showBadgePopup = true;
    });

    _badgePopupTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _showBadgePopup = false;
        _badgePopupMessage = null;
      });
    });
  }

  void _dismissBadgePopup() {
    _badgePopupTimer?.cancel();
    setState(() {
      _showBadgePopup = false;
      _badgePopupMessage = null;
    });
  }

  void _consumePendingBadges(GameProvider game) {
    final badges = game.consumePendingBadgeTitles();
    if (badges.isEmpty) return;
    _showBadgePopupMessage(badges);
  }

  bool _isFlyingAnimal(String animalId) {
    final meta = kAnimalMetadataByName[animalId];
    return meta?.habitat == AnimalHabitat.air;
  }

  bool _isMarineAnimal(String animalId) {
    final meta = kAnimalMetadataByName[animalId];
    return meta?.habitat == AnimalHabitat.marine;
  }

  bool _isLandAnimal(String animalId) {
    final meta = kAnimalMetadataByName[animalId];
    return meta?.habitat == AnimalHabitat.land;
  }

  Future<bool> _collectSpawnAfterInteraction(
      GameProvider game, MapSpawn spawn) async {
    final navigator = Navigator.of(context);
    var bonusXpFromMiniGame = 0;

    // ✅ FIX: We gebruiken hier _getAvatarAssetPath() in plaats van widget.selectedAvatar.assetPath
    final safeAvatarPath = _getAvatarAssetPath();

    if (spawn.type == SpawnType.animal && _isFlyingAnimal(spawn.asset)) {
      final allowMidAir =
          game.getResearchLevel(ResearchUpgrade.spawnRadius) >= 2;
      final result = await navigator.push<MiniGameResult>(
        MaterialPageRoute(
          builder: (_) => FlyingCatchMiniGameScreen(
            animalId: spawn.asset,
            animalName: _toDisplayName(spawn.asset),
            allowMidAirAdjustment: allowMidAir,
            avatarAssetPath: safeAvatarPath,
          ),
        ),
      );
      if (result?.didCatch != true) {
        _showCollectToast("${_toDisplayName(spawn.asset)} escaped!");
        return false;
      }
      bonusXpFromMiniGame = result?.bonusXp ?? 0;
    }
    if (spawn.type == SpawnType.animal && _isMarineAnimal(spawn.asset)) {
      final hasReelBoost =
          game.getResearchLevel(ResearchUpgrade.moreAnimals) >= 2;
      final hasLineElasticity =
          game.getResearchLevel(ResearchUpgrade.spawnRadius) >= 3;
      final hasPredictiveRipple =
          game.getResearchLevel(ResearchUpgrade.rareSpawns) >= 2 ||
              game.getResearchLevel(ResearchUpgrade.specialSpawns) >= 1;

      final result = await navigator.push<MiniGameResult>(
        MaterialPageRoute(
          builder: (_) => WaterFishingMiniGameScreen(
            animalId: spawn.asset,
            animalName: _toDisplayName(spawn.asset),
            avatarAssetPath: safeAvatarPath,
            hasReelBoost: hasReelBoost,
            hasLineElasticity: hasLineElasticity,
            hasPredictiveRipple: hasPredictiveRipple,
          ),
        ),
      );
      if (result?.didCatch != true) {
        _showCollectToast("${_toDisplayName(spawn.asset)} slipped away!");
        return false;
      }
      bonusXpFromMiniGame = result?.bonusXp ?? 0;
    }
    if (spawn.type == SpawnType.animal && _isLandAnimal(spawn.asset)) {
      final allowExtraBait =
          game.getResearchLevel(ResearchUpgrade.moreAnimals) >= 2;
      final allowExtraSlowTrap =
          game.getResearchLevel(ResearchUpgrade.spawnRadius) >= 3;
      final result = await navigator.push<MiniGameResult>(
        MaterialPageRoute(
          builder: (_) => LandNetTrapMiniGameScreen(
            animalId: spawn.asset,
            animalName: _toDisplayName(spawn.asset),
            avatarAssetPath: safeAvatarPath,
            allowExtraBait: allowExtraBait,
            allowExtraSlowTrap: allowExtraSlowTrap,
          ),
        ),
      );
      if (result?.didCatch != true) {
        _showCollectToast("${_toDisplayName(spawn.asset)} got away!");
        return false;
      }
      bonusXpFromMiniGame = result?.bonusXp ?? 0;
    }

    final isFirstUnlock = spawn.type == SpawnType.animal
        ? !game.isAnimalUnlocked(spawn.asset)
        : !game.isSeedUnlocked(spawn.asset);
    final baseXp = game.collectSpawn(spawn);
    if (bonusXpFromMiniGame > 0) {
      game.addXP(bonusXpFromMiniGame);
    }
    final xpGained = baseXp + bonusXpFromMiniGame;
    if (isFirstUnlock) {
      AudioService().playNewObjectUnlocked();
    } else {
      AudioService().playCollect();
    }
    _consumePendingBadges(game);
    _triggerXpGlow();
    _showFloatingXp(xpGained);
    if (isFirstUnlock) {
      final isAnimal = spawn.type == SpawnType.animal;
      final masterPath = isAnimal
          ? "assets/animals/master/${spawn.asset}.png"
          : "assets/seeds/master/${spawn.asset}.png";
      final rarity = isAnimal
          ? (kAnimalMetadataByName[spawn.asset]?.rarity ?? AnimalRarity.common)
          : null;
      _showDiscoveryPopup(
        assetPath: masterPath,
        title: isAnimal ? "New animal found!" : "New seed found!",
        name: _toDisplayName(spawn.asset),
        rarityLabel: rarity != null ? _toDisplayName(rarity.name) : null,
        rarityColor: rarity != null ? getRarityBorderColor(rarity) : null,
      );
    } else {
      _showCollectToast("${_toDisplayName(spawn.asset)} collected!");
    }
    return true;
  }

  Widget _buildXpBar(GameProvider game) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Level ${game.level}  •  ${game.xp} / ${game.xpNeeded} XP",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final progress = game.xpNeeded == 0
                      ? 0.0
                      : (game.xp / game.xpNeeded).clamp(0.0, 1.0);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _xpGlow ? _hudAccent : _hudBorder,
                        width: _xpGlow ? 5 : 3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          color: Colors.white24,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 8,
                          width: constraints.maxWidth * progress,
                          color: _hudPrimary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRadar(
    GameProvider game,
    LatLng playerLatLng,
    QuestLocation? nearest,
    double heading,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _hudBorder, width: 3),
          ),
        ),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        ...game.locations.map((loc) {
          final completed = game.visitedLocations.contains(loc.id);
          final questPoint = LatLng(loc.latitude, loc.longitude);
          final bearing = _calculateBearing(playerLatLng, questPoint);
          final relativeBearing = (bearing - heading + 360) % 360;
          final angleRad = relativeBearing * math.pi / 180;
          final offset = _radarDotPosition(angleRad, _dotRadius);

          return Transform.translate(
            offset: offset,
            child: Icon(
              completed ? Icons.check : Icons.question_mark,
              size: 14,
              color: completed
                  ? Colors.green
                  : () {
                      // determine colour by quest icon name
                      switch (loc.icon) {
                        case 'quest_gold':
                          return Colors.amber;
                        case 'quest_silver':
                          return Colors.grey;
                        case 'quest_bronze':
                          return Colors.brown;
                        default:
                          return Colors.orange;
                      }
                    }(),
            ),
          );
        }),
        Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: CustomPaint(
                size: const Size(60, 60),
                painter: const _ConePainter(color: Color(0xFF5B6BFF)),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: _hudAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final heading = game.heading;
    final position = game.currentPosition;
    final locations = game.locations;

    if (position == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final playerLatLng = LatLng(position.latitude, position.longitude);
    final nearest = game.nearestLocation;
    final nearestDistance = game.nearestDistance;
    final xpLeft = _miniRadarLeft + _miniRadarSize + _uiGap;
    final xpRight = _coinIndicatorRight + _coinIndicatorWidth + _uiGap;

    _openQuestIfUnlocked(game, nearest);
    _maybeOpenFruitMarket(game, playerLatLng);
    _maybeOpenAnimalMarket(game, playerLatLng);

    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          // 🗺️ MAP (1x!)
          MapboxGameMap(
            playerPosition: playerLatLng,
            locations: locations,
            visited: game.visitedLocations,
            playerAsset: _getAvatarAssetPath(), // We gebruiken onze nieuwe veilige helper!
            nearestLocationId: nearest?.id,
            activeSpawns: game.activeSpawns,
            showHud: _showIntroHud,
            fruitMarketPosition: game.fruitMarketPosition,
            animalMarketPosition: game.animalMarketPosition,
            onSpawnTapped: (spawnId) async {
              final spawnIndex =
                  game.activeSpawns.indexWhere((s) => s.id == spawnId);
              if (spawnIndex == -1) return false;
              final spawn = game.activeSpawns[spawnIndex];
              return _collectSpawnAfterInteraction(game, spawn);
            },
          ),
          if (locations.isEmpty)
            Positioned(
              top: 140,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _showIntroHud ? 1 : 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hudAccent.withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: const Text(
                        "Loading nearby quests…",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 86,
            right: _coinIndicatorRight,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 5),
              opacity: _showIntroHud ? 1 : 0,
              child: _CoinIndicator(coins: game.coins),
            ),
          ),

          // 🧭 TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
              child: SafeArea(
                bottom: false,
                child: GameTopBar(
                  onHomeTap: _goHome,
                  onMapTap: () {},
                  onCollectionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CollectionScreen()),
                  );
                },
                onTrophyTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FinalWordScreen()),
                  );
                },
                onResearchTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResearchScreen()),
                  );
                },
                onGardenTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyGardenScreen()),
                  );
                },
                  onStatsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyStatsScreen()),
                    );
                  },
                  currentTab: GameTopTab.map,
                  showCollectionBadge: game.hasUnseenCollectionItems,
                  showTrophyBadge: game.hasUnseenBadges,
                  showResearchBadge: game.hasAffordableResearch,
                ),
              ),
            ),

          // FLOATING XP
           if (_floatingXp != null)
             Positioned(
               top: 122,
               left: xpLeft,
               right: xpRight,
               child: AnimatedOpacity(
                duration: const Duration(seconds: 5),
                opacity: _showIntroHud ? 1 : 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _showXp ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 600),
                      offset: _showXp ? const Offset(0, 0.3) : Offset.zero,
                    child: Text(
                      "+$_floatingXp XP",
                      style: const TextStyle(
                        color: _hudAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),

          // XP BAR
           Positioned(
             top: 86,
             left: xpLeft,
             right: xpRight,
             child: AnimatedOpacity(
               duration: const Duration(seconds: 5),
               opacity: _showIntroHud ? 1 : 0,
               child: _buildXpBar(game),
            ),
          ),

          // MINI RADAR
          Positioned(
            top: 86,
            left: _miniRadarLeft,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 5),
              opacity: _showIntroHud ? 1 : 0,
              child: _buildMiniRadar(
                game,
                playerLatLng,
                nearest,
                heading,
              ),
            ),
          ),

          // DISTANCE BAR
          Positioned(
            bottom: 25,
            left: 80,
            right: 80,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 5),
              opacity: _showIntroHud ? 1 : 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _hudPrimary.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _hudBorder, width: 2),
                ),
                child: Text(
                  "Nearest quest: ${nearestDistance.toStringAsFixed(0)} meters",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _hudGold,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (_collectToastMessage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showCollectToastVisible ? 1 : 0,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 240),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hudAccent.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        _collectToastMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_discoveryAssetPath != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 420),
                          opacity: _showDiscovery ? 1 : 0,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 420),
                            scale: _showDiscovery ? 1 : 0.95,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.56,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8D6B4).withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _discoveryRarityColor ??
                                      const Color(0xFF8D6E63),
                                  width: 1.4,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Image.asset(
                                      _discoveryAssetPath!,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _discoveryTitle ?? "",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF5D4037),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _discoveryName ?? "",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF3E2723),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_discoveryRarityLabel != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _discoveryRarityLabel!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _discoveryRarityColor ??
                                            const Color(0xFF5D4037),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: -6,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 420),
                            opacity: _showDiscovery ? 0.9 : 0,
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFFE082),
                              size: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: -8,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 420),
                            opacity: _showDiscovery ? 0.7 : 0,
                            child: const Icon(
                              Icons.star,
                              color: Color(0xFFFFD54F),
                              size: 14,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -6,
                          right: 16,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 420),
                            opacity: _showDiscovery ? 0.8 : 0,
                            child: const Icon(
                              Icons.star,
                              color: Color(0xFFFFD54F),
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          if (_badgePopupMessage != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissBadgePopup,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showBadgePopup ? 1 : 0,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.84),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.amber,
                            width: 1.4,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: _dismissBadgePopup,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _badgePopupMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFC107),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                    ),
                                    onPressed: () {
                                      _dismissBadgePopup();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FinalWordScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "To achievements",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConePainter extends CustomPainter {
  final Color color;

  const _ConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
              colors: [color.withValues(alpha: 0.8), Colors.transparent])
          .createShader(
        Rect.fromCircle(center: center, radius: size.width / 2),
      );
    final path = ui.Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(Rect.fromCircle(center: center, radius: size.width / 2),
        -math.pi / 4, math.pi / 2, false);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _CoinIndicator extends StatefulWidget {
  final int coins;

  const _CoinIndicator({required this.coins});

  @override
  State<_CoinIndicator> createState() => _CoinIndicatorState();
}

class _CoinIndicatorState extends State<_CoinIndicator> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.coins;
  }

  @override
  void didUpdateWidget(covariant _CoinIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins) {
      _from = oldWidget.coins;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A66).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF11194A), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            color: Color(0xFFFFCC00),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _from.toDouble(),
                end: widget.coins.toDouble(),
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  value.round().toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
