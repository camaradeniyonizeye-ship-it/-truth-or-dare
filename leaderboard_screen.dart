import 'package:flutter/material.dart';
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
    final sorted = [...players];
    sorted.sort((a, b) => b.score.compareTo(a.score));

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF0080), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LEADERBOARD',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onContinue,
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (ctx, i) {
                final p = sorted[i];
                final rank = i + 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _getRankColor(rank), width: 1.5),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(rank),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${p.score} pts',
                        style: const TextStyle(color: Colors.white70)),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: onContinue,
            child: const Text('CONTINUE GAME'),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
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
