import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF20142D), AppColors.background, Color(0xFF0D111B)],
            stops: [0, .48, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -110, right: -80, child: _Glow(color: AppColors.neonPink.withOpacity(.12), size: 260)),
            Positioned(bottom: -130, left: -100, child: _Glow(color: AppColors.neonBlue.withOpacity(.10), size: 280)),
            child,
          ],
        ),
      );
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)]),
        ),
      );
}

class AppSectionLabel extends StatelessWidget {
  final String text;
  const AppSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
      );
}
