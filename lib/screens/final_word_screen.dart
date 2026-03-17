import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_top_bar.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'my_garden_screen.dart';
import 'my_stats_screen.dart';
import 'research_screen.dart';

class _BadgeDefinition {
  final String title;
  final IconData icon;
  final bool unlocked;

  const _BadgeDefinition({
    required this.title,
    required this.icon,
    required this.unlocked,
  });
}

class FinalWordScreen extends StatelessWidget {
  const FinalWordScreen({super.key});

  List<_BadgeDefinition> _buildBadges(GameProvider game) {
    final animals = game.unlockedAnimals.length;
    final seeds = game.unlockedSeeds.length;
    final visited = game.visitedLocations.length;
    final level = game.level;
    final discoveredSpecies = animals + seeds;

    return [
      _BadgeDefinition(title: "First Animal", icon: Icons.pets, unlocked: animals >= 1),
      _BadgeDefinition(title: "5 Animals", icon: Icons.pets_outlined, unlocked: animals >= 5),
      _BadgeDefinition(title: "10 Animals", icon: Icons.cruelty_free, unlocked: animals >= 10),
      _BadgeDefinition(title: "15 Animals", icon: Icons.bug_report, unlocked: animals >= 15),
      _BadgeDefinition(title: "20 Animals", icon: Icons.forest, unlocked: animals >= 20),
      _BadgeDefinition(title: "First Seed", icon: Icons.spa, unlocked: seeds >= 1),
      _BadgeDefinition(title: "5 Seeds", icon: Icons.grass, unlocked: seeds >= 5),
      _BadgeDefinition(title: "10 Seeds", icon: Icons.agriculture, unlocked: seeds >= 10),
      _BadgeDefinition(title: "15 Seeds", icon: Icons.eco, unlocked: seeds >= 15),
      _BadgeDefinition(title: "20 Seeds", icon: Icons.local_florist, unlocked: seeds >= 20),
      _BadgeDefinition(title: "Explorer I", icon: Icons.explore, unlocked: visited >= 1),
      _BadgeDefinition(title: "Explorer II", icon: Icons.map, unlocked: visited >= 3),
      _BadgeDefinition(title: "Explorer III", icon: Icons.travel_explore, unlocked: visited >= 5),
      _BadgeDefinition(title: "Explorer IV", icon: Icons.terrain, unlocked: visited >= 7),
      _BadgeDefinition(title: "All Quests", icon: Icons.public, unlocked: visited >= 9),
      _BadgeDefinition(title: "Level 2", icon: Icons.star, unlocked: level >= 2),
      _BadgeDefinition(title: "Level 3", icon: Icons.stars, unlocked: level >= 3),
      _BadgeDefinition(title: "Level 5", icon: Icons.military_tech, unlocked: level >= 5),
      _BadgeDefinition(title: "Level 8", icon: Icons.workspace_premium, unlocked: level >= 8),
      _BadgeDefinition(title: "Level 10", icon: Icons.verified, unlocked: level >= 10),
      _BadgeDefinition(title: "10 Species", icon: Icons.auto_awesome, unlocked: discoveredSpecies >= 10),
      _BadgeDefinition(title: "20 Species", icon: Icons.auto_awesome_motion, unlocked: discoveredSpecies >= 20),
      _BadgeDefinition(title: "30 Species", icon: Icons.brightness_high, unlocked: discoveredSpecies >= 30),
      _BadgeDefinition(title: "40 Species", icon: Icons.wb_sunny, unlocked: discoveredSpecies >= 40),
      _BadgeDefinition(title: "Samui Master", icon: Icons.emoji_events, unlocked: animals >= 20 && seeds >= 20 && visited >= 9),
    ];
  }

  Color _badgeColor(int index) {
    const colors = [
      Color(0xFF42A5F5),
      Color(0xFF26A69A),
      Color(0xFF66BB6A),
      Color(0xFFFFA726),
      Color(0xFFEF5350),
      Color(0xFFAB47BC),
      Color(0xFF5C6BC0),
      Color(0xFF29B6F6),
      Color(0xFF9CCC65),
      Color(0xFFFF7043),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      game.markBadgesSeen();
    });
    final badges = _buildBadges(game);
    final unlockedCount = badges.where((b) => b.unlocked).length;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/maps/jungle.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1F2A66).withValues(alpha: 0.6),
            ),
          ),
          SafeArea(
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
                  onCollectionTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CollectionScreen(),
                      ),
                    );
                  },
                  onTrophyTap: () {},
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
                  onStatsTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyStatsScreen(),
                      ),
                    );
                  },
                  currentTab: GameTopTab.trophy,
                  showCollectionBadge: game.hasUnseenCollectionItems,
                  showTrophyBadge: game.hasUnseenBadges,
                  showResearchBadge: game.hasAffordableResearch,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2A66).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      "Badges unlocked: $unlockedCount / 25",
                      style: const TextStyle(
                        color: Color(0xFFFFCC00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: GridView.builder(
                      itemCount: badges.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        final color = _badgeColor(index);

                        return Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: badge.unlocked
                                      ? const Color(0xFF1F2A66)
                                          .withValues(alpha: 0.65)
                                      : const Color(0xFF11194A)
                                          .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: badge.unlocked
                                        ? const Color(0xFFFFCC00)
                                        : const Color(0xFFFFCC00)
                                            .withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    badge.icon,
                                    size: 26,
                                    color: badge.unlocked
                                        ? const Color(0xFFFFCC00)
                                        : const Color(0xFFFFCC00)
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: badge.unlocked
                                    ? const Color(0xFFFFCC00)
                                    : const Color(0xFFFFCC00)
                                        .withValues(alpha: 0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
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
