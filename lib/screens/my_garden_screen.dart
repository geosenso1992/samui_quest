import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import 'collection_screen.dart';
import 'final_word_screen.dart';
import 'home_screen.dart';
import 'my_stats_screen.dart';
import 'research_screen.dart';

enum _SelectionMode { single, multi, all }

class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> {
  static const int _gridCount = 10;
  static const int _cellCount = _gridCount * _gridCount;
  static const String _unplantToken = '__UNPLANT__';

  _SelectionMode _selectionMode = _SelectionMode.single;
  final Set<int> _selectedIndices = {};
  Timer? _progressTimer;
  int? _infoCellIndex;
  String? _harvestPopupSeedId;
  bool _pathEditMode = false;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  String _toDisplayName(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split(RegExp(r'[_\-\s]+'))
        .where((p) => p.isNotEmpty)
        .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
        .join(' ');
  }

  String _formatRemaining(Duration value) {
    final totalSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _openSeedPicker(GameProvider game) async {
    if (game.gardenPathCells.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not able to plant seed. Create a path cell first."),
        ),
      );
      return;
    }
    if (_selectedIndices.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one cell first.")),
      );
      return;
    }

    final unlockedSeeds = game.unlockedSeeds.toList()..sort();
    final plantableSeeds =
        unlockedSeeds.where((seed) => game.getAvailableSeedCount(seed) > 0).toList();
    final hasAnyPlant = _selectedIndices
        .any((cellIndex) => game.getGardenPlot(cellIndex) != null);

    if (plantableSeeds.isEmpty && !hasAnyPlant) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No seeds available to plant yet.")),
      );
      return;
    }

    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8D6B4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: const Color(0xFF8D6E63), width: 2),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.brown.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  "Select Seed",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Apply to ${_selectedIndices.length} selected cell(s)",
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasAnyPlant)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Unplant selected cells"),
                    onTap: () => Navigator.pop(context, _unplantToken),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: plantableSeeds.length,
                    itemBuilder: (context, i) {
                      final seed = plantableSeeds[i];
                      final availableCount = game.getAvailableSeedCount(seed);
                      final canPlant = true;
                      return ListTile(
                        dense: true,
                        enabled: canPlant,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/seeds/icons_300/$seed.png",
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        title: Text(
                          "${_toDisplayName(seed)} ($availableCount)",
                          style: TextStyle(
                            color: const Color(0xFF3E2723),
                          ),
                        ),
                        onTap: () => Navigator.pop(context, seed),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      final selected = _selectedIndices.toList(growable: false);
      if (selection == _unplantToken) {
        for (final index in selected) {
          game.unplantSeedAt(index);
        }
      } else if (selection != null) {
        var plantedCount = 0;
        var failedCount = 0;
        var blockedByPath = 0;
        int? firstPlantedIndex;
        for (final index in selected) {
          if (!game.canPlantAtCell(index)) {
            blockedByPath++;
            continue;
          }
          final didPlant =
              game.plantSeedAt(index: index, seedId: selection);
          if (didPlant) {
            plantedCount++;
            firstPlantedIndex ??= index;
          } else {
            failedCount++;
          }
        }

        if (plantedCount > 0) {
          AudioService().playDigDirt();
          _infoCellIndex = firstPlantedIndex;
        }

        if (blockedByPath > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Not able to plant seed. Cell must touch a path cell.",
              ),
            ),
          );
        }

        if (failedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                plantedCount > 0
                    ? "Planted $plantedCount cell(s). $failedCount skipped: not enough ${_toDisplayName(selection)} seeds."
                    : "Not enough ${_toDisplayName(selection)} seeds.",
              ),
            ),
          );
        }
      }
      _selectedIndices.clear();
    });
  }

  void _setSelectionMode(_SelectionMode mode) {
    setState(() {
      _selectionMode = mode;
      _selectedIndices.clear();
      if (mode == _SelectionMode.all) {
        _selectedIndices.addAll(List<int>.generate(_cellCount, (i) => i));
      }
    });
  }

  void _onCellTap(GameProvider game, int index) {
    final plot = game.getGardenPlot(index);
    final isCompleted = game.isGardenPlotCompleted(index);
    if (plot != null && isCompleted && !plot.isHarvested) {
      final harvested = game.harvestSeedAt(index);
      if (harvested != null) {
        AudioService().playHarvest();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${_toDisplayName(harvested)} harvested (+${game.getSeedHarvestXp(harvested)} XP)",
            ),
          ),
        );
        _harvestPopupSeedId = harvested;
      }
      setState(() {
        if (_infoCellIndex == index) {
          _infoCellIndex = null;
        }
      });
      return;
    }

    setState(() {
      if (_selectionMode == _SelectionMode.all) return;
      if (_pathEditMode) {
        final success = game.toggleGardenPathCell(index);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Not enough coins. A path cell costs 10 coins."),
            ),
          );
          return;
        }
        if (game.isGardenPathCell(index) && _infoCellIndex == index) {
          _infoCellIndex = null;
        }
        return;
      }
      if (game.isGardenPathCell(index)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Not able to plant seed on a path cell."),
          ),
        );
        return;
      }
      if (_selectionMode == _SelectionMode.single) {
        _selectedIndices
          ..clear()
          ..add(index);
      } else {
        if (_selectedIndices.contains(index)) {
          _selectedIndices.remove(index);
        } else {
          _selectedIndices.add(index);
        }
      }

      final plot = game.getGardenPlot(index);
      if (plot != null &&
          !plot.isHarvested &&
          !game.isGardenPlotCompleted(index)) {
        _infoCellIndex = index;
      } else if (_infoCellIndex == index) {
        _infoCellIndex = null;
      }
    });
  }

  Widget _buildToolButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
    IconData icon = Icons.agriculture,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF1F2A66).withValues(alpha: 0.7)
              : const Color(0xFF11194A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFFFFCC00)
                : const Color(0xFFFFCC00).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFFFFCC00)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFCC00),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/grass.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1F2A66).withValues(alpha: 0.35),
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
                  onResearchTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResearchScreen(),
                      ),
                    );
                  },
                  onGardenTap: () {},
                  onStatsTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyStatsScreen(),
                      ),
                    );
                  },
                  currentTab: GameTopTab.garden,
                  showCollectionBadge: game.hasUnseenCollectionItems,
                  showTrophyBadge: game.hasUnseenBadges,
                  showResearchBadge: game.hasAffordableResearch,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolButton(
                          label: "Single",
                          active: _selectionMode == _SelectionMode.single,
                          onTap: () => _setSelectionMode(_SelectionMode.single),
                        ),
                        const SizedBox(width: 8),
                        _buildToolButton(
                          label: "Multi",
                          active: _selectionMode == _SelectionMode.multi,
                          onTap: () => _setSelectionMode(_SelectionMode.multi),
                        ),
                        const SizedBox(width: 8),
                        _buildToolButton(
                          label: "All",
                          active: _selectionMode == _SelectionMode.all,
                          onTap: () => _setSelectionMode(_SelectionMode.all),
                        ),
                        const SizedBox(width: 10),
                        _buildToolButton(
                          label: _pathEditMode ? "Path mode" : "Path",
                          active: _pathEditMode,
                          icon: Icons.route,
                          onTap: () {
                            setState(() {
                              _pathEditMode = !_pathEditMode;
                              _selectedIndices.clear();
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _selectedIndices.isEmpty || _pathEditMode
                              ? null
                              : () => _openSeedPicker(game),
                          icon: const Icon(Icons.agriculture, size: 14),
                          label: Text(
                            "Plant (${_selectedIndices.length})",
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1F2A66).withValues(alpha: 0.85),
                            foregroundColor: const Color(0xFFFFCC00),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardWidth = constraints.maxWidth;
                      final cellWidth = boardWidth / _gridCount;

                      return Center(
                        child: SizedBox(
                          width: boardWidth,
                          height: boardWidth,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.25),
                                ),
                              ),
                              Positioned.fill(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _cellCount,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _gridCount,
                                  ),
                                  itemBuilder: (context, index) {
                                    final isSelected =
                                        _selectedIndices.contains(index);
                                    final plot = game.getGardenPlot(index);
                                    final planted = plot?.seedId;
                                    final hasPlant = planted != null;
                                    final isHarvested = plot?.isHarvested ?? false;
                                    final isPath = game.isGardenPathCell(index);
                                    final progress = game.getGardenProgress(index);
                                    final completed = game.isGardenPlotCompleted(index);

                                    return GestureDetector(
                                      onTap: () => _onCellTap(game, index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isPath
                                              ? Colors.grey.withValues(alpha: 0.75)
                                              : hasPlant
                                                  ? const Color(0xFF8D6E63).withValues(alpha: 0.62)
                                                  : Colors.transparent,
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.yellowAccent,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: hasPlant
                                            ? Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Center(
                                                      child: Padding(
                                                        padding: const EdgeInsets.fromLTRB(1, 1, 1, 8),
                                                        child: Transform.scale(
                                                          scale: 1.9,
                                                          child: Image.asset(
                                                            isHarvested
                                                                ? "assets/fruits/icons_300/$planted.png"
                                                                : "assets/seeds/icons_300/$planted.png",
                                                            fit: BoxFit.contain,
                                                            filterQuality: FilterQuality.high,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isHarvested)
                                                    Positioned(
                                                      left: 2,
                                                      right: 2,
                                                      bottom: 2,
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: LinearProgressIndicator(
                                                          minHeight: 4,
                                                          value: progress,
                                                          backgroundColor:
                                                              Colors.black.withValues(alpha: 0.35),
                                                          valueColor: AlwaysStoppedAnimation<Color>(
                                                            completed ? Colors.greenAccent : Colors.orangeAccent,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (completed && !isHarvested)
                                                    const Positioned(
                                                      top: 2,
                                                      right: 2,
                                                      child: Icon(
                                                        Icons.touch_app,
                                                        color: Colors.greenAccent,
                                                        size: 12,
                                                      ),
                                                    ),
                                                ],
                                              )
                                            : isPath
                                                ? const Center(
                                                    child: Icon(
                                                      Icons.drag_handle,
                                                      size: 14,
                                                      color: Colors.black54,
                                                    ),
                                                  )
                                                : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _DashedGridPainter(
                                      gridCount: _gridCount,
                                      color: Colors.black.withValues(alpha: 0.58),
                                    ),
                                  ),
                                ),
                              ),
                              if (_infoCellIndex != null)
                                Builder(
                                  builder: (context) {
                                    final infoIndex = _infoCellIndex!;
                                    final infoPlot = game.getGardenPlot(infoIndex);
                                    if (infoPlot == null ||
                                        game.isGardenPlotCompleted(infoIndex)) {
                                      return const SizedBox.shrink();
                                    }
                                    final remaining =
                                        game.getGardenTimeRemaining(infoIndex) ??
                                            Duration.zero;
                                    final row = infoIndex ~/ _gridCount;
                                    final col = infoIndex % _gridCount;
                                    final bubbleTop =
                                        (row * cellWidth - 54).clamp(2.0, boardWidth - 64);
                                    final bubbleLeft = (col * cellWidth - 6)
                                        .clamp(2.0, boardWidth - 148);

                                     return Positioned(
                                       top: bubbleTop,
                                       left: bubbleLeft,
                                       child: Container(
                                         width: 146,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.72),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white70,
                                            width: 1,
                                          ),
                                        ),
                                         child: Column(
                                           mainAxisSize: MainAxisSize.min,
                                           crossAxisAlignment: CrossAxisAlignment.center,
                                           children: [
                                             Align(
                                               alignment: Alignment.topRight,
                                               child: InkWell(
                                                 onTap: () {
                                                   setState(() {
                                                     _infoCellIndex = null;
                                                   });
                                                 },
                                                 child: const Icon(
                                                   Icons.close,
                                                   color: Colors.white70,
                                                   size: 12,
                                                 ),
                                               ),
                                             ),
                                             Text(
                                               "${_toDisplayName(infoPlot.seedId)} (+${game.getSeedHarvestXp(infoPlot.seedId)} XP)",
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatRemaining(remaining),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (_harvestPopupSeedId != null)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _harvestPopupSeedId = null;
                                      });
                                    },
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      alignment: Alignment.center,
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          width: boardWidth * 0.72,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8D6B4),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFF8D6E63),
                                              width: 2,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _harvestPopupSeedId = null;
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.black54,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 8),
                                                  Image.asset(
                                                    "assets/fruits/master/${_harvestPopupSeedId!}.png",
                                                    height: boardWidth * 0.45,
                                                    fit: BoxFit.contain,
                                                    filterQuality: FilterQuality.high,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _toDisplayName(_harvestPopupSeedId!),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Color(0xFF3E2723),
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text(
                                                    "Harvested!",
                                                    style: TextStyle(
                                                      color: Color(0xFF5D4037),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedGridPainter extends CustomPainter {
  final int gridCount;
  final Color color;

  const _DashedGridPainter({
    required this.gridCount,
    required this.color,
  });

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
  ) {
    const dash = 4.0;
    const gap = 3.0;
    final total = (p2 - p1).distance;
    final direction = (p2 - p1) / total;
    var traveled = 0.0;
    while (traveled < total) {
      final start = p1 + direction * traveled;
      final end = p1 + direction * (traveled + dash).clamp(0, total);
      canvas.drawLine(start, end, paint);
      traveled += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final stepX = size.width / gridCount;
    final stepY = size.height / gridCount;

    for (var i = 1; i < gridCount; i++) {
      final dx = stepX * i;
      final dy = stepY * i;
      _drawDashedLine(canvas, Offset(dx, 0), Offset(dx, size.height), paint);
      _drawDashedLine(canvas, Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedGridPainter oldDelegate) {
    return oldDelegate.gridCount != gridCount || oldDelegate.color != color;
  }
}
