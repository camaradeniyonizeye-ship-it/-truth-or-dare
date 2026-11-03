import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/question.dart';

class TruthCard extends StatelessWidget {
  final Question question;
  final Player player;
  final int countdownSeconds;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const TruthCard({
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
        border: Border.all(color: const Color(0xFF0080FF), width: 3),
        image: const DecorationImage(
          image: AssetImage('assets/images/card_truth.jpg'),
          fit: BoxFit.cover,
          opacity: 0.85,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'TRUTH',
            style: TextStyle(
              color: Color(0xFF0080FF),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
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
                    backgroundColor: const Color(0xFF0080FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('COMPLETED (+10)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onFail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
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

