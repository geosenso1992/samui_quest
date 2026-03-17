import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/animal_metadata.dart';
import '../models/seed_metadata.dart';
import '../providers/game_provider.dart';
import '../widgets/game_top_bar.dart';
import 'final_word_screen.dart';
import 'home_screen.dart';
import 'my_garden_screen.dart';
import 'my_stats_screen.dart';
import 'research_screen.dart';


class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String?> animals = [
    "ladybug",
    "ant",
    "bat",
    "buffalo",
    "butterfly",
    "dragonfly",
    "frog",
    "gecko",
    "giant_hornet",
    "grasshopper",
    "jumping_spider",
    "king_cobra",
    "kingfisher",
    "macaque",
    "mosquito",
    "pangolin",
    "praying_mantis",
    "rat",
    "scorpion",
    "squirrel",
  ];

  final List<String?> seeds = [
    "barley",
    "pineapple",
    "basil",
    "chili",
    "coriander",
    "corn",
    "durian",
    "eggplant",
    "jackfruit",
    "lotus",
    "mango",
    "mustard",
    "peanut",
    "rambutan",
    "rice",
    "sesame",
    "soybean",
    "strawberry",
    "tamarind",
    "watermelon",
  ];

  final List<String?> fruits = [
    "barley",
    "pineapple",
    "basil",
    "chili",
    "coriander",
    "corn",
    "durian",
    "eggplant",
    "jackfruit",
    "lotus",
    "mango",
    "mustard",
    "peanut",
    "rambutan",
    "rice",
    "sesame",
    "soybean",
    "strawberry",
    "tamarind",
    "watermelon",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameTopBar(
              onHomeTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(showMenuImmediately: true),
                  ),
                  (route) => false,
                );
              },
              onMapTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              onCollectionTap: () {},
              onTrophyTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FinalWordScreen()),
                );
              },
              onResearchTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ResearchScreen()),
                );
              },
              onGardenTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyGardenScreen()),
                );
              },
              onStatsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyStatsScreen()),
                );
              },
              currentTab: GameTopTab.collection,
              showCollectionBadge: game.hasUnseenCollectionItems,
              showTrophyBadge: game.hasUnseenBadges,
              showResearchBadge: game.hasAffordableResearch,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      "assets/maps/colscreen.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF1F2A66).withValues(alpha: 0.55),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 38),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFFFFCC00),
                          unselectedLabelColor:
                              const Color(0xFFFFCC00).withValues(alpha: 0.55),
                          indicatorColor: const Color(0xFFFFCC00),
                          tabs: const [
                            Tab(text: "Seeds"),
                            Tab(text: "Fruits"),
                            Tab(text: "Animals"),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildGrid(
                                  items: seeds,
                                  isUnlocked: (id) =>
                                      id != null && game.isSeedUnlocked(id),
                                  getCount: (id) => id == null
                                      ? 0
                                      : game.getAvailableSeedCount(id),
                                  assetFolder: "assets/seeds/icons_300/",
                                  iconScale: 2.0,
                                  unlockedBorderColor: (id) {
                                    final rarity =
                                        kSeedMetadataByName[id]?.rarity ??
                                            SeedRarity.common;
                                    return getSeedRarityBorderColor(rarity);
                                  },
                                  isUnseen: (id) => game.isUnseenSeed(id),
                                  onUnlockedTap: (id) =>
                                      _showMasterPreview(context, id, CollectionKind.seed),
                                ),
                                _buildGrid(
                                  items: fruits,
                                  isUnlocked: (id) =>
                                      id != null && game.isFruitUnlocked(id),
                                  getCount: (id) => id == null
                                      ? 0
                                      : game.getCollectedFruitCount(id),
                                  assetFolder: "assets/fruits/icons_300/",
                                  // Fruits icons fill more; zoom out a bit vs seeds.
                                  iconScale: 1.35,
                                  unlockedBorderColor: (id) {
                                    final rarity =
                                        kSeedMetadataByName[id]?.rarity ??
                                            SeedRarity.common;
                                    return getSeedRarityBorderColor(rarity);
                                  },
                                  isUnseen: (id) => game.isUnseenFruit(id),
                                  onUnlockedTap: (id) =>
                                      _showMasterPreview(context, id, CollectionKind.fruit),
                                ),
                                _buildGrid(
                                  items: animals,
                                  isUnlocked: (id) =>
                                      id != null && game.isAnimalUnlocked(id),
                                  getCount: (id) => id == null
                                      ? 0
                                      : game.getCollectedSpawnCount(id),
                                  assetFolder: "assets/animals/icons_300/",
                                  iconScale: 1.5,
                                  unlockedBorderColor: (id) {
                                    final rarity =
                                        kAnimalMetadataByName[id]?.rarity ??
                                            AnimalRarity.common;
                                    return getRarityBorderColor(rarity);
                                  },
                                  isUnseen: (id) => game.isUnseenAnimal(id),
                                  onUnlockedTap: (id) =>
                                      _showMasterPreview(context, id, CollectionKind.animal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toDisplayName(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split(RegExp(r'[_\-\s]+'))
        .where((p) => p.isNotEmpty)
        .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
        .join(' ');
  }

  Future<void> _showMasterPreview(
    BuildContext context,
    String id,
    CollectionKind kind,
  ) async {
    context.read<GameProvider>().markCollectionItemSeen(kind, id);
    final masterPath = switch (kind) {
      CollectionKind.animal => "assets/animals/master/$id.png",
      CollectionKind.seed => "assets/seeds/master/$id.png",
      CollectionKind.fruit => "assets/fruits/master/$id.png",
    };
    final typeLabel = switch (kind) {
      CollectionKind.animal => "Animal",
      CollectionKind.seed => "Seed",
      CollectionKind.fruit => "Fruit",
    };

    final rarityLabel = switch (kind) {
      CollectionKind.animal =>
        (kAnimalMetadataByName[id]?.rarity ?? AnimalRarity.common).name,
      CollectionKind.seed =>
        (kSeedMetadataByName[id]?.rarity ?? SeedRarity.common).name,
      CollectionKind.fruit =>
        (kSeedMetadataByName[id]?.rarity ?? SeedRarity.common).name,
    };

    final rarityColor = switch (kind) {
      CollectionKind.animal => getRarityBorderColor(
          kAnimalMetadataByName[id]?.rarity ?? AnimalRarity.common,
        ),
      CollectionKind.seed => getSeedRarityBorderColor(
          kSeedMetadataByName[id]?.rarity ?? SeedRarity.common,
        ),
      CollectionKind.fruit => getSeedRarityBorderColor(
          kSeedMetadataByName[id]?.rarity ?? SeedRarity.common,
        ),
    };

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D6B4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: rarityColor,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Image.asset(
                    masterPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  typeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _toDisplayName(id),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3E2723),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rarityLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid({
    required List<String?> items,
    required bool Function(String?) isUnlocked,
    required int Function(String?) getCount,
    required String assetFolder,
    required double iconScale,
    Color Function(String id)? unlockedBorderColor,
    required bool Function(String id) isUnseen,
    required void Function(String id) onUnlockedTap,
  }) {
    return GridView.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 32,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final id = items[index];
        final unlocked = id != null && isUnlocked(id);
        final unlockedId = unlocked ? id : null;
        final isNew = unlockedId != null && isUnseen(unlockedId);
        final collectedCount = getCount(id);
        final displayName = id == null ? "Unknown" : _toDisplayName(id);
        final borderColor = unlockedId != null
            ? (unlockedBorderColor?.call(unlockedId) ??
                Colors.brown.withValues(alpha: 0.4))
            : Colors.brown.withValues(alpha: 0.25);
        final nameColor = unlocked
            ? const Color(0xFF5D4037)
            : const Color(0xFF5D4037).withValues(alpha: 0.45);

        return GestureDetector(
          onTap: unlockedId != null ? () => onUnlockedTap(unlockedId) : null,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: AspectRatio(
                  aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2A66).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                        width: unlocked ? 2 : 1.5,
                      ),
                    ),
                    child: id == null
                        ? const SizedBox()
                        : unlocked
                            ? _buildCollectionIcon(
                                assetPath: "$assetFolder$id.png",
                                iconScale: iconScale,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: _buildCollectionIcon(
                                        assetPath: "$assetFolder$id.png",
                                        iconScale: iconScale,
                                        color: Colors.black,
                                        colorBlendMode: BlendMode.srcATop,
                                      ),
                                    ),
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.45),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
              ),
              if (collectedCount > 0)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF90CAF9).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      "$collectedCount",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              if (isNew)
                Positioned(
                  top: 1,
                  left: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFCC00),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "!",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 14,
                child: Text(
                  "#${index + 1}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: unlocked
                    ? Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: nameColor,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Opacity(
                          opacity: 0.35,
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: nameColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectionIcon({
    required String assetPath,
    required double iconScale,
    Color? color,
    BlendMode? colorBlendMode,
  }) {
    return ClipRect(
      child: Transform.scale(
        scale: iconScale,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          color: color,
          colorBlendMode: colorBlendMode,
        ),
      ),
    );
  }
}
