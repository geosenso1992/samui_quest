import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/minigame_result.dart';
import '../models/animal_metadata.dart';

enum _FlightPattern { glider, darter, hoverer }

class FlyingCatchMiniGameScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final bool allowMidAirAdjustment;
  final String avatarAssetPath;

  const FlyingCatchMiniGameScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    required this.allowMidAirAdjustment,
    required this.avatarAssetPath,
  });

  @override
  State<FlyingCatchMiniGameScreen> createState() =>
      _FlyingCatchMiniGameScreenState();
}

class _FlyingCatchMiniGameScreenState extends State<FlyingCatchMiniGameScreen> {
  static const double _gravity = 640;
  static const double _windChangeSeconds = 3.0;
  static const int _maxShots = 3;
  static const double _timeLimitSeconds = 50;

  final math.Random _random = math.Random();
  Timer? _ticker;

  Size _arenaSize = Size.zero;
  Offset _target = const Offset(220, 120);
  Offset _targetVelocity = const Offset(-70, 30);
  Offset? _projectile;
  Offset _projectileVelocity = Offset.zero;
  Offset? _dragPoint;
  double _elapsed = 0;
  double _windX = 0;
  double _nextWindAt = _windChangeSeconds;
  double _power = 0.55;
  bool _inFlight = false;
  bool _isEnding = false;
  int _shotsLeft = _maxShots;
  String _status = "Drag to aim. Set power on the right";
  bool _midAirUsed = false;
  Offset? _boomCenter;
  double _boomProgress = -1;
  final List<Offset> _leafPositions = [];
  final List<double> _leafSpeeds = [];
  late final _FlightPattern _pattern;

  @override
  void initState() {
    super.initState();
    _pattern = _patternForAnimal(widget.animalId);
    _initializeWind();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _tick(0.016);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _initializeWind() {
    _windX = _random.nextDouble() * 120 - 60;
  }

  _FlightPattern _patternForAnimal(String id) {
    const gliders = {'butterfly', 'dragonfly', 'kingfisher'};
    const darters = {'giant_hornet', 'mosquito'};
    if (gliders.contains(id)) return _FlightPattern.glider;
    if (darters.contains(id)) return _FlightPattern.darter;
    return _FlightPattern.hoverer;
  }

  Offset get _launchOrigin {
    final width = _arenaSize.width;
    final height = _arenaSize.height;
    return Offset(width * 0.18, height * 0.84);
  }

  double get _targetSpriteSize {
    final size = kAnimalMetadataByName[widget.animalId]?.appearingSize;
    switch (size) {
      case AnimalSize.small:
        return 42; // 1.5x larger than previous 28
      case AnimalSize.medium:
        return 30;
      case AnimalSize.big:
        return 34;
      default:
        return 30;
    }
  }

  void _ensureLeafField() {
    if (_arenaSize == Size.zero || _leafPositions.isNotEmpty) return;
    for (var i = 0; i < 8; i++) {
      _leafPositions.add(
        Offset(
          _random.nextDouble() * _arenaSize.width,
          _random.nextDouble() * _arenaSize.height * 0.8 + 20,
        ),
      );
      _leafSpeeds.add(_random.nextDouble() * 18 + 20);
    }
  }

  void _tick(double dt) {
    if (!mounted || _arenaSize == Size.zero) return;
    _ensureLeafField();
    _elapsed += dt;
    if (!_isEnding && _elapsed >= _timeLimitSeconds) {
      _finishFailure("Time's up. Animal escaped.");
      return;
    }

    if (!_isEnding) {
      if (_elapsed >= _nextWindAt) {
        _windX = _random.nextDouble() * 160 - 80;
        _nextWindAt += _windChangeSeconds + _random.nextDouble() * 1.7;
        if (_inFlight) {
          _status = "Wind gust changed";
        }
      }

      _updateLeaves(dt);
      _updateTarget(dt);
      _updateProjectile(dt);
    }
    if (_boomProgress >= 0) {
      _boomProgress += dt * 2.6;
      if (_boomProgress >= 1.0) {
        _boomProgress = -1;
        _boomCenter = null;
      }
    }
    if (mounted) setState(() {});
  }

  void _updateLeaves(double dt) {
    for (var i = 0; i < _leafPositions.length; i++) {
      final p = _leafPositions[i];
      final leafVx = (_windX * 0.35) + _leafSpeeds[i];
      var nx = p.dx + leafVx * dt;
      var ny = p.dy + (14 + _leafSpeeds[i] * 0.08) * dt;
      if (nx > _arenaSize.width + 20) nx = -20;
      if (nx < -20) nx = _arenaSize.width + 20;
      if (ny > _arenaSize.height - 20) ny = 20;
      _leafPositions[i] = Offset(nx, ny);
    }
  }

  void _updateTarget(double dt) {
    final width = _arenaSize.width;
    final height = _arenaSize.height;
    switch (_pattern) {
      case _FlightPattern.glider:
        final x = (width * 0.7) + math.sin(_elapsed * 0.8) * (width * 0.23);
        final y = (height * 0.25) + math.sin(_elapsed * 2.1) * (height * 0.09);
        _target = Offset(x, y);
        break;
      case _FlightPattern.darter:
        var vx = _targetVelocity.dx;
        var vy = _targetVelocity.dy;
        if ((_elapsed * 10).floor() % 7 == 0 && _random.nextDouble() < 0.06) {
          vx = _random.nextDouble() * 240 - 180;
          vy = _random.nextDouble() * 220 - 110;
          _targetVelocity = Offset(vx, vy);
        }
        var next = _target + Offset(vx * dt, vy * dt);
        if (next.dx < 40 || next.dx > width - 40) {
          vx = -vx;
          _targetVelocity = Offset(vx, vy);
          next = _target + Offset(vx * dt, vy * dt);
        }
        if (next.dy < 50 || next.dy > height * 0.58) {
          vy = -vy;
          _targetVelocity = Offset(vx, vy);
          next = _target + Offset(vx * dt, vy * dt);
        }
        _target = next;
        break;
      case _FlightPattern.hoverer:
        final hover = (_elapsed % 3.2) < 1.6;
        if (hover) {
          _target = Offset(
            _target.dx + math.sin(_elapsed * 4) * 0.7,
            _target.dy + math.cos(_elapsed * 4.5) * 0.45,
          );
        } else {
          final dashX = math.sin(_elapsed * 2.8) * 140;
          final dashY = math.cos(_elapsed * 3.1) * 80;
          _target = Offset(
            (width * 0.62) + dashX,
            (height * 0.28) + dashY,
          );
        }
        _target = Offset(
          _target.dx.clamp(40, width - 40),
          _target.dy.clamp(52, height * 0.62),
        );
        break;
    }
  }

  void _updateProjectile(double dt) {
    if (!_inFlight || _projectile == null) return;
    _projectileVelocity = Offset(
      _projectileVelocity.dx + (_windX * 0.22) * dt,
      _projectileVelocity.dy + _gravity * dt,
    );
    _projectile = _projectile! +
        Offset(
          _projectileVelocity.dx * dt,
          _projectileVelocity.dy * dt,
        );

    final p = _projectile!;
    final d = (p - _target).distance;
    if (d <= 24) {
      _finishSuccess("Perfect intercept! Combo bonus");
      return;
    }
    if (d <= 38) {
      _finishSuccess("Inner zone catch! Bonus capture");
      return;
    }
    if (d <= 56) {
      final caught = _random.nextDouble() < 0.72;
      if (caught) {
        _finishSuccess("Outer zone catch!");
      } else {
        _status = "Graze! Try leading a bit more";
      }
      return;
    }

    if (p.dx < -30 ||
        p.dx > _arenaSize.width + 30 ||
        p.dy < -30 ||
        p.dy > _arenaSize.height + 30) {
      _inFlight = false;
      _projectile = null;
      _projectileVelocity = Offset.zero;
      _shotsLeft--;
      _midAirUsed = false;
      if (_shotsLeft <= 0) {
        _finishFailure();
      } else {
        _status = "Missed. $_shotsLeft shot(s) left";
      }
    }
  }

  void _finishSuccess(String message) {
    if (_isEnding) return;
    _isEnding = true;
    setState(() {
      _inFlight = false;
      _projectile = null;
      _projectileVelocity = Offset.zero;
      _status = message;
      _boomCenter = _target;
      _boomProgress = 0;
    });
    Future.delayed(const Duration(milliseconds: 760), () {
      if (!mounted) return;
      Navigator.pop(
        context,
        MiniGameResult(
          didCatch: true,
          bonusXp: _elapsed <= 10 ? 5 : 0,
          elapsedSeconds: _elapsed.clamp(0, _timeLimitSeconds),
        ),
      );
    });
  }

  void _finishFailure([String message = "Animal escaped this time"]) {
    if (_isEnding) return;
    _isEnding = true;
    setState(() {
      _status = message;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pop(
        context,
        MiniGameResult.failed(
          elapsedSeconds: _elapsed.clamp(0, _timeLimitSeconds),
        ),
      );
    });
  }

  Offset _launchVelocityFromDrag(Offset dragPoint) {
    final raw = _launchOrigin - dragPoint;
    if (raw.distance == 0) {
      return const Offset(250, -260);
    }
    final unit = raw / raw.distance;
    final speed = 240 + (700 * _power);
    return Offset(
      unit.dx * speed,
      unit.dy * speed,
    );
  }

  List<Offset> _buildPreviewArc() {
    if (_dragPoint == null || _inFlight) return const [];
    var pos = _launchOrigin;
    var vel = _launchVelocityFromDrag(_dragPoint!);
    final points = <Offset>[];
    for (var i = 0; i < 28; i++) {
      vel = Offset(
        vel.dx + (_windX * 0.22) * 0.05,
        vel.dy + _gravity * 0.05,
      );
      pos = pos + Offset(vel.dx * 0.05, vel.dy * 0.05);
      if (pos.dy > _arenaSize.height || pos.dx > _arenaSize.width) break;
      points.add(pos);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1321),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _arenaSize = Size(constraints.maxWidth, constraints.maxHeight - 84);
            final windArrow = _windX >= 0 ? "->" : "<-";
            final arcPoints = _buildPreviewArc();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A2E52).withValues(alpha: 0.92),
                          const Color(0xFF13304A).withValues(alpha: 0.92),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white38, width: 1.1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.track_changes,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            "Sky Catapult: ${widget.animalName}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: Colors.lightGreenAccent, width: 0.9),
                          ),
                          child: Text(
                            "Wind $windArrow ${_windX.abs().toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: Colors.amberAccent, width: 0.9),
                          ),
                          child: Text(
                            "Time ${(math.max(0, _timeLimitSeconds - _elapsed)).ceil()}s",
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _inFlight
                        ? null
                        : (d) {
                            setState(() {
                              _dragPoint = d.localPosition;
                              _status =
                                  "Release to fire (power ${(100 * _power).round()}%)";
                            });
                          },
                    onPanUpdate: _inFlight
                        ? null
                        : (d) {
                            setState(() {
                              _dragPoint = d.localPosition;
                            });
                          },
                    onPanEnd: _inFlight
                        ? null
                        : (_) {
                            if (_dragPoint == null) return;
                            setState(() {
                              _projectile = _launchOrigin;
                              _projectileVelocity =
                                  _launchVelocityFromDrag(_dragPoint!);
                              _dragPoint = null;
                              _inFlight = true;
                              _midAirUsed = false;
                              _status = widget.allowMidAirAdjustment
                                  ? "Tap once in-air to nudge shot"
                                  : "Projectile launched";
                            });
                          },
                    onTapDown: (details) {
                      if (!_inFlight ||
                          !widget.allowMidAirAdjustment ||
                          _midAirUsed ||
                          _projectile == null) {
                        return;
                      }
                      final nudge = details.localPosition - _projectile!;
                      if (nudge.distance < 1) return;
                      final unit = nudge / nudge.distance;
                      setState(() {
                        _projectileVelocity =
                            _projectileVelocity + (unit * 130);
                        _midAirUsed = true;
                        _status = "Mid-air adjustment used";
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/maps/fly_background2.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ArcPreviewPainter(points: arcPoints),
                            ),
                          ),
                          for (final leaf in _leafPositions)
                            Positioned(
                              left: leaf.dx,
                              top: leaf.dy,
                              child: Transform.rotate(
                                angle: _windX.sign * 0.4,
                                child: const Icon(
                                  Icons.eco,
                                  size: 12,
                                  color: Color(0x88C5E1A5),
                                ),
                              ),
                            ),
                          Positioned(
                            left: _target.dx - 14,
                            top: _target.dy - 14,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.lightBlueAccent
                                          .withValues(alpha: 0.8),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.amberAccent,
                                      width: 1.1,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  "assets/animals/icons_300/${widget.animalId}.png",
                                  width: _targetSpriteSize,
                                  height: _targetSpriteSize,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          // avatar placed just left of the catapult
                          Positioned(
                            left: _launchOrigin.dx - 120,
                            top: _launchOrigin.dy - 52,
                            child: Image.asset(
                              widget.avatarAssetPath,
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            left: _launchOrigin.dx - 40, // shifted 10px right
                            top: _launchOrigin.dy - 49,  // shifted 5px down
                            child: Image.asset(
                              "assets/Catapult1.png",
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (_dragPoint != null && !_inFlight)
                            CustomPaint(
                              size: _arenaSize,
                              painter: _SlingshotBandPainter(
                                from: _launchOrigin,
                                to: _dragPoint!,
                              ),
                            ),
                          if (_projectile != null)
                            Positioned(
                              left: _projectile!.dx - 8,
                              top: _projectile!.dy - 8,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAFAFA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Positioned(
                            right: 10,
                            bottom: 51,
                            child: Container(
                              width: 56,
                              height: 174,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white54,
                                  width: 1.1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "PWR",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                            enabledThumbRadius: 8,
                                          ),
                                        ),
                                        child: Slider(
                                          value: _power,
                                          min: 0.2,
                                          max: 1.0,
                                          activeColor: Colors.orangeAccent,
                                          inactiveColor: Colors.white30,
                                          onChanged: _inFlight
                                              ? null
                                              : (v) {
                                                  setState(() {
                                                    _power = v;
                                                  });
                                                },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${(100 * _power).round()}%",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_boomCenter != null && _boomProgress >= 0)
                            Positioned(
                              left: _boomCenter!.dx - 50,
                              top: _boomCenter!.dy - 50,
                              child: IgnorePointer(
                                child: Transform.scale(
                                  scale: 0.7 + (_boomProgress * 1.4),
                                  child: Opacity(
                                    opacity:
                                        (1.0 - _boomProgress).clamp(0.0, 1.0),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.amberAccent
                                                .withValues(alpha: 0.95),
                                            Colors.deepOrange
                                                .withValues(alpha: 0.86),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "BOOM!",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 6),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$_status  |  Shots: $_shotsLeft",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(
                          context,
                          MiniGameResult.failed(
                            elapsedSeconds:
                                _elapsed.clamp(0, _timeLimitSeconds),
                          ),
                        ),
                        child: const Text("Skip"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArcPreviewPainter extends CustomPainter {
  final List<Offset> points;

  const _ArcPreviewPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
    for (var i = 0; i < points.length; i += 2) {
      canvas.drawCircle(points[i], 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _SlingshotBandPainter extends CustomPainter {
  final Offset from;
  final Offset to;

  const _SlingshotBandPainter({
    required this.from,
    required this.to,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xCC5D4037)
      ..strokeWidth = 3;
    canvas.drawLine(from + const Offset(-8, -6), to, paint);
    canvas.drawLine(from + const Offset(8, -6), to, paint);
  }

  @override
  bool shouldRepaint(covariant _SlingshotBandPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}
