import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/question.dart';
import 'challenge_card.dart';

class DareCard extends StatelessWidget {
  final Question question;
  final int countdownSeconds;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const DareCard({
    super.key,
    required this.question,
    required this.countdownSeconds,
    required this.onComplete,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (countdownSeconds / GameRules.dareDurationSeconds).clamp(0.0, 1.0).toDouble();
    final timerColor = countdownSeconds <= 5 ? Colors.redAccent : const Color(0xFFFF0080);

    return ChallengeCardSurface(
      color: const Color(0xFFFF0080),
      imagePath: 'assets/images/card_dare.jpg',
      title: 'DARE',
      question: question,
      content: [
        const SizedBox(height: 18),
        Semantics(
          liveRegion: true,
          label: '$countdownSeconds seconds remaining',
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${countdownSeconds}s',
                style: TextStyle(color: timerColor, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ChallengeActions(
          primaryColor: const Color(0xFFFF0080),
          onComplete: onComplete,
          onFail: onFail,
        ),
      ],
    );
  }
}
