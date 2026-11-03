import 'package:flutter/material.dart';

import '../models/question.dart';
import 'challenge_card.dart';

class TruthCard extends StatelessWidget {
  final Question question;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const TruthCard({
    super.key,
    required this.question,
    required this.onComplete,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return ChallengeCardSurface(
      color: const Color(0xFF0080FF),
      imagePath: 'assets/images/card_truth.jpg',
      title: 'TRUTH',
      question: question,
      content: [
        const SizedBox(height: 30),
        ChallengeActions(
          primaryColor: const Color(0xFF0080FF),
          onComplete: onComplete,
          onFail: onFail,
        ),
      ],
    );
  }
}
