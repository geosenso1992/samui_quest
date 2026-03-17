import 'dart:ui';
import 'package:flutter/material.dart';

class AllMapsScreen extends StatelessWidget {
  const AllMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> maps = [
      {
        "name": "Europe",
        "image": "assets/maps/Europe.png",
        "silhouette": false,
        "locked": false,
      },
      {
        "name": "Africa ",
        "image": "assets/maps/Africa.png",
        "silhouette": true,
        "locked": true,
      },
      {
        "name": "Asia",
        "image": "assets/maps/Asia.png",
        "silhouette": true,
        "locked": true,
      },
      {
        "name": "Australia",
        "image": "assets/maps/Australia.png",
        "silhouette": true,
        "locked": true,
      },
      {
        "name": "South America",
        "image": "assets/maps/South_America.png",
        "silhouette": true,
        "locked": true,
      },
      {
        "name": "North America",
        "image": "assets/maps/North_America.png",
        "silhouette": true,
        "locked": true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Continents"),
        foregroundColor: const Color(0xFFFFCC00),
        backgroundColor: const Color(0xFF1F2A66),
        elevation: 0,
      ),
      body: Stack(
        children: [

          // 🌴 Jungle Background
          Positioned.fill(
            child: Image.asset(
              "assets/maps/jungle.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // 🌑 Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),

          // 🗺 Grid Content
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: maps.length,
            itemBuilder: (context, index) {
              return _MapTile(
                name: maps[index]["name"] as String,
                imagePath: maps[index]["image"] as String,
                useSilhouette: maps[index]["silhouette"] as bool,
                isLocked: maps[index]["locked"] as bool,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapTile extends StatefulWidget {
  final String name;
  final String imagePath;
  final bool useSilhouette;
  final bool isLocked;

  const _MapTile({
    required this.name,
    required this.imagePath,
    required this.useSilhouette,
    required this.isLocked,
  });

  @override
  State<_MapTile> createState() => _MapTileState();
}

class _MapTileState extends State<_MapTile> {
  void _handleTap() {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        children: [
          // 🏝 Island Name
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // beter zichtbaar op jungle
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: widget.useSilhouette
                            ? const ColorFilter.mode(
                                Colors.black87,
                                BlendMode.saturation,
                              )
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              ),
                        child: Image.asset(
                          widget.imagePath,
                          width: 250,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),

                      if (widget.useSilhouette)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),

                      // Lock overlay
                      if (widget.isLocked)
                        Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.lock,
                                  color: Color(0xFFFFCC00),
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Buy flight ticket!\nUnlock at Level 100\nOr get Pro!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFFFCC00),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
