import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/animal_metadata.dart';
import '../models/minigame_result.dart';

enum LandPhase { setup, active, slowedSecure, struggle, success, failed }

enum TrapPlacementMode { bait, slowTrap }

class LandNetTrapMiniGameScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final String avatarAssetPath;
  final bool allowExtraBait;
  final bool allowExtraSlowTrap;

  const LandNetTrapMiniGameScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    required this.avatarAssetPath,
    required this.allowExtraBait,
    required this.allowExtraSlowTrap,
  });

  @override
  State<LandNetTrapMiniGameScreen> createState() =>
      _LandNetTrapMiniGameScreenState();
}

class _LandNetTrapMiniGameScreenState extends State<LandNetTrapMiniGameScreen> {
  late final LandNetTrapGame _game;

  @override
  void initState() {
    super.initState();
    _game = LandNetTrapGame(
      animalId: widget.animalId,
      avatarAssetPath: widget.avatarAssetPath,
      allowExtraBait: widget.allowExtraBait,
      allowExtraSlowTrap: widget.allowExtraSlowTrap,
      onResolved: (result) {
        if (!mounted) return;
        Navigator.pop(context, result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E2212),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _game.handleTap(details.localPosition),
                child: GameWidget(game: _game),
              ),
            ),
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: ValueListenableBuilder<LandHudData>(
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
                            const Icon(Icons.landscape,
                                color: Colors.lightGreenAccent, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Land Trap Duel: ${widget.animalName}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              "${hud.timeLeftSeconds}s",
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(
                                context,
                                const MiniGameResult.failed(),
                              ),
                              child: const Text("Skip"),
                            ),
                          ],
                        ),
                        Text(
                          hud.status,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Meter(label: "Stealth alert", value: hud.alert),
                        const SizedBox(height: 5),
                        if (hud.phase == LandPhase.setup)
                          Wrap(
                            spacing: 6,
                            children: [
                              _Chip(
                                label: "Place bait",
                                selected: hud.mode == TrapPlacementMode.bait,
                                onTap: () => _game
                                    .setPlacementMode(TrapPlacementMode.bait),
                              ),
                              _Chip(
                                label: "Place slow trap",
                                selected:
                                    hud.mode == TrapPlacementMode.slowTrap,
                                onTap: () => _game.setPlacementMode(
                                    TrapPlacementMode.slowTrap),
                              ),
                              _Chip(
                                label: "Start encounter",
                                selected: false,
                                onTap: _game.startEncounter,
                              ),
                            ],
                          ),
                        if (hud.phase == LandPhase.slowedSecure)
                          Text(
                            "Secure taps: ${hud.secureTaps}/6",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : Colors.white12,
          borderRadius: BorderRadius.circular(18),
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

class _Meter extends StatelessWidget {
  final String label;
  final double value;

  const _Meter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class LandHudData {
  final String status;
  final double alert;
  final int timeLeftSeconds;
  final LandPhase phase;
  final TrapPlacementMode mode;
  final int secureTaps;

  const LandHudData({
    required this.status,
    required this.alert,
    required this.timeLeftSeconds,
    required this.phase,
    required this.mode,
    required this.secureTaps,
  });

  factory LandHudData.initial() {
    return const LandHudData(
      status: "Place bait/traps, then start encounter.",
      alert: 0,
      timeLeftSeconds: 50,
      phase: LandPhase.setup,
      mode: TrapPlacementMode.bait,
      secureTaps: 0,
    );
  }
}

class LandNetTrapGame extends FlameGame {
  final String animalId;
  final String avatarAssetPath;
  final bool allowExtraBait;
  final bool allowExtraSlowTrap;
  final void Function(MiniGameResult result) onResolved;

  final ValueNotifier<LandHudData> hud = ValueNotifier(LandHudData.initial());
  final math.Random _rng = math.Random();

  static const double _timeLimitSeconds = 50;

  Sprite? _avatarSprite;
  Sprite? _animalSprite;

  LandPhase _phase = LandPhase.setup;
  TrapPlacementMode _mode = TrapPlacementMode.bait;
  Offset _animal = const Offset(250, 340);
  Offset _velocity = const Offset(105, -24);
  Offset _playerPos = const Offset(70, 280);
  double _elapsed = 0;
  double _alert = 0;
  double _secureTimer = 0;
  int _secureTaps = 0;
  bool _firstRareCatchTriggered = false;
  bool _resolved = false;
  double _slowEffectTime = 0;

  final List<Offset> _baitSpots = [];
  final List<Offset> _slowTraps = [];

  Offset? _aimPoint;
  Offset? _netCenter;
  double _netRadius = 0;
  double _netProgress = 0;
  bool _netInFlight = false;
  bool _netExpanding = false;
  bool _netHitThisCast = false;
  String _status = "Place bait/traps, then start encounter.";

  bool get _isRareOrSpecial {
    final rarity =
        kAnimalMetadataByName[animalId]?.rarity ?? AnimalRarity.common;
    return rarity != AnimalRarity.common;
  }

  int get _maxBaits => allowExtraBait ? 2 : 1;
  int get _maxSlowTraps => allowExtraSlowTrap ? 2 : 1;

  Rect get _terrainRect =>
      Rect.fromLTWH(0, size.y * 0.18, size.x, size.y * 0.82);
  Rect get _mudZone =>
      Rect.fromLTWH(size.x * 0.08, size.y * 0.68, size.x * 0.3, size.y * 0.17);
  Rect get _downhillZone =>
      Rect.fromLTWH(size.x * 0.58, size.y * 0.35, size.x * 0.36, size.y * 0.2);
  Rect get _tallGrassZone =>
      Rect.fromLTWH(size.x * 0.4, size.y * 0.58, size.x * 0.22, size.y * 0.24);

  LandNetTrapGame({
    required this.animalId,
    required this.avatarAssetPath,
    required this.allowExtraBait,
    required this.allowExtraSlowTrap,
    required this.onResolved,
  });

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

  void setPlacementMode(TrapPlacementMode mode) {
    if (_phase != LandPhase.setup) return;
    _mode = mode;
    _status = mode == TrapPlacementMode.bait
        ? "Tap terrain to place bait (max $_maxBaits)."
        : "Tap terrain to place slow traps (max $_maxSlowTraps).";
    _pushHud();
  }

  void startEncounter() {
    if (_phase != LandPhase.setup) return;
    _phase = LandPhase.active;
    _status = "Tap to throw net. Time your expansion.";
    _pushHud();
  }

  void handleTap(Offset localPos) {
    if (!_terrainRect.contains(localPos)) return;

    if (_phase == LandPhase.setup) {
      if (_mode == TrapPlacementMode.bait) {
        if (_baitSpots.length >= _maxBaits) return;
        _baitSpots.add(localPos);
      } else {
        if (_slowTraps.length >= _maxSlowTraps) return;
        _slowTraps.add(localPos);
      }
      _pushHud();
      return;
    }

    if (_phase == LandPhase.slowedSecure) {
      _secureTaps++;
      if (_secureTaps >= 6) {
        _succeed();
      }
      _pushHud();
      return;
    }

    if (_phase != LandPhase.active && _phase != LandPhase.struggle) return;
    if (_netInFlight || _netExpanding) return;

    _aimPoint = localPos;
    _netCenter = null;
    _netRadius = 0;
    _netProgress = 0;
    _netInFlight = true;
    _netExpanding = false;
    _netHitThisCast = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (size == Vector2.zero()) return;
    _elapsed += dt;

    if (_phase != LandPhase.success &&
        _phase != LandPhase.failed &&
        _elapsed >= _timeLimitSeconds) {
      _fail("Time's up. Animal fled.");
      return;
    }

    _playerPos = Offset(size.x * 0.11, size.y * 0.24);

    _updateAnimal(dt);
    _updateNet(dt);

    if (_phase == LandPhase.slowedSecure) {
      _secureTimer += dt;
      if (_secureTimer >= 1.8) {
        _phase = LandPhase.struggle;
        _status = "Struggle phase! Animal panicked.";
      }
    }

    if (_phase == LandPhase.struggle) {
      _alert = (_alert + 0.08 * dt).clamp(0.0, 1.0);
      if (_alert >= 1) {
        _fail("Max alert. Animal fled permanently.");
        return;
      }
    }

    _pushHud();
  }

  void _updateAnimal(double dt) {
    if (_phase == LandPhase.success || _phase == LandPhase.failed) return;
    if (_phase == LandPhase.setup) {
      _animal = Offset(
        size.x * 0.58 + math.sin(_elapsed * 1.2) * 38,
        size.y * 0.55 + math.cos(_elapsed * 1.1) * 20,
      );
      return;
    }

    if (_slowEffectTime > 0) {
      _slowEffectTime -= dt;
    }

    final nearestBait = _nearestTarget(_baitSpots, _animal);
    if (nearestBait != null && (nearestBait - _animal).distance > 12) {
      final toBait = nearestBait - _animal;
      final unit = toBait / (toBait.distance == 0 ? 1 : toBait.distance);
      _velocity = _velocity + (unit * 14 * dt);
    } else if (_rng.nextDouble() < 0.02) {
      _velocity = Offset(
        (_rng.nextDouble() * 220) - 110,
        (_rng.nextDouble() * 180) - 90,
      );
    }

    var speedMul = 1.0;
    if (_downhillZone.contains(_animal)) speedMul *= 1.28;
    if (_mudZone.contains(_animal)) speedMul *= 0.66;
    if (_slowEffectTime > 0) speedMul *= 0.62;
    if (_phase == LandPhase.struggle) speedMul *= 1.35;
    speedMul *= 1.0 + (_alert * 0.35);

    final next = _animal + (_velocity * dt * speedMul);
    var nx = next.dx;
    var ny = next.dy;
    if (nx < _terrainRect.left + 22 || nx > _terrainRect.right - 22) {
      _velocity = Offset(-_velocity.dx, _velocity.dy);
      nx = nx.clamp(_terrainRect.left + 22, _terrainRect.right - 22);
    }
    if (ny < _terrainRect.top + 26 || ny > _terrainRect.bottom - 22) {
      _velocity = Offset(_velocity.dx, -_velocity.dy);
      ny = ny.clamp(_terrainRect.top + 26, _terrainRect.bottom - 22);
    }
    _animal = Offset(nx, ny);

    for (final trap in _slowTraps) {
      if ((_animal - trap).distance < 26) {
        _slowEffectTime = 2.5;
      }
    }
  }

  void _updateNet(double dt) {
    if (_netInFlight) {
      _netProgress += dt / 0.24;
      if (_netProgress >= 1) {
        _netInFlight = false;
        _netExpanding = true;
        _netCenter = _aimPoint;
        _netProgress = 0;
      }
      return;
    }

    if (_netExpanding && _netCenter != null) {
      _netProgress += dt / 0.34;
      _netRadius =
          18 + (56 * Curves.easeOut.transform(_netProgress.clamp(0, 1)));
      final inTallGrass = _tallGrassZone.contains(_animal);
      final catchRadius = inTallGrass ? _netRadius * 0.72 : _netRadius;
      if ((_animal - _netCenter!).distance <= catchRadius) {
        _netHitThisCast = true;
      }
      if (_netProgress >= 1) {
        _resolveCast();
        _netExpanding = false;
        _netCenter = null;
        _netRadius = 0;
      }
    }
  }

  void _resolveCast() {
    if (_netHitThisCast) {
      if (_isRareOrSpecial && !_firstRareCatchTriggered) {
        _firstRareCatchTriggered = true;
        _phase = LandPhase.slowedSecure;
        _secureTimer = 0;
        _secureTaps = 0;
        _slowEffectTime = 2.0;
        _status = "Rare catch slowed. Tap quickly to secure!";
      } else {
        _succeed();
      }
      return;
    }

    _alert = (_alert + 0.24).clamp(0.0, 1.0);
    _status = _alert >= 0.75
        ? "Miss! High alert, animal is panicking."
        : "Miss! Alert increased.";
    if (_alert >= 1) {
      _fail("Max alert. Animal fled permanently.");
    }
  }

  Offset? _nearestTarget(List<Offset> targets, Offset from) {
    if (targets.isEmpty) return null;
    Offset? best;
    var bestDist = double.infinity;
    for (final t in targets) {
      final d = (t - from).distance;
      if (d < bestDist) {
        best = t;
        bestDist = d;
      }
    }
    return best;
  }

  void _succeed() {
    _phase = LandPhase.success;
    _status = "Capture secured!";
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
    _phase = LandPhase.failed;
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
    hud.value = LandHudData(
      status: _status,
      alert: _alert,
      timeLeftSeconds: math.max(0, (_timeLimitSeconds - _elapsed).ceil()),
      phase: _phase,
      mode: _mode,
      secureTaps: _secureTaps,
    );
  }

  @override
  void render(Canvas canvas) {
    _paintTerrain(canvas);
    _paintObjects(canvas);
    _paintAim(canvas);
    _paintSprites(canvas);
    super.render(canvas);
  }

  void _paintTerrain(Canvas canvas) {
    final skyRect = Rect.fromLTWH(0, 0, size.x, size.y * 0.18);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFAFE9FF), Color(0xFF75C5E7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(skyRect),
    );

    final terrain = _terrainRect;
    canvas.drawRect(
      terrain,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8CC36B), Color(0xFF4A7B41)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(terrain),
    );

    canvas.drawRect(_downhillZone, Paint()..color = const Color(0x554A7A31));
    canvas.drawRect(_mudZone, Paint()..color = const Color(0x886D4C41));
    canvas.drawRect(_tallGrassZone, Paint()..color = const Color(0x883B8D54));
  }

  void _paintObjects(Canvas canvas) {
    final baitPaint = Paint()..color = const Color(0xFFFFD54F);
    for (final b in _baitSpots) {
      canvas.drawCircle(b, 7, baitPaint);
    }

    final trapPaint = Paint()..color = const Color(0xFF90CAF9);
    for (final trap in _slowTraps) {
      canvas.drawCircle(trap, 10, trapPaint);
      canvas.drawCircle(
        trap,
        18 + math.sin(_elapsed * 5) * 1.5,
        trapPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      trapPaint.style = PaintingStyle.fill;
    }
  }

  void _paintAim(Canvas canvas) {
    if ((_phase != LandPhase.active && _phase != LandPhase.struggle) ||
        _aimPoint == null) {
      return;
    }

    final start = _playerPos + const Offset(20, 14);
    final end = _aimPoint!;
    final ctrl =
        Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 48);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(
      end,
      18,
      Paint()
        ..color = Colors.white60
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (_netCenter != null && _netRadius > 0) {
      canvas.drawCircle(
        _netCenter!,
        _netRadius,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  void _paintSprites(Canvas canvas) {
    _avatarSprite?.render(
      canvas,
      position: Vector2(_playerPos.dx, _playerPos.dy - 22),
      size: Vector2(52, 52),
    );

    final animalSize = switch (kAnimalMetadataByName[animalId]?.appearingSize) {
      AnimalSize.small => 42.0,
      AnimalSize.big => 58.0,
      _ => 50.0,
    };
    final inTallGrass = _tallGrassZone.contains(_animal);
    final alpha = inTallGrass ? 0.62 : 0.96;
    _animalSprite?.render(
      canvas,
      position:
          Vector2(_animal.dx - animalSize / 2, _animal.dy - animalSize / 2),
      size: Vector2.all(animalSize),
      overridePaint: Paint()..color = Colors.white.withValues(alpha: alpha),
    );
  }
}
