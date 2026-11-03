import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/question.dart';

class DareCard extends StatelessWidget {
  final Question question;
  final Player player;
  final int countdownSeconds;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const DareCard({
    super.key,
    required this.question,
    required this.player,
    required this.countdownSeconds,
    required this.onComplete,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF0080), width: 3),
        image: const DecorationImage(
          image: AssetImage('assets/images/card_dare.jpg'),
          fit: BoxFit.cover,
          opacity: 0.85,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DARE',
            style: TextStyle(
              color: Color(0xFFFF0080),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Time left: ${countdownSeconds}s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0080),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('COMPLETED (+10)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onFail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('FAILED (-5)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

