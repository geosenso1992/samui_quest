import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/game_top_bar.dart';
import 'collection_screen.dart';
import 'final_word_screen.dart';
import 'map_screen.dart';
import 'my_garden_screen.dart';
import 'research_screen.dart';

class MyStatsScreen extends StatelessWidget {
  const MyStatsScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final username = game.username.isEmpty ? "Explorer" : game.username;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0E1236),
                  Color(0xFF1F2A66),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                GameTopBar(
                  onHomeTap: () => Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ),
                  onMapTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          selectedAvatar: game.currentAvatar,
                        ),
                      ),
                    );
                  },
                  onCollectionTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CollectionScreen(),
                      ),
                    );
                  },
                  onTrophyTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FinalWordScreen(),
                      ),
                    );
                  },
                  onResearchTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResearchScreen(),
                      ),
                    );
                  },
                  onGardenTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyGardenScreen(),
                      ),
                    );
                  },
                  onStatsTap: () {},
                  currentTab: GameTopTab.stats,
                  showCollectionBadge: game.hasUnseenCollectionItems,
                  showTrophyBadge: game.hasUnseenBadges,
                  showResearchBadge: game.hasAffordableResearch,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2A66)
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFCC00)
                                  .withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                backgroundImage:
                                    AssetImage(game.currentAvatar),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Explorer since ${_formatDate(game.explorerSince)}",
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatTile(
                          icon: Icons.directions_walk,
                          label: "Total distance",
                          value: "${game.totalDistanceKm.toStringAsFixed(1)} km",
                        ),
                        _StatTile(
                          icon: Icons.auto_graph,
                          label: "Avg km per day",
                          value:
                              "${game.avgDistanceKmPerDay.toStringAsFixed(1)} km",
                        ),
                        _StatTile(
                          icon: Icons.pets,
                          label: "Animals caught",
                          value: "${game.animalsCaughtCount}",
                        ),
                        _StatTile(
                          icon: Icons.percent,
                          label: "Animal catch ratio",
                          value: "${game.animalCatchRatioPercent.toStringAsFixed(1)}%",
                        ),
                        _StatTile(
                          icon: Icons.spa,
                          label: "Seeds collected",
                          value: "${game.seedsCollectedCount}",
                        ),
                        _StatTile(
                          icon: Icons.local_grocery_store,
                          label: "Fruits collected",
                          value: "${game.fruitsCollectedCount}",
                        ),
                        const SizedBox(height: 12),
                        _StatTile(
                          icon: Icons.bolt,
                          label: "Total XP earned",
                          value: "${game.totalXpEarned.toStringAsFixed(0)}",
                        ),
                        _StatTile(
                          icon: Icons.monetization_on,
                          label: "Total coins earned",
                          value: "${game.totalCoinsEarned}",
                        ),
                        _StatTile(
                          icon: Icons.local_offer,
                          label: "Value of sold fruits",
                          value: "${game.totalFruitSalesValue}",
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
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A66).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFCC00).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFCC00), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
