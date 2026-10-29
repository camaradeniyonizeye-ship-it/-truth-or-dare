import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerSpinner extends StatefulWidget {
  final List<Player> players;
  final Function(Player) onPlayerSelected;

  const PlayerSpinner({
    super.key,
    required this.players,
    required this.onPlayerSelected,
  });

  @override
  State<PlayerSpinner> createState() => _PlayerSpinnerState();
}

class _PlayerSpinnerState extends State<PlayerSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _angle = 0.0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel(List<Player> availablePlayers) {
    if (_isSpinning || availablePlayers.isEmpty) return;

    setState(() {
      _isSpinning = true;
    });

    // Pick a random player from the eligible pool (who haven't played yet this cycle)
    final random = math.Random();
    final selectedPlayer = availablePlayers[random.nextInt(availablePlayers.length)];
    final selectedIndex = widget.players.indexOf(selectedPlayer);

    // Calculate slice angle and target rotation
    final double sliceAngle = (2 * math.pi) / widget.players.length;
    // Target position so the selected player lands under the top pointer
    final double targetAngle = (2 * math.pi * 5) + (2 * math.pi - (selectedIndex * sliceAngle) - (sliceAngle / 2));

    _controller.reset();
    _controller.duration = const Duration(seconds: 3);

    Animation<double> animation = Tween<double>(
      begin: _angle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      setState(() {
        _angle = animation.value;
      });
    });

    animation.statusListener = (status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        widget.onPlayerSelected(selectedPlayer);
      }
    };

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Filter players who have NOT completed their turn in this round
    final availablePlayers = widget.players.where((p) => !p.hasCompletedTurn).toList();
    // If everyone has played, reset the cycle automatically
    final activePool = availablePlayers.isNotEmpty ? availablePlayers : widget.players;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Pointer at the top
            Positioned(
              top: 0,
              zIndex: 10,
              child: CustomPaint(
                size: const Size(30, 30),
                painter: _TrianglePainter(),
              ),
            ),
            // The Spinning Wheel
            Transform.rotate(
              angle: _angle,
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _WheelPainter(players: widget.players),
              ),
            ),
            // Center spin button hub
            GestureDetector(
              onTap: () => _spinWheel(activePool),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF007F), Color(0xFF0080FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SPIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isSpinning ? null : () => _spinWheel(activePool),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 5,
          ),
          child: Text(
            _isSpinning ? 'SPINNING...' : 'SPIN THE WHEEL',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Player> players;
  _WheelPainter({required this.players});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double sliceAngle = (2 * math.pi) / players.length;

    final List<Color> sliceColors = [
      const Color(0xFF0080FF),
      const Color(0xFFFF0080),
      const Color(0xFF7B1FA2),
      const Color(0xFF00796B),
      const Color(0xFFC2185B),
      const Color(0xFF303F9F),
    ];

    for (int i = 0; i < players.length; i++) {
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..color = sliceColors[i % sliceColors.length];

      canvas.drawArc(rect, i * sliceAngle, sliceAngle, true, paint);

      // Draw Player Names
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sliceAngle + sliceAngle / 2);

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: players[i].name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      tp.layout();
      tp.paint(canvas, Offset(radius * 0.55, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }
}
