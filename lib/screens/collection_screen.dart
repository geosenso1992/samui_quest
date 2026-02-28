import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

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
    null, null, null, null,
    null, null, null, null, null,
    null, null, null, null, null,
    null, null, null, null, null,
    null, null, null, null, null,
  ];

  final List<String?> seeds = [
    "pineapple",
    null, null, null, null,
    null, null, null, null, null,
    null, null, null, null, null,
    null, null, null, null, null,
    null, null, null, null, null,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/maps/colscreen.png",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                const SizedBox(height: 12),

                TabBar(
                  controller: _tabController,
                  labelColor: Colors.brown.shade900,
                  unselectedLabelColor: Colors.brown.shade400,
                  indicatorColor: Colors.brown,
                  tabs: const [
                    Tab(text: "Animals"),
                    Tab(text: "Seeds"),
                  ],
                ),

                const SizedBox(height: 25),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 20),
                    child: TabBarView(
                      controller: _tabController,
                      children: [

                        _buildGrid(
                          items: animals,
                          isUnlocked: (id) =>
                              id != null && game.isAnimalUnlocked(id),
                          assetFolder: "assets/animals/",
                        ),

                        _buildGrid(
                          items: seeds,
                          isUnlocked: (id) =>
                              id != null && game.isSeedUnlocked(id),
                          assetFolder: "assets/seeds/",
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

Widget _buildGrid({
  required List<String?> items,
  required bool Function(String?) isUnlocked,
  required String assetFolder,
}) {
  return GridView.builder(
    physics: const ClampingScrollPhysics(),
    itemCount: 25,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 36,
      childAspectRatio: 0.75, // iets hoger dan breed → ruimte voor nummer
    ),
    itemBuilder: (context, index) {
      final id = items[index];

      return Stack(
        alignment: Alignment.topCenter,
        children: [

          // ====== VIERKANT ======
          Align(
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.brown.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: id == null
                    ? const SizedBox()
                    : isUnlocked(id)
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              "$assetFolder$id.png",
                              fit: BoxFit.contain,
                            ),
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
                                  child: Image.asset(
                                    "$assetFolder$id.png",
                                    color: Colors.black,
                                    colorBlendMode: BlendMode.srcATop,
                                  ),
                                ),
                                Container(
                                  color: Colors.black.withOpacity(0.45),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),

          // ====== NUMMER ======
          Positioned(
            bottom: 0,
            child: Text(
              "#${index + 1}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}
}