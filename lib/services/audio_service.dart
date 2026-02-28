import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _walkingPlayer = AudioPlayer();

  Future<void> init() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _walkingPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // 🌴 Jungle ambience (HomeScreen)
  Future<void> playBackground() async {
    await _bgPlayer.play(
      AssetSource('audio/jungle.mp3'),
      volume: 0.3,
    );
  }

  Future<void> stopBackground() async {
    await _bgPlayer.stop();
  }

  // 🚶 Walking music (MapScreen)
  Future<void> playWalking() async {
    await _walkingPlayer.play(
      AssetSource('audio/walking.mp3'),
      volume: 0.4,
    );
  }

  Future<void> stopWalking() async {
    await _walkingPlayer.stop();
  }
}