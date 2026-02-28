import 'dart:ui';
import 'package:flutter/material.dart';

class AllMapsScreen extends StatelessWidget {
  const AllMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> maps = [
      {
        "name": "Koh Phangan",
        "image": "assets/maps/Phangan.png",
      },
      {
        "name": "Koh Tao",
        "image": "assets/maps/Tao.png",
      },
      {
        "name": "Phuket",
        "image": "assets/maps/Phuket.png",
      },
      {
        "name": "Koh Chang",
        "image": "assets/maps/Chang.png",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore All Maps"),
        backgroundColor: Colors.green.shade900,
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
                name: maps[index]["name"]!,
                imagePath: maps[index]["image"]!,
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

  const _MapTile({
    required this.name,
    required this.imagePath,
  });

  @override
  State<_MapTile> createState() => _MapTileState();
}

class _MapTileState extends State<_MapTile> {
  bool _isRevealed = false;
  bool _isHovering = false;

  void _handleTap() {
    setState(() {
      _isRevealed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "This map can be unlocked once you're located here",
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
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
                      Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                      ),

                      if (!_isRevealed && !_isHovering)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}