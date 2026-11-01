import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/audio_service.dart';
import 'data/game_data.dart'; // Make sure this path matches your project structure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize audio service
  AudioService.initialize();
  
  // 2. Preload your JSON question databases into memory
  await GameData.init();

  runApp(const TruthOrDareApp());
}

class TruthOrDropApp extends StatelessWidget { // Keep your original class name if it was TruthOrDareApp
  const TruthOrDareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truth or Dare (18+)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
