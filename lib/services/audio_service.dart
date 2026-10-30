import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _isBgPlaying = false;

  static Future<void> playBackground() async {
    if (_isBgPlaying) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.3); // 30% soft background volume
      await _bgPlayer.play(AssetSource('music/background_music.mp3'));
      _isBgPlaying = true;
    } catch (e) {
      print("Audio background error: $e");
    }
  }

  static Future<void> playClick() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('music/click.mp3'));
    } catch (_) {}
  }

  static Future<void> playWheelSpin() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('music/card_flip.wav'));
    } catch (_) {}
  }

  static Future<void> playCardFlip() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('music/card_flip.wav'));
    } catch (_) {}
  }

  static Future<void> playWinner() async {
    try {
      await _bgPlayer.stop();
      _isBgPlaying = false;
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource('music/winner.wav'));
      
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
