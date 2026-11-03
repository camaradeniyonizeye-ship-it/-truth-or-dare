import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  Timer? _navigationTimer;
  bool _isNavigating = false;

  static const String _splashArtwork =
      'assets/images/Gemini_Generated_Image_jdf484jdf484jdf4.jfif';

  @override
  void initState() {
    super.initState();
    AudioService.playBackground();
    // Keep the artwork on screen long enough to read, but allow a tap to move on.
    _navigationTimer = Timer(const Duration(milliseconds: 3200), _openApp);
  }

  void _openApp() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    _navigationTimer?.cancel();
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const LanguageSelectionScreen(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openApp,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _entrance,
                builder: (context, child) => Opacity(
                  opacity: Curves.easeOut.transform(_entrance.value),
                  child: Transform.scale(
                    scale: 1.035 - (_entrance.value * .035),
                    child: child,
                  ),
                ),
                child: Image.asset(
                  _splashArtwork,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/bg_splash.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.background,
                      child: Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.neonPink,
                          size: 74,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1609060D), Color(0x0009060D), Color(0x9909060D)],
                      stops: [0, .68, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                child: const Column(
                  children: [
                    Text(
                      '18+  •  PLAY WITH RESPECT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'TAP TO ENTER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
