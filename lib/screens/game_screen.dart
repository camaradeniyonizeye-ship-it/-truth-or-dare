import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../models/game_rules.dart'; // Ensure you have your GameRules imported if separate
import '../utils/question_loader.dart';
import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';
import '../widgets/player_spinner.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final List<Question> questions;

  const GameScreen({
    super.key,
    required this.players,
    required this.questions,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  Player? _currentPlayer;
  Question? _currentQuestion;
  String _activeType = '';
  bool _isTurnActive = false;

  // Timer state variables (30s total: 10s reading, 20s action)
  Timer? _dareTimer;
  int _remainingSeconds = 30;
  bool _isTimerActive = false;

  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _dareTimer?.cancel();
    _cardController.dispose();
    super.dispose();
  }

  void _startDareTimer() {
    _dareTimer?.cancel();
    setState(() {
      _remainingSeconds = 30;
      _isTimerActive = true;
    });

    _dareTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerActive = false;
        });
        AudioService.playClick();
      }
    });
  }

  void _onPlayerSelected(Player selectedPlayer) {
    AudioService.playClick();
    setState(() {
      _currentPlayer = selectedPlayer;
      _isTurnActive = true;
      _currentQuestion = null;
      _activeType = '';
      _isTimerActive = false;
    });
    _cardController.forward(from: 0.0);
  }

  void _selectType(String type) {
    AudioService.playClick();
    _dareTimer?.cancel();

    final available = widget.questions.where((q) => q.type.toLowerCase() == type.toLowerCase()).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more questions in this category!')),
      );
      return;
    }

    available.shuffle();
    final rawQuestion = available.first;
    
    final processedText = QuestionLoader.processQuestionText(
      rawQuestion.text,
      _currentPlayer,
      widget.players,
    );

    setState(() {
      _activeType = type;
      _currentQuestion = Question(
        id: rawQuestion.id,
        type: rawQuestion.type,
        text: processedText,
        category: rawQuestion.category,
      );
      _isTimerActive = false;
    });

    _cardController.forward(from: 0.0);

    if (type.toLowerCase() == 'dare') {
      _startDareTimer();
    }
  }

  void _recordChallengeResult(bool completed) {
    AudioService.playClick();
    _dareTimer?.cancel();

    if (_currentPlayer != null) {
      // Apply scoring rules (+10 on completion, -5 on failure/skip)
      final delta = completed ? 10 : -5;
      _currentPlayer!.score = (_currentPlayer!.score + delta).clamp(0, 0x7fffffff);
      _currentPlayer!.hasCompletedTurn = true;
    }

    // Check if round cycle is complete
    final allDone = widget.players.every((p) => p.hasCompletedTurn);
    if (allDone) {
      for (var p in widget.players) {
        p.hasCompletedTurn = false;
      }
    }

    setState(() {
      _currentPlayer = null;
      _isTurnActive = false;
      _currentQuestion = null;
      _activeType = '';
      _isTimerActive = false;
    });
    _cardController.forward(from: 0.0);
  }

  void _showLeaderboard() {
    AudioService.playClick();
    final sortedPlayers = List<Player>.from(widget.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonPink.withOpacity(0.4), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.leaderboard_rounded, color: AppColors.neonPink),
            SizedBox(width: 10),
            Text(
              'SCOREBOARD',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              final isLeader = index == 0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isLeader ? AppColors.neonPink.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLeader ? AppColors.neonPink : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: isLeader ? AppColors.neonPink : AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${player.score} PTS',
                      style: TextStyle(
                        color: isLeader ? AppColors.neonPink : AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerAccent = _currentPlayer != null && _currentPlayer!.gender.toLowerCase() == 'male' 
        ? AppColors.neonBlue 
        : AppColors.neonPink;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlayer == null ? 'SPIN FOR YOUR FATE' : '${_currentPlayer!.name.toUpperCase()}\'S TURN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: AppColors.neonPink),
            tooltip: 'View Leaderboard',
            onPressed: _showLeaderboard,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _dareTimer?.cancel();
            Navigator.pop(context);
          },
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_currentPlayer != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: playerAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: playerAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded, size: 16, color: playerAccent),
                            const SizedBox(width: 6),
                            Text(
                              _currentPlayer!.name,
                              style: TextStyle(
                                color: playerAccent,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Score: ${_currentPlayer!.score}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),

                ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: !_isTurnStatusActive()
                        ? PlayerSpinner(
                            players: widget.players,
                            onPlayerSelected: _onPlayerSelected,
                          )
                        : (_currentQuestion == null
                            ? _buildChoiceSelectorCard()
                            : _buildChallengeCard()),
                  ),
                ),

                const Spacer(),

                // Outcome Action Buttons (Completed vs Failed)
                if (_currentQuestion != null)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonRed.withOpacity(0.2),
                              side: const BorderSide(color: AppColors.neonRed, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _recordChallengeResult(false),
                            icon: const Icon(Icons.close_rounded, color: AppColors.neonRed),
                            label: const Text(
                              'FAILED (-5)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.neonRed),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonGreen.withOpacity(0.2),
                              side: const BorderSide(color: AppColors.neonGreen, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _recordChallengeResult(true),
                            icon: const Icon(Icons.check_rounded, color: AppColors.neonGreen),
                            label: const Text(
                              'COMPLETED (+10)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.neonGreen),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isTurnStatusActive() {
    return _isTurnActive && _currentPlayer != null;
  }

  Widget _buildChoiceSelectorCard() {
    return AppGlassPanel(
      key: const ValueKey('selector'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHOOSE YOUR FATE',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentPlayer?.name ?? "Player"}, truth or dare?',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue.withOpacity(0.2),
                      side: const BorderSide(color: AppColors.neonBlue, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _selectType('truth'),
                    child: const Text(
                      'TRUTH',
                      style: TextStyle(color: AppColors.neonBlue, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPink.withOpacity(0.2),
                      side: const BorderSide(color: AppColors.neonPink, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _selectType('dare'),
                    child: const Text(
                      'DARE',
                      style: TextStyle(color: AppColors.neonPink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    final isTruth = _activeType.toLowerCase() == 'truth';
    final accentColor = isTruth ? AppColors.neonBlue : AppColors.neonPink;

    String timerStatusText = '';
    if (!isTruth && _isTimerActive) {
      if (_remainingSeconds > 20) {
        timerStatusText = '📖 READING & PREPARING (${_remainingSeconds - 20}s)';
      } else {
        timerStatusText = '⚡ ACTION TIME! (${_remainingSeconds}s remaining)';
      }
    } else if (!isTruth && !_isTimerActive && _remainingSeconds == 0) {
      timerStatusText = '⏰ TIME IS UP!';
    }

    return AppGlassPanel(
      key: const ValueKey('challenge'),
      accent: accentColor,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _activeType.toUpperCase(),
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _currentQuestion!.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isTruth) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / 30.0,
                    strokeWidth: 3,
                    color: accentColor,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  timerStatusText,
                  style: TextStyle(
                    color: _remainingSeconds <= 5 && _isTimerActive ? AppColors.neonRed : accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
