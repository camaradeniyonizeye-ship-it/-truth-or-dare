import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    AudioService.playBackground();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/splash.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF130D20))),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55100A18), Color(0xF5090711)]))),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(scale: 1 + _pulse.value * .06, child: child),
                  child: Container(
                    width: 112, height: 112,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF211827), border: Border.all(color: const Color(0xFFFF4F9A).withOpacity(.65)), boxShadow: const [BoxShadow(color: Color(0x55FF4F9A), blurRadius: 40)]),
                    child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B9E), size: 56),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('TRUTH OR DARE', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 2.4)),
                const SizedBox(height: 8),
                const Text('THE NIGHT IS YOURS', style: TextStyle(color: Color(0xFFBDB4C9), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3)),
                const SizedBox(height: 38),
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF4F9A))),
              ]),
            ),
            const Positioned(left: 0, right: 0, bottom: 36, child: Text('18+  •  PLAY WITH RESPECT', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8))),
          ],
        ),
      );
}
