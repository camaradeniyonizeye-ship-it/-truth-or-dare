import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: 1.2,
            colors: [Color(0xFF28142C), Color(0xFF120B18), AppColors.background],
            stops: [0, .48, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _NeonBackdropPainter()))),
            Positioned(top: -120, right: -100, child: _Glow(color: AppColors.neonPink.withOpacity(.12), size: 280)),
            Positioned(bottom: -140, left: -110, child: _Glow(color: AppColors.neonPurple.withOpacity(.13), size: 300)),
            child,
          ],
        ),
      );
}

class AppGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? accent;
  const AppGlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.borderRadius = const BorderRadius.all(Radius.circular(22)), this.accent});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xCC140D18),
              borderRadius: borderRadius,
              border: Border.all(color: accent?.withOpacity(.4) ?? Colors.white.withOpacity(.12)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.32), blurRadius: 28, offset: const Offset(0, 12))],
            ),
            child: child,
          ),
        ),
      );
}

class AppSectionLabel extends StatelessWidget {
  final String text;
  const AppSectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2));
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)])));
}

class _NeonBackdropPainter extends CustomPainter {
  const _NeonBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()..color = AppColors.neonPink.withOpacity(.22)..style = PaintingStyle.stroke..strokeWidth = 2;
    final purple = Paint()..color = AppColors.neonPurple.withOpacity(.2)..style = PaintingStyle.stroke..strokeWidth = 2;
    final dim = Paint()..color = Colors.black.withOpacity(.24)..style = PaintingStyle.stroke..strokeWidth = 7;
    final paths = <Path>[
      Path()..moveTo(-20, size.height * .25)..lineTo(size.width * .08, size.height * .5)..lineTo(-20, size.height * .74),
      Path()..moveTo(size.width + 20, size.height * .25)..lineTo(size.width * .92, size.height * .5)..lineTo(size.width + 20, size.height * .74),
      Path()..moveTo(size.width * .35, -20)..lineTo(size.width * .5, size.height * .10)..lineTo(size.width * .65, -20),
      Path()..moveTo(size.width * .35, size.height + 20)..lineTo(size.width * .5, size.height * .88)..lineTo(size.width * .65, size.height + 20),
    ];
    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], dim);
      canvas.drawPath(paths[i], i.isEven ? pink : purple);
    }
    final grain = Paint()..color = Colors.white.withOpacity(.018);
    for (var i = 0; i < 80; i++) {
      final x = (i * 97.0) % size.width;
      final y = (i * 173.0) % size.height;
      canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 1.5 : 1, grain);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
