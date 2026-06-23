import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:toilet_survivor/config/asset_paths.dart';
import 'package:toilet_survivor/config/sound_paths.dart';

enum _SoundKey {
  uiClick,
  playerShooting,
  bulletHit,
  enemyDeath,
  enemyPoop,
  playerDamage,
  sludgePuddle,
  snakeEnemy,
  bossSound,
}

class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  static const double _sfxVolume = 0.72;
  static const double _musicVolume = 0.22;
  static const double _ambienceVolume = 0.18;

  final Map<_SoundKey, AudioPool> _pools = {};
  final Map<_SoundKey, int> _lastPlayedAtMs = {};
  bool _initialized = false;
  bool _audioAvailable = false;
  bool _loopsPaused = false;
  int _nextMusicIndex = 0;
  String? _currentMusicPath;
  String? _currentAmbiencePath;
  AudioPlayer? _musicPlayer;
  AudioPlayer? _ambiencePlayer;
  Future<void> Function()? _bossSoundStop;
  int _bossSoundToken = 0;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    FlameAudio.updatePrefix('sound/');

    try {
      await FlameAudio.audioCache.loadAll(SoundPaths.all);
      _pools[_SoundKey.uiClick] = await _pool(
        SoundPaths.uiClick,
        maxPlayers: 2,
      );
      _pools[_SoundKey.playerShooting] = await _pool(
        SoundPaths.playerShooting,
        maxPlayers: 4,
      );
      _pools[_SoundKey.bulletHit] = await _pool(
        SoundPaths.bulletHit,
        maxPlayers: 4,
      );
      _pools[_SoundKey.enemyDeath] = await _pool(
        SoundPaths.enemyDeath,
        maxPlayers: 3,
      );
      _pools[_SoundKey.enemyPoop] = await _pool(
        SoundPaths.enemyPoop,
        maxPlayers: 2,
      );
      _pools[_SoundKey.playerDamage] = await _pool(
        SoundPaths.playerDamage,
        maxPlayers: 2,
      );
      _pools[_SoundKey.sludgePuddle] = await _pool(
        SoundPaths.sludgePuddle,
        maxPlayers: 2,
      );
      _pools[_SoundKey.snakeEnemy] = await _pool(
        SoundPaths.snakeEnemy,
        maxPlayers: 2,
      );
      _pools[_SoundKey.bossSound] = await _pool(
        SoundPaths.bossSound,
        maxPlayers: 1,
      );
      _audioAvailable = true;
    } catch (error, stackTrace) {
      _audioAvailable = false;
      debugPrint('SoundManager disabled: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<AudioPool> _pool(String path, {required int maxPlayers}) {
    return FlameAudio.createPool(path, minPlayers: 1, maxPlayers: maxPlayers);
  }

  void playUiClick() {
    _play(_SoundKey.uiClick, cooldown: const Duration(milliseconds: 80));
  }

  void playPlayerShooting() {
    _play(
      _SoundKey.playerShooting,
      volume: 0.42,
      cooldown: const Duration(milliseconds: 120),
    );
  }

  void playBulletHit() {
    _play(
      _SoundKey.bulletHit,
      volume: 0.48,
      cooldown: const Duration(milliseconds: 70),
    );
  }

  void playEnemyDeath() {
    _play(
      _SoundKey.enemyDeath,
      volume: 0.62,
      cooldown: const Duration(milliseconds: 120),
    );
  }

  void playEnemyPoop() {
    _play(
      _SoundKey.enemyPoop,
      volume: 0.55,
      cooldown: const Duration(milliseconds: 650),
    );
  }

  void playPlayerDamage() {
    _play(
      _SoundKey.playerDamage,
      volume: 0.62,
      cooldown: const Duration(milliseconds: 280),
    );
  }

  void playSludgePuddle() {
    _play(
      _SoundKey.sludgePuddle,
      volume: 0.46,
      cooldown: const Duration(milliseconds: 650),
    );
  }

  void playSnakeSpawn() {
    _play(
      _SoundKey.snakeEnemy,
      volume: 0.50,
      cooldown: const Duration(milliseconds: 900),
    );
  }

  void playBossSpawn() {
    if (!_audioAvailable ||
        !_canPlay(_SoundKey.bossSound, const Duration(seconds: 4))) {
      return;
    }

    final pool = _pools[_SoundKey.bossSound];
    if (pool == null) {
      return;
    }

    final token = ++_bossSoundToken;
    unawaited(_startBossSound(pool, token, 0.70 * _sfxVolume));
  }

  void stopBossSound() {
    _bossSoundToken++;
    final stop = _bossSoundStop;
    _bossSoundStop = null;
    if (stop == null) {
      return;
    }

    unawaited(_stopBossSound(stop));
  }

  Future<void> startRunAudioForTile(String tilePath) async {
    if (!_audioAvailable) {
      return;
    }

    try {
      _loopsPaused = false;
      final musicPath = _nextMusicPath();
      final ambiencePath = _ambienceForTile(tilePath);
      await _restartLoop(
        currentPath: _currentMusicPath,
        nextPath: musicPath,
        currentPlayer: _musicPlayer,
        assign: (player) => _musicPlayer = player,
        volume: _musicVolume,
      );
      _currentMusicPath = musicPath;
      await _restartLoop(
        currentPath: _currentAmbiencePath,
        nextPath: ambiencePath,
        currentPlayer: _ambiencePlayer,
        assign: (player) => _ambiencePlayer = player,
        volume: _ambienceVolume,
      );
      _currentAmbiencePath = ambiencePath;
    } catch (error) {
      debugPrint('SoundManager loop start failed: $error');
    }
  }

  Future<void> pauseRunAudio() async {
    if (!_audioAvailable || _loopsPaused) {
      return;
    }

    try {
      _loopsPaused = true;
      await Future.wait([
        if (_musicPlayer != null) _musicPlayer!.pause(),
        if (_ambiencePlayer != null) _ambiencePlayer!.pause(),
      ]);
    } catch (error) {
      debugPrint('SoundManager loop pause failed: $error');
    }
  }

  Future<void> resumeRunAudio() async {
    if (!_audioAvailable || !_loopsPaused) {
      return;
    }

    try {
      _loopsPaused = false;
      await Future.wait([
        if (_musicPlayer != null) _musicPlayer!.resume(),
        if (_ambiencePlayer != null) _ambiencePlayer!.resume(),
      ]);
    } catch (error) {
      debugPrint('SoundManager loop resume failed: $error');
    }
  }

  Future<void> stopRunAudio() async {
    try {
      _loopsPaused = false;
      await Future.wait([
        if (_musicPlayer != null) _musicPlayer!.stop(),
        if (_ambiencePlayer != null) _ambiencePlayer!.stop(),
      ]);
    } catch (error) {
      debugPrint('SoundManager loop stop failed: $error');
    }
  }

  void _play(_SoundKey key, {double volume = 1.0, required Duration cooldown}) {
    if (!_audioAvailable || !_canPlay(key, cooldown)) {
      return;
    }

    final pool = _pools[key];
    if (pool == null) {
      return;
    }

    unawaited(_startPoolSound(pool, key, volume * _sfxVolume));
  }

  Future<void> _startPoolSound(
    AudioPool pool,
    _SoundKey key,
    double volume,
  ) async {
    try {
      await pool.start(volume: volume);
    } catch (error) {
      debugPrint('SoundManager SFX failed ($key): $error');
    }
  }

  Future<void> _startBossSound(AudioPool pool, int token, double volume) async {
    try {
      final previousStop = _bossSoundStop;
      _bossSoundStop = null;
      if (previousStop != null) {
        await previousStop();
      }

      final stop = await pool.start(volume: volume);
      if (token != _bossSoundToken) {
        await stop();
        return;
      }

      _bossSoundStop = stop;
    } catch (error) {
      debugPrint('SoundManager boss SFX failed: $error');
    }
  }

  Future<void> _stopBossSound(Future<void> Function() stop) async {
    try {
      await stop();
    } catch (error) {
      debugPrint('SoundManager boss SFX stop failed: $error');
    }
  }

  bool _canPlay(_SoundKey key, Duration cooldown) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = _lastPlayedAtMs[key] ?? -cooldown.inMilliseconds;
    if (now - previous < cooldown.inMilliseconds) {
      return false;
    }

    _lastPlayedAtMs[key] = now;
    return true;
  }

  String _nextMusicPath() {
    final path = SoundPaths.musicTracks[_nextMusicIndex];
    _nextMusicIndex = (_nextMusicIndex + 1) % SoundPaths.musicTracks.length;
    return path;
  }

  String _ambienceForTile(String tilePath) {
    return tilePath == AssetPaths.floorSewage
        ? SoundPaths.ambienceSewage
        : SoundPaths.ambienceDirty;
  }

  Future<void> _restartLoop({
    required String? currentPath,
    required String nextPath,
    required AudioPlayer? currentPlayer,
    required void Function(AudioPlayer? player) assign,
    required double volume,
  }) async {
    if (currentPath == nextPath && currentPlayer != null) {
      await currentPlayer.setVolume(volume);
      await currentPlayer.resume();
      return;
    }

    await currentPlayer?.stop();
    final player = await FlameAudio.loopLongAudio(nextPath, volume: volume);
    assign(player);
  }
}
