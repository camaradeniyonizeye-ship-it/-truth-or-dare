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
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _promptPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
    lowerBound: .94,
    upperBound: 1,
  )..repeat(reverse: true);

  Timer? _navigationTimer;
  bool _isNavigating = false;

  static const String _splashArtwork =
      'assets/images/Gemini_Generated_Image_jdf484jdf484jdf4.jfif';

  @override
  void initState() {
    super.initState();
    AudioService.playBackground();
    _navigationTimer = Timer(const Duration(milliseconds: 3600), _openApp);
  }

  void _openApp() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    _navigationTimer?.cancel();
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const LanguageSelectionScreen(),
        transitionDuration: const Duration(milliseconds: 500),
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
    _promptPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openApp,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth / constraints.maxHeight > 1.15;
              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _entrance,
                    builder: (context, child) => Opacity(
                      opacity: Curves.easeOut.transform(_entrance.value),
                      child: Transform.scale(
                        scale: 1.045 - (_entrance.value * .045),
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
                            child: Icon(Icons.local_fire_department_rounded,
                                color: AppColors.neonPink, size: 74),
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
                          colors: [
                            Color(0x2509060D),
                            Color(0x0009060D),
                            Color(0xA609060D),
                          ],
                          stops: [0, .66, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: MediaQuery.paddingOf(context).bottom + (isWide ? 12 : 27),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xB309060D),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: AppColors.neonPink.withOpacity(.4)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonPink.withOpacity(.12),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: const Text(
                            '18+  •  PLAY WITH RESPECT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: _promptPulse,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  size: 16,
                                  color: AppColors.neonPink.withOpacity(.95)),
                              const SizedBox(width: 7),
                              const Text(
                                'TAP ANYWHERE TO ENTER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
