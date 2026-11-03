import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class PlayerSpinner extends StatefulWidget {
  final List<Player> players;
  final Function(Player) onPlayerSelected;
  const PlayerSpinner({super.key, required this.players, required this.onPlayerSelected});
  @override
  State<PlayerSpinner> createState() => _PlayerSpinnerState();
}

class _PlayerSpinnerState extends State<PlayerSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _angle = 0;
  bool _isSpinning = false;

  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600)); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _spinWheel(List<Player> availablePlayers) {
    if (_isSpinning || availablePlayers.isEmpty || widget.players.isEmpty) return;
    setState(() => _isSpinning = true);
    final selected = availablePlayers[math.Random().nextInt(availablePlayers.length)];
    final index = widget.players.indexOf(selected);
    final sliceAngle = 2 * math.pi / widget.players.length;
    final current = _angle % (2 * math.pi);
    final targetNormalized = (2 * math.pi - (index * sliceAngle + sliceAngle / 2)) % (2 * math.pi);
    var delta = (targetNormalized - current) % (2 * math.pi);
    if (delta < .08) delta += 2 * math.pi;
    final target = _angle + 2 * math.pi * 6 + delta;
    _controller.reset();
    final animation = Tween<double>(begin: _angle, end: target).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    animation.addListener(() { if (mounted) setState(() => _angle = animation.value); });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() { _isSpinning = false; _angle = targetNormalized; });
        widget.onPlayerSelected(selected);
      }
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.players.where((player) => !player.hasCompletedTurn).toList();
    final activePool = remaining.isNotEmpty ? remaining : widget.players;
    return LayoutBuilder(builder: (context, constraints) {
      final diameter = math.min(320.0, math.min(constraints.maxWidth, MediaQuery.sizeOf(context).height * .39));
      return Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: diameter, height: diameter, child: Stack(alignment: Alignment.center, children: [
          Container(width: diameter, height: diameter, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.neonPink.withOpacity(.12), blurRadius: 34, spreadRadius: 4)])),
          Transform.rotate(angle: _angle, child: CustomPaint(size: Size.square(diameter), painter: _WheelPainter(players: widget.players))),
          Positioned(top: 0, child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gold, size: diameter * .15)),
          Material(color: Colors.transparent, child: InkWell(onTap: _isSpinning ? null : () => _spinWheel(activePool), customBorder: const CircleBorder(), child: Container(width: diameter * .24, height: diameter * .24, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.neonPink, AppColors.neonPurple]), border: Border.all(color: Colors.white.withOpacity(.55), width: 3), boxShadow: [BoxShadow(color: AppColors.neonPink.withOpacity(.4), blurRadius: 20)]), child: Center(child: Text(_isSpinning ? '…' : 'SPIN', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1))))))
        ])),
        const SizedBox(height: 18),
        Text(_isSpinning ? 'Picking your player…' : 'Tap the wheel or button to pick', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(width: math.min(280, constraints.maxWidth), child: ElevatedButton.icon(onPressed: _isSpinning ? null : () => _spinWheel(activePool), icon: Icon(_isSpinning ? Icons.hourglass_top_rounded : Icons.casino_rounded), label: Text(_isSpinning ? 'SPINNING…' : 'SPIN THE WHEEL'))),
      ]);
    });
  }
}

class _WheelPainter extends CustomPainter {
  final List<Player> players;
  _WheelPainter({required this.players});
  static const colors = [Color(0xFF513B82), Color(0xFF315A82), Color(0xFF743A67), Color(0xFF245F62), Color(0xFF79503D), Color(0xFF453D78)];

  @override
  void paint(Canvas canvas, Size size) {
    if (players.isEmpty) return;
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - 5);
    final sliceAngle = 2 * math.pi / players.length;
    const offset = -math.pi / 2;
    final separator = Paint()..color = const Color(0xFF171421)..style = PaintingStyle.stroke..strokeWidth = 3;
    for (var i = 0; i < players.length; i++) {
      final start = offset + i * sliceAngle;
      final fill = Paint()..shader = RadialGradient(colors: [colors[i % colors.length].withOpacity(.82), colors[i % colors.length]]).createShader(rect);
      canvas.drawArc(rect, start, sliceAngle, true, fill);
      canvas.drawArc(rect, start, sliceAngle, true, separator);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(start + sliceAngle / 2);
      final text = players[i].name;
      final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: Colors.white, fontSize: math.min(14.0, radius / math.max(6, players.length)), fontWeight: FontWeight.w800, shadows: const [Shadow(color: Colors.black87, blurRadius: 5)])), textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…');
      tp.layout(maxWidth: radius * .55);
      tp.paint(canvas, Offset(radius * .35, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(center, radius - 5, Paint()..color = AppColors.gold.withOpacity(.8)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(center, radius * .20, Paint()..color = Colors.white.withOpacity(.09)..style = PaintingStyle.stroke..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => oldDelegate.players != players;
}
