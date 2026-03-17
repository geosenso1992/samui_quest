import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  bool _bgPlaying = false;
  double _bgTargetVolume = 0.12;
  bool _walkingEnabled = false;
  static const double _sfxToBgRatio = 0.8;

  AudioService._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _walkingPlayer = AudioPlayer();
  final AudioPlayer _collectPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  Future<void> _configureMixer(AudioPlayer player) async {
    await player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
  }

  Future<void> init() async {
    await _configureMixer(_bgPlayer);
    await _configureMixer(_walkingPlayer);
    await _configureMixer(_collectPlayer);
    await _configureMixer(_sfxPlayer);
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _walkingPlayer.setReleaseMode(ReleaseMode.loop);
    await _collectPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
  }

  double _fxVolume() {
    return (_bgTargetVolume * _sfxToBgRatio).clamp(0.0, 1.0);
  }

  Future<void> playCollect() async {
    await _collectPlayer.stop();
    await _collectPlayer.play(
      AssetSource('audio/collect_so.mp3'),
      volume: _fxVolume(),
    );
  }

  Future<void> playDigDirt() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(
      AssetSource('audio/dig_dirt.mp3'),
      volume: _fxVolume(),
    );
  }

  Future<void> playHarvest() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(
      AssetSource('audio/harvest.mp3'),
      volume: _fxVolume(),
    );
  }

  Future<void> playNewObjectUnlocked() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(
      AssetSource('audio/new_object_unlocked.mp3'),
      volume: _fxVolume(),
    );
  }

  Future<void> playNewBadge() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(
      AssetSource('audio/new_badge.mp3'),
      volume: _fxVolume(),
    );
  }

  Future<void> playBackground() async {
    if (_bgPlaying) return;

    const fadeSteps = 24;
    const fadeStepDelay = Duration(milliseconds: 300);

    await _bgPlayer.play(
      AssetSource('audio/background2.mp3'),
      volume: 0.0,
    );

    _bgPlaying = true;

    for (var i = 1; i <= fadeSteps; i++) {
      final v = (_bgTargetVolume * (i / fadeSteps))
          .clamp(0.0, _bgTargetVolume);
      await _bgPlayer.setVolume(v);
      await Future.delayed(fadeStepDelay);
    }
  }

  Future<void> setBackgroundVolume(
    double volume, {
    Duration duration = const Duration(seconds: 2),
  }) async {
    _bgTargetVolume = volume.clamp(0.0, 1.0);
    if (!_bgPlaying) return;
    if (duration == Duration.zero) {
      await _bgPlayer.setVolume(_bgTargetVolume);
      return;
    }
    const steps = 12;
    final stepDelay = duration ~/ steps;
    final current = _bgPlayer.volume;
    final delta = (_bgTargetVolume - current) / steps;
    for (var i = 0; i < steps; i++) {
      await _bgPlayer.setVolume((current + delta * (i + 1))
          .clamp(0.0, 1.0));
      await Future.delayed(stepDelay);
    }
  }

  Future<void> stopBackground() async {
    await _bgPlayer.stop();
    _bgPlaying = false;
  }

  Future<void> playWalking() async {
    if (!_walkingEnabled) return;
    await _walkingPlayer.setReleaseMode(ReleaseMode.loop);
    await _walkingPlayer.play(
      AssetSource('audio/walking.mp3'),
      volume: _fxVolume(),
    );
  }

  Future<void> ensureWalking() async {
    if (!_walkingEnabled) return;
    if (_walkingPlayer.state != PlayerState.playing) {
      await playWalking();
    }
  }

  Future<void> stopWalking() async {
    await _walkingPlayer.stop();
  }
}
