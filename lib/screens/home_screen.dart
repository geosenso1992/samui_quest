import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/audio_service.dart';

import 'how_to_play_screen.dart';
import 'all_maps.dart';
import 'avatar_select_screen.dart';
import 'map_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  bool _showMenu = false;

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final game = context.read<GameProvider>();
      game.loadLocations();
      game.startTracking();
    });

    // ✅ START JUNGLE AUDIO
    _startAudio();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: const Interval(0.8, 1.0),
      ),
    );

    _zoomController.forward();

    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showMenu = true;
        });
      }
    });
  }

  // ✅ FIXED AUDIO START METHOD
  Future<void> _startAudio() async {
    await AudioService().init();
    await AudioService().playBackground();
  }

  @override
  void dispose() {
    _zoomController.dispose();

    // ❌ REMOVED stopBackground() HERE
    // We let MapScreen replace the music instead.

    super.dispose();
  }

  void _openHowToPlayScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HowToPlayScreen(),
      ),
    );
  }

  void _openExploreMaps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AllMapsScreen(),
      ),
    );
  }

void _openSinglePlayer() async {
  final selectedAvatar = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AvatarSelectScreen(),
    ),
  );

 if (selectedAvatar != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MapScreen(
  selectedAvatar: selectedAvatar,
),
    ),
  );
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _showMenu ? _buildMenu() : _buildSplash(),
      ),
    );
  }

  Widget _buildSplash() {
    return AnimatedBuilder(
      key: const ValueKey("splash"),
      animation: _zoomController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _zoomAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/samui2.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenu() {
    return Container(
      key: const ValueKey("menu"),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/samui2.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Samui\nAdventure\nQuest",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 50),

              _menuButton("Singleplayer"),
              const SizedBox(height: 30),

              _menuButton("Multiplayer"),
              const SizedBox(height: 30),

              _menuButton("How to Play"),
              const SizedBox(height: 30),

              _menuButton("Explore All Maps"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String text) {
    return ElevatedButton(
      onPressed: () {
        if (text == "How to Play") {
          _openHowToPlayScreen();
        } else if (text == "Explore All Maps") {
          _openExploreMaps();
        } else {
          _openSinglePlayer();
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(220, 60),
        backgroundColor: text == "How to Play"
            ? Colors.green.shade700
            : text == "Explore All Maps"
                ? Colors.orange.shade700
                : Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}