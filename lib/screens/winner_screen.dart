import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/player.dart';
import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';

class WinnerScreen extends StatefulWidget {
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
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  late ConfettiController _confettiController;
  bool _showConfetti = false;
  bool _animatedIn = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    // Initialize confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    // Start animations
    _animationController.forward();
    
    // Start confetti after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showConfetti = true);
        _confettiController.play();
      }
    });
    
    // Mark as animated in
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _animatedIn = true);
    });
    
    // Play victory sound
    if (AudioService.sfxEnabled) {
      AudioService.playClick();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort players by score
    final rankedPlayers = [...widget.players]
      ..sort((a, b) => b.score.compareTo(a.score));
    
    // Get winner's rank
    final winnerRank = rankedPlayers.indexWhere((p) => p.id == widget.winner.id) + 1;

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              'assets/images/winner_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.background,
              ),
            ),
            
            // Dark overlay
            const ColoredBox(color: Color(0xCC090711)),
            
            // Confetti
            if (_showConfetti)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  colors: const [
                    Colors.red,
                    Colors.pink,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.white,
                    AppColors.gold,
                  ],
                  emissionFrequency: 0.5,
                  numberOfParticles: 20,
                  maxBlastForce: 120,
                  minBlastForce: 80,
                  gravity: 0.3,
                ),
              ),
            
            // Main Content
            AppBackground(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedOpacity(
                      opacity: _animatedIn ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Trophy with Animation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold.withOpacity(.12),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(.55),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(.16),
                                    blurRadius: 35,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.gold,
                                size: 60,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Champion Label
                          FadeTransition(
                            opacity: _opacityAnimation,
                            child: const Text(
                              'THE CHAMPION',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Winner Name with Animation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Text(
                              widget.winner.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Score Badge
                          FadeTransition(
                            opacity: _opacityAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(.9),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppColors.outline),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${widget.winner.score} POINTS',
                                style: const TextStyle(
                                  color: AppColors.neonPink,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Play Again Button
                          FadeTransition(
                            opacity: _opacityAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  if (AudioService.sfxEnabled) {
                                    AudioService.playClick();
                                  }
                                  widget.onRestart();
                                },
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('PLAY AGAIN'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Player Count
                          FadeTransition(
                            opacity: _opacityAnimation,
                            child: Text(
                              '${widget.players.length} players brought the energy tonight',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Podium/Leaderboard
                          if (widget.players.length > 1)
                            FadeTransition(
                              opacity: _opacityAnimation,
                              child: _buildPodium(rankedPlayers),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<Player> rankedPlayers) {
    // Take top 3 players
    final topPlayers = rankedPlayers.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'LEADERBOARD',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3rd Place
            if (topPlayers.length > 2)
              _buildPodiumPosition(
                topPlayers[2],
                3,
                AppColors.neonPurple,
                80,
              ),
            
            const SizedBox(width: 16),
            
            // 1st Place (Winner)
            _buildPodiumPosition(
              topPlayers[0],
              1,
              AppColors.gold,
              100,
            ),
            
            const SizedBox(width: 16),
            
            // 2nd Place
            if (topPlayers.length > 1)
              _buildPodiumPosition(
                topPlayers[1],
                2,
                const Color(0xFFC9C6D0), // Silver
                80,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumPosition(Player player, int position, Color color, double height) {
    return Column(
      children: [
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              position == 1 ? '🥇' : position == 2 ? '🥈' : '🥉',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          player.name,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${player.score} pts',
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
