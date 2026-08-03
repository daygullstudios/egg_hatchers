import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/boss_finisher_rewards.dart';
import '../models/background_theme.dart';
import '../models/boss_battle.dart';
import '../models/finisher_reward.dart';
import 'boss_battle_background.dart';
import 'boss_sprite.dart';
import 'audio_scope.dart';

/// Five-second post-victory slash window before the boss defeat cinematic.
class BossFinisherSlashOverlay extends StatefulWidget {
  const BossFinisherSlashOverlay({
    super.key,
    required this.boss,
    required this.theme,
    required this.showBattleBackgrounds,
    required this.onComplete,
  });

  final BossBattleDefinition boss;
  final BackgroundTheme theme;
  final bool showBattleBackgrounds;
  final ValueChanged<FinisherRewardTotals> onComplete;

  @override
  State<BossFinisherSlashOverlay> createState() =>
      _BossFinisherSlashOverlayState();
}

class _BossFinisherSlashOverlayState extends State<BossFinisherSlashOverlay>
    with SingleTickerProviderStateMixin {
  static const _bossDisplaySize = 140.0;

  late final Ticker _ticker;
  late final Random _random;
  late final FinisherSlashStyle _style;

  var _elapsed = 0.0;
  var _completed = false;
  var _bonusRollCount = 0;
  var _lastRewardSlashMs = -1000.0;
  var _totals = const FinisherRewardTotals();
  Duration? _lastTickElapsed;

  Offset? _segmentStart;
  final List<_SlashVisual> _slashes = [];
  final List<_FloatingFinisherText> _floaters = [];

  @override
  void initState() {
    super.initState();
    _random = Random();
    _style = BossFinisherRewards.styleFor(widget.boss.id);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_completed || !mounted) return;
    final dt = _lastTickElapsed == null
        ? 0.0
        : (elapsed - _lastTickElapsed!).inMicroseconds / 1e6;
    _lastTickElapsed = elapsed;
    _elapsed = elapsed.inMicroseconds / 1e6;

    if (_elapsed >= BossFinisherRewards.slashWindowSeconds) {
      _finishOnce();
      return;
    }

    for (var i = _slashes.length - 1; i >= 0; i--) {
      _slashes[i].age += dt;
      if (_slashes[i].age > 0.45) _slashes.removeAt(i);
    }
    for (var i = _floaters.length - 1; i >= 0; i--) {
      _floaters[i].age += dt;
      if (_floaters[i].age > 1.4) _floaters.removeAt(i);
    }

    setState(() {});
  }

  void _finishOnce() {
    if (_completed) return;
    _completed = true;
    _ticker.stop();
    widget.onComplete(_totals);
  }

  Offset _bossCenter(Size size) => Offset(size.width / 2, size.height * 0.48);

  double get _bossHitRadius => _bossDisplaySize * 0.52;

  bool _segmentHitsBoss(Offset a, Offset b, Size size) {
    final center = _bossCenter(size);
    final ab = b - a;
    final ac = center - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1) return (center - a).distance <= _bossHitRadius;
    final t = ((ac.dx * ab.dx + ac.dy * ab.dy) / len2).clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (closest - center).distance <= _bossHitRadius;
  }

  void _registerSlash(Offset start, Offset end, Size size) {
    if ((end - start).distance < BossFinisherRewards.slashMinDistance) return;
    if (!_segmentHitsBoss(start, end, size)) return;

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    _slashes.add(_SlashVisual(start: start, end: end));
    AudioScope.maybeOf(context)?.playFinisherSlash();

    final elapsedMs = _elapsed * 1000;
    final maxRolls = BossFinisherRewards.maxBonusRolls(widget.boss);

    if (_bonusRollCount >= maxRolls) {
      return;
    }

    if (elapsedMs - _lastRewardSlashMs <
        BossFinisherRewards.slashRewardCooldownMs) {
      return;
    }
    _lastRewardSlashMs = elapsedMs;

    if (!BossFinisherRewards.passesRewardGate(_random)) {
      _addFloater(
        mid,
        BossFinisherRewards.noRewardMessageFor(widget.boss.id),
        isNoReward: true,
      );
      return;
    }

    _bonusRollCount++;
    final roll = BossFinisherRewards.rollBonus(widget.boss.id, _random);
    _totals = _totals.addRoll(roll);
    if (roll.grantsReward) {
      Future<void>.delayed(const Duration(milliseconds: 240), () {
        if (mounted) {
          AudioScope.maybeOf(context)?.playRewardTriumph();
        }
      });
    }
    _addFloater(mid, roll.message, isReward: roll.grantsReward);
  }

  void _addFloater(
    Offset position,
    String label, {
    bool isReward = false,
    bool isNoReward = false,
  }) {
    _floaters.add(
      _FloatingFinisherText(
        position: position - const Offset(0, 18),
        label: label,
        isReward: isReward,
        isNoReward: isNoReward,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _segmentStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final current = details.localPosition;
    final start = _segmentStart;
    if (start == null) return;

    if ((current - start).distance >= BossFinisherRewards.slashMinDistance) {
      _registerSlash(start, current, size);
      _segmentStart = current;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _segmentStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (BossFinisherRewards.slashWindowSeconds - _elapsed)
        .ceil()
        .clamp(0, 5);
    final maxRolls = BossFinisherRewards.maxBonusRolls(widget.boss);

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final bossCenter = _bossCenter(size);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.showBattleBackgrounds)
                  Positioned.fill(
                    child: BossBattleBackground(bossId: widget.boss.id),
                  ),
                if (widget.showBattleBackgrounds)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                CustomPaint(
                  painter: _FinisherSlashPainter(
                    slashes: _slashes,
                    style: _style,
                  ),
                ),
                Positioned(
                  left: bossCenter.dx - _bossDisplaySize / 2,
                  top: bossCenter.dy - _bossDisplaySize / 2,
                  child: Opacity(
                    opacity: 0.92,
                    child: BossSprite(
                      spritePath: widget.boss.spritePath,
                      fallbackEmoji: widget.boss.emoji,
                      bossId: widget.boss.id,
                      size: _bossDisplaySize,
                      semanticLabel: widget.boss.name,
                    ),
                  ),
                ),
                for (final f in _floaters)
                  Positioned(
                    left: f.position.dx - 60,
                    top: f.position.dy - f.age * 36,
                    child: Opacity(
                      opacity: (1 - f.age / 1.4).clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 120,
                        child: Text(
                          f.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: f.isReward
                                ? Colors.amber.shade200
                                : f.isNoReward
                                ? Colors.white.withValues(alpha: 0.58)
                                : _style.sparkColor,
                            fontSize: f.isReward
                                ? 13
                                : (f.isNoReward ? 11 : 10),
                            fontWeight: f.isReward
                                ? FontWeight.bold
                                : FontWeight.w600,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 24,
                  child: Column(
                    children: [
                      Text(
                        'FINISHER!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: widget.theme.secondaryColor,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Slash the boss!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.92),
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Slash for a 50% bonus chance!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bonus found: $_bonusRollCount / $maxRolls',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.secondaryColor.withValues(
                            alpha: 0.9,
                          ),
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(
                        color: widget.theme.secondaryColor,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.secondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SlashVisual {
  _SlashVisual({required this.start, required this.end});

  final Offset start;
  final Offset end;
  double age = 0;
}

class _FloatingFinisherText {
  _FloatingFinisherText({
    required this.position,
    required this.label,
    this.isReward = false,
    this.isNoReward = false,
  });

  final Offset position;
  final String label;
  final bool isReward;
  final bool isNoReward;
  double age = 0;
}

class _FinisherSlashPainter extends CustomPainter {
  _FinisherSlashPainter({required this.slashes, required this.style});

  final List<_SlashVisual> slashes;
  final FinisherSlashStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    for (final slash in slashes) {
      final fade = (1 - slash.age / 0.45).clamp(0.0, 1.0);
      if (fade <= 0) continue;

      final paint = Paint()
        ..color = style.slashColor.withValues(alpha: fade * 0.95)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(slash.start, slash.end, paint);

      canvas.drawLine(
        slash.start,
        slash.end,
        Paint()
          ..color = Colors.white.withValues(alpha: fade * 0.85)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      final mid = Offset(
        (slash.start.dx + slash.end.dx) / 2,
        (slash.start.dy + slash.end.dy) / 2,
      );
      canvas.drawCircle(
        mid,
        6 * fade,
        Paint()
          ..color = style.sparkColor.withValues(alpha: fade * 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      for (var i = 0; i < 4; i++) {
        final angle = i * pi / 2 + slash.age * 8;
        final dist = 10 + i * 4;
        canvas.drawCircle(
          mid + Offset(cos(angle) * dist, sin(angle) * dist),
          2.5 * fade,
          Paint()..color = style.particleColor.withValues(alpha: fade * 0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FinisherSlashPainter oldDelegate) => true;
}
