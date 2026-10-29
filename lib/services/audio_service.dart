import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static Future<void> playBackground() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(0.25); // Set to low, pleasant background volume
    await _bgPlayer.play(AssetSource('background_music.mp3'));
  }

  static Future<void> playClick() async {
    await _sfxPlayer.setVolume(0.7);
    await _sfxPlayer.play(AssetSource('click.mp3'));
  }

  static Future<void> playWheelSpin() async {
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer.play(AssetSource('card_flip.wav'));
  }

  static Future<void> playCardFlip() async {
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer.play(AssetSource('card_flip.wav'));
  }

  static Future<void> playWinner() async {
    await _sfxPlayer.setVolume(1.0);
    await _sfxPlayer.play(AssetSource('winner.wav'));
  }

  static Future<void> stopAll() async {
    await _bgPlayer.stop();
    await _sfxPlayer.stop();
  }
}
