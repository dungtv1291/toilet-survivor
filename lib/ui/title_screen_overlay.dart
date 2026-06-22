import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:toilet_survivor/game/toilet_survivor_game.dart';

const String _uiAssetRoot = 'assets/images/ui/';
const String _uiMainRoot = '${_uiAssetRoot}main/';
const String _uiDripRoot = '${_uiAssetRoot}drips/';
const String _uiPuddleRoot = '${_uiAssetRoot}puddles/';

const double _panelAspect = 821 / 591;
const double _buttonAspect = 409 / 203;

class TitleScreenOverlay extends StatelessWidget {
  const TitleScreenOverlay({required this.game, super.key});

  final ToiletSurvivorGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(95),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = math
                .min(constraints.maxWidth * 0.82, 320.0)
                .clamp(260.0, 320.0)
                .toDouble();

            return Center(
              child: _TitlePanel(panelWidth: panelWidth, onStart: game.startRun),
            );
          },
        ),
      ),
    );
  }
}

class _TitlePanel extends StatelessWidget {
  const _TitlePanel({required this.panelWidth, required this.onStart});

  final double panelWidth;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final panelHeight = panelWidth / _panelAspect;
    final badgeSize = panelWidth * 0.17;
    final totalHeight = panelHeight + badgeSize * 0.42;
    final contentTop = badgeSize * 0.42 + panelHeight * 0.18;
    final titleWidth = panelWidth * 0.72;
    final startButtonWidth = panelWidth * 0.30;
    final startButtonHeight = startButtonWidth / _buttonAspect;

    return SizedBox(
      width: panelWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: badgeSize * 0.42,
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
            top: badgeSize * 0.46,
            right: panelWidth * 0.22,
            child: _UiArt(
              assetPath: '${_uiDripRoot}slime_drip_2.png',
              width: panelWidth * 0.10,
              height: panelWidth * 0.12,
            ),
          ),
          Positioned(
            bottom: -panelHeight * 0.03,
            right: panelWidth * 0.20,
            child: _UiArt(
              assetPath: '${_uiPuddleRoot}slime_puddle_1.png',
              width: panelWidth * 0.12,
              height: panelWidth * 0.045,
            ),
          ),
          Positioned(
            left: panelWidth * 0.11,
            right: panelWidth * 0.11,
            top: contentTop,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: titleWidth,
                  height: panelHeight * 0.18,
                  child: const _FittedPixelText(
                    'TOILET',
                    fontSize: 44,
                    color: Color(0xFFFFF0B8),
                    strokeColor: Color(0xFF271408),
                    shadowColor: Color(0xFF5EC52B),
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(
                  width: titleWidth,
                  height: panelHeight * 0.15,
                  child: const _FittedPixelText(
                    'SURVIVOR',
                    fontSize: 38,
                    color: Color(0xFFE7FFD0),
                    strokeColor: Color(0xFF17220D),
                    shadowColor: Color(0xFF6D35A6),
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: panelHeight * 0.045),
                SizedBox(
                  width: panelWidth * 0.58,
                  child: _FittedPixelText(
                    'Survive the sewer swarm',
                    fontSize: panelWidth * 0.034,
                    color: const Color(0xFFE1F7D2),
                    strokeColor: const Color(0xFF11190F),
                    shadowColor: const Color(0xFF27331E),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: panelHeight * 0.08),
                _PixelButton(
                  label: 'Start',
                  assetPath: '${_uiMainRoot}button_restart.png',
                  width: startButtonWidth,
                  height: startButtonHeight,
                  fontSize: panelWidth * 0.040,
                  onPressed: onStart,
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
