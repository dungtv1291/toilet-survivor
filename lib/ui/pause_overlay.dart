import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:toilet_survivor/game/toilet_survivor_game.dart';

const String _uiAssetRoot = 'assets/images/ui/';
const String _uiMainRoot = '${_uiAssetRoot}main/';

const double _panelAspect = 821 / 591;
const double _buttonAspect = 409 / 203;

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, super.key});

  final ToiletSurvivorGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(145),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = math
                .min(constraints.maxWidth * 0.66, 260.0)
                .clamp(220.0, 260.0)
                .toDouble();

            return Center(
              child: _PausePanel(
                panelWidth: panelWidth,
                onResume: game.resumeGame,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PausePanel extends StatelessWidget {
  const _PausePanel({required this.panelWidth, required this.onResume});

  final double panelWidth;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final panelHeight = panelWidth / _panelAspect;
    final badgeSize = panelWidth * 0.16;
    final panelTop = badgeSize * 0.42;
    final totalHeight = panelTop + panelHeight;
    final buttonWidth = panelWidth * 0.34;
    final buttonHeight = buttonWidth / _buttonAspect;

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
            left: panelWidth * 0.12,
            right: panelWidth * 0.12,
            top: panelTop + panelHeight * 0.25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: panelWidth * 0.56,
                  height: panelHeight * 0.16,
                  child: const _FittedPixelText(
                    'PAUSED',
                    fontSize: 36,
                    color: Color(0xFFFFF0B8),
                    strokeColor: Color(0xFF271408),
                    shadowColor: Color(0xFF5EC52B),
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: panelHeight * 0.12),
                _PixelButton(
                  label: 'Resume',
                  assetPath: '${_uiMainRoot}button_restart.png',
                  width: buttonWidth,
                  height: buttonHeight,
                  fontSize: panelWidth * 0.038,
                  onPressed: onResume,
                ),
              ],
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
