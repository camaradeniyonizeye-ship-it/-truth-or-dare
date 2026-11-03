import 'package:flutter/material.dart';
import '../models/game_rules.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'challenge_card.dart';

class DareCard extends StatelessWidget {
  final Question question;
  final int countdownSeconds;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const DareCard({super.key, required this.question, required this.countdownSeconds, required this.onComplete, required this.onFail});

  @override
  Widget build(BuildContext context) {
    final progress = (countdownSeconds / GameRules.dareDurationSeconds).clamp(0.0, 1.0).toDouble();
    final timerColor = countdownSeconds <= 5 ? AppColors.neonRed : AppColors.neonPink;
    return ChallengeCardSurface(
      color: AppColors.neonPink,
      imagePath: 'assets/images/card_dare.jpg',
      title: 'DARE',
      question: question,
      content: [
        Padding(
          padding: const EdgeInsets.only(top: 11),
          child: Semantics(
            liveRegion: true,
            label: '$countdownSeconds seconds remaining',
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$countdownSeconds s', style: TextStyle(color: timerColor, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        ChallengeActions(primaryColor: AppColors.neonPink, onComplete: onComplete, onFail: onFail),
      ],
    );
  }
}
