import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'challenge_card.dart';

class TruthCard extends StatelessWidget {
  final Question question;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  const TruthCard({super.key, required this.question, required this.onComplete, required this.onFail});

  @override
  Widget build(BuildContext context) => ChallengeCardSurface(
        color: AppColors.neonBlue,
        imagePath: 'assets/images/card_truth.jpg',
        title: 'TRUTH',
        question: question,
        content: [const SizedBox(height: 30), ChallengeActions(primaryColor: AppColors.neonBlue, onComplete: onComplete, onFail: onFail)],
      );
}
