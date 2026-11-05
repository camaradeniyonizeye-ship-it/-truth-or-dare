import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _isBgPlaying = false;
  static bool _musicEnabled = true;
  static bool _sfxEnabled = true;
  static bool _initialized = false;
  static bool _winnerPlaying = false;
  static Timer? _winnerResumeTimer;
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;
  AudioService._internal();

  static bool get musicEnabled => _musicEnabled;
  static bool get sfxEnabled => _sfxEnabled;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(_instance);
    SharedPreferences.getInstance().then((preferences) {
      _musicEnabled = preferences.getBool('music_enabled') ?? true;
      _sfxEnabled = preferences.getBool('sfx_enabled') ?? true;
      if (_musicEnabled && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        playBackground();
      }
    });
  }

  static Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('music_enabled', enabled);
    if (!enabled) {
      _winnerResumeTimer?.cancel();
      _winnerPlaying = false;
      await _bgPlayer.stop();
      _isBgPlaying = false;
    } else {
      await playBackground();
    }
  }

  static Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('sfx_enabled', enabled);
    if (!enabled) {
      await _sfxPlayer.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      stopAll();
    } else if (state == AppLifecycleState.resumed && _musicEnabled) {
      playBackground();
    }
  }

  static Future<void> playBackground() async {
    if (!_musicEnabled || _isBgPlaying || _winnerPlaying) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.22);
      await _bgPlayer.play(AssetSource('music/background_music.mp3'));
      _isBgPlaying = true;
    } catch (_) {
      _isBgPlaying = false;
    }
  }

  static Future<void> playClick() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.setVolume(.75);
      await _sfxPlayer.play(AssetSource('music/click.mp3'));
    } catch (_) {}
  }

  static Future<void> playWheelSpin() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.setVolume(.75);
      await _sfxPlayer.play(AssetSource('music/card_flip.wav'));
    } catch (_) {}
  }

  static Future<void> playCardFlip() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.setVolume(.75);
      await _sfxPlayer.play(AssetSource('music/card_flip.wav'));
    } catch (_) {}
  }

  static Future<void> playWinner() async {
    if (!_sfxEnabled && !_musicEnabled) return;
    try {
      _winnerResumeTimer?.cancel();
      await _bgPlayer.stop();
      _isBgPlaying = false;
      _winnerPlaying = true;
      if (_sfxEnabled) {
        await _sfxPlayer.setVolume(.85);
        await _sfxPlayer.play(AssetSource('music/winner.wav'));
      }
      _winnerResumeTimer = Timer(const Duration(seconds: 4), () {
        _winnerPlaying = false;
        if (_musicEnabled) playBackground();
      });
    } catch (_) {
      _winnerPlaying = false;
    }
  }

  static Future<void> stopAll() async {
    try {
      await _bgPlayer.stop();
      await _sfxPlayer.stop();
    } catch (_) {}
    _isBgPlaying = false;
  }
}
