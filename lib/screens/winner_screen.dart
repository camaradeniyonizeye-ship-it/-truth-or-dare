import 'package:flutter/material.dart';
import '../models/player.dart';

class WinnerScreen extends StatelessWidget {
  final Player winner;
  final List<Player> players;
  final VoidCallback onRestart;

  const WinnerScreen({
    super.key,
    required this.winner,
    required this.players,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/winner_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 100),
                const SizedBox(height: 20),
                const Text(
                  'WINNER!',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  winner.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${winner.score} Points',
                  style: const TextStyle(color: Color(0xFFFF0080), fontSize: 22),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('PLAY AGAIN',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
