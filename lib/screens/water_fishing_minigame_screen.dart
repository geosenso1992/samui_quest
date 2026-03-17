import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../models/animal_metadata.dart';
import '../models/minigame_result.dart';

enum FishingDepthLayer { surface, mid, deep }

enum _DuelPhase { ready, castMiss, hooked, success, failed }

enum _PullDirection { left, right, down, up }

enum _FishPattern { steady, sprinter, trickster }

class WaterFishingMiniGameScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final String avatarAssetPath;
  final bool hasReelBoost;
  final bool hasLineElasticity;
  final bool hasPredictiveRipple;

  const WaterFishingMiniGameScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    required this.avatarAssetPath,
    required this.hasReelBoost,
    required this.hasLineElasticity,
    required this.hasPredictiveRipple,
  });

  @override
  State<WaterFishingMiniGameScreen> createState() =>
      _WaterFishingMiniGameScreenState();
}

class _WaterFishingMiniGameScreenState
    extends State<WaterFishingMiniGameScreen> {
  late final UnderwaterFishingGame _game;

  @override
  void initState() {
    super.initState();
    _game = UnderwaterFishingGame(
      animalId: widget.animalId,
      avatarAssetPath: widget.avatarAssetPath,
      hasReelBoost: widget.hasReelBoost,
      hasLineElasticity: widget.hasLineElasticity,
      hasPredictiveRipple: widget.hasPredictiveRipple,
      onResolved: (result) {
        if (!mounted) return;
        Navigator.pop(context, result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041223),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _game.handleTap(details.localPosition),
                onPanEnd: (details) =>
                    _game.handleSwipe(details.velocity.pixelsPerSecond),
                child: GameWidget(game: _game),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: ValueListenableBuilder<FishingHudData>(
                valueListenable: _game.hud,
                builder: (context, hud, _) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water,
                                size: 16, color: Colors.cyanAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Underwater Duel: ${widget.animalName}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(
                                context,
                                const MiniGameResult.failed(),
                              ),
                              child: const Text("Skip"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Time left: ${hud.timeLeftSeconds}s",
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _DepthChip(
                              label: "Surface",
                              selected: hud.depth == FishingDepthLayer.surface,
                              onTap: () =>
                                  _game.setDepth(FishingDepthLayer.surface),
                            ),
                            _DepthChip(
                              label: "Mid",
                              selected: hud.depth == FishingDepthLayer.mid,
                              onTap: () =>
                                  _game.setDepth(FishingDepthLayer.mid),
                            ),
                            _DepthChip(
                              label: "Deep",
                              selected: hud.depth == FishingDepthLayer.deep,
                              onTap: () =>
                                  _game.setDepth(FishingDepthLayer.deep),
                            ),
                            if (widget.hasReelBoost)
                              _DepthChip(
                                label:
                                    hud.boostReady ? "Reel Boost" : "Boost CD",
                                selected: false,
                                onTap: _game.triggerReelBoost,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: ValueListenableBuilder<FishingHudData>(
                valueListenable: _game.hud,
                builder: (context, hud, _) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hud.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _MeterRow(
                          label: "Tension",
                          value: hud.tension,
                          color: const Color(0xFFFFB74D),
                          range: hud.safeZone,
                        ),
                        const SizedBox(height: 6),
                        _MeterRow(
                          label: "Fish stamina",
                          value: hud.stamina,
                          color: const Color(0xFF66BB6A),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Pull: ${hud.pullHint} | Rub risk: ${(hud.rubRisk * 100).round()}%",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (hud.predatorActive)
                              const Text(
                                "Predator incoming!",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DepthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D6DA3) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30, width: 0.9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MeterRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final RangeValues? range;

  const _MeterRow({
    required this.label,
    required this.value,
    required this.color,
    this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              SizedBox(
                height: 11,
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  backgroundColor: Colors.white12,
                ),
              ),
              if (range != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SafeZonePainter(range!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafeZonePainter extends CustomPainter {
  final RangeValues range;

  const _SafeZonePainter(this.range);

  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * range.start;
    final width = size.width * (range.end - range.start);
    final paint = Paint()..color = Colors.greenAccent.withValues(alpha: 0.22);
    canvas.drawRect(Rect.fromLTWH(left, 0, width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SafeZonePainter oldDelegate) =>
      oldDelegate.range != range;
}

class FishingHudData {
  final String status;
  final double tension;
  final double stamina;
  final double rubRisk;
  final RangeValues safeZone;
  final bool predatorActive;
  final String pullHint;
  final FishingDepthLayer depth;
  final bool boostReady;
  final int timeLeftSeconds;

  const FishingHudData({
    required this.status,
    required this.tension,
    required this.stamina,
    required this.rubRisk,
    required this.safeZone,
    required this.predatorActive,
    required this.pullHint,
    required this.depth,
    required this.boostReady,
    required this.timeLeftSeconds,
  });

  factory FishingHudData.initial() {
    return const FishingHudData(
      status: "Tap a moving ripple to cast",
      tension: 0.5,
      stamina: 1,
      rubRisk: 0,
      safeZone: RangeValues(0.4, 0.6),
      predatorActive: false,
      pullHint: "none",
      depth: FishingDepthLayer.mid,
      boostReady: true,
      timeLeftSeconds: 50,
    );
  }
}

class UnderwaterFishingGame extends FlameGame {
  final String animalId;
  final String avatarAssetPath;
  final bool hasReelBoost;
  final bool hasLineElasticity;
  final bool hasPredictiveRipple;
  final void Function(MiniGameResult result) onResolved;

  final math.Random _rng = math.Random();
  final ValueNotifier<FishingHudData> hud =
      ValueNotifier(FishingHudData.initial());

  Sprite? _avatarSprite;
  Sprite? _animalSprite;

  late final _FishPattern _fishPattern;
  late final FishingDepthLayer _preferredDepth;

  _DuelPhase _phase = _DuelPhase.ready;
  FishingDepthLayer _selectedDepth = FishingDepthLayer.mid;
  _PullDirection _pullDirection = _PullDirection.left;

  Offset _fish = const Offset(280, 300);
  Offset _fishVelocity = const Offset(-65, -12);
  Offset _hook = const Offset(140, 220);
  Offset _predator = const Offset(0, 0);
  Offset? _castPoint;

  double _elapsed = 0;
  double _rippleX = 220;
  double _rippleSpeed = 84;
  double _tension = 0.5;
  double _fishStamina = 1;
  double _rubRisk = 0;
  double _timeHooked = 0;
  double _nextPullSwitchAt = 1.2;
  double _nextBubbleAt = 0.2;
  double _nextWeedSpikeAt = 2.8;
  double _predatorProgress = -1;
  double _boostCooldown = 0;
  double _boostTimeLeft = 0;

  String _status = "Tap a moving ripple to cast";
  bool _resolved = false;
  static const double _timeLimitSeconds = 50;

  UnderwaterFishingGame({
    required this.animalId,
    required this.avatarAssetPath,
    required this.hasReelBoost,
    required this.hasLineElasticity,
    required this.hasPredictiveRipple,
    required this.onResolved,
  }) {
    final rarity =
        kAnimalMetadataByName[animalId]?.rarity ?? AnimalRarity.common;
    if (rarity == AnimalRarity.special) {
      _fishPattern = _FishPattern.trickster;
    } else if (animalId.hashCode % 3 == 0) {
      _fishPattern = _FishPattern.sprinter;
    } else {
      _fishPattern = _FishPattern.steady;
    }
    _preferredDepth = FishingDepthLayer.values[animalId.hashCode.abs() % 3];
  }

  @override
  Future<void> onLoad() async {
    _avatarSprite =
        await Sprite.load(avatarAssetPath, images: Images(prefix: ""));
    _animalSprite = await Sprite.load(
      "assets/animals/icons_300/$animalId.png",
      images: Images(prefix: ""),
    );
    _pushHud();
  }

  double get _surfaceY => size.y * 0.25;

  RangeValues get _safeZone {
    if (hasLineElasticity) {
      return const RangeValues(0.32, 0.68);
    }
    return const RangeValues(0.40, 0.60);
  }

  double get _depthY {
    switch (_selectedDepth) {
      case FishingDepthLayer.surface:
        return _surfaceY + 48;
      case FishingDepthLayer.mid:
        return _surfaceY + (size.y * 0.28);
      case FishingDepthLayer.deep:
        return _surfaceY + (size.y * 0.52);
    }
  }

  Offset get _rodTip => Offset(size.x * 0.21, _surfaceY - 18);

  Offset get _avatarPos => Offset(size.x * 0.15, _surfaceY - 58);

  Rect get _rockHazard =>
      Rect.fromLTWH(size.x * 0.58, _surfaceY + 0.45 * size.y, 80, 54);

  Rect get _seaweedHazard =>
      Rect.fromLTWH(size.x * 0.34, _surfaceY + 0.34 * size.y, 58, 88);

  void setDepth(FishingDepthLayer depth) {
    _selectedDepth = depth;
    if (_phase == _DuelPhase.ready || _phase == _DuelPhase.castMiss) {
      _status = "Depth set to ${depth.name}. Tap ripple to cast.";
    }
    _pushHud();
  }

  void triggerReelBoost() {
    if (!hasReelBoost || _boostCooldown > 0 || _phase != _DuelPhase.hooked) {
      return;
    }
    _boostCooldown = 6.0;
    _boostTimeLeft = 1.2;
    _status = "Reel boost active";
    _pushHud();
  }

  void handleTap(Offset localPosition) {
    if (_phase == _DuelPhase.success || _phase == _DuelPhase.failed) return;
    if (_phase == _DuelPhase.hooked) return;

    final rippleCenter = Offset(_rippleX, _surfaceY + 10);
    if ((localPosition - rippleCenter).distance > 44) {
      _status = "Aim for the moving ripple zone";
      _pushHud();
      return;
    }

    _castPoint = Offset(_rippleX, _depthY);
    _hook = _castPoint!;

    final depthMatch = _selectedDepth == _preferredDepth;
    final distance = (_fish - _hook).distance;
    final hookChance = depthMatch
        ? (distance < 130 ? 0.9 : 0.58)
        : (distance < 100 ? 0.35 : 0.18);
    final hooked = _rng.nextDouble() < hookChance;

    if (!hooked) {
      _phase = _DuelPhase.castMiss;
      _status = depthMatch
          ? "Missed hook. Recast quickly."
          : "Wrong depth band. Try ${_preferredDepth.name}.";
      _pushHud();
      return;
    }

    _phase = _DuelPhase.hooked;
    _timeHooked = 0;
    _tension = 0.5;
    _rubRisk = 0;
    _fishStamina = 1;
    _nextPullSwitchAt = 0.8;
    _status = "Hooked! Swipe opposite to the pull direction.";
    _pushHud();
  }

  void handleSwipe(Offset velocity) {
    if (_phase != _DuelPhase.hooked) return;
    if (velocity.distance < 150) return;

    _PullDirection swipeDir;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      swipeDir = velocity.dx > 0 ? _PullDirection.right : _PullDirection.left;
    } else {
      swipeDir = velocity.dy > 0 ? _PullDirection.down : _PullDirection.up;
    }

    final expected = _oppositeOf(_pullDirection);
    if (swipeDir == expected) {
      final signed = _tension - 0.5;
      _tension -= signed.sign * 0.16;
      _status = "Good counter";
    } else {
      _tension += _pullDirection == _PullDirection.down ? 0.10 : 0.08;
      _status = "Wrong direction";
    }
    _tension = _tension.clamp(0.0, 1.0);
    _pushHud();
  }

  _PullDirection _oppositeOf(_PullDirection d) {
    switch (d) {
      case _PullDirection.left:
        return _PullDirection.right;
      case _PullDirection.right:
        return _PullDirection.left;
      case _PullDirection.down:
        return _PullDirection.up;
      case _PullDirection.up:
        return _PullDirection.down;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (size == Vector2.zero()) return;
    _elapsed += dt;

    _updateRipple(dt);
    _updateFishMovement(dt);

    if (_elapsed >= _nextBubbleAt) {
      _nextBubbleAt = _elapsed + 0.28 + (_rng.nextDouble() * 0.18);
      _emitBubbles(_fish + const Offset(0, -8));
    }
    if (_phase != _DuelPhase.success &&
        _phase != _DuelPhase.failed &&
        _elapsed >= _timeLimitSeconds) {
      _fail("Time's up. Fish escaped.");
      return;
    }

    if (_boostCooldown > 0) {
      _boostCooldown = (_boostCooldown - dt).clamp(0.0, 999);
    }
    if (_boostTimeLeft > 0) {
      _boostTimeLeft = (_boostTimeLeft - dt).clamp(0.0, 999);
    }

    if (_phase == _DuelPhase.hooked) {
      _updateDuel(dt);
    }
  }

  void _updateRipple(double dt) {
    _rippleX += _rippleSpeed * dt;
    if (_rippleX < size.x * 0.36) {
      _rippleX = size.x * 0.36;
      _rippleSpeed = _rippleSpeed.abs();
    } else if (_rippleX > size.x * 0.92) {
      _rippleX = size.x * 0.92;
      _rippleSpeed = -_rippleSpeed.abs();
    }
  }

  void _updateFishMovement(double dt) {
    final depthTarget = switch (_preferredDepth) {
      FishingDepthLayer.surface => _surfaceY + 70,
      FishingDepthLayer.mid => _surfaceY + size.y * 0.36,
      FishingDepthLayer.deep => _surfaceY + size.y * 0.58,
    };

    final phaseY = math.sin(_elapsed * 1.8) * 28;
    _fishVelocity = Offset(
      _fishVelocity.dx,
      ((_fishVelocity.dy * 0.92) + ((depthTarget + phaseY - _fish.dy) * 0.12)),
    );
    _fish += Offset(_fishVelocity.dx * dt, _fishVelocity.dy * dt);
    if (_fish.dx < size.x * 0.35 || _fish.dx > size.x * 0.95) {
      _fishVelocity = Offset(-_fishVelocity.dx, _fishVelocity.dy);
    }
    _fish = Offset(
      _fish.dx.clamp(size.x * 0.35, size.x * 0.95),
      _fish.dy.clamp(_surfaceY + 40, size.y - 35),
    );
  }

  void _updateDuel(double dt) {
    _timeHooked += dt;
    _hook = _fish;

    if (_timeHooked >= _nextPullSwitchAt) {
      _switchPull();
      _nextPullSwitchAt = _timeHooked + 0.9 + (_rng.nextDouble() * 0.8);
    }

    final patternMultiplier = switch (_fishPattern) {
      _FishPattern.sprinter => _timeHooked < 5 ? 1.55 : 0.85,
      _FishPattern.trickster =>
        ((_timeHooked % 3.6) < 0.8 || (_timeHooked % 4.9) > 4.1) ? 1.7 : 0.6,
      _FishPattern.steady => 1.0,
    };

    final pullForce = switch (_pullDirection) {
      _PullDirection.left => -0.12,
      _PullDirection.right => 0.12,
      _PullDirection.down => 0.16,
      _PullDirection.up => -0.08,
    };

    _tension += pullForce * patternMultiplier * dt;

    if (_boostTimeLeft > 0) {
      _fishStamina -= 0.16 * dt;
    }

    final safe = _safeZone;
    final inSafe = _tension >= safe.start && _tension <= safe.end;
    _fishStamina -= (inSafe ? 0.095 : 0.022) * dt;

    if (_lineHitsRect(_rodTip, _hook, _rockHazard)) {
      _rubRisk = (_rubRisk + (0.38 * dt)).clamp(0.0, 1.0);
      _tension += 0.10 * dt;
    } else {
      _rubRisk = (_rubRisk - (0.20 * dt)).clamp(0.0, 1.0);
    }

    if (_lineHitsRect(_rodTip, _hook, _seaweedHazard) &&
        _timeHooked > _nextWeedSpikeAt) {
      _nextWeedSpikeAt = _timeHooked + 2.1 + _rng.nextDouble() * 2.4;
      _tension += 0.08 + _rng.nextDouble() * 0.07;
      _status = "Seaweed snag spike!";
    }

    if (_timeHooked > 11 && _predatorProgress < 0) {
      _predatorProgress = 0;
      _predator = Offset(size.x + 26, _hook.dy + 12);
    }
    if (_predatorProgress >= 0) {
      _predatorProgress += dt * 0.23;
      _predator = Offset(
        _predator.dx + ((_hook.dx - _predator.dx) * 0.08),
        _predator.dy + ((_hook.dy - _predator.dy) * 0.08),
      );
      if ((_predator - _hook).distance < 22) {
        _fail("Predator stole your catch.");
        return;
      }
    }

    _tension = _tension.clamp(0.0, 1.0);
    _fishStamina = _fishStamina.clamp(0.0, 1.0);

    if (_rubRisk >= 1) {
      _fail("Line rubbed on rocks and snapped.");
      return;
    }
    if (_tension <= 0.08) {
      _fail("Too loose. Fish escaped.");
      return;
    }
    if (_tension >= 0.92) {
      _fail("Too tight. Line snapped.");
      return;
    }
    if (_fishStamina <= 0) {
      _succeed();
      return;
    }

    _pushHud();
  }

  void _switchPull() {
    final values = _PullDirection.values;
    _pullDirection = values[_rng.nextInt(values.length)];
  }

  bool _lineHitsRect(Offset a, Offset b, Rect rect) {
    final center = rect.center;
    final line = b - a;
    final len2 = line.dx * line.dx + line.dy * line.dy;
    if (len2 == 0) return rect.contains(a);
    final t =
        (((center.dx - a.dx) * line.dx) + ((center.dy - a.dy) * line.dy)) /
            len2;
    final clampedT = t.clamp(0.0, 1.0);
    final closest =
        Offset(a.dx + line.dx * clampedT, a.dy + line.dy * clampedT);
    final radius = math.max(rect.width, rect.height) * 0.36;
    return (closest - center).distance <= radius;
  }

  void _emitBubbles(Offset origin) {
    add(
      ParticleSystemComponent(
        position: Vector2(origin.dx, origin.dy),
        particle: Particle.generate(
          count: 4,
          lifespan: 1.4,
          generator: (_) {
            final drift = (_rng.nextDouble() * 16) - 8;
            return MovingParticle(
              from: Vector2.zero(),
              to: Vector2(drift, -28 - (_rng.nextDouble() * 42)),
              child: CircleParticle(
                radius: 1.7 + (_rng.nextDouble() * 2.2),
                paint: Paint()
                  ..color = const Color(0xFFD6F5FF).withValues(
                    alpha: 0.42 + (_rng.nextDouble() * 0.28),
                  ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _succeed() {
    _phase = _DuelPhase.success;
    _status = "Catch secured!";
    _pushHud();
    if (_resolved) return;
    _resolved = true;
    Future.delayed(
      const Duration(milliseconds: 450),
      () => onResolved(
        MiniGameResult(
          didCatch: true,
          bonusXp: _elapsed <= 10 ? 5 : 0,
          elapsedSeconds: _elapsed.clamp(0, _timeLimitSeconds),
        ),
      ),
    );
  }

  void _fail(String message) {
    _phase = _DuelPhase.failed;
    _status = message;
    _pushHud();
    if (_resolved) return;
    _resolved = true;
    Future.delayed(
      const Duration(milliseconds: 420),
      () => onResolved(
        MiniGameResult.failed(
          elapsedSeconds: _elapsed.clamp(0, _timeLimitSeconds),
        ),
      ),
    );
  }

  void _pushHud() {
    hud.value = FishingHudData(
      status: _status,
      tension: _tension,
      stamina: _fishStamina,
      rubRisk: _rubRisk,
      safeZone: _safeZone,
      predatorActive: _predatorProgress >= 0,
      pullHint: switch (_pullDirection) {
        _PullDirection.left => "left",
        _PullDirection.right => "right",
        _PullDirection.down => "down",
        _PullDirection.up => "surface jump",
      },
      depth: _selectedDepth,
      boostReady: _boostCooldown <= 0,
      timeLeftSeconds: math.max(0, (_timeLimitSeconds - _elapsed).ceil()),
    );
  }

  @override
  void render(Canvas canvas) {
    _paintSkyAndWater(canvas);
    _paintEnvironment(canvas);
    _paintRipples(canvas);
    _paintLine(canvas);
    _paintSprites(canvas);
    super.render(canvas);
  }

  void _paintSkyAndWater(Canvas canvas) {
    final skyRect = Rect.fromLTWH(0, 0, size.x, _surfaceY);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFAEE6FF),
          Color(0xFF66BEE6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final waterRect = Rect.fromLTWH(0, _surfaceY, size.x, size.y - _surfaceY);
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0E8CB8),
          Color(0xFF0A4E7A),
          Color(0xFF052844),
        ],
        stops: [0.0, 0.45, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(waterRect);
    canvas.drawRect(waterRect, waterPaint);

    final surfacePaint = Paint()
      ..color = const Color(0xBBE0F7FF)
      ..strokeWidth = 2.2;
    canvas.drawLine(
        Offset(0, _surfaceY), Offset(size.x, _surfaceY), surfacePaint);

    for (var i = 0; i < 3; i++) {
      final x =
          (size.x * (0.2 + (i * 0.3))) + math.sin(_elapsed * 0.5 + i) * 16;
      final shaft =
          Rect.fromLTWH(x, _surfaceY + 6, size.x * 0.12, size.y * 0.55);
      canvas.drawRect(
        shaft,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x55D5F2FF), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(shaft),
      );
    }
  }

  void _paintEnvironment(Canvas canvas) {
    final rock = Paint()..color = const Color(0xFF4F5D75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(_rockHazard, const Radius.circular(10)),
      rock,
    );
    final seaweed = Paint()..color = const Color(0xAA2FAF7E);
    for (var i = 0; i < 5; i++) {
      final x = _seaweedHazard.left + 8 + i * 10;
      final top = _seaweedHazard.top + math.sin(_elapsed * 1.2 + i) * 8;
      canvas.drawLine(
        Offset(x, _seaweedHazard.bottom),
        Offset(x + math.sin(_elapsed * 1.8 + i) * 4, top),
        seaweed..strokeWidth = 3,
      );
    }

    if (_predatorProgress >= 0) {
      final predatorPaint = Paint()..color = const Color(0xFFB71C1C);
      final body = Rect.fromCenter(center: _predator, width: 36, height: 18);
      canvas.drawOval(body, predatorPaint);
      final finPath = Path()
        ..moveTo(_predator.dx + 14, _predator.dy)
        ..lineTo(_predator.dx + 24, _predator.dy - 8)
        ..lineTo(_predator.dx + 24, _predator.dy + 8)
        ..close();
      canvas.drawPath(finPath, predatorPaint);
    }
  }

  void _paintRipples(Canvas canvas) {
    final center = Offset(_rippleX, _surfaceY + 10);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE8FCFF).withValues(alpha: 0.8)
      ..strokeWidth = 1.3;
    canvas.drawCircle(center, 15 + math.sin(_elapsed * 4) * 2, p);
    canvas.drawCircle(center, 24 + math.sin(_elapsed * 3.3) * 3, p);

    if (hasPredictiveRipple) {
      final nextX =
          (_rippleX + _rippleSpeed * 0.9).clamp(size.x * 0.36, size.x * 0.92);
      final ghost = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x99C7F9FF)
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(nextX, _surfaceY + 10), 20, ghost);
    }
  }

  void _paintLine(Canvas canvas) {
    if (_phase == _DuelPhase.ready && _castPoint == null) return;
    final end = (_phase == _DuelPhase.hooked) ? _hook : (_castPoint ?? _hook);
    final linePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.4;
    canvas.drawLine(_rodTip, end, linePaint);
  }

  void _paintSprites(Canvas canvas) {
    _avatarSprite?.render(
      canvas,
      position: Vector2(_avatarPos.dx, _avatarPos.dy),
      size: Vector2(58, 58),
    );

    final fishSize = switch (kAnimalMetadataByName[animalId]?.appearingSize) {
      AnimalSize.small => 42.0,
      AnimalSize.big => 58.0,
      _ => 50.0,
    };
    _animalSprite?.render(
      canvas,
      position: Vector2(_fish.dx - fishSize / 2, _fish.dy - fishSize / 2),
      size: Vector2.all(fishSize),
      overridePaint: Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
  }
}
