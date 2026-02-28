import 'package:flutter/material.dart';
import '../models/avatars.dart';

class AvatarSelectScreen extends StatelessWidget {
  const AvatarSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🌴 Jungle achtergrond
          Positioned.fill(
            child: Image.asset(
              "assets/maps/jungle.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // Donkere overlay voor leesbaarheid
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                const SizedBox(height: 20),

                const Text(
                  "Choose Your Explorer",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: PlayerAvatar.values.map((avatar) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context, avatar);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  avatar.assetPath,
                                  height: 90,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  avatar.displayName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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