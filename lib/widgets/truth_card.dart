import 'package:flutter/material.dart';
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
        color: AppColors.neonPurple,
        imagePath: 'assets/images/card_truth.jpg',
        title: 'TRUTH',
        question: question,
        content: [ChallengeActions(primaryColor: AppColors.neonPurple, onComplete: onComplete, onFail: onFail)],
      );
}
