# Codex Context - 2026-06-23

## Summary

Today we integrated the first audio pass for Toilet Survivor.

## Implemented

- Added `flame_audio` and registered the root `sound/` asset folder.
- Added `SoundPaths` to centralize all audio filenames.
- Added `SoundManager` to preload audio, use `AudioPool` for repeated SFX, and throttle sounds with cooldowns to avoid spam.
- Added run music that alternates between `music_1.mp3` and `music_2.mp3`.
- Added ambient loops based on selected floor tile:
  - `floor_sewage` uses `Ambience_1.mp3`.
  - `floor_toilet_dirty` and `floor_dirt` use `Ambience_2.mp3`.
- Hooked SFX into gameplay:
  - `ui_click`: start, pause, resume, restart, revive button taps.
  - `player_shooting`: player auto-shoot.
  - `bullet_hit`: bullet hits enemy.
  - `enemy_death`: enemy dies.
  - `enemy_poop`: snake/boss stink cloud emission.
  - `player_damage`: player takes contact/cloud damage.
  - `sludge_puddle`: player triggers sludge slide.
  - `snake_enemy`: snake appears inside the camera view.
  - `boss_sound`: boss appears inside the camera view.
- Paused run music/ambience on pause and Game Over.
- Resumed run music/ambience on pause resume and rewarded revive.

## Anti-Spam Notes

- Fast sounds such as shooting and bullet hit use short cooldowns.
- Damage, sludge, stink cloud, snake spawn, and boss spawn use longer cooldowns.
- Snake/boss spawn sounds are guarded by `spawnSoundPlayed` so each enemy only triggers its appear sound once.
- Boss cloud emission intentionally uses `enemy_poop`, not `boss_sound`.

## Validation

- `flutter analyze` passed.
- `flutter test` passed.
- `flutter build apk --debug` passed.

## Important Repo Note

`pubspec.yaml` previously contained an invalid `flutter.config` block after pulling latest code. It was removed because Flutter rejected it while adding `flame_audio`. iOS CocoaPods config remains handled in the iOS `.xcconfig` files.
