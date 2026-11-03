import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';
import '../utils/question_loader.dart';
import '../widgets/audio_toggle_button.dart';
import '../widgets/dare_card.dart';
import '../widgets/player_spinner.dart';
import '../widgets/truth_card.dart';
import 'leaderboard_screen.dart';
import 'winner_screen.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final List<Question> questions;

  const GameScreen({super.key, required this.players, required this.questions});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  final math.Random _random = math.Random();
  final Map<String, String> _lastChosenTypePerPlayer = {};

  String _selectedType = '';
  Player? _selectedPlayer;
  Question? _currentQuestion;
  bool _showPlayerSpinner = true;
  bool _showTypeSelector = false;
  bool _showQuestion = false;
  bool _isResolvingChallenge = false;
  Timer? _challengeTimer;
  int _challengeSecondsLeft = GameRules.dareDurationSeconds;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(players: List.of(widget.players), questions: widget.questions);
    AudioService.playBackground();
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    AudioService.stopAll();
    super.dispose();
  }

  void _onPlayerSelected(Player player) {
    AudioService.playWheelSpin();
    setState(() {
      _selectedPlayer = player;
      _showPlayerSpinner = false;
      _showTypeSelector = true;
      _selectedType = '';
    });
  }

  void _selectType(String type) {
    final player = _selectedPlayer;
    if (player != null &&
        type == 'truth' &&
        _lastChosenTypePerPlayer[player.id] == 'truth') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You chose Truth last turn! You must take a Dare this time.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    AudioService.playClick();
    setState(() => _selectedType = type);
  }

  void _startQuestion() {
    final player = _selectedPlayer;
    if (_selectedType.isEmpty || player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Truth or Dare.')),
      );
      return;
    }

    final matchingQuestions = _gameState.questions
        .where((question) => question.type.toLowerCase() == _selectedType)
        .toList();
    final unusedQuestions = matchingQuestions
        .where((question) => !_gameState.usedQuestions.contains(question))
        .toList();
    final pool = unusedQuestions.isNotEmpty ? unusedQuestions : matchingQuestions;
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions are available for this type.')),
      );
      return;
    }

    final selected = pool[_random.nextInt(pool.length)];
    final processedText = QuestionLoader.processQuestionText(
      selected.text,
      player,
      _gameState.players,
    );
    _challengeTimer?.cancel();
    _lastChosenTypePerPlayer[player.id] = _selectedType;

    setState(() {
      _currentQuestion = selected.copyWith(text: processedText);
      _gameState = _gameState.copyWith(
        currentType: _selectedType,
        currentQuestionIndex: _gameState.questions.indexOf(selected),
        usedQuestions: [..._gameState.usedQuestions, selected],
        currentPlayerIndex:
            _gameState.players.indexWhere((item) => item.id == player.id),
      );
      _challengeSecondsLeft = GameRules.dareDurationSeconds;
      _showTypeSelector = false;
      _showQuestion = true;
      _isResolvingChallenge = false;
    });
    AudioService.playCardFlip();
    if (_selectedType == 'dare') _startDareTimer();
  }

  void _startDareTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted ||
          _selectedPlayer == null ||
          _currentQuestion?.type.toLowerCase() != 'dare') {
        timer.cancel();
        return;
      }
      if (_challengeSecondsLeft <= 1) {
        timer.cancel();
        _applyChallengeResult(successful: false, timedOut: true);
        return;
      }
      setState(() => _challengeSecondsLeft--);
    });
  }

  void _applyChallengeResult({required bool successful, bool timedOut = false}) {
    final player = _selectedPlayer;
    if (player == null || _currentQuestion == null || _isResolvingChallenge) return;
    _isResolvingChallenge = true;
    _challengeTimer?.cancel();
    AudioService.playClick();

    final updatedPlayer = player.copyWith(
      score: GameRules.scoreAfterChallenge(
        currentScore: player.score,
        completed: successful,
      ),
      hasCompletedTurn: true,
    );
    final updatedPlayers = [..._gameState.players];
    final playerIndex = updatedPlayers.indexWhere((item) => item.id == player.id);
    if (playerIndex == -1) {
      _isResolvingChallenge = false;
      return;
    }
    updatedPlayers[playerIndex] = updatedPlayer;

    final resultText = successful
        ? '${player.name} completed the challenge! +${GameRules.pointsForCompletion} points.'
        : timedOut
            ? '${player.name} ran out of time. -${GameRules.pointsForFailure} points.'
            : '${player.name} skipped the challenge. -${GameRules.pointsForFailure} points.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultText),
        backgroundColor: successful ? AppColors.neonGreen : AppColors.neonRed,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _gameState = _gameState.copyWith(players: updatedPlayers, currentType: '');
      _selectedType = '';
      _showQuestion = false;
      _showPlayerSpinner = true;
      _selectedPlayer = null;
      _currentQuestion = null;
      _challengeSecondsLeft = GameRules.dareDurationSeconds;
      _isResolvingChallenge = false;
    });

    if (updatedPlayers.isNotEmpty &&
        updatedPlayers.every((item) => item.hasCompletedTurn)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLeaderboard(resetRoundOnContinue: true);
      });
    }
  }

  void _showLeaderboard({bool resetRoundOnContinue = false}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LeaderboardScreen(
        players: _gameState.players,
        onContinue: () {
          Navigator.of(dialogContext).pop();
          if (!resetRoundOnContinue || !mounted) return;
          setState(() {
            _gameState = _gameState.copyWith(
              players: _gameState.players
                  .map((player) => player.copyWith(hasCompletedTurn: false))
                  .toList(),
            );
          });
        },
      ),
    );
  }

  Future<void> _endGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: AppGlassPanel(
          accent: AppColors.neonPink,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.neonPink, size: 35),
              const SizedBox(height: 14),
              const Text('End the game?', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Your current scores will decide the winner.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('KEEP PLAYING'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('END GAME'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final winner = _gameState.getWinner();
    if (winner == null) return;
    AudioService.playWinner();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WinnerScreen(
          winner: winner,
          players: _gameState.players,
          onRestart: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final truthDisabled = _selectedPlayer != null &&
        _lastChosenTypePerPlayer[_selectedPlayer!.id] == 'truth';
    final stage = _showPlayerSpinner
        ? 'wheel'
        : _showTypeSelector
            ? 'choice'
            : 'challenge';

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPlayer != null
            ? "${_selectedPlayer!.name.toUpperCase()}'S TURN"
            : 'TRUTH OR DARE'),
        actions: [
          const AudioToggleButton(),
          IconButton(
            tooltip: 'Show leaderboard',
            icon: const Icon(Icons.leaderboard_rounded, color: AppColors.gold),
            onPressed: () => _showLeaderboard(),
          ),
          IconButton(
            tooltip: 'End game',
            icon: const Icon(Icons.flag_rounded, color: AppColors.neonPink),
            onPressed: _endGame,
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 7, 18, 5),
                child: Row(
                  children: [
                    Expanded(
                      child: _progressPill(
                        'ROUND',
                        _gameState.players.where((player) => player.hasCompletedTurn).length,
                        _gameState.players.length,
                      ),
                    ),
                    const SizedBox(width: 9),
                    _progressPill(
                      'TOTAL SCORE',
                      _gameState.players.fold<int>(0, (sum, p) => sum + p.score),
                      null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(stage),
                    child: _showPlayerSpinner
                        ? _buildSpinnerStage()
                        : _showTypeSelector
                            ? _buildChoiceStage(truthDisabled)
                            : _buildQuestionStage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressPill(String label, int value, int? total) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.055),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .9)),
            const SizedBox(width: 7),
            Text(total == null ? '$value' : '$value/$total', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _buildSpinnerStage() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSectionLabel('Every turn starts with a spin'),
              const SizedBox(height: 8),
              Text('Who’s up next?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 6),
              const Text('Let fate choose your player.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              AppGlassPanel(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: PlayerSpinner(players: _gameState.players, onPlayerSelected: _onPlayerSelected),
              ),
            ],
          ),
        ),
      );

  Widget _buildChoiceStage(bool truthDisabled) {
    final accent = _getGenderColor(_selectedPlayer?.gender ?? 'Other');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(.14), border: Border.all(color: accent.withOpacity(.4))),
              child: Icon(Icons.person_rounded, color: accent, size: 34),
            ),
            const SizedBox(height: 14),
            const AppSectionLabel('Your moment'),
            const SizedBox(height: 8),
            Text("${_selectedPlayer?.name ?? ''}'s turn", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30)),
            const SizedBox(height: 7),
            const Text('Choose your path for this round.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            if (truthDisabled)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: AppGlassPanel(
                  accent: AppColors.neonPink,
                  padding: const EdgeInsets.all(11),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColors.neonPink, size: 18),
                      SizedBox(width: 9),
                      Expanded(child: Text('Truth is locked this turn—you chose it last time.', style: TextStyle(color: AppColors.white, fontSize: 12))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _choiceCard('TRUTH', 'Be honest. No dodging.', Icons.visibility_rounded, AppColors.neonPurple, truthDisabled)),
                const SizedBox(width: 12),
                Expanded(child: _choiceCard('DARE', 'Take the challenge.', Icons.bolt_rounded, AppColors.neonPink, false)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedType.isNotEmpty ? _startQuestion : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('REVEAL MY PROMPT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceCard(String title, String subtitle, IconData icon, Color color, bool disabled) {
    final selected = _selectedType == title.toLowerCase();
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: title,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? .38 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => _selectType(title.toLowerCase()),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(.18) : Colors.white.withOpacity(.045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: selected ? color : Colors.white.withOpacity(.12), width: selected ? 1.7 : 1),
                boxShadow: selected ? [BoxShadow(color: color.withOpacity(.16), blurRadius: 24)] : [],
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 29),
                  const SizedBox(height: 11),
                  Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 5),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 10, height: 1.3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionStage() {
    final question = _currentQuestion;
    if (question == null) return const SizedBox.shrink();
    final isTruth = question.type.toLowerCase() == 'truth';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: isTruth
          ? TruthCard(
              question: question,
              onComplete: () => _applyChallengeResult(successful: true),
              onFail: () => _applyChallengeResult(successful: false),
            )
          : DareCard(
              question: question,
              countdownSeconds: _challengeSecondsLeft,
              onComplete: () => _applyChallengeResult(successful: true),
              onFail: () => _applyChallengeResult(successful: false),
            ),
    );
  }

  Color _getGenderColor(String gender) =>
      gender == 'Male' ? AppColors.neonBlue : AppColors.neonPink;
}
