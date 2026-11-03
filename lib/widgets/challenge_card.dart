import 'package:flutter/material.dart';
import '../models/game_rules.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';

class ChallengeCardSurface extends StatelessWidget {
  final Color color;
  final String imagePath;
  final String title;
  final Question question;
  final List<Widget> content;
  const ChallengeCardSurface({super.key, required this.color, required this.imagePath, required this.title, required this.question, required this.content});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: AppColors.surface,
          border: Border.all(color: color.withOpacity(.75), width: 1.4),
          boxShadow: [BoxShadow(color: color.withOpacity(.13), blurRadius: 32, spreadRadius: 1)],
          image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover, opacity: .14, onError: (_, __) {}),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7), decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(.35))), child: Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.4))),
          const SizedBox(height: 24),
          const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 20),
          const SizedBox(height: 14),
          Flexible(child: SingleChildScrollView(child: Text(question.text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.4, letterSpacing: -.2)))),
          ...content,
        ]),
      );
}

class ChallengeActions extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  const ChallengeActions({super.key, required this.primaryColor, required this.onComplete, required this.onFail});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ElevatedButton.icon(onPressed: onComplete, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.check_circle_outline_rounded), label: Text('DONE  +${GameRules.pointsForCompletion}')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onFail, style: OutlinedButton.styleFrom(foregroundColor: AppColors.muted, side: const BorderSide(color: AppColors.outline), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.skip_next_rounded), label: Text('SKIP  −${GameRules.pointsForFailure}')),
      ]);
}
