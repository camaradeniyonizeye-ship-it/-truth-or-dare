import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/question.dart';

class ChallengeCardSurface extends StatelessWidget {
  final Color color;
  final String imagePath;
  final String title;
  final Question question;
  final List<Widget> content;

  const ChallengeCardSurface({
    super.key,
    required this.color,
    required this.imagePath,
    required this.title,
    required this.question,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2.5),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          opacity: 0.85,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                question.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          ...content,
        ],
      ),
    );
  }
}

class ChallengeActions extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const ChallengeActions({
    super.key,
    required this.primaryColor,
    required this.onComplete,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: Text('DONE (+${GameRules.pointsForCompletion})'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onFail,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.close_rounded),
          label: Text('SKIP (-${GameRules.pointsForFailure})'),
        ),
      ],
    );
  }
}
