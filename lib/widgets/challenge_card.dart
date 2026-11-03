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
      builder: (context, constraints) => Container(
        // Let the card use virtually all the available game area. The outer
        // margin is accounted for by its parent constraints rather than being
        // added on top of a max-height sized card.
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 15),
          decoration: BoxDecoration(
            color: const Color(0xFF130D17),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withOpacity(.95), width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(.34), blurRadius: 30, spreadRadius: 1),
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
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: color, size: 19),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(.55))),
                    child: const Text('18+', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(.04), color.withOpacity(.85), color.withOpacity(.04)]))),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, questionConstraints) {
                    final fontSize = _fittingFontSize(
                      context,
                      question.text,
                      questionConstraints.maxWidth,
                      questionConstraints.maxHeight,
                    );
                    return Center(
                      child: Text(
                        question.text,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.27,
                          letterSpacing: -.15,
                          shadows: [Shadow(color: color.withOpacity(.42), blurRadius: 16)],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: Colors.white.withOpacity(.09)),
              ...content,
            ],
          ),
        ),
      ),
    );
  }

  // Keep the prompt large and legible. Only step down when its full wrapped
  // text would not fit in the generously sized card area; never make the card
  // itself shrink to accommodate the prompt.
  double _fittingFontSize(BuildContext context, String text, double width, double height) {
    final direction = Directionality.of(context);
    for (var size = 27.0; size >= 18; size -= 1) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, height: 1.27, letterSpacing: -.15),
        ),
        textDirection: direction,
      )..layout(maxWidth: width);
      if (painter.height <= height) return size;
    }
    return 18;
  }
}

class ChallengeActions extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const ChallengeActions({super.key, required this.primaryColor, required this.onComplete, required this.onFail});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: primaryColor.withOpacity(.7),
                elevation: 8,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text('DONE  +${GameRules.pointsForCompletion}'),
            ),
            const SizedBox(height: 7),
            OutlinedButton.icon(
              onPressed: onFail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: BorderSide(color: Colors.white.withOpacity(.24)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text('SKIP  −${GameRules.pointsForFailure}'),
            ),
          ],
        ),
      );
}
