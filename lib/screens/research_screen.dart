import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/game_top_bar.dart';
import 'collection_screen.dart';
import 'final_word_screen.dart';
import 'home_screen.dart';
import 'my_garden_screen.dart';
import 'my_stats_screen.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

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
                  onTrophyTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FinalWordScreen(),
                      ),
                    );
                  },
                  onResearchTap: () {},
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
                  currentTab: GameTopTab.research,
                  showCollectionBadge: game.hasUnseenCollectionItems,
                  showTrophyBadge: game.hasUnseenBadges,
                  showResearchBadge: game.hasAffordableResearch,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2A66).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Research Lab  |  XP ${game.xp}  |  Coins ${game.coins}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      final crossAxisCount = isNarrow ? 1 : 2;
                      final aspectRatio = isNarrow ? 2.2 : 1.2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                        itemCount: GameProvider.researchDefinitions.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: aspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final def = GameProvider.researchDefinitions[index];
                          final level = game.getResearchLevel(def.id);
                          final maxed = level >= def.maxLevel;
                          final canBuy = game.canUpgradeResearch(def.id);
                          final xpCost = game.getResearchXpCost(def.id);
                          final coinCost = game.getResearchCoinCost(def.id);
                          final nextEffect =
                              game.getResearchEffectLabel(def.id, nextLevel: true);

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: maxed
                                ? null
                                : () {
                                    final upgraded = context
                                        .read<GameProvider>()
                                        .upgradeResearch(def.id);
                                    if (!upgraded) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Not enough XP or coins for this research.",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2A66)
                                    .withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: maxed
                                      ? Colors.greenAccent
                                      : (canBuy ? def.color : Colors.white54),
                                  width: 1.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: def.color.withValues(alpha: 0.22),
                                    blurRadius: 8,
                                    spreadRadius: 0.6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(def.icon, color: def.color, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          def.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Lvl $level / ${def.maxLevel}",
                                    style: TextStyle(
                                      color: maxed ? Colors.greenAccent : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Next: $nextEffect",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: maxed ? Colors.greenAccent : def.color,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: maxed
                                          ? Colors.green.withValues(alpha: 0.24)
                                          : (canBuy
                                              ? def.color.withValues(alpha: 0.22)
                                              : const Color(0xFF11194A)
                                                  .withValues(alpha: 0.55)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: maxed
                                            ? Colors.greenAccent
                                            : (canBuy ? def.color : Colors.white54),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      maxed
                                          ? "Completed"
                                          : "Upgrade: $xpCost XP + $coinCost C",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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
