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
    return LayoutBuilder(
      builder: (context, outerConstraints) => Container(
        width: double.infinity,
        height: outerConstraints.maxHeight,
        margin: const EdgeInsets.fromLTRB(13, 14, 13, 14),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF130D17),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withOpacity(.95), width: 1.8),
          boxShadow: [
            BoxShadow(color: color.withOpacity(.3), blurRadius: 30, spreadRadius: 1),
            BoxShadow(color: Colors.black.withOpacity(.48), blurRadius: 18, offset: const Offset(0, 10)),
          ],
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            opacity: .13,
            onError: (_, __) {},
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(.5))),
                  child: const Text('18+', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(.05), color.withOpacity(.8), color.withOpacity(.05)]))),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, questionConstraints) => Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: questionConstraints.maxWidth,
                      child: Text(
                        question.text,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: _questionFontSize(question.text.length),
                          fontWeight: FontWeight.w800,
                          height: 1.28,
                          letterSpacing: -.2,
                          shadows: [Shadow(color: color.withOpacity(.38), blurRadius: 16)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withOpacity(.08)),
            ...content,
          ],
        ),
      ),
    );
  }

  double _questionFontSize(int length) {
    if (length > 180) return 17;
    if (length > 120) return 19;
    if (length > 75) return 22;
    return 26;
  }
}

class ChallengeActions extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const ChallengeActions({super.key, required this.primaryColor, required this.onComplete, required this.onFail});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: primaryColor.withOpacity(.7),
                elevation: 8,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text('DONE  +${GameRules.pointsForCompletion}'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onFail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: BorderSide(color: Colors.white.withOpacity(.24)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text('SKIP  −${GameRules.pointsForFailure}'),
            ),
          ],
        ),
      );
}
