import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  final List<Player> players;
  final VoidCallback onContinue;

  const LeaderboardScreen({super.key, required this.players, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final rankedPlayers = [...players]
      ..sort((first, second) {
        final scoreComparison = second.score.compareTo(first.score);
        return scoreComparison != 0 ? scoreComparison : first.name.compareTo(second.name);
      });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 460),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.outline),
          boxShadow: [BoxShadow(color: AppColors.neonPink.withOpacity(.14), blurRadius: 34)],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.gold.withOpacity(.12), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.leaderboard_rounded, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('ROUND RESULTS', style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1))),
                IconButton(tooltip: 'Continue game', icon: const Icon(Icons.close_rounded, color: AppColors.muted), onPressed: onContinue),
              ],
            ),
            const Divider(height: 18),
            if (rankedPlayers.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 36), child: Text('No players to rank yet.', style: TextStyle(color: AppColors.muted)))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rankedPlayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = rankedPlayers[index];
                    final rank = index + 1;
                    final color = _rankColor(rank);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: rank == 1 ? AppColors.gold.withOpacity(.08) : AppColors.surfaceRaised.withOpacity(.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(.34)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 17, backgroundColor: color.withOpacity(.18), child: Text('$rank', style: TextStyle(color: color, fontWeight: FontWeight.w900))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(player.hasCompletedTurn ? 'Turn complete' : 'Ready for this round', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('${player.score} pts', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('CONTINUE GAME'),
              ),
            ),
            const SizedBox(height: 10),
            Text('Complete +${GameRules.pointsForCompletion}  •  Skip −${GameRules.pointsForFailure}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return const Color(0xFFC9C6D0);
      case 3:
        return const Color(0xFFD59A70);
      default:
        return AppColors.neonBlue;
    }
  }
}
