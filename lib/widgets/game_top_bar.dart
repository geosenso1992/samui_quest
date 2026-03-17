import 'package:flutter/material.dart';

enum GameTopTab { map, collection, trophy, research, garden, stats }

class GameTopBar extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onMapTap;
  final VoidCallback onCollectionTap;
  final VoidCallback onTrophyTap;
  final VoidCallback onResearchTap;
  final VoidCallback onGardenTap;
  final VoidCallback onStatsTap;
  final GameTopTab currentTab;
  final bool showHomeBadge;
  final bool showMapBadge;
  final bool showCollectionBadge;
  final bool showTrophyBadge;
  final bool showResearchBadge;
  final bool showGardenBadge;
  final bool showStatsBadge;

  const GameTopBar({
    super.key,
    required this.onHomeTap,
    required this.onMapTap,
    required this.onCollectionTap,
    required this.onTrophyTap,
    required this.onResearchTap,
    required this.onGardenTap,
    required this.onStatsTap,
    required this.currentTab,
    this.showHomeBadge = false,
    this.showMapBadge = false,
    this.showCollectionBadge = false,
    this.showTrophyBadge = false,
    this.showResearchBadge = false,
    this.showGardenBadge = false,
    this.showStatsBadge = false,
  });

  static const double _iconSize = 22;

  Widget _buildIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          icon: Icon(icon, color: color, size: _iconSize),
          onPressed: onTap,
        ),
        if (showBadge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFFCC00),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  "!",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _iconColor(GameTopTab tab) {
    return currentTab == tab ? const Color(0xFFFFCC00) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A66).withValues(alpha: 0.85),
      ),
      child: Row(
        children: [
          _buildIcon(
            icon: Icons.home,
            color: Colors.white,
            onTap: onHomeTap,
            showBadge: showHomeBadge,
          ),
          const SizedBox(width: 4),
          _buildIcon(
            icon: Icons.public,
            color: _iconColor(GameTopTab.map),
            onTap: onMapTap,
            showBadge: showMapBadge,
          ),
          _buildIcon(
            icon: Icons.menu_book,
            color: _iconColor(GameTopTab.collection),
            onTap: onCollectionTap,
            showBadge: showCollectionBadge,
          ),
          _buildIcon(
            icon: Icons.emoji_events,
            color: _iconColor(GameTopTab.trophy),
            onTap: onTrophyTap,
            showBadge: showTrophyBadge,
          ),
          _buildIcon(
            icon: Icons.science,
            color: _iconColor(GameTopTab.research),
            onTap: onResearchTap,
            showBadge: showResearchBadge,
          ),
          _buildIcon(
            icon: Icons.yard,
            color: _iconColor(GameTopTab.garden),
            onTap: onGardenTap,
            showBadge: showGardenBadge,
          ),
          _buildIcon(
            icon: Icons.bar_chart,
            color: _iconColor(GameTopTab.stats),
            onTap: onStatsTap,
            showBadge: showStatsBadge,
          ),
        ],
      ),
    );
  }
}
