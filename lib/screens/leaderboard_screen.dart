import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../models/game_rules.dart';
import '../models/player.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final List<Player> players;
  final VoidCallback onContinue;

  const LeaderboardScreen({
    super.key,
    required this.players,
    required this.onContinue,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late ConfettiController _confettiController;
  bool _showConfetti = false;
  bool _animatedIn = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    // Trigger confetti if there's a winner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ranked = [...widget.players]
        ..sort((a, b) => b.score.compareTo(a.score));
      if (ranked.isNotEmpty && ranked.first.score > 0) {
        setState(() => _showConfetti = true);
        _confettiController.play();
      }
    });
    
    // Animate in after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animatedIn = true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankedPlayers = [...widget.players]
      ..sort((first, second) {
        final scoreComparison = second.score.compareTo(first.score);
        return scoreComparison != 0 
            ? scoreComparison 
            : first.name.compareTo(second.name);
      });

    final winner = rankedPlayers.isNotEmpty ? rankedPlayers.first : null;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti for winner
        if (_showConfetti)
          Positioned(
            top: 40,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.pink,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.white,
              ],
              emissionFrequency: 0.3,
              numberOfParticles: 30,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.3,
            ),
          ),
        
        // Main dialog
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(
              0,
              _animatedIn ? 0 : 20,
              0,
            ),
            transformAlignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600, maxWidth: 460),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.outline),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPink.withOpacity(.14),
                    blurRadius: 34,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      key: ValueKey<bool>(_animatedIn),
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.leaderboard_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ROUND RESULTS',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Continue game',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.muted,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (AudioService.sfxEnabled) {
                              AudioService.playClick();
                            }
                            widget.onContinue();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const AnimatedDivider(
                    height: 18,
                    color: AppColors.outline,
                  ),
                  
                  // Winner celebration
                  if (winner != null && winner.score > 0 && rankedPlayers.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withOpacity(0.2),
                              AppColors.gold.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${winner.name} is leading with ${winner.score} points!',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Player list
                  if (rankedPlayers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Text(
                        'No players to rank yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: rankedPlayers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final player = rankedPlayers[index];
                          final rank = index + 1;
                          final color = _rankColor(rank);
                          
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              0,
                              _animatedIn ? 0 : 20,
                              0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey<String>('${player.id}_$rank'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: rank == 1 
                                      ? AppColors.gold.withOpacity(.08)
                                      : AppColors.surfaceRaised.withOpacity(.75),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: color.withOpacity(.34),
                                  ),
                                  boxShadow: rank == 1
                                      ? [
                                          BoxShadow(
                                            color: AppColors.gold.withOpacity(0.1),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Rank badge
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
                                      transform: rank == 1
                                          ? Matrix4.identity()
                                          : Matrix4.translationValues(0, 0, 0),
                                      child: CircleAvatar(
                                        radius: 17,
                                        backgroundColor: color.withOpacity(.18),
                                        child: rank == 1
                                            ? Icon(
                                                Icons.star_rounded,
                                                color: color,
                                                size: 18,
                                              )
                                            : Text(
                                                '$rank',
                                                style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Player info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: rank == 1 
                                                  ? AppColors.gold
                                                  : AppColors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                player.hasCompletedTurn
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                size: 12,
                                                color: player.hasCompletedTurn
                                                    ? AppColors.neonGreen
                                                    : AppColors.muted,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                player.hasCompletedTurn
                                                    ? 'Turn complete'
                                                    : 'Ready for this round',
                                                style: TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Score
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOutBack,
                                      transform: rank == 1
                                          ? Matrix4.translationValues(0, 0, 0)
                                          : Matrix4.translationValues(0, 0, 0),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${player.score}',
                                            style: TextStyle(
                                              color: rank == 1
                                                  ? AppColors.gold
                                                  : AppColors.gold,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'pts',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Continue button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (AudioService.sfxEnabled) {
                            AudioService.playClick();
                          }
                          widget.onContinue();
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('CONTINUE GAME'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Scoring info
                  AnimatedOpacity(
                    opacity: _animatedIn ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'Complete +${GameRules.pointsForCompletion}  •  Skip −${GameRules.pointsForFailure}',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return const Color(0xFFC9C6D0); // Silver
      case 3:
        return const Color(0xFFD59A70); // Bronze
      default:
        return AppColors.neonBlue;
    }
  }
}

// Animated Divider
class AnimatedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const AnimatedDivider({
    super.key,
    this.height = 18,
    this.color = AppColors.outline,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: 1,
          width: MediaQuery.of(context).size.width * 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                color,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
