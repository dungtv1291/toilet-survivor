import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:toilet_survivor/game/toilet_survivor_game.dart';

const String _uiAssetRoot = 'assets/images/ui/';
const String _uiMainRoot = '${_uiAssetRoot}main/';

const double _panelAspect = 821 / 591;
const double _scorePlateAspect = 378 / 113;
const double _restartButtonAspect = 409 / 203;

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({required this.game, super.key});

  final ToiletSurvivorGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(210),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: game.adsManager,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxPanelWidth = math.min(
                  constraints.maxWidth * 0.76,
                  310.0,
                );
                final minPanelWidth = math.min(
                  250.0,
                  constraints.maxWidth * 0.92,
                );
                final panelWidth = maxPanelWidth
                    .clamp(minPanelWidth, 310.0)
                    .toDouble();

                return Center(
                  child: _GameOverPanel(
                    panelWidth: panelWidth,
                    score: game.score,
                    canRevive: game.canShowRewardedRevive,
                    onRevive: game.requestRewardedRevive,
                    onRestart: game.restartFromGameOver,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.panelWidth,
    required this.score,
    required this.canRevive,
    required this.onRevive,
    required this.onRestart,
  });

  final double panelWidth;
  final int score;
  final bool canRevive;
  final VoidCallback onRevive;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final panelHeight = panelWidth / _panelAspect;
    final badgeSize = panelWidth * 0.16;
    final panelTop = badgeSize * 0.42;
    final contentTop = panelTop + panelHeight * (canRevive ? 0.16 : 0.22);
    final titleWidth = panelWidth * (canRevive ? 0.70 : 0.76);
    final titleHeight = panelHeight * (canRevive ? 0.10 : 0.12);
    final scoreWidth = panelWidth * (canRevive ? 0.43 : 0.45);
    final scoreHeight = scoreWidth / _scorePlateAspect;
    final reviveButtonWidth = panelWidth * 0.50;
    final reviveButtonHeight = reviveButtonWidth / _scorePlateAspect;
    final buttonWidth = panelWidth * (canRevive ? 0.23 : 0.29);
    final buttonHeight = buttonWidth / _restartButtonAspect;
    final totalHeight = panelTop + panelHeight;
    final gap = panelHeight * (canRevive ? 0.018 : 0.045);

    return SizedBox(
      width: panelWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: panelTop,
            child: _UiArt(
              assetPath: '${_uiMainRoot}game_over_panel.png',
              width: panelWidth,
              height: panelHeight,
            ),
          ),
          Positioned(
            top: 0,
            child: _UiArt(
              assetPath: '${_uiMainRoot}poop_skull_badge.png',
              width: badgeSize,
              height: badgeSize,
            ),
          ),
          Positioned(
            left: panelWidth * 0.10,
            right: panelWidth * 0.10,
            top: contentTop,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: titleWidth,
                  height: titleHeight,
                  child: _FittedPixelText(
                    'GAME OVER',
                    fontSize: panelWidth * (canRevive ? 0.064 : 0.072),
                    color: const Color(0xFFFFF0B8),
                    strokeColor: const Color(0xFF271408),
                    shadowColor: const Color(0xFF5EC52B),
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: gap),
                _ScorePlate(
                  score: score,
                  width: scoreWidth,
                  height: scoreHeight,
                  fontSize: panelWidth * (canRevive ? 0.041 : 0.047),
                ),
                SizedBox(height: gap),
                if (canRevive) ...[
                  _PixelButton(
                    label: 'Watch Ad to Revive',
                    assetPath: '${_uiMainRoot}score_plate.png',
                    width: reviveButtonWidth,
                    height: reviveButtonHeight,
                    fontSize: panelWidth * 0.031,
                    onPressed: onRevive,
                  ),
                  SizedBox(height: gap),
                ],
                _PixelButton(
                  label: 'Restart',
                  assetPath: '${_uiMainRoot}button_restart.png',
                  width: buttonWidth,
                  height: buttonHeight,
                  fontSize: panelWidth * (canRevive ? 0.034 : 0.040),
                  onPressed: onRestart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePlate extends StatelessWidget {
  const _ScorePlate({
    required this.score,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  final int score;
  final double width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _UiArt(
            assetPath: '${_uiMainRoot}score_plate.png',
            width: width,
            height: height,
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.09),
              child: Center(
                child: _FittedPixelText(
                  'Score: $score',
                  fontSize: fontSize,
                  color: const Color(0xFFE7FFD0),
                  strokeColor: const Color(0xFF15200E),
                  shadowColor: const Color(0xFF10130A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelButton extends StatelessWidget {
  const _PixelButton({
    required this.label,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final double width;
  final double height;
  final double fontSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _UiArt(assetPath: assetPath, width: width, height: height),
            Positioned.fill(
              child: Center(
                child: _FittedPixelText(
                  label,
                  fontSize: fontSize,
                  color: const Color(0xFFFFF5C8),
                  strokeColor: const Color(0xFF1B1207),
                  shadowColor: const Color(0xFF4C8F1C),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FittedPixelText extends StatelessWidget {
  const _FittedPixelText(
    this.text, {
    required this.fontSize,
    required this.color,
    required this.strokeColor,
    required this.shadowColor,
    this.letterSpacing = 0,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final Color shadowColor;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: _PixelText(
        text,
        fontSize: fontSize,
        color: color,
        strokeColor: strokeColor,
        shadowColor: shadowColor,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

class _PixelText extends StatelessWidget {
  const _PixelText(
    this.text, {
    required this.fontSize,
    required this.color,
    required this.strokeColor,
    required this.shadowColor,
    this.letterSpacing = 0,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final Color shadowColor;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing,
      height: 1,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(
            color: color,
            shadows: [Shadow(color: shadowColor, offset: const Offset(1, 2))],
          ),
        ),
      ],
    );
  }
}

class _UiArt extends StatelessWidget {
  const _UiArt({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        assetPath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
