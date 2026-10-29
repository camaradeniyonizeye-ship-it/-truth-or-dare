import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _clickPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static Future<void> playBackground() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(0.25);
    await _bgPlayer.play(AssetSource('background_music.mp3'));
  }

  static Future<void> playClick() async {
    // Ensure the click sound is strictly configured for a single one-shot tap
    await _clickPlayer.setReleaseMode(ReleaseMode.stop);
    await _clickPlayer.setVolume(0.8);
    await _clickPlayer.stop(); // Stop any overlapping click audio before replaying
    await _clickPlayer.play(AssetSource('click.mp3'));
  }

  static Future<void> playWheelSpin() async {
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer.play(AssetSource('card_flip.wav'));
  }

  static Future<void> playCardFlip() async {
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer.play(AssetSource('card_flip.wav'));
  }

  static Future<void> playWinner() async {
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(1.0);
    await _sfxPlayer.play(AssetSource('winner.wav'));
  }

  static Future<void> stopAll() async {
    await _bgPlayer.stop();
    await _clickPlayer.stop();
    await _sfxPlayer.stop();
  }
}
