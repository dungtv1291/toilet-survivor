import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:toilet_survivor/config/game_config.dart';
import 'package:toilet_survivor/game/toilet_survivor_game.dart';
import 'package:toilet_survivor/services/ads_manager.dart';
import 'package:toilet_survivor/ui/game_over_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsManager.instance.initialize();
  runApp(const ToiletSurvivorApp());
}

class ToiletSurvivorApp extends StatelessWidget {
  const ToiletSurvivorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toilet Survivor',
      theme: ThemeData.dark(useMaterial3: true),
      home: const _GameHost(),
    );
  }
}

class _GameHost extends StatefulWidget {
  const _GameHost();

  @override
  State<_GameHost> createState() => _GameHostState();
}

class _GameHostState extends State<_GameHost> {
  ToiletSurvivorGame? _game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final game = _game ??= ToiletSurvivorGame(
              viewHeight: _viewportHeightFor(constraints),
            );

            return GameWidget<ToiletSurvivorGame>(
              game: game,
              overlayBuilderMap: {
                ToiletSurvivorGame.gameOverOverlay: (_, game) {
                  return GameOverOverlay(game: game);
                },
              },
            );
          },
        ),
      ),
    );
  }
}

double _viewportHeightFor(BoxConstraints constraints) {
  if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
    return GameConfig.viewHeight;
  }

  final targetHeight =
      GameConfig.viewWidth * constraints.maxHeight / constraints.maxWidth;
  return targetHeight
      .clamp(GameConfig.minViewHeight, GameConfig.maxViewHeight)
      .toDouble();
}
