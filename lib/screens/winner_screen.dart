import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';

class WinnerScreen extends StatelessWidget {
  final Player winner;
  final List<Player> players;
  final VoidCallback onRestart;
  const WinnerScreen({super.key, required this.winner, required this.players, required this.onRestart});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/winner_bg.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.background)),
          const ColoredBox(color: Color(0xCC090711)),
          AppBackground(child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 112, height: 112, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.12), border: Border.all(color: AppColors.gold.withOpacity(.55)), boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(.16), blurRadius: 35)]), child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 60)),
            const SizedBox(height: 24),
            const Text('THE CHAMPION', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 12),
            Text(winner.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 38)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: AppColors.surface.withOpacity(.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.outline)), child: Text('${winner.score} POINTS', style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onRestart, icon: const Icon(Icons.replay_rounded), label: const Text('PLAY AGAIN'))),
            const SizedBox(height: 15),
            Text('${players.length} players brought the energy tonight', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]))))),
        ]),
      );
}
