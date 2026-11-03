import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/player.dart';

class LeaderboardScreen extends StatelessWidget {
  final List<Player> players;
  final VoidCallback onContinue;

  const LeaderboardScreen({
    super.key,
    required this.players,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final rankedPlayers = [...players]
      ..sort((first, second) {
        final scoreComparison = second.score.compareTo(first.score);
        return scoreComparison != 0 ? scoreComparison : first.name.compareTo(second.name);
      });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560, maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF111018),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF0080), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0080).withOpacity(0.22),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFD700)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'LEADERBOARD',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Continue game',
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onContinue,
                ),
              ],
            ),
            const Divider(color: Color(0x55FF0080), thickness: 1),
            if (rankedPlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Text('No players to rank yet.', style: TextStyle(color: Colors.white70)),
              )
            else ...[
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rankedPlayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = rankedPlayers[index];
                    final rank = index + 1;
                    final rankColor = _rankColor(rank);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: rank == 1 ? const Color(0xFF282313) : const Color(0xFF1C1A23),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: rankColor.withOpacity(0.65)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: rankColor,
                          foregroundColor: Colors.black,
                          child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        title: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          player.hasCompletedTurn ? 'Turn complete' : 'Ready for this round',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${player.score} pts',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'CONTINUE GAME',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete +${GameRules.pointsForCompletion}  •  Skip -${GameRules.pointsForFailure}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF0080FF);
    }
  }
}
