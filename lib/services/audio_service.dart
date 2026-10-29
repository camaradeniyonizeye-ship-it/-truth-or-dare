import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _isBgPlaying = false;

  static Future<void> playBackground() async {
    if (_isBgPlaying) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.3);
      await _bgPlayer.play(AssetSource('background_music.mp3'));
      _isBgPlaying = true;
    } catch (_) {}
  }

  static Future<void> playClick() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('click.mp3'));
    } catch (_) {}
  }

  static Future<void> playWheelSpin() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('card_flip.wav'));
    } catch (_) {}
  }

  static Future<void> playCardFlip() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('card_flip.wav'));
    } catch (_) {}
  }

  static Future<void> playWinner() async {
    try {
      await _bgPlayer.stop(); // Stop background for winner sound
      _isBgPlaying = false;
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('winner.wav'));
      
      // Resume background music after winner celebration
      Future.delayed(const Duration(seconds: 4), () {
        playBackground();
      });
    } catch (_) {}
  }

  static Future<void> stopAll() async {
    try {
      await _bgPlayer.stop();
      await _sfxPlayer.stop();
      _isBgPlaying = false;
    } catch (_) {}
  }
}
