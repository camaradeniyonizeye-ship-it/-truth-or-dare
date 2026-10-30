import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'player_setup_screen.dart';
import 'difficulty_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.playBackground();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerSetupScreen(
          language: 'English',
          onPlayersReady: (players) {
            AudioService.playClick();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DifficultySelectionScreen(
                  players: players,
                  selectedLanguage: 'English',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a0033), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TRUTH OR DARE 18+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: Colors.pinkAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
