import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:toilet_survivor/config/asset_paths.dart';
import 'package:toilet_survivor/config/game_config.dart';
import 'package:toilet_survivor/game/bullet.dart';
import 'package:toilet_survivor/game/enemy.dart';
import 'package:toilet_survivor/game/hud_panel_component.dart';
import 'package:toilet_survivor/game/pause_button_component.dart';
import 'package:toilet_survivor/game/player.dart';
import 'package:toilet_survivor/game/poop_splat_effect.dart';
import 'package:toilet_survivor/game/prop_component.dart';
import 'package:toilet_survivor/game/sludge_puddle_component.dart';
import 'package:toilet_survivor/game/stink_cloud_hazard.dart';
import 'package:toilet_survivor/game/tiled_background.dart';
import 'package:toilet_survivor/services/ads_manager.dart';
import 'package:toilet_survivor/services/sound_manager.dart';

class ToiletSurvivorGame extends FlameGame {
  ToiletSurvivorGame({
    AdsManager? adsManager,
    SoundManager? soundManager,
    this.viewWidth = GameConfig.viewWidth,
    this.viewHeight = GameConfig.viewHeight,
  }) : adsManager = adsManager ?? AdsManager.instance,
       soundManager = soundManager ?? SoundManager.instance,
       super(
         camera: CameraComponent.withFixedResolution(
           width: viewWidth,
           height: viewHeight,
         ),
       );

  static const String gameOverOverlay = 'gameOver';
  static const String titleOverlay = 'title';
  static const String pauseOverlay = 'pause';

  final AdsManager adsManager;
  final SoundManager soundManager;
  final double viewWidth;
  final double viewHeight;

  final math.Random _random = math.Random();
  final List<Enemy> enemies = [];
  final List<Bullet> bullets = [];
  final List<PoopSplatEffect> effects = [];
  final List<PoopSplatEffect> splats = [];
  final List<PropComponent> props = [];
  final List<SludgePuddleComponent> sludgePuddles = [];
  final List<StinkCloudHazard> stinkClouds = [];

  late final JoystickComponent joystick;
  late final CircleComponent joystickKnob;
  late final CircleComponent joystickBackground;
  late final Player player;
  late final Map<Direction, SpriteAnimation> playerIdleAnimations;
  late final Map<Direction, SpriteAnimation> playerWalkAnimations;
  late final Map<EnemyType, Map<Direction, SpriteAnimation>> enemyAnimations;
  late final Map<EnemyType, Set<Direction>> enemyMirroredDirections;
  late final Map<EnemyType, EnemyStats> enemyStats;
  late final List<Sprite> bulletSprites;
  late final List<Sprite> muzzleFlashSprites;
  late final List<Sprite> hitSparkSprites;
  late final List<Sprite> poopSplatSprites;
  late final List<Sprite> fartSprites;
  late final List<Sprite> stinkSprites;
  late final List<Sprite> floorTileSprites;
  late final Sprite sludgePuddleSprite;
  late final Sprite stinkCloudSmallSprite;
  late final Sprite stinkCloudSkullSprite;
  late final Sprite hudCornerSprite;
  late final Sprite hudSlimeDripSprite;
  late final TiledBackground tiledBackground;
  late final HudPanelComponent hudPanel;
  late final TextComponent hpText;
  late final TextComponent scoreText;
  late final PauseButtonComponent pauseButton;

  int score = 0;
  bool isWaitingToStart = true;
  bool isPaused = false;
  bool isGameOver = false;
  bool _reviveUsedThisRun = false;
  bool _rewardedReviveWatchedThisRun = false;
  bool _restartRequested = false;

  double _shootTimer = 0;
  double _spawnTimer = 0;
  double _elapsedTime = 0;
  double _lastBossSpawnTime = -9999;
  double _hudDamageFlashTimer = 0;
  double _cloudDamageWindowTimer = 0;
  double _cloudDamageInWindow = 0;
  int _enemySpawnIndex = 0;
  String _currentFloorTilePath = AssetPaths.floorDirt;

  Vector2 get playerSpawnPosition {
    return Vector2(GameConfig.worldWidth / 2, GameConfig.worldHeight / 2);
  }

  bool get canShowRewardedRevive {
    return isGameOver &&
        !_reviveUsedThisRun &&
        adsManager.isRewardedReviveReady;
  }

  @override
  Future<void> onLoad() async {
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, GameConfig.worldWidth, GameConfig.worldHeight),
      considerViewport: true,
    );

    await images.loadAll(AssetPaths.allImages);
    await soundManager.initialize();

    playerIdleAnimations = _idleAnimations(
      AssetPaths.playerSheet,
      frameWidth: GameConfig.playerFrameWidth,
      frameHeight: GameConfig.playerFrameHeight,
    );
    playerWalkAnimations = _walkAnimations(
      AssetPaths.playerSheet,
      frameWidth: GameConfig.playerFrameWidth,
      frameHeight: GameConfig.playerFrameHeight,
    );
    final snakeAnimations = await _snakeEnemyAnimations();
    enemyAnimations = _buildEnemyAnimations(snakeAnimations.animations);
    enemyMirroredDirections = {
      EnemyType.basic: const {},
      EnemyType.snake: snakeAnimations.mirroredDirections,
      EnemyType.boss: const {},
    };
    enemyStats = _buildEnemyStats();
    bulletSprites = _spritesFromPaths(AssetPaths.bulletSprites);
    muzzleFlashSprites = _spritesFromPaths(AssetPaths.muzzleSprites);
    hitSparkSprites = _spritesFromPaths(AssetPaths.hitSprites);
    poopSplatSprites = _spritesFromPaths(AssetPaths.splatSprites);
    fartSprites = _spritesFromPaths(AssetPaths.fartSprites);
    stinkSprites = _spritesFromPaths(AssetPaths.stinkSprites);
    floorTileSprites = _spritesFromPaths(AssetPaths.tileSprites);
    sludgePuddleSprite = Sprite(images.fromCache(AssetPaths.sludgePuddle));
    stinkCloudSmallSprite = Sprite(
      images.fromCache(AssetPaths.stinkCloudSmall),
    );
    stinkCloudSkullSprite = Sprite(
      images.fromCache(AssetPaths.stinkCloudSkull),
    );
    hudCornerSprite = Sprite(images.fromCache(AssetPaths.hudCorner));
    hudSlimeDripSprite = Sprite(images.fromCache(AssetPaths.hudSlimeDrip));

    tiledBackground = TiledBackground(tileSprite: _selectFloorTileSprite());
    world.add(tiledBackground);
    _addProps();
    _addSludgePuddles();

    joystick = _createJoystick();
    player = Player(
      idleAnimations: playerIdleAnimations,
      walkAnimations: playerWalkAnimations,
      joystick: joystick,
      position: playerSpawnPosition,
    );

    hudPanel = _hudPanel();
    hpText = _hudText(Vector2(GameConfig.hudTextX, GameConfig.hudHpY));
    scoreText = _hudText(Vector2(GameConfig.hudTextX, GameConfig.hudScoreY));
    pauseButton = _pauseButton();

    await world.add(player);
    camera.follow(player, snap: true);
    await camera.viewport.addAll([
      joystick,
      hudPanel,
      hpText,
      scoreText,
      pauseButton,
    ]);
    _updateHud();
    _setGameplayHudVisible(false);
    overlays.add(titleOverlay);
    _logAssetUsageReport();
  }

  @override
  void update(double dt) {
    if (isWaitingToStart) {
      super.update(dt);
      return;
    }

    if (isPaused) {
      return;
    }

    if (isGameOver) {
      return;
    }

    player.updateControlledMovement(dt, _playerPositionBlocked);
    super.update(dt);
    _elapsedTime += dt;

    _shootTimer -= dt;
    _spawnTimer -= dt;

    if (_shootTimer <= 0) {
      _autoShoot();
      _shootTimer = GameConfig.autoShootInterval;
    }

    if (_spawnTimer <= 0) {
      _spawnEnemy();
      _spawnTimer = _currentEnemySpawnInterval();
    }

    _handleSludgePuddles();
    _handleBulletEnemyCollisions();
    _handleEnemyPlayerCollisions();
    _handleEnemyVisualEffects(dt);
    _handleEnemySpawnSounds();
    _updateCloudDamageWindow(dt);
    _handleStinkCloudDamage(dt);
    _cleanupRemovedComponents();
    _updateHud();
    _updateDamageFeedback(dt);
  }

  void restartFromGameOver() {
    if (!isGameOver || _restartRequested) {
      return;
    }

    soundManager.playUiClick();
    _restartRequested = true;
    adsManager.showInterstitialAfterGameOver(
      skipBecauseRewardedRevive: _rewardedReviveWatchedThisRun,
      onComplete: () {
        _restartRequested = false;
        restart();
      },
    );
  }

  void requestRewardedRevive() {
    soundManager.playUiClick();
    if (!canShowRewardedRevive) {
      adsManager.loadRewardedAd();
      return;
    }

    adsManager.showRewardedRevive(onRewarded: _completeRewardedRevive);
  }

  void pauseGame() {
    if (isWaitingToStart || isPaused || isGameOver) {
      return;
    }

    soundManager.playUiClick();
    isPaused = true;
    joystick.onDragStop();
    _setJoystickVisible(false);
    _setPauseButtonVisible(false);
    unawaited(soundManager.pauseRunAudio());
    overlays.add(pauseOverlay);
  }

  void resumeGame() {
    if (!isPaused) {
      return;
    }

    soundManager.playUiClick();
    isPaused = false;
    _setJoystickVisible(true);
    _setPauseButtonVisible(true);
    unawaited(soundManager.resumeRunAudio());
    overlays.remove(pauseOverlay);
  }

  void startRun() {
    if (!isWaitingToStart) {
      return;
    }

    soundManager.playUiClick();
    isWaitingToStart = false;
    restart();
    overlays.remove(titleOverlay);
  }

  void restart() {
    for (final component in [
      ...enemies,
      ...bullets,
      ...effects,
      ...stinkClouds,
    ]) {
      component.removeFromParent();
    }

    enemies.clear();
    bullets.clear();
    effects.clear();
    splats.clear();
    stinkClouds.clear();
    for (final puddle in sludgePuddles) {
      puddle.resetCooldown();
    }
    score = 0;
    _reviveUsedThisRun = false;
    _rewardedReviveWatchedThisRun = false;
    _restartRequested = false;
    isPaused = false;
    _shootTimer = 0;
    _spawnTimer = 0;
    _elapsedTime = 0;
    _lastBossSpawnTime = -9999;
    _hudDamageFlashTimer = 0;
    _cloudDamageWindowTimer = 0;
    _cloudDamageInWindow = 0;
    _enemySpawnIndex = 0;
    isWaitingToStart = false;
    isGameOver = false;

    joystick.onDragStop();
    _setGameplayHudVisible(true);
    _resetHudDamageFeedback();
    tiledBackground.tileSprite = _selectFloorTileSprite();
    unawaited(soundManager.startRunAudioForTile(_currentFloorTilePath));
    player.reset(playerSpawnPosition);
    overlays.remove(gameOverOverlay);
    overlays.remove(pauseOverlay);
    _updateHud();
  }

  void _completeRewardedRevive() {
    if (!isGameOver || _reviveUsedThisRun) {
      return;
    }

    _reviveUsedThisRun = true;
    _rewardedReviveWatchedThisRun = true;
    _restartRequested = false;
    isPaused = false;
    isGameOver = false;
    _hudDamageFlashTimer = 0;
    _cloudDamageWindowTimer = 0;
    _cloudDamageInWindow = 0;

    joystick.onDragStop();
    _setGameplayHudVisible(true);
    _resetHudDamageFeedback();
    unawaited(soundManager.resumeRunAudio());
    _clearRewardedReviveSafeArea();
    player.revive(
      GameConfig.playerMaxHp * GameConfig.rewardedReviveHpRatio,
      invincibilityDuration: GameConfig.rewardedReviveInvincibilityDuration,
    );
    overlays.remove(gameOverOverlay);
    overlays.remove(pauseOverlay);
    _updateHud();
  }

  void _clearRewardedReviveSafeArea() {
    final safeRadiusSquared =
        GameConfig.rewardedReviveSafeRadius *
        GameConfig.rewardedReviveSafeRadius;

    for (final enemy in enemies.toList()) {
      if (enemy.position.distanceToSquared(player.position) <=
          safeRadiusSquared) {
        enemy.removeFromParent();
        enemies.remove(enemy);
      }
    }

    for (final cloud in stinkClouds.toList()) {
      if (cloud.position.distanceToSquared(player.position) <=
          safeRadiusSquared) {
        cloud.removeFromParent();
        stinkClouds.remove(cloud);
      }
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF111A18);

  Future<Sprite?> _loadOptionalSprite(String path) async {
    try {
      final image = await images.load(path);
      return Sprite(image);
    } catch (_) {
      return null;
    }
  }

  List<Sprite> _spritesFromPaths(List<String> paths) {
    final sprites = <Sprite>[];
    for (final path in paths) {
      try {
        sprites.add(Sprite(images.fromCache(path)));
      } catch (_) {
        debugPrint('Asset not found or skipped: $path');
      }
    }
    return sprites;
  }

  Sprite? _randomSprite(List<Sprite> sprites) {
    if (sprites.isEmpty) {
      return null;
    }
    return sprites[_random.nextInt(sprites.length)];
  }

  Sprite? _selectFloorTileSprite() {
    if (AssetPaths.tileSprites.isEmpty) {
      return null;
    }

    _currentFloorTilePath =
        AssetPaths.tileSprites[_random.nextInt(AssetPaths.tileSprites.length)];
    return Sprite(images.fromCache(_currentFloorTilePath));
  }

  Vector2 _displaySizeForSprite(Sprite sprite, double targetWidth) {
    final sourceSize = sprite.srcSize;
    if (sourceSize.x == 0 || sourceSize.y == 0) {
      return Vector2.all(targetWidth);
    }

    return Vector2(targetWidth, targetWidth * sourceSize.y / sourceSize.x);
  }

  Map<Direction, SpriteAnimation> _idleAnimations(
    String assetPath, {
    required double frameWidth,
    required double frameHeight,
  }) {
    final sheet = SpriteSheet(
      image: images.fromCache(assetPath),
      srcSize: Vector2(frameWidth, frameHeight),
    );
    return {
      for (final direction in Direction.values)
        direction: SpriteAnimation.spriteList([
          sheet.getSprite(0, _playerColumnFor(direction)),
        ], stepTime: 1),
    };
  }

  Map<Direction, SpriteAnimation> _walkAnimations(
    String assetPath, {
    required double frameWidth,
    required double frameHeight,
  }) {
    final sheet = SpriteSheet(
      image: images.fromCache(assetPath),
      srcSize: Vector2(frameWidth, frameHeight),
    );
    return {
      for (final direction in Direction.values)
        direction: SpriteAnimation.spriteList([
          for (final row in GameConfig.playerWalkRows)
            sheet.getSprite(row, _playerColumnFor(direction)),
        ], stepTime: 0.1),
    };
  }

  Map<EnemyType, Map<Direction, SpriteAnimation>> _buildEnemyAnimations(
    Map<Direction, SpriteAnimation> snakeAnimations,
  ) {
    return {
      EnemyType.basic: _basicEnemyAnimations(
        AssetPaths.poopBasicSheet,
        frameWidth: GameConfig.enemyFrameWidth,
        frameHeight: GameConfig.enemyFrameHeight,
      ),
      EnemyType.snake: snakeAnimations,
      EnemyType.boss: _bossEnemyAnimations(
        AssetPaths.poopBossSheet,
        frameWidth: GameConfig.bossFrameWidth,
        frameHeight: GameConfig.bossFrameHeight,
      ),
    };
  }

  Map<Direction, SpriteAnimation> _basicEnemyAnimations(
    String assetPath, {
    required double frameWidth,
    required double frameHeight,
  }) {
    final sheet = SpriteSheet(
      image: images.fromCache(assetPath),
      srcSize: Vector2(frameWidth, frameHeight),
    );
    return {
      Direction.front: _enemyAnimation(sheet, const [(0, 0), (1, 0), (1, 2)]),
      Direction.left: _enemyAnimation(sheet, const [(0, 1), (2, 0), (3, 2)]),
      Direction.right: _enemyAnimation(sheet, const [(0, 2), (3, 1), (2, 2)]),
      Direction.back: _enemyAnimation(sheet, const [(0, 3), (4, 0)]),
    };
  }

  Future<
    ({
      Map<Direction, SpriteAnimation> animations,
      Set<Direction> mirroredDirections,
    })
  >
  _snakeEnemyAnimations() async {
    final leftFrames = await _loadSnakeMoveFrames('left');
    final rightFrames = await _loadSnakeMoveFrames('right');
    final mirroredDirections = <Direction>{};
    final safeLeftFrames = leftFrames.isNotEmpty ? leftFrames : rightFrames;
    final safeRightFrames = rightFrames.isNotEmpty
        ? rightFrames
        : safeLeftFrames;

    if (rightFrames.isEmpty) {
      mirroredDirections.add(Direction.right);
    }

    return (
      animations: {
        Direction.front: _enemyFrameAnimation(safeLeftFrames),
        Direction.left: _enemyFrameAnimation(safeLeftFrames),
        Direction.right: _enemyFrameAnimation(safeRightFrames),
        Direction.back: _enemyFrameAnimation(safeLeftFrames),
      },
      mirroredDirections: mirroredDirections,
    );
  }

  Future<List<Sprite>> _loadSnakeMoveFrames(String direction) async {
    final sprites = <Sprite>[];
    for (final frameName in _snakeFrameNames(direction)) {
      final sprite = await _loadOptionalSprite(
        AssetPaths.poopSnakeFrame(frameName),
      );
      if (sprite != null) {
        sprites.add(sprite);
      }
    }

    if (sprites.isEmpty) {
      final idleSprite = await _loadOptionalSprite(
        AssetPaths.poopSnakeFrame('idle_$direction'),
      );
      if (idleSprite != null) {
        sprites.add(idleSprite);
      }
    }
    return sprites;
  }

  List<String> _snakeFrameNames(String direction) {
    return [
      'move_${direction}_1',
      'move_${direction}_2',
      'move_${direction}_3',
    ];
  }

  Map<Direction, SpriteAnimation> _bossEnemyAnimations(
    String assetPath, {
    required double frameWidth,
    required double frameHeight,
  }) {
    final sheet = SpriteSheet(
      image: images.fromCache(assetPath),
      srcSize: Vector2(frameWidth, frameHeight),
    );
    return {
      Direction.front: _enemyAnimation(sheet, const [
        (0, 0),
        (1, 0),
        (1, 1),
        (1, 2),
      ]),
      Direction.left: _enemyAnimation(sheet, const [
        (0, 1),
        (2, 0),
        (2, 1),
        (2, 2),
      ]),
      Direction.right: _enemyAnimation(sheet, const [
        (0, 2),
        (3, 0),
        (3, 1),
        (3, 2),
      ]),
      Direction.back: _enemyAnimation(sheet, const [
        (0, 3),
        (4, 0),
        (4, 1),
        (4, 2),
      ]),
    };
  }

  SpriteAnimation _enemyAnimation(
    SpriteSheet sheet,
    List<(int row, int column)> frames,
  ) {
    return _enemyFrameAnimation([
      for (final frame in frames) sheet.getSprite(frame.$1, frame.$2),
    ]);
  }

  SpriteAnimation _enemyFrameAnimation(List<Sprite> frames) {
    return SpriteAnimation.spriteList(
      frames,
      stepTime: GameConfig.enemyAnimationStepTime,
    );
  }

  void _addProps() {
    final placements = <_PropPlacement>[
      ..._basePropPlacements,
      ..._randomPropPlacements(_basePropPlacements),
    ];

    for (final placement in placements) {
      final sprite = Sprite(images.fromCache(placement.assetPath));
      final prop = PropComponent(
        sprite: sprite,
        position: placement.position,
        size: _displaySizeForSprite(
          sprite,
          _propTargetWidth(placement.assetPath),
        ),
        blocksPlayer: placement.blocksPlayer,
        collisionSize: placement.collisionSize,
        collisionOffset: placement.collisionOffset,
        collisionScale: _propCollisionScaleFor(placement.assetPath),
      );
      props.add(prop);
      world.add(prop);
    }
  }

  void _addSludgePuddles() {
    final random = math.Random(GameConfig.worldDecorationSeed + 1);
    final positions = <Vector2>[];
    var attempts = 0;

    while (sludgePuddles.length < GameConfig.sludgePuddleCount &&
        attempts < GameConfig.sludgePuddleCount * 24) {
      attempts++;
      final position = Vector2(
        _randomRangeWith(
          random,
          GameConfig.decalWorldMargin,
          GameConfig.worldWidth - GameConfig.decalWorldMargin,
        ),
        _randomRangeWith(
          random,
          GameConfig.decalWorldMargin,
          GameConfig.worldHeight - GameConfig.decalWorldMargin,
        ),
      );

      if (!_isValidSludgePuddlePosition(position, positions)) {
        continue;
      }

      final scale =
          GameConfig.sludgePuddleScales[sludgePuddles.length %
              GameConfig.sludgePuddleScales.length];
      final triggersSlide = scale >= GameConfig.sludgePuddleHazardMinScale;
      final puddle = SludgePuddleComponent(
        sprite: sludgePuddleSprite,
        position: position,
        triggersSlide: triggersSlide,
        opacity: triggersSlide
            ? GameConfig.sludgeHazardOpacity
            : GameConfig.sludgeDecorationOpacity,
        size: _displaySizeForSprite(
          sludgePuddleSprite,
          GameConfig.decalSludgePuddleTargetWidth * scale,
        ),
        angle: 0,
      );
      positions.add(position);
      sludgePuddles.add(puddle);
      world.add(puddle);
    }
  }

  bool _isValidSludgePuddlePosition(
    Vector2 position,
    List<Vector2> existingPositions,
  ) {
    if (position.distanceToSquared(playerSpawnPosition) <
        GameConfig.sludgePuddlePlayerSafeRadius *
            GameConfig.sludgePuddlePlayerSafeRadius) {
      return false;
    }

    final puddleSpacingSquared =
        GameConfig.sludgePuddleMinSpacing * GameConfig.sludgePuddleMinSpacing;
    for (final existingPosition in existingPositions) {
      if (position.distanceToSquared(existingPosition) < puddleSpacingSquared) {
        return false;
      }
    }

    final propSpacingSquared =
        GameConfig.randomPropMinSpacing * GameConfig.randomPropMinSpacing;
    for (final prop in props) {
      if (position.distanceToSquared(prop.position) < propSpacingSquared) {
        return false;
      }
    }

    return true;
  }

  List<_PropPlacement> _randomPropPlacements(
    List<_PropPlacement> existingPlacements,
  ) {
    final placements = <_PropPlacement>[];
    final random = math.Random(GameConfig.worldDecorationSeed);
    var attempts = 0;

    while (placements.length < GameConfig.randomPropCount &&
        attempts < GameConfig.randomPropPlacementAttempts) {
      attempts++;
      final assetPath =
          _randomPropAssetPaths[random.nextInt(_randomPropAssetPaths.length)];
      final position = Vector2(
        _randomRangeWith(
          random,
          GameConfig.randomPropWorldMargin,
          GameConfig.worldWidth - GameConfig.randomPropWorldMargin,
        ),
        _randomRangeWith(
          random,
          GameConfig.randomPropWorldMargin,
          GameConfig.worldHeight - GameConfig.randomPropWorldMargin,
        ),
      );

      if (!_isValidRandomPropPosition(position, [
        ...existingPlacements,
        ...placements,
      ])) {
        continue;
      }

      placements.add(_propPlacementFor(assetPath, position));
    }

    return placements;
  }

  bool _isValidRandomPropPosition(
    Vector2 position,
    List<_PropPlacement> existingPlacements,
  ) {
    if (position.distanceToSquared(playerSpawnPosition) <
        GameConfig.randomPropPlayerSafeRadius *
            GameConfig.randomPropPlayerSafeRadius) {
      return false;
    }

    final initialCameraTopLeft = Vector2(
      playerSpawnPosition.x - viewWidth / 2,
      playerSpawnPosition.y - viewHeight / 2,
    );
    final initialHudRect = Rect.fromLTWH(
      initialCameraTopLeft.x,
      initialCameraTopLeft.y,
      GameConfig.hudPanelWidth,
      GameConfig.hudPanelHeight,
    ).inflate(GameConfig.randomPropInitialHudSafePadding);
    if (initialHudRect.contains(Offset(position.x, position.y))) {
      return false;
    }

    final minSpacingSquared =
        GameConfig.randomPropMinSpacing * GameConfig.randomPropMinSpacing;
    for (final placement in existingPlacements) {
      if (position.distanceToSquared(placement.position) < minSpacingSquared) {
        return false;
      }
    }

    return true;
  }

  Map<EnemyType, EnemyStats> _buildEnemyStats() {
    return {
      EnemyType.basic: EnemyStats(
        size: Vector2.all(GameConfig.enemySize),
        speed: GameConfig.enemySpeed,
        hp: GameConfig.enemyHp,
        radius: GameConfig.enemyRadius,
        score: GameConfig.enemyScore,
      ),
      EnemyType.snake: EnemyStats(
        size: Vector2(GameConfig.snakeEnemyWidth, GameConfig.snakeEnemyHeight),
        speed: GameConfig.snakeEnemySpeed,
        hp: GameConfig.snakeEnemyHp,
        radius: GameConfig.snakeEnemyRadius,
        score: GameConfig.snakeEnemyScore,
      ),
      EnemyType.boss: EnemyStats(
        size: Vector2.all(GameConfig.bossEnemySize),
        speed: GameConfig.bossEnemySpeed,
        hp: GameConfig.bossEnemyHp,
        radius: GameConfig.bossEnemyRadius,
        score: GameConfig.bossEnemyScore,
      ),
    };
  }

  JoystickComponent _createJoystick() {
    joystickKnob = CircleComponent(
      radius: GameConfig.joystickKnobRadius,
      paint: Paint()..color = const Color(0xFFE8FFE2).withAlpha(225),
    );
    joystickBackground = CircleComponent(
      radius: GameConfig.joystickSize / 2,
      paint: Paint()
        ..color = const Color(
          0xFF101816,
        ).withAlpha(GameConfig.joystickBackgroundAlpha),
    );

    return JoystickComponent(
      knob: joystickKnob,
      background: joystickBackground,
      size: GameConfig.joystickSize,
      position: _joystickVisiblePosition(),
      priority: 100,
    );
  }

  Vector2 _joystickVisiblePosition() {
    return Vector2(
      viewWidth / 2,
      viewHeight -
          GameConfig.joystickBottomMargin -
          GameConfig.joystickSize / 2,
    );
  }

  void _setJoystickVisible(bool visible) {
    joystick.position = visible
        ? _joystickVisiblePosition()
        : Vector2(-GameConfig.joystickSize * 2, -GameConfig.joystickSize * 2);
    joystickKnob.paint.color = const Color(
      0xFFE8FFE2,
    ).withAlpha(visible ? 225 : 0);
    joystickBackground.paint.color = const Color(
      0xFF101816,
    ).withAlpha(visible ? GameConfig.joystickBackgroundAlpha : 0);
  }

  void _setGameplayHudVisible(bool visible) {
    _setJoystickVisible(visible);
    _setHudVisible(visible);
    _setPauseButtonVisible(visible);
  }

  void _setPauseButtonVisible(bool visible) {
    pauseButton.position = visible
        ? _pauseButtonVisiblePosition()
        : Vector2(
            viewWidth + GameConfig.pauseButtonSize * 2,
            -GameConfig.pauseButtonSize * 2,
          );
  }

  Vector2 _pauseButtonVisiblePosition() {
    return Vector2(
      viewWidth - GameConfig.pauseButtonMargin - GameConfig.pauseButtonSize,
      GameConfig.pauseButtonMargin,
    );
  }

  void _setHudVisible(bool visible) {
    final hiddenPosition = Vector2(
      -GameConfig.hudPanelWidth * 2,
      -GameConfig.hudPanelHeight * 2,
    );

    hudPanel.position = visible
        ? Vector2(GameConfig.hudPanelX, GameConfig.hudPanelY)
        : hiddenPosition.clone();
    hpText.position = visible
        ? Vector2(GameConfig.hudTextX, GameConfig.hudHpY)
        : hiddenPosition.clone();
    scoreText.position = visible
        ? Vector2(GameConfig.hudTextX, GameConfig.hudScoreY)
        : hiddenPosition.clone();
  }

  TextComponent _hudText(Vector2 position) {
    return TextComponent(
      position: position,
      priority: 100,
      textRenderer: _hudTextPaint(const Color(0xFFF2FFE9)),
    );
  }

  TextPaint _hudTextPaint(Color color) {
    return TextPaint(
      style: TextStyle(
        color: color,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        shadows: const [
          Shadow(color: Color(0xFF07100D), offset: Offset(1, 1), blurRadius: 2),
        ],
      ),
    );
  }

  HudPanelComponent _hudPanel() {
    return HudPanelComponent(
      cornerSprite: hudCornerSprite,
      slimeDripSprite: hudSlimeDripSprite,
      position: Vector2(GameConfig.hudPanelX, GameConfig.hudPanelY),
      size: Vector2(GameConfig.hudPanelWidth, GameConfig.hudPanelHeight),
    );
  }

  PauseButtonComponent _pauseButton() {
    return PauseButtonComponent(
      onPressed: pauseGame,
      position: _pauseButtonVisiblePosition(),
      size: Vector2.all(GameConfig.pauseButtonSize),
    );
  }

  void _autoShoot() {
    Enemy? nearestEnemy;
    var nearestDistance = GameConfig.autoShootRange * GameConfig.autoShootRange;

    for (final enemy in enemies) {
      if (!enemy.isMounted || enemy.isDead) {
        continue;
      }

      final distance = player.position.distanceToSquared(enemy.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestEnemy = enemy;
      }
    }

    if (nearestEnemy == null) {
      return;
    }

    final direction = nearestEnemy.position - player.position;
    if (direction.length2 == 0) {
      return;
    }

    final bulletSprite = _randomSprite(bulletSprites);
    if (bulletSprite == null) {
      return;
    }

    final bullet = Bullet(
      sprite: bulletSprite,
      position: player.position.clone(),
      direction: direction,
    );
    bullets.add(bullet);
    world.add(bullet);
    _spawnMuzzleFlash(direction);
    soundManager.playPlayerShooting();
  }

  void _spawnEnemy() {
    final enemyType = _nextEnemyType();
    final stats = enemyStats[enemyType]!;
    final enemy = Enemy(
      type: enemyType,
      directionAnimations: enemyAnimations[enemyType]!,
      mirroredDirections: enemyMirroredDirections[enemyType]!,
      stats: stats,
      target: player,
      isBlocked: _enemyPositionBlocked,
      position: _randomEnemySpawnPosition(stats.radius),
    );
    enemy.visualEffectTimer = switch (enemyType) {
      EnemyType.snake => _randomRange(
        GameConfig.snakeFartMinInterval,
        GameConfig.snakeFartMaxInterval,
      ),
      EnemyType.boss => _randomRange(
        GameConfig.bossFartMinInterval,
        GameConfig.bossFartMaxInterval,
      ),
      EnemyType.basic => 0,
    };
    enemy.hazardTimer = switch (enemyType) {
      EnemyType.snake => GameConfig.snakeCloudCooldown,
      EnemyType.boss => GameConfig.bossCloudCooldown,
      EnemyType.basic => 0,
    };
    enemies.add(enemy);
    world.add(enemy);

    if (enemyType == EnemyType.boss) {
      _lastBossSpawnTime = _elapsedTime;
      _spawnFartEffect(
        enemy.position,
        size: GameConfig.bossEnemySize * 0.75,
        lifetime: 0.9,
      );
    }
  }

  EnemyType _nextEnemyType() {
    final spawnIndex = _enemySpawnIndex++;

    if (_shouldSpawnBoss) {
      return EnemyType.boss;
    }

    if (_elapsedTime < GameConfig.midGameStartTime) {
      return EnemyType.basic;
    }

    if (_elapsedTime < GameConfig.lateGameStartTime) {
      const midCycle = [
        EnemyType.basic,
        EnemyType.basic,
        EnemyType.snake,
        EnemyType.basic,
        EnemyType.snake,
      ];
      return midCycle[spawnIndex % midCycle.length];
    }

    const lateCycle = [
      EnemyType.basic,
      EnemyType.snake,
      EnemyType.basic,
      EnemyType.snake,
      EnemyType.basic,
    ];
    return lateCycle[spawnIndex % lateCycle.length];
  }

  bool get _shouldSpawnBoss {
    return _elapsedTime >= GameConfig.firstBossSpawnTime &&
        _elapsedTime - _lastBossSpawnTime >= GameConfig.bossRespawnCooldown &&
        _activeBossCount < GameConfig.maxActiveBosses;
  }

  double _currentEnemySpawnInterval() {
    if (_elapsedTime < GameConfig.midGameStartTime) {
      return GameConfig.earlyEnemySpawnInterval;
    }
    if (_elapsedTime < GameConfig.lateGameStartTime) {
      return GameConfig.midEnemySpawnInterval;
    }

    final ramp =
        ((_elapsedTime - GameConfig.lateGameStartTime) /
                GameConfig.enemySpawnRampDuration)
            .clamp(0.0, 1.0)
            .toDouble();
    return GameConfig.lateEnemySpawnInterval -
        (GameConfig.lateEnemySpawnInterval - GameConfig.minEnemySpawnInterval) *
            ramp;
  }

  int get _activeBossCount {
    return enemies
        .where(
          (enemy) =>
              enemy.type == EnemyType.boss && enemy.isMounted && !enemy.isDead,
        )
        .length;
  }

  Vector2 _randomSpawnPosition() {
    final visibleBounds = camera.visibleWorldRect;
    final edge = _random.nextInt(4);
    final spawnOffset =
        GameConfig.minSpawnOutsideView +
        _random.nextDouble() *
            (GameConfig.maxSpawnOutsideView - GameConfig.minSpawnOutsideView);
    final x = _randomRange(visibleBounds.left, visibleBounds.right);
    final y = _randomRange(visibleBounds.top, visibleBounds.bottom);

    final position = switch (edge) {
      0 => Vector2(x, visibleBounds.top - spawnOffset),
      1 => Vector2(visibleBounds.right + spawnOffset, y),
      2 => Vector2(x, visibleBounds.bottom + spawnOffset),
      _ => Vector2(visibleBounds.left - spawnOffset, y),
    };
    return _clampToWorld(position);
  }

  Vector2 _randomEnemySpawnPosition(double enemyRadius) {
    final avoidanceRadius =
        enemyRadius * GameConfig.enemyPropAvoidanceRadiusScale;
    for (var attempt = 0; attempt < 20; attempt++) {
      final position = _randomSpawnPosition();
      if (position.distanceToSquared(player.position) <
          GameConfig.enemySpawnPlayerSafeRadius *
              GameConfig.enemySpawnPlayerSafeRadius) {
        continue;
      }
      if (!_enemyPositionBlocked(position, avoidanceRadius)) {
        return position;
      }
    }

    return _fallbackEnemySpawnPosition(avoidanceRadius);
  }

  Vector2 _fallbackEnemySpawnPosition(double avoidanceRadius) {
    final visibleBounds = camera.visibleWorldRect;
    final offset = GameConfig.maxSpawnOutsideView;
    final centerX = player.position.x.clamp(
      visibleBounds.left,
      visibleBounds.right,
    );
    final centerY = player.position.y.clamp(
      visibleBounds.top,
      visibleBounds.bottom,
    );
    final candidates =
        [
          Vector2(centerX.toDouble(), visibleBounds.top - offset),
          Vector2(visibleBounds.right + offset, centerY.toDouble()),
          Vector2(centerX.toDouble(), visibleBounds.bottom + offset),
          Vector2(visibleBounds.left - offset, centerY.toDouble()),
        ].map(_clampToWorld).toList()..sort(
          (a, b) => b
              .distanceToSquared(player.position)
              .compareTo(a.distanceToSquared(player.position)),
        );

    for (final candidate in candidates) {
      if (!_enemyPositionBlocked(candidate, avoidanceRadius)) {
        return candidate;
      }
    }

    return candidates.first;
  }

  double _randomRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  double _randomRangeWith(math.Random random, double min, double max) {
    return min + random.nextDouble() * (max - min);
  }

  Vector2 _clampToWorld(Vector2 position) {
    return Vector2(
      position.x.clamp(0, GameConfig.worldWidth).toDouble(),
      position.y.clamp(0, GameConfig.worldHeight).toDouble(),
    );
  }

  void _handleBulletEnemyCollisions() {
    for (final bullet in bullets.toList()) {
      if (!bullet.isMounted) {
        continue;
      }

      for (final enemy in enemies.toList()) {
        if (!enemy.isMounted || enemy.isDead) {
          continue;
        }

        if (!_overlaps(
          bullet.position,
          GameConfig.bulletRadius,
          enemy.position,
          enemy.stats.radius,
        )) {
          continue;
        }

        bullet.removeFromParent();
        enemy.takeDamage(GameConfig.bulletDamage);
        _spawnHitSpark(bullet.position);
        soundManager.playBulletHit();

        if (enemy.isDead) {
          _killEnemy(enemy);
        }
        break;
      }
    }
  }

  void _handleEnemyPlayerCollisions() {
    for (final enemy in enemies) {
      if (!enemy.isMounted ||
          enemy.isDead ||
          !enemy.canDamagePlayer ||
          !_overlaps(
            enemy.position,
            enemy.stats.radius,
            player.position,
            GameConfig.playerRadius,
          )) {
        continue;
      }

      if (!player.takeDamage(GameConfig.enemyContactDamage)) {
        continue;
      }
      soundManager.playPlayerDamage();
      _triggerDamageFeedback();
      enemy.markDamageDealt();

      if (player.hp <= 0) {
        _endGame();
        return;
      }
    }
  }

  void _handleEnemyVisualEffects(double dt) {
    for (final enemy in enemies) {
      if (!enemy.isMounted || enemy.isDead) {
        continue;
      }

      if (enemy.type == EnemyType.snake) {
        enemy.visualEffectTimer -= dt;
        if (enemy.visualEffectTimer <= 0) {
          _spawnFartEffect(
            enemy.position,
            size: 18 + _random.nextDouble() * 8,
            lifetime: 0.45 + _random.nextDouble() * 0.35,
          );
          enemy.visualEffectTimer = _randomRange(
            GameConfig.snakeFartMinInterval,
            GameConfig.snakeFartMaxInterval,
          );
        }

        enemy.hazardTimer -= dt;
        if (enemy.hazardTimer <= 0) {
          _spawnSnakeStinkCloud(enemy.position);
          enemy.hazardTimer = GameConfig.snakeCloudCooldown;
        }
      }

      if (enemy.type == EnemyType.boss) {
        enemy.visualEffectTimer -= dt;
        if (enemy.visualEffectTimer <= 0) {
          _spawnFartEffect(
            enemy.position,
            size: GameConfig.bossEnemySize * 0.65,
            lifetime: 0.8,
          );
          enemy.visualEffectTimer = _randomRange(
            GameConfig.bossFartMinInterval,
            GameConfig.bossFartMaxInterval,
          );
        }

        enemy.hazardTimer -= dt;
        if (enemy.hazardTimer <= 0) {
          _spawnBossStinkCloud(enemy.position);
          enemy.hazardTimer = GameConfig.bossCloudCooldown;
        }

        if (!enemy.lowHpStinkEmitted && enemy.hp <= enemy.stats.hp * 0.35) {
          enemy.lowHpStinkEmitted = true;
          _spawnStinkEffect(
            enemy.position,
            size: GameConfig.bossEnemySize,
            lifetime: 1.1,
          );
        }
      }
    }
  }

  void _handleEnemySpawnSounds() {
    final visibleBounds = camera.visibleWorldRect.inflate(32);
    for (final enemy in enemies) {
      if (!enemy.isMounted ||
          enemy.isDead ||
          enemy.spawnSoundPlayed ||
          !visibleBounds.contains(enemy.position.toOffset())) {
        continue;
      }

      enemy.spawnSoundPlayed = true;
      switch (enemy.type) {
        case EnemyType.snake:
          soundManager.playSnakeSpawn();
        case EnemyType.boss:
          soundManager.playBossSpawn();
        case EnemyType.basic:
          break;
      }
    }
  }

  void _handleSludgePuddles() {
    for (final puddle in sludgePuddles) {
      if (!puddle.isMounted ||
          !puddle.canTrigger(player.position, GameConfig.playerRadius)) {
        continue;
      }

      final movement = joystick.relativeDelta.clone();
      if (movement.length2 > 0.04) {
        movement.normalize();
      } else {
        movement.setFrom(player.lastMoveDirection);
      }

      player.startSlide(movement);
      puddle.markTriggered();
      soundManager.playSludgePuddle();
      return;
    }
  }

  void _handleStinkCloudDamage(double dt) {
    for (final cloud in stinkClouds) {
      if (!cloud.isMounted ||
          !cloud.tryDamage(player.position, GameConfig.playerRadius, dt)) {
        continue;
      }

      final remainingCloudDamage =
          GameConfig.maxCloudDamagePerTickWindow - _cloudDamageInWindow;
      if (remainingCloudDamage <= 0) {
        continue;
      }

      final damage = math.min(cloud.damage, remainingCloudDamage);
      _cloudDamageInWindow += damage;
      if (!player.takeDamage(damage)) {
        continue;
      }
      soundManager.playPlayerDamage();
      _triggerDamageFeedback();
      if (player.hp <= 0) {
        _endGame();
        return;
      }
    }
  }

  void _updateCloudDamageWindow(double dt) {
    _cloudDamageWindowTimer -= dt;
    if (_cloudDamageWindowTimer > 0) {
      return;
    }

    _cloudDamageWindowTimer = GameConfig.stinkCloudTickInterval;
    _cloudDamageInWindow = 0;
  }

  bool _playerPositionBlocked(Vector2 position) {
    for (final prop in props) {
      if (!prop.isMounted ||
          !prop.blocksPlayer ||
          !_circleOverlapsRect(
            position,
            GameConfig.playerRadius,
            prop.collisionRect,
          )) {
        continue;
      }

      return true;
    }

    return false;
  }

  bool _enemyPositionBlocked(Vector2 position, double radius) {
    for (final prop in props) {
      if (!prop.isMounted ||
          !prop.blocksPlayer ||
          !_circleOverlapsRect(position, radius, prop.collisionRect)) {
        continue;
      }

      return true;
    }

    return false;
  }

  void _killEnemy(Enemy enemy) {
    score += enemy.stats.score;
    enemy.removeFromParent();

    soundManager.playEnemyDeath();
    _spawnSplat(enemy);
    if (enemy.type == EnemyType.boss) {
      _spawnStinkEffect(
        enemy.position,
        size: GameConfig.bossEnemySize * 1.1,
        lifetime: 1.2,
      );
    }
  }

  void _spawnMuzzleFlash(Vector2 direction) {
    final sprite = _randomSprite(muzzleFlashSprites);
    if (sprite == null || direction.length2 == 0) {
      return;
    }

    final normalized = direction.clone()..normalize();
    final flash = PoopSplatEffect(
      sprite: sprite,
      position: player.position + normalized * (GameConfig.playerSize * 0.42),
      size: Vector2.all(26 + _random.nextDouble() * 5),
      lifetime: 0.06 + _random.nextDouble() * 0.04,
      angle: math.atan2(normalized.y, normalized.x),
      priority: 13,
    );
    effects.add(flash);
    world.add(flash);
  }

  void _spawnHitSpark(Vector2 position) {
    final sprite = _randomSprite(hitSparkSprites);
    if (sprite == null) {
      return;
    }

    final spark = PoopSplatEffect(
      sprite: sprite,
      position: position.clone(),
      size: Vector2.all(16 + _random.nextDouble() * 6),
      lifetime: 0.08 + _random.nextDouble() * 0.07,
      priority: 13,
    );
    effects.add(spark);
    world.add(spark);
  }

  void _spawnSplat(Enemy enemy) {
    final sprite = _randomSprite(poopSplatSprites);
    if (sprite == null) {
      return;
    }

    final splat = PoopSplatEffect(
      sprite: sprite,
      position: enemy.position.clone(),
      size: _displaySizeForSprite(sprite, enemy.stats.radius * 3.1),
      lifetime:
          GameConfig.splatMinLifetime +
          _random.nextDouble() *
              (GameConfig.splatMaxLifetime - GameConfig.splatMinLifetime),
      angle: 0,
      priority: -70,
    );
    splats.add(splat);
    effects.add(splat);
    world.add(splat);
    _limitActiveSplats();
  }

  void _limitActiveSplats() {
    splats.removeWhere((splat) => splat.isRemoved);
    while (splats.length > GameConfig.maxActiveSplats) {
      splats.removeAt(0).removeFromParent();
    }
  }

  void _spawnFartEffect(
    Vector2 position, {
    double size = 28,
    double lifetime = 0.7,
  }) {
    final sprite = _randomSprite(fartSprites);
    if (sprite == null) {
      return;
    }

    final effect = PoopSplatEffect(
      sprite: sprite,
      position: position.clone(),
      size: Vector2.all(size),
      lifetime: lifetime,
      angle: _random.nextDouble() * math.pi * 2,
      priority: 13,
    );
    effects.add(effect);
    world.add(effect);
  }

  void _spawnStinkEffect(
    Vector2 position, {
    double size = 48,
    double lifetime = 1.0,
  }) {
    final sprite = _randomSprite(stinkSprites);
    if (sprite == null) {
      return;
    }

    final effect = PoopSplatEffect(
      sprite: sprite,
      position: position.clone(),
      size: Vector2.all(size),
      lifetime: lifetime,
      priority: 13,
    );
    effects.add(effect);
    world.add(effect);
  }

  void _spawnSnakeStinkCloud(Vector2 position) {
    final spawned = _spawnStinkCloud(
      StinkCloudKind.small,
      stinkCloudSmallSprite,
      position,
      visualSize: Vector2(
        GameConfig.snakeCloudWidth,
        GameConfig.snakeCloudHeight,
      ),
      damage: GameConfig.snakeCloudDamage,
      lifetime: GameConfig.snakeCloudDuration,
      fadeInDuration: GameConfig.snakeCloudFadeInDuration,
      fadeOutDuration: GameConfig.snakeCloudFadeOutDuration,
      collisionScale: GameConfig.snakeCloudCollisionScale,
      opacityAlpha: GameConfig.snakeCloudOpacityAlpha,
      maxActiveClouds: GameConfig.maxActiveSmallStinkClouds,
    );
    if (spawned) {
      soundManager.playEnemyPoop();
    }
  }

  void _spawnBossStinkCloud(Vector2 position) {
    final spawned = _spawnStinkCloud(
      StinkCloudKind.skull,
      stinkCloudSkullSprite,
      position,
      visualSize: Vector2(
        GameConfig.bossCloudWidth,
        GameConfig.bossCloudHeight,
      ),
      damage: GameConfig.bossCloudDamage,
      lifetime: GameConfig.bossCloudDuration,
      fadeInDuration: GameConfig.bossCloudFadeInDuration,
      fadeOutDuration: GameConfig.bossCloudFadeOutDuration,
      collisionScale: GameConfig.bossCloudCollisionScale,
      opacityAlpha: GameConfig.bossCloudOpacityAlpha,
      maxActiveClouds: GameConfig.maxActiveSkullStinkClouds,
    );
    if (spawned) {
      soundManager.playEnemyPoop();
    }
  }

  bool _spawnStinkCloud(
    StinkCloudKind kind,
    Sprite sprite,
    Vector2 position, {
    required Vector2 visualSize,
    required double damage,
    required double lifetime,
    required double fadeInDuration,
    required double fadeOutDuration,
    required double collisionScale,
    required int opacityAlpha,
    required int maxActiveClouds,
  }) {
    stinkClouds.removeWhere((cloud) => cloud.isRemoved);
    final sameKindClouds = stinkClouds
        .where((cloud) => cloud.kind == kind && cloud.isMounted)
        .toList();
    if (sameKindClouds.length >= maxActiveClouds) {
      return false;
    }

    final cloudPosition = _clampCloudPositionToVisibleWorld(
      position,
      visualSize,
    );

    final cloud = StinkCloudHazard(
      kind: kind,
      sprite: sprite,
      position: cloudPosition,
      size: visualSize,
      damage: damage,
      tickInterval: GameConfig.stinkCloudTickInterval,
      collisionRadius:
          math.min(visualSize.x, visualSize.y) * 0.5 * collisionScale,
      lifetime: lifetime,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      opacityAlpha: opacityAlpha,
    );
    stinkClouds.add(cloud);
    world.add(cloud);
    return true;
  }

  Vector2 _clampCloudPositionToVisibleWorld(
    Vector2 position,
    Vector2 visualSize,
  ) {
    final visibleBounds = camera.visibleWorldRect;
    final halfWidth = visualSize.x / 2;
    final halfHeight = visualSize.y / 2;

    final minX = math.max(halfWidth, visibleBounds.left + halfWidth);
    final maxX = math.min(
      GameConfig.worldWidth - halfWidth,
      visibleBounds.right - halfWidth,
    );
    final minY = math.max(halfHeight, visibleBounds.top + halfHeight);
    final maxY = math.min(
      GameConfig.worldHeight - halfHeight,
      visibleBounds.bottom - halfHeight,
    );

    return Vector2(
      position.x.clamp(math.min(minX, maxX), math.max(minX, maxX)).toDouble(),
      position.y.clamp(math.min(minY, maxY), math.max(minY, maxY)).toDouble(),
    );
  }

  bool _overlaps(Vector2 a, double aRadius, Vector2 b, double bRadius) {
    final radius = aRadius + bRadius;
    return a.distanceToSquared(b) <= radius * radius;
  }

  bool _circleOverlapsRect(Vector2 center, double radius, Rect rect) {
    final closestX = center.x.clamp(rect.left, rect.right).toDouble();
    final closestY = center.y.clamp(rect.top, rect.bottom).toDouble();
    final distanceX = center.x - closestX;
    final distanceY = center.y - closestY;
    return distanceX * distanceX + distanceY * distanceY <= radius * radius;
  }

  void _endGame() {
    if (isGameOver) {
      return;
    }

    isGameOver = true;
    adsManager.recordGameOver();
    joystick.onDragStop();
    _setJoystickVisible(false);
    _setPauseButtonVisible(false);
    unawaited(soundManager.pauseRunAudio());
    overlays.add(gameOverOverlay);
  }

  void _cleanupRemovedComponents() {
    enemies.removeWhere((enemy) => enemy.isRemoved || enemy.isDead);
    bullets.removeWhere((bullet) => bullet.isRemoved);
    effects.removeWhere((effect) => effect.isRemoved);
    splats.removeWhere((splat) => splat.isRemoved);
    stinkClouds.removeWhere((cloud) => cloud.isRemoved);
  }

  void _updateHud() {
    hpText.text = 'HP: ${player.hp.ceil()}';
    scoreText.text = 'Score: $score';
  }

  void _triggerDamageFeedback() {
    _hudDamageFlashTimer = GameConfig.hudDamageFlashDuration;
    hudPanel.color = HudPanelComponent.damageColor;
    hpText.textRenderer = _hudTextPaint(const Color(0xFFFFD1D1));
  }

  void _updateDamageFeedback(double dt) {
    if (_hudDamageFlashTimer <= 0) {
      return;
    }

    _hudDamageFlashTimer -= dt;
    if (_hudDamageFlashTimer <= 0) {
      _resetHudDamageFeedback();
    }
  }

  void _resetHudDamageFeedback() {
    hudPanel.color = HudPanelComponent.normalColor;
    hpText.textRenderer = _hudTextPaint(const Color(0xFFF2FFE9));
  }

  void _logAssetUsageReport() {
    debugPrint('''
Toilet Survivor asset usage report
- player/: ${AssetPaths.playerSprites.length} sheet used for player idle/walk animations.
- enemies/: ${AssetPaths.enemySprites.length} assets registered; basic/boss sheets animate enemies, snake PNG frames animate poop_snake, snake sheet is loaded as a registered fallback/reference.
- props/: ${AssetPaths.propSprites.length} props used by deterministic world placement and seeded random placement; blocking/decorative classification is applied.
- decals/: ${AssetPaths.decalSprites.length} sludge asset used as small/medium/large slide hazards.
- effects/bullets/: ${AssetPaths.bulletSprites.length} bullet variants selected per shot.
- effects/muzzle/: ${AssetPaths.muzzleSprites.length} muzzle flashes selected per shot.
- effects/hit/: ${AssetPaths.hitSprites.length} hit sparks selected on bullet impact.
- effects/fart/: ${AssetPaths.fartSprites.length} fart puffs used by snake movement and boss events.
- effects/splat/: ${AssetPaths.splatSprites.length} death splats selected on enemy death with active limit ${GameConfig.maxActiveSplats}.
- effects/stink/: ${AssetPaths.stinkSprites.length} stink clouds used by boss/snake timed hazards plus boss visual events.
- tiles/: ${AssetPaths.tileSprites.length} floor tiles loaded; one is selected per run/restart.
''');
  }
}

int _playerColumnFor(Direction direction) {
  return switch (direction) {
    Direction.front => GameConfig.playerFrontColumn,
    Direction.left || Direction.right => GameConfig.playerSideColumn,
    Direction.back => GameConfig.playerBackColumn,
  };
}

final List<_PropPlacement> _basePropPlacements = [
  _PropPlacement(AssetPaths.barrelRed, Vector2(220, 280)),
  _PropPlacement(AssetPaths.woodenCrate, Vector2(520, 420)),
  _PropPlacement(AssetPaths.metalBarricade, Vector2(840, 360)),
  _PropPlacement(AssetPaths.trashBin, Vector2(1240, 520)),
  _PropPlacement(AssetPaths.portableToilet, Vector2(1640, 420)),
  _PropPlacement(AssetPaths.rockPile, Vector2(350, 820)),
  _PropPlacement(AssetPaths.brokenCar, Vector2(760, 900)),
  _PropPlacement(
    AssetPaths.wetFloorSign,
    Vector2(1190, 980),
    collisionSize: _wetFloorSignCollisionSize,
    collisionOffset: _wetFloorSignCollisionOffset,
  ),
  _PropPlacement(AssetPaths.toilet, Vector2(1560, 860)),
  _PropPlacement(AssetPaths.barrelRed, Vector2(1810, 1120)),
  _propPlacementFor(AssetPaths.toiletPaperStack, Vector2(1480, 1180)),
  _PropPlacement(AssetPaths.woodenCrate, Vector2(260, 1420)),
  _PropPlacement(AssetPaths.metalBarricade, Vector2(640, 1520)),
  _PropPlacement(AssetPaths.trashBin, Vector2(1040, 1360)),
  _PropPlacement(AssetPaths.rockPile, Vector2(1450, 1540)),
  _propPlacementFor(AssetPaths.plungerGround, Vector2(1320, 1660)),
  _PropPlacement(AssetPaths.portableToilet, Vector2(1780, 1740)),
  _PropPlacement(AssetPaths.brokenCar, Vector2(420, 2060)),
  _PropPlacement(AssetPaths.toilet, Vector2(820, 2240)),
  _PropPlacement(
    AssetPaths.wetFloorSign,
    Vector2(1260, 2120),
    collisionSize: _wetFloorSignCollisionSize,
    collisionOffset: _wetFloorSignCollisionOffset,
  ),
  _PropPlacement(AssetPaths.metalBarricade, Vector2(1600, 2380)),
  _PropPlacement(AssetPaths.barrelRed, Vector2(1120, 2720)),
];

const List<String> _randomPropAssetPaths = [
  AssetPaths.barrelRed,
  AssetPaths.woodenCrate,
  AssetPaths.trashBin,
  AssetPaths.rockPile,
  AssetPaths.wetFloorSign,
  AssetPaths.metalBarricade,
  AssetPaths.toilet,
  AssetPaths.portableToilet,
  AssetPaths.brokenCar,
  AssetPaths.toiletPaperStack,
  AssetPaths.plungerGround,
];

class _PropPlacement {
  _PropPlacement(
    this.assetPath,
    this.position, {
    bool? blocksPlayer,
    Vector2? collisionSize,
    Vector2? collisionOffset,
  }) : blocksPlayer =
           blocksPlayer ?? AssetPaths.blockingPropSprites.contains(assetPath),
       collisionSize = collisionSize?.clone(),
       collisionOffset = collisionOffset?.clone();

  final String assetPath;
  final Vector2 position;
  final bool blocksPlayer;
  final Vector2? collisionSize;
  final Vector2? collisionOffset;
}

final Map<String, double> _propTargetWidths = {
  AssetPaths.barrelRed: GameConfig.propBarrelTargetWidth,
  AssetPaths.woodenCrate: GameConfig.propCrateTargetWidth,
  AssetPaths.trashBin: GameConfig.propTrashBinTargetWidth,
  AssetPaths.toilet: GameConfig.propToiletTargetWidth,
  AssetPaths.wetFloorSign: GameConfig.propWetFloorSignTargetWidth,
  AssetPaths.metalBarricade: GameConfig.propBarrierTargetWidth,
  AssetPaths.brokenCar: GameConfig.propBrokenCarTargetWidth,
  AssetPaths.portableToilet: GameConfig.propPortableToiletTargetWidth,
  AssetPaths.rockPile: GameConfig.propRockPileTargetWidth,
  AssetPaths.toiletPaperStack: GameConfig.propToiletPaperStackTargetWidth,
  AssetPaths.plungerGround: GameConfig.propPlungerGroundTargetWidth,
};

final Vector2 _wetFloorSignCollisionSize = Vector2(
  GameConfig.wetFloorSignCollisionWidth,
  GameConfig.wetFloorSignCollisionHeight,
);

final Vector2 _wetFloorSignCollisionOffset = Vector2(
  0,
  GameConfig.wetFloorSignCollisionOffsetY,
);

_PropPlacement _propPlacementFor(String assetPath, Vector2 position) {
  if (assetPath == AssetPaths.wetFloorSign) {
    return _PropPlacement(
      assetPath,
      position,
      collisionSize: _wetFloorSignCollisionSize,
      collisionOffset: _wetFloorSignCollisionOffset,
    );
  }

  return _PropPlacement(assetPath, position);
}

double _propTargetWidth(String assetPath) {
  return _propTargetWidths[assetPath] ?? 48;
}

Vector2 _propCollisionScaleFor(String assetPath) {
  return switch (assetPath) {
    AssetPaths.barrelRed || AssetPaths.trashBin => Vector2(
      GameConfig.propRoundCollisionScaleX,
      GameConfig.propRoundCollisionScaleY,
    ),
    AssetPaths.brokenCar || AssetPaths.portableToilet => Vector2(
      GameConfig.propLargeCollisionScaleX,
      GameConfig.propLargeCollisionScaleY,
    ),
    _ => Vector2(
      GameConfig.propCollisionScaleX,
      GameConfig.propCollisionScaleY,
    ),
  };
}
