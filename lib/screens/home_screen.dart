import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';

import 'how_to_play_screen.dart';
import 'all_maps.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showMenuImmediately;

  const HomeScreen({
    super.key,
    this.showMenuImmediately = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _showMenu = false;
  bool _isSyncing = false;

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showMenu = widget.showMenuImmediately;

    final game = context.read<GameProvider>();
    game.loadLocations();
    game.startTracking();

    // START JUNGLE AUDIO
    _startAudio();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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

    if (!_showMenu) {
      _zoomController.forward();
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _showMenu = true;
          });
        }
      });
    }
  }

  Future<void> _startAudio() async {
    await AudioService().init();
    await AudioService().playBackground();
    await AudioService().setBackgroundVolume(0.12);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _zoomController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      context.read<GameProvider>().persistNow();
    }
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

  // Tijdelijk: altijd de monkey avatar gebruiken (geen keuzemenu)
  Future<void> _handleSinglePlayer(GameProvider game) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    game.currentAvatar = 'assets/monkey_player.png';
    var didSync = false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user session");
      }
      didSync = await game
          .syncUserDataWithFallback(user.uid)
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // ignore here, handled below
    } catch (_) {
      // ignore here, handled below
    } finally {
      if (!mounted) return;
      setState(() => _isSyncing = false);
    }

    if (!mounted) return;
    if (!didSync) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Offline mode: showing last saved data."),
        ),
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(selectedAvatar: game.currentAvatar),
      ),
    );
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

  String _startupBackgroundForOrientation(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape
        ? "assets/seedscape1.png"
        : "assets/seedscape2.png";
  }

  Widget _buildSplash() {
    final backgroundAsset = _startupBackgroundForOrientation(context);
    return AnimatedBuilder(
      key: const ValueKey("splash"),
      animation: _zoomController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _zoomAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundAsset),
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
    final backgroundAsset = _startupBackgroundForOrientation(context);
    final gameProvider = context.watch<GameProvider>();
    
    // Bepaal de tekst voor de hoofdknop
    String singlePlayerText = (gameProvider.username != 'Onbekende Speler') 
        ? "Continue Journey" 
        : "Singleplayer";

    return Stack(
      children: [
        Container(
        key: const ValueKey("menu"),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.cover,
          ),
        ),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Align(
          alignment: const Alignment(0, 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hoofdknop: Start of Continue
              _menuButton(singlePlayerText, () => _handleSinglePlayer(gameProvider)),
              const SizedBox(height: 20),

              _menuButton("Multiplayer", () {}),
              const SizedBox(height: 20),

              _menuButton("How to Play", _openHowToPlayScreen),
              const SizedBox(height: 20),

              _menuButton("Explore Continents", _openExploreMaps),
              const SizedBox(height: 30),

              _menuButton("Log out", () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              }),
            ],
          ),
        ),
      ),
    ),
        if (_isSyncing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Align(
                alignment: const Alignment(0, -0.5),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Loading your journey...",
                      style: TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _menuButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(250, 60),
        backgroundColor:
            const Color(0xFF1F2A66).withValues(alpha: 0.78),
        foregroundColor: const Color(0xFFFFCC00),
        side: BorderSide(
          color: const Color(0xFF11194A).withValues(alpha: 0.95),
          width: 2,
        ),
        elevation: 6,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(text),
    );
  }
}
