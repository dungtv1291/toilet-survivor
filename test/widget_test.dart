import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toilet_survivor/game/toilet_survivor_game.dart';
import 'package:toilet_survivor/main.dart';

void main() {
  testWidgets('builds the Toilet Survivor game shell', (tester) async {
    await tester.pumpWidget(const ToiletSurvivorApp());

    expect(find.byType(GameWidget<ToiletSurvivorGame>), findsOneWidget);
  });

  testWidgets('keeps the same game instance across rebuilds', (tester) async {
    await tester.pumpWidget(const ToiletSurvivorApp());
    final firstGame = tester
        .widget<GameWidget<ToiletSurvivorGame>>(
          find.byType(GameWidget<ToiletSurvivorGame>),
        )
        .game;

    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pump();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final rebuiltGame = tester
        .widget<GameWidget<ToiletSurvivorGame>>(
          find.byType(GameWidget<ToiletSurvivorGame>),
        )
        .game;

    expect(identical(firstGame, rebuiltGame), isTrue);
  });
}
