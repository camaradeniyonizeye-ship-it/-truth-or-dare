import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static double _volume = 0.5;

  static Future<void> init() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
  }

  static Future<void> playBackground() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _bgPlayer.setSource(AssetSource('music/background_music.mp3'));
      await _bgPlayer.setVolume(_volume);
      await _bgPlayer.resume();
    } catch (_) {}
  }

  static Future<void> stopBackground() async {
    try {
      await _bgPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  static Future<void> playSFX(String fileName) async {
    try {
      await _sfxPlayer.setSource(AssetSource('music/$fileName'));
      await _sfxPlayer.resume();
    } catch (_) {}
  }

  static Future<void> playClick() async => playSFX('click.mp3');
  static Future<void> playCardFlip() async => playSFX('card_flip.wav');
  static Future<void> playWheelSpin() async => playSFX('wheel_spin.wav');
  static Future<void> playWinner() async => playSFX('winner.wav');

  static Future<void> stopAll() async {
    try {
      await _bgPlayer.stop();
      await _sfxPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  static Future<void> dispose() async {
    await _bgPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
