import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../services/game_service.dart';
import 'egg_shard_upgrades_card.dart';
import 'game_background.dart';
import 'game_sprite.dart';
import 'phone_width_layout.dart';

class DayGullDiscoverySequence extends StatefulWidget {
  const DayGullDiscoverySequence({
    super.key,
    required this.game,
    required this.theme,
  });

  final GameService game;
  final BackgroundTheme theme;

  static Future<void> show(
    BuildContext context, {
    required GameService game,
    required BackgroundTheme theme,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    builder: (_) => DayGullDiscoverySequence(game: game, theme: theme),
  );

  @override
  State<DayGullDiscoverySequence> createState() =>
      _DayGullDiscoverySequenceState();
}

class _DayGullDiscoverySequenceState extends State<DayGullDiscoverySequence>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _glitchController;
  late final AnimationController _revealController;
  Timer? _scrollDelayTimer;
  var _tapped = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollDelayTimer = Timer(const Duration(milliseconds: 550), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 1700),
          curve: Curves.easeInOutCubic,
        );
      });
    });
  }

  void _reveal() {
    if (_tapped) return;
    setState(() => _tapped = true);
    _revealController.forward();
  }

  @override
  void dispose() {
    _scrollDelayTimer?.cancel();
    _scrollController.dispose();
    _glitchController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final egg = GameData.eggById(GameData.dayGullEggId)!;
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: '⚔️ Boss Battles',
            titleStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: widget.theme.appBarColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: GameBackground(
            theme: widget.theme,
            child: PhoneWidthLayout(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                child: Column(
                  children: [
                    EggShardUpgradesCard(
                      theme: widget.theme,
                      game: widget.game,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 540,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _glitchController,
                          _revealController,
                        ]),
                        builder: (context, _) {
                          final reveal = _revealController.value;
                          final flash = reveal < 0.36
                              ? reveal / 0.36
                              : (1 - reveal) / 0.64;
                          final eggOpacity = ((reveal - 0.48) / 0.28).clamp(
                            0.0,
                            1.0,
                          );
                          final controlsOpacity = ((reveal - 0.78) / 0.18)
                              .clamp(0.0, 1.0);
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: _DiscoveryGlitchPainter(
                                  progress: _glitchController.value,
                                  intensity: _tapped ? 1 - reveal : 1,
                                ),
                              ),
                              if (!_tapped)
                                Center(
                                  child: Semantics(
                                    button: true,
                                    label: 'Tap the glitch',
                                    child: InkResponse(
                                      key: const Key('daygull-glitch-tap'),
                                      onTap: _reveal,
                                      radius: 110,
                                      child: SizedBox(
                                        width: 220,
                                        height: 220,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _GlitchCore(
                                              progress: _glitchController.value,
                                            ),
                                            const SizedBox(height: 22),
                                            _GlitchLabel(
                                              text: 'Tap',
                                              progress: _glitchController.value,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_tapped)
                                Center(
                                  child: Opacity(
                                    opacity: eggOpacity,
                                    child: Transform.scale(
                                      scale: 0.82 + eggOpacity * 0.18,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GameEggSprite(
                                            egg: egg,
                                            size: 190,
                                            semanticLabel: egg.name,
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            egg.name,
                                            style: TextStyle(
                                              color: widget
                                                  .theme
                                                  .cardTextPrimaryColor,
                                              fontSize: 27,
                                              fontWeight: FontWeight.w900,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0xFF62E8FF),
                                                  blurRadius: 12,
                                                ),
                                                Shadow(
                                                  color: Color(0xFFA64DFF),
                                                  blurRadius: 15,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'A new path has opened.',
                                            style: TextStyle(
                                              color: widget
                                                  .theme
                                                  .cardTextSecondaryColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Opacity(
                                            opacity: controlsOpacity,
                                            child: FilledButton(
                                              onPressed: controlsOpacity >= 1
                                                  ? () => Navigator.pop(context)
                                                  : null,
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF5D39C9,
                                                ),
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(
                                                  190,
                                                  48,
                                                ),
                                              ),
                                              child: const Text(
                                                'Continue',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (_tapped)
                                IgnorePointer(
                                  child: ColoredBox(
                                    color: Colors.white.withValues(
                                      alpha: flash.clamp(0.0, 1.0),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlitchCore extends StatelessWidget {
  const _GlitchCore({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(progress * pi * 2) + 1) / 2;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 94 + pulse * 12,
          height: 94 + pulse * 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.72),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF52E4FF),
                blurRadius: 30,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: Color(0xFFA64DFF),
                blurRadius: 42,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: Offset(sin(progress * pi * 12) * 7, 0),
          child: Container(
            width: 62,
            height: 16,
            color: const Color(0xFF47E4FF).withValues(alpha: 0.72),
          ),
        ),
        Transform.translate(
          offset: Offset(-sin(progress * pi * 10) * 8, 9),
          child: Container(
            width: 74,
            height: 12,
            color: const Color(0xFFA74DFF).withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}

class _GlitchLabel extends StatelessWidget {
  const _GlitchLabel({required this.text, required this.progress});
  final String text;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shake = sin(progress * pi * 18) * 2.5;
    const style = TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Color(0xFF43DEFF), blurRadius: 12),
        Shadow(color: Color(0xFFA64DFF), blurRadius: 16),
      ],
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(-5 - shake, 1),
          child: Text(
            text,
            style: style.copyWith(color: const Color(0xFFA64DFF)),
          ),
        ),
        Transform.translate(
          offset: Offset(5 + shake, -1),
          child: Text(
            text,
            style: style.copyWith(color: const Color(0xFF43DEFF)),
          ),
        ),
        Text(text, style: style),
      ],
    );
  }
}

class _DiscoveryGlitchPainter extends CustomPainter {
  const _DiscoveryGlitchPainter({
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final cyan = Paint()
      ..color = const Color(0xFF45E1FF).withValues(alpha: 0.30 * intensity);
    final purple = Paint()
      ..color = const Color(0xFFA44DFF).withValues(alpha: 0.28 * intensity);
    for (var i = 0; i < 22; i++) {
      final y = size.height * ((i * 0.067 + progress * 0.42) % 1);
      final width = size.width * (0.10 + (i % 8) * 0.055);
      final centerBias = 0.5 + sin(progress * 8 + i * 1.8) * 0.20;
      final x = size.width * centerBias - width / 2;
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, 2 + (i % 4).toDouble()),
        i.isEven ? cyan : purple,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiscoveryGlitchPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}
