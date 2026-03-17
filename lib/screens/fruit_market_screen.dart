import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fruit_metadata.dart';
import '../models/seed_metadata.dart';
import '../providers/game_provider.dart';
import '../widgets/game_top_bar.dart';
import 'home_screen.dart';
import 'final_word_screen.dart';
import 'my_garden_screen.dart';
import 'my_stats_screen.dart';
import 'research_screen.dart';

class FruitMarketScreen extends StatelessWidget {
  const FruitMarketScreen({super.key});

  String _toDisplayName(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split(RegExp(r'[_\\-\\s]+'))
        .where((p) => p.isNotEmpty)
        .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final items = game.unlockedFruits.toList()..sort();
    final sellable = items.where((id) => game.getCollectedFruitCount(id) > 0).toList();

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
                if (Navigator.canPop(context)) Navigator.pop(context);
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
              currentTab: GameTopTab.map,
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF3E7CF),
                child: sellable.isEmpty
                    ? const Center(
                        child: Text(
                          "No fruits collected yet.",
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        itemCount: sellable.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final id = sellable[index];
                          final count = game.getCollectedFruitCount(id);
                          final meta = getFruitMetadata(id);
                          final rarity =
                              kSeedMetadataByName[id]?.rarity ?? SeedRarity.common;
                          final border = getSeedRarityBorderColor(rarity);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.brown.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    "assets/fruits/icons_300/$id.png",
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _toDisplayName(id),
                                        style: const TextStyle(
                                          color: Color(0xFF3E2723),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "x$count  •  ${rarity.name}",
                                        style: const TextStyle(
                                          color: Color(0xFF6D4C41),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (meta != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          "Sell: +${meta.valueCoinsWhenSold} coins, +${meta.xpWhenSold} XP",
                                          style: const TextStyle(
                                            color: Color(0xFF5D4037),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    _SellButton(
                                      label: "Sell 1",
                                      onTap: () {
                                        final result =
                                            game.sellFruit(fruitId: id, amount: 1);
                                        if (result.sold <= 0) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Sold 1 ${_toDisplayName(id)} (+${result.coinsGained} coins, +${result.xpGained} XP)",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _SellButton(
                                      label: "Sell all",
                                      onTap: () {
                                        final result = game.sellFruit(
                                          fruitId: id,
                                          amount: count,
                                        );
                                        if (result.sold <= 0) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Sold ${result.sold} ${_toDisplayName(id)} (+${result.coinsGained} coins, +${result.xpGained} XP)",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SellButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF8D6E63),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
